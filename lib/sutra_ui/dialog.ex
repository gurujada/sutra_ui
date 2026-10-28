defmodule SutraUI.Dialog do
  @moduledoc """
  A modal dialog component using div-based overlay (screen share compatible).

  Uses a div-based implementation instead of native `<dialog>` element to ensure
  compatibility with screen sharing tools like Zoom, Google Meet, etc. The native
  dialog's "top layer" rendering can be invisible during screen shares.

  ## Examples

      # Basic confirmation dialog (server-controlled)
      <.dialog id="confirm-dialog" show={@show_confirm} on_cancel="close_confirm">
        <:title>Confirm Action</:title>
        <:description>Are you sure you want to proceed?</:description>
        This action cannot be undone.
        <:footer>
          <.button variant="outline" phx-click="close_confirm">Cancel</.button>
          <.button phx-click="confirm">Confirm</.button>
        </:footer>
      </.dialog>

      # Open by setting assign
      def handle_event("open_confirm", _, socket) do
        {:noreply, assign(socket, show_confirm: true)}
      end

      def handle_event("close_confirm", _, socket) do
        {:noreply, assign(socket, show_confirm: false)}
      end

      # Or open with JS commands
      <.button phx-click={SutraUI.Dialog.show_dialog("confirm-dialog")}>
        Open Dialog
      </.button>

      # Form inside dialog
      <.dialog id="edit-user-dialog" show={@show_edit} on_cancel="cancel_edit">
        <:title>Edit Profile</:title>
        <.form for={@form} class="form" phx-submit="save_user">
          <.input field={@form[:name]} label="Name" />
          <.input field={@form[:email]} label="Email" type="email" />
          <div class="flex justify-end">
            <.button type="submit">Save Changes</.button>
          </div>
        </.form>
      </.dialog>

  ## Placement

  `placement` says where the panel sits. All of them are the same div-based dialog (focus
  trapped, Escape and the backdrop close it):

  | Placement | Phone (under 640 px; `side` under 768 px) | Wider |
  |-----------|--------------------------------------------|-------|
  | `center` (default) | centred card | centred card |
  | `side` | bottom sheet | docked right, full height, from 768 px; `size` sets the width |
  | `sheet` | bottom sheet | centred card |
  | `popover` | bottom sheet | a card hanging under its `anchor` (or the trigger that opened it) from 640 px, the page visible behind it |

      <.dialog id="filters" placement="side" size="lg" show={@show} on_cancel="close">...</.dialog>
      <.dialog id="why" placement="popover" anchor="#course-bar" show={@show} on_cancel="close">...</.dialog>

  A `popover` placement measures `anchor` (a CSS selector) when it opens and sets the card's
  top through the CSSOM (`--popover-top`), so no `style` attribute is rendered. Without
  `anchor` it hangs under the element that had focus when the dialog opened (the trigger).
  The card is centred; use `SutraUI.Popover` for a small card next to a button.

  ## Opening and Closing

  **Server-controlled (recommended):**

  Control visibility via the `show` assign and handle `on_cancel` event:

      <.dialog id="my-dialog" show={@show_dialog} on_cancel="close_dialog">
        ...
      </.dialog>

      def handle_event("close_dialog", _, socket) do
        {:noreply, assign(socket, show_dialog: false)}
      end

  **JS commands:**

  | Function | Description |
  |----------|-------------|
  | `show_dialog/1` | Opens dialog with animation |
  | `show_dialog/2` | Chain with existing JS commands |
  | `hide_dialog/1` | Closes dialog with animation |
  | `hide_dialog/2` | Chain with existing JS commands |

      # Open on button click
      <.button phx-click={SutraUI.Dialog.show_dialog("my-dialog")}>Open</.button>

      # Close from inside dialog
      <.button phx-click={SutraUI.Dialog.hide_dialog("my-dialog")}>Cancel</.button>

  ## Slots

  | Slot | Description |
  |------|-------------|
  | `title` | Dialog header title |
  | `description` | Explanatory text below title |
  | `inner_block` | Main content area |
  | `footer` | Action buttons, typically Cancel/Confirm |

  ## Accessibility

  - Uses `role="dialog"` and `aria-modal="true"`
  - `Escape` key closes the dialog
  - Click on backdrop closes the dialog (configurable)
  - Focus is trapped within the dialog when open (via `focus_wrap`)
  - `aria-labelledby` links to title
  - `aria-describedby` links to description

  ## Screen Sharing Compatibility

  Unlike the native `<dialog>` element which renders in the browser's "top layer",
  this div-based implementation renders in the normal document flow with fixed
  positioning and z-index. This ensures the dialog is visible when screen sharing.

  ## Related

  - `SutraUI.Popover` - For non-modal floating content
  - `SutraUI.DropdownMenu` - For menu interactions
  - `SutraUI.Command` - For command palette dialogs
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal dialog component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the dialog")
  attr(:show, :boolean, default: false, doc: "Whether the dialog is visible")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the dialog panel")

  attr(:on_cancel, :any,
    default: nil,
    doc: "Event name (string) or JS commands to execute when dialog is closed"
  )

  attr(:close_on_escape, :boolean, default: true, doc: "Whether ESC key closes the dialog")

  attr(:close_on_backdrop, :boolean,
    default: true,
    doc: "Whether clicking the backdrop closes the dialog"
  )

  attr(:placement, :string,
    default: "center",
    values: ~w(center side sheet popover),
    doc: "Where the panel sits; see the Placement section"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(md lg xl),
    doc: "Width of a `side` panel from 768 px: md 26rem, lg 44rem, xl 64rem"
  )

  attr(:anchor, :string,
    default: nil,
    doc: "CSS selector of the element a `popover` placement hangs under"
  )

  attr(:alert, :boolean,
    default: false,
    doc: "Renders `role=\"alertdialog\"`, for a question that interrupts (see `SutraUI.Confirm`)"
  )

  attr(:initial_focus, :string,
    default: nil,
    doc: "CSS selector (inside the panel) of the element that gets focus when the dialog opens"
  )

  attr(:inert_page, :boolean,
    default: false,
    doc:
      "Mark the rest of the page `inert` while open: nothing behind it can be clicked, focused or read by a screen reader"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "The main dialog content")
  slot(:title, doc: "The dialog title")
  slot(:description, doc: "The dialog description")
  slot(:footer, doc: "Footer content, typically action buttons")

  def dialog(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".Dialog"
      phx-mounted={@show && show_dialog(@id)}
      class={["dialog", @show && "is-open"]}
      data-close-on-backdrop={to_string(@close_on_backdrop)}
      data-placement={@placement}
      data-size={@placement == "side" && @size}
      data-anchor={@placement == "popover" && @anchor}
      data-show={to_string(@show)}
      data-alert={@alert && "true"}
      data-initial-focus={@initial_focus}
      data-inert-page={@inert_page && "true"}
      {@rest}
    >
      <.focus_wrap
        id={"#{@id}-focus-wrap"}
        class="dialog-focus"
        phx-window-keydown={@close_on_escape && close_action(@on_cancel, @id)}
        phx-key="escape"
      >
        <div
          class="dialog-backdrop"
          aria-hidden="true"
          phx-click={@close_on_backdrop && close_action(@on_cancel, @id)}
        >
        </div>

        <div
          id={"#{@id}-panel"}
          class={["dialog-panel", @class]}
          role={if @alert, do: "alertdialog", else: "dialog"}
          aria-modal="true"
          aria-labelledby={@title != [] && "#{@id}-title"}
          aria-describedby={@description != [] && "#{@id}-description"}
        >
          <header :if={@title != [] || @description != []}>
            <h2 :if={@title != []} id={"#{@id}-title"}>
              {render_slot(@title)}
            </h2>
            <p :if={@description != []} id={"#{@id}-description"}>
              {render_slot(@description)}
            </p>
          </header>

          <section>
            {render_slot(@inner_block)}
          </section>

          <footer :if={@footer != []}>
            {render_slot(@footer)}
          </footer>

          <button
            :if={@on_cancel}
            type="button"
            phx-click={close_action(@on_cancel, @id)}
            aria-label="Close"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <path d="M18 6 6 18" /><path d="m6 6 12 12" />
            </svg>
          </button>
        </div>
      </.focus_wrap>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Dialog">
      export default {
        mounted() {
          // A popover placement hangs under its anchor (or the trigger that had focus): the card's
          // top is set through the CSSOM, never a style attribute.
          this.place = () => {
            if (this.el.dataset.placement !== "popover") return;
            const anchor = this.el.dataset.anchor
              ? document.querySelector(this.el.dataset.anchor)
              : this.trigger;
            if (!anchor) return;
            const bottom = anchor.getBoundingClientRect().bottom + 8;
            this.el.style.setProperty("--popover-top", Math.max(8, Math.round(bottom)) + "px");
          };

          this.showHandler = () => {
            const active = document.activeElement;
            this.trigger = active && !this.el.contains(active) && active !== document.body ? active : this.trigger;
            this.place();
            this.el.classList.add("is-open");
            this.opened = true;
            this.setInert(true);
            // Focus the requested element, else the first focusable one
            requestAnimationFrame(() => {
              const panel = this.el.querySelector("[role='dialog'], [role='alertdialog']");
              if (panel) {
                const wanted = this.el.dataset.initialFocus && panel.querySelector(this.el.dataset.initialFocus);
                const focusable = wanted || panel.querySelector("button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])");
                if (focusable) focusable.focus();
              }
            });
          };

          this.hideHandler = () => {
            const wasOpen = this.el.classList.contains("is-open");
            this.el.classList.remove("is-open");
            this.opened = false;
            this.setInert(false);
            // Focus goes back to what opened the dialog
            if (wasOpen && this.trigger && this.trigger.isConnected) this.trigger.focus();
          };

          // inert_page: everything outside the dialog is inert while it is open. Only the
          // siblings along the path from the dialog up to <body> are marked, so the dialog
          // itself stays live.
          this.inerted = [];
          this.setInert = (on) => {
            if (this.el.dataset.inertPage !== "true") return;
            if (!on) {
              for (const node of this.inerted) node.inert = false;
              this.inerted = [];
              return;
            }
            let node = this.el;
            while (node && node !== document.body) {
              const parent = node.parentElement;
              if (!parent) break;
              for (const sibling of parent.children) {
                if (sibling !== node && !sibling.inert && sibling.tagName !== "SCRIPT") {
                  sibling.inert = true;
                  this.inerted.push(sibling);
                }
              }
              node = parent;
            }
          };

          this.opened = this.el.dataset.show === "true";
          this.serverShow = this.el.dataset.show;
          this.el.addEventListener("phx:show-dialog", this.showHandler);
          this.el.addEventListener("phx:hide-dialog", this.hideHandler);
          window.addEventListener("resize", this.place);
        },

        updated() {
          // A parent re-render resets the class attribute to the server's; an open dialog stays open.
          // When the server itself changed `show`, the server wins.
          if (this.el.dataset.show !== this.serverShow) this.opened = this.el.dataset.show === "true";
          this.serverShow = this.el.dataset.show;
          if (this.opened) this.el.classList.add("is-open");
          if (this.el.classList.contains("is-open")) this.place();
        },

        destroyed() {
          this.setInert(false);
          this.el.removeEventListener("phx:show-dialog", this.showHandler);
          this.el.removeEventListener("phx:hide-dialog", this.hideHandler);
          window.removeEventListener("resize", this.place);
        }
      }
    </script>
    """
  end

  # Helper to create appropriate close action
  defp close_action(nil, id), do: hide_dialog(id)
  defp close_action(js_commands, _id) when is_struct(js_commands, JS), do: js_commands

  defp close_action(event_name, id) when is_binary(event_name) do
    hide_dialog(id) |> JS.push(event_name)
  end

  @doc """
  Shows a dialog by ID.

  ## Examples

      <button phx-click={SutraUI.Dialog.show_dialog("my-dialog")}>Open</button>

      # Chain with other JS commands
      <button phx-click={JS.push("load_data") |> SutraUI.Dialog.show_dialog("my-dialog")}>
        Load and Open
      </button>
  """
  def show_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:show-dialog", to: "##{id}")
  end

  @doc """
  Hides a dialog by ID.

  ## Examples

      <button phx-click={SutraUI.Dialog.hide_dialog("my-dialog")}>Close</button>

      # Chain with other JS commands
      <button phx-click={JS.push("save") |> SutraUI.Dialog.hide_dialog("my-dialog")}>
        Save and Close
      </button>
  """
  def hide_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:hide-dialog", to: "##{id}")
  end
end
