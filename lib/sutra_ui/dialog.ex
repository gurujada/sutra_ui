defmodule SutraUI.Dialog do
  @moduledoc """
  A modal dialog component that displays content in a layer above the page.

  Uses the native HTML `<dialog>` element for proper accessibility and behavior.
  Dialogs are used to display important content that requires user attention
  or interaction before continuing.

  ## Examples

      <.dialog id="confirm-dialog">
        <:title>Confirm Action</:title>
        <:description>Are you sure you want to proceed?</:description>
        This action cannot be undone.
        <:footer>
          <.button variant="outline" onclick="this.closest('dialog').close()">Cancel</.button>
          <.button phx-click="confirm">Confirm</.button>
        </:footer>
      </.dialog>

      # Open dialog
      <button onclick="document.getElementById('confirm-dialog').showModal()">Open</button>

      # Or use JS commands
      <.button phx-click={PhxUI.Dialog.show_dialog("confirm-dialog")}>Open</.button>

  ## Accessibility

  - Uses native `<dialog>` element for proper modal behavior
  - Escape key closes the dialog by default
  - Click on backdrop closes the dialog
  - Focus is trapped within the dialog when open
  - Focus returns to trigger element on close
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
            <.icon name="hero-x-mark" />
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
