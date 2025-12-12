defmodule SutraUI.Dialog do
  @moduledoc """
  A modal dialog component that displays content in a layer above the page.

  Uses the native HTML `<dialog>` element for proper accessibility and behavior.
  Dialogs are used to display important content that requires user attention
  or interaction before continuing - confirmations, forms, alerts, or any
  focused interaction.

  ## Examples

      # Basic confirmation dialog
      <.dialog id="confirm-dialog">
        <:title>Confirm Action</:title>
        <:description>Are you sure you want to proceed?</:description>
        This action cannot be undone.
        <:footer>
          <.button variant="outline" phx-click={SutraUI.Dialog.hide_dialog("confirm-dialog")}>
            Cancel
          </.button>
          <.button phx-click="confirm">Confirm</.button>
        </:footer>
      </.dialog>

      # Open with JS commands (recommended)
      <.button phx-click={SutraUI.Dialog.show_dialog("confirm-dialog")}>
        Open Dialog
      </.button>

      # Form inside dialog
      <.dialog id="edit-user-dialog">
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

  Use the provided helper functions for LiveView integration:

  | Function | Description |
  |----------|-------------|
  | `show_dialog/1` | Opens dialog with `showModal()` |
  | `show_dialog/2` | Chain with existing JS commands |
  | `hide_dialog/1` | Closes dialog with `close()` |
  | `hide_dialog/2` | Chain with existing JS commands |

      # Open on button click
      <.button phx-click={SutraUI.Dialog.show_dialog("my-dialog")}>Open</.button>

      # Close from inside dialog
      <.button phx-click={SutraUI.Dialog.hide_dialog("my-dialog")}>Cancel</.button>

      # Chain with other JS commands
      <.button phx-click={
        JS.push("prepare_data")
        |> SutraUI.Dialog.show_dialog("my-dialog")
      }>
        Load and Open
      </.button>

  ## Slots

  | Slot | Description |
  |------|-------------|
  | `title` | Dialog header title |
  | `description` | Explanatory text below title |
  | `inner_block` | Main content area |
  | `footer` | Action buttons, typically Cancel/Confirm |

  ## Colocated Hook

  The `.Dialog` hook handles:
  - `phx:show-dialog` event → calls `showModal()`
  - `phx:hide-dialog` event → calls `close()`
  - Backdrop click to close

  See [JavaScript Hooks](colocated-hooks.md) for more details.

  ## Accessibility

  - Uses native `<dialog>` element for proper modal behavior
  - `Escape` key closes the dialog
  - Click on backdrop closes the dialog
  - Focus is trapped within the dialog when open
  - Focus returns to trigger element on close
  - `aria-labelledby` links to title
  - `aria-describedby` links to description

  > #### Focus Management {: .tip}
  >
  > The native `<dialog>` element handles focus trapping automatically.
  > When opened with `showModal()`, focus moves into the dialog and
  > is trapped until closed. No JavaScript focus trap needed.

  ## Related

  - `SutraUI.Popover` - For non-modal floating content
  - `SutraUI.DropdownMenu` - For menu interactions
  - `SutraUI.Command` - For command palette dialogs
  - [JavaScript Hooks Guide](colocated-hooks.md) - Hook details
  - [Accessibility Guide](accessibility.md) - ARIA patterns
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a modal dialog component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the dialog")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the dialog panel")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "The main dialog content")
  slot(:title, doc: "The dialog title")
  slot(:description, doc: "The dialog description")
  slot(:footer, doc: "Footer content, typically action buttons")

  def dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook=".Dialog"
      class="dialog"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={"#{@id}-description"}
      {@rest}
    >
      <div class={@class}>
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

        <form method="dialog">
          <button type="submit" aria-label="Close" class="cursor-pointer">
            <.icon name="lucide-x" />
          </button>
        </form>
      </div>
    </dialog>

    <script :type={ColocatedHook} name=".Dialog">
      export default {
        mounted() {
          this.showHandler = (e) => this.el.showModal();
          this.hideHandler = (e) => this.el.close();

          this.el.addEventListener("phx:show-dialog", this.showHandler);
          this.el.addEventListener("phx:hide-dialog", this.hideHandler);
          
          // Close on backdrop click
          this.el.addEventListener("click", (e) => {
            if (e.target === this.el) {
              this.el.close();
            }
          });
        },

        destroyed() {
          this.el.removeEventListener("phx:show-dialog", this.showHandler);
          this.el.removeEventListener("phx:hide-dialog", this.hideHandler);
        }
      }
    </script>
    """
  end

  @doc """
  Shows a dialog by ID using the native showModal() method.

  ## Examples

      <button phx-click={PhxUI.Dialog.show_dialog("my-dialog")}>Open</button>
  """
  def show_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:show-dialog", to: "##{id}")
  end

  @doc """
  Hides a dialog by ID using the native close() method.

  ## Examples

      <button phx-click={PhxUI.Dialog.hide_dialog("my-dialog")}>Close</button>
  """
  def hide_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:hide-dialog", to: "##{id}")
  end
end
