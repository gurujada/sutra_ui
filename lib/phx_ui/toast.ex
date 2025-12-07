defmodule PhxUI.Toast do
  @moduledoc """
  A toast notification component for displaying temporary messages.

  Toasts are used to show brief notifications that automatically disappear
  after a set duration. They can be used for success messages, errors, or
  general information.

  ## Examples

      # In your LiveView, use the flash mechanism
      <.toast_container flash={@flash} />

      # Or programmatically show toasts
      <.toast variant="success">
        <:title>Success!</:title>
        <:description>Your changes have been saved.</:description>
      </.toast>

  ## Accessibility

  - Uses `role="status"` and `aria-live="polite"` for screen reader announcements
  - Provides close button for manual dismissal
  - Supports keyboard navigation
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

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
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M18 6 6 18" /><path d="m6 6 12 12" />
        </svg>
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
