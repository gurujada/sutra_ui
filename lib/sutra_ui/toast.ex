defmodule SutraUI.Toast do
  @moduledoc """
  Toast notification component for displaying temporary messages.

  Toasts provide brief, non-blocking notifications that automatically disappear.
  Use them for success confirmations, error alerts, or informational messages
  that don't require user action.

  ## Examples

      # Using with Phoenix flash (most common)
      <.toast_container flash={@flash} />

      # In your LiveView, use put_flash
      def handle_event("save", params, socket) do
        case save_data(params) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Changes saved successfully")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save changes")}
        end
      end

      # Programmatic toast via push_event
      def handle_event("complete", _params, socket) do
        {:noreply,
         socket
         |> push_event("toast", %{
           variant: "success",
           title: "Task Complete",
           description: "Your export is ready for download.",
           duration: 5000
         })}
      end

      # Individual toast (for custom layouts)
      <.toast id="custom-toast" variant="success">
        <:title>Upload Complete</:title>
        <:description>Your file has been uploaded successfully.</:description>
        <:action>
          <.button size="sm" variant="outline">View File</.button>
        </:action>
      </.toast>

  ## Components

  | Component | Description |
  |-----------|-------------|
  | `toast_container/1` | Container that displays flash messages |
  | `toast/1` | Individual toast notification |

  ## Variants

  | Variant | Usage | Appearance |
  |---------|-------|------------|
  | `default` | General information | Neutral styling |
  | `success` | Successful actions | Green/success color |
  | `destructive` | Errors and failures | Red/danger color |

  ## Programmatic Toasts

  Send toasts from your LiveView using `push_event`:

      push_event(socket, "toast", %{
        variant: "success",     # "default", "success", or "destructive"
        title: "Title text",    # Required
        description: "Details", # Optional
        duration: 5000          # Auto-dismiss in ms (0 = manual only)
      })

  The `.ToastContainer` hook listens for the `toast` event and creates
  toast elements dynamically.

  ## Toast Slots

  | Slot | Description |
  |------|-------------|
  | `title` | Main toast message |
  | `description` | Additional detail text |
  | `action` | Optional action button |

  ## Auto-Dismissal

  - Flash-based toasts: Cleared when user navigates or clicks close
  - Programmatic toasts: Auto-dismiss after `duration` milliseconds
  - Set `duration: 0` for toasts that require manual dismissal

  ## Colocated Hook

  The `.ToastContainer` hook handles:
  - Listening for `toast` push events
  - Creating toast elements dynamically
  - Animating show/hide transitions
  - Auto-dismissal timers

  See [JavaScript Hooks](colocated-hooks.md) for more details.

  ## Accessibility

  - Uses `role="status"` for non-critical notifications
  - Uses `aria-live="polite"` for screen reader announcements
  - Close button has `aria-label="Close"`
  - Focus is not stolen from current context

  > #### Screen Reader Behavior {: .info}
  >
  > Toasts use `aria-live="polite"` which waits for the user to pause
  > before announcing. This prevents interrupting ongoing screen reader
  > speech. For critical alerts that must interrupt, use `SutraUI.Alert`
  > with `role="alert"` instead.

  ## Related

  - `SutraUI.Alert` - For persistent, inline alerts
  - `SutraUI.Dialog` - For messages requiring user action
  - [JavaScript Hooks Guide](colocated-hooks.md) - Hook details
  - [Accessibility Guide](accessibility.md) - ARIA patterns
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a toast container that displays flash messages.

  ## Examples

      <.toast_container flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "The flash map from the socket")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  def toast_container(assigns) do
    ~H"""
    <div
      id="toast-container"
      class={["toast-container", @class]}
      phx-hook=".ToastContainer"
    >
      <.toast :if={info = Phoenix.Flash.get(@flash, :info)} id="toast-info" variant="default">
        <:title>{info}</:title>
      </.toast>
      <.toast :if={error = Phoenix.Flash.get(@flash, :error)} id="toast-error" variant="destructive">
        <:title>{error}</:title>
      </.toast>
    </div>

    <script :type={ColocatedHook} name=".ToastContainer">
      export default {
        mounted() {
          this.handleEvent("toast", ({variant, title, description, duration}) => {
            this.showToast(variant, title, description, duration);
          });
        },
        showToast(variant, title, description, duration = 5000) {
          const container = this.el;
          const id = `toast-${Date.now()}`;
          const toast = document.createElement('div');
          toast.id = id;
          toast.className = `toast toast-${variant || 'default'}`;
          toast.setAttribute('role', 'status');
          toast.setAttribute('aria-live', 'polite');
          
          toast.innerHTML = `
            <div class="toast-content">
              ${title ? `<div class="toast-title">${title}</div>` : ''}
              ${description ? `<div class="toast-description">${description}</div>` : ''}
            </div>
            <button class="toast-close" aria-label="Close">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
          `;
          
          const closeBtn = toast.querySelector('.toast-close');
          closeBtn.addEventListener('click', () => this.dismissToast(toast));
          
          container.appendChild(toast);
          
          // Trigger animation
          requestAnimationFrame(() => {
            toast.classList.add('toast-show');
          });
          
          // Auto dismiss
          if (duration > 0) {
            setTimeout(() => this.dismissToast(toast), duration);
          }
        },
        dismissToast(toast) {
          if (!toast || !toast.parentNode) return;
          toast.classList.remove('toast-show');
          toast.classList.add('toast-hide');
          setTimeout(() => toast.remove(), 300);
        }
      }
    </script>
    """
  end

  @doc """
  Renders an individual toast notification.

  ## Examples

      <.toast variant="success">
        <:title>Success!</:title>
        <:description>Your changes have been saved.</:description>
      </.toast>
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the toast")

  attr(:variant, :string,
    default: "default",
    values: ~w(default success destructive),
    doc: "The visual variant"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(role aria-live),
    doc: "Additional HTML attributes"
  )

  slot(:title, doc: "The toast title")
  slot(:description, doc: "Optional description text")
  slot(:action, doc: "Optional action button")

  def toast(assigns) do
    ~H"""
    <div
      id={@id}
      class={["toast", variant_class(@variant), @class]}
      role="status"
      aria-live="polite"
      {@rest}
    >
      <div class="toast-content">
        <div :if={@title != []} class="toast-title">
          {render_slot(@title)}
        </div>
        <div :if={@description != []} class="toast-description">
          {render_slot(@description)}
        </div>
      </div>
      <div :if={@action != []} class="toast-action">
        {render_slot(@action)}
      </div>
      <button
        type="button"
        class="toast-close"
        aria-label="Close"
        phx-click={hide_toast(@id)}
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>
    </div>
    """
  end

  defp variant_class("default"), do: nil
  defp variant_class("success"), do: "toast-success"
  defp variant_class("destructive"), do: "toast-destructive"

  defp hide_toast(id) do
    JS.hide(
      to: "##{id}",
      transition: {"toast-hide", "toast-show", "toast-hidden"}
    )
    |> JS.push("lv:clear-flash")
  end
end
