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
        <.simple_form for={@form} phx-submit="save_user">
          <.input field={@form[:name]} label="Name" />
          <.input field={@form[:email]} label="Email" type="email" />
          <:actions>
            <.button type="submit">Save Changes</.button>
          </:actions>
        </.simple_form>
      </.dialog>

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
  attr :id, :string, required: true, doc: "Unique identifier for the dialog"
  attr :show, :boolean, default: false, doc: "Whether the dialog is visible"
  attr :class, :string, default: nil, doc: "Additional CSS classes for the dialog panel"

  attr :on_cancel, :any,
    default: nil,
    doc: "Event name (string) or JS commands to execute when dialog is closed"

  attr :close_on_escape, :boolean, default: true, doc: "Whether ESC key closes the dialog"

  attr :close_on_backdrop, :boolean,
    default: true,
    doc: "Whether clicking the backdrop closes the dialog"

  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, required: true, doc: "The main dialog content"
  slot :title, doc: "The dialog title"
  slot :description, doc: "The dialog description"
  slot :footer, doc: "Footer content, typically action buttons"

  def dialog(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".Dialog"
      phx-mounted={@show && show_dialog(@id)}
      class={["dialog", @show && "is-open"]}
      data-close-on-backdrop={to_string(@close_on_backdrop)}
      {@rest}
    >
      <.focus_wrap
        id={"#{@id}-focus-wrap"}
        phx-window-keydown={@close_on_escape && close_action(@on_cancel, @id)}
        phx-key="escape"
      >
        <div class="dialog-backdrop" aria-hidden="true" phx-click={@close_on_backdrop && close_action(@on_cancel, @id)}></div>

        <div
          id={"#{@id}-panel"}
          class={["dialog-panel", @class]}
          role="dialog"
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
      {
        mounted() {
          this.showHandler = () => {
            this.el.classList.add("is-open");
            // Focus first focusable element
            requestAnimationFrame(() => {
              const panel = this.el.querySelector("[role='dialog']");
              if (panel) {
                const focusable = panel.querySelector("button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])");
                if (focusable) focusable.focus();
              }
            });
          };

          this.hideHandler = () => {
            this.el.classList.remove("is-open");
          };

          this.el.addEventListener("phx:show-dialog", this.showHandler);
          this.el.addEventListener("phx:hide-dialog", this.hideHandler);
        },

        destroyed() {
          this.el.removeEventListener("phx:show-dialog", this.showHandler);
          this.el.removeEventListener("phx:hide-dialog", this.hideHandler);
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
