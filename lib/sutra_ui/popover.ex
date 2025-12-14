defmodule SutraUI.Popover do
  @moduledoc """
  A floating content panel that appears on click or keyboard interaction.

  Popovers are used to display rich content in a floating panel that is
  positioned relative to a trigger element. Unlike tooltips, popovers
  are interactive and can contain buttons, forms, and other elements.

  Supports dynamic positioning that automatically adjusts based on viewport
  boundaries to prevent the popover from being clipped.

  ## Examples

      <.popover id="user-popover">
        <:trigger>
          <button class="btn">User Info</button>
        </:trigger>
        <div class="p-4">
          <p>User details go here</p>
          <button class="btn btn-primary">View Profile</button>
        </div>
      </.popover>

      <.popover id="settings-popover" side="auto">
        <:trigger>
          <button class="btn">Settings</button>
        </:trigger>
        Settings content...
      </.popover>

  ## With dynamic button text

      <.popover id="toggle-popover">
        <:trigger let={open}>
          <button class="btn">{if open, do: "Close", else: "Open"} Popover</button>
        </:trigger>
        Popover content...
      </.popover>

  ## Accessibility

  - Trigger has `aria-expanded` and `aria-controls` attributes
  - Popover content is hidden from screen readers when closed
  - Escape key closes the popover
  - Click outside closes the popover
  - Focus is managed appropriately
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a popover component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the popover")

  attr(:side, :string,
    default: "auto",
    values: ~w(top bottom left right auto),
    doc: "Which side the popover opens on (auto for dynamic positioning)"
  )

  attr(:align, :string,
    default: "start",
    values: ~w(start center end),
    doc: "Alignment of the popover relative to the trigger"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes for the popover content")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "The element that triggers the popover")
  slot(:inner_block, required: true, doc: "The popover content")

  def popover(assigns) do
    ~H"""
    <div
      id={@id}
      class="popover"
      phx-hook=".Popover"
      data-side={@side}
      data-align={@align}
      {@rest}
    >
      <button
        type="button"
        class="popover-trigger"
        aria-expanded="false"
        aria-controls={"#{@id}-content"}
        phx-click={toggle_popover(@id)}
      >
        <span class="popover-trigger-closed">
          {render_slot(@trigger, false)}
        </span>
        <span class="popover-trigger-open" style="display: none;">
          {render_slot(@trigger, true)}
        </span>
      </button>
      <div
        id={"#{@id}-content"}
        class={@class}
        data-popover
        data-side={@side}
        data-align={@align}
        role="dialog"
        aria-hidden="true"
      >
        {render_slot(@inner_block)}
      </div>
    </div>

    <script :type={ColocatedHook} name=".Popover" runtime>
      {
        mounted() {
          this.trigger = this.el.querySelector('.popover-trigger');
          this.content = this.el.querySelector('[data-popover]');
          this.triggerClosed = this.el.querySelector('.popover-trigger-closed');
          this.triggerOpen = this.el.querySelector('.popover-trigger-open');
          this.side = this.el.dataset.side;
          
          // Close on click outside
          this.outsideClickHandler = (e) => {
            if (!this.el.contains(e.target) && this.isOpen()) {
              this.close();
            }
          };
          document.addEventListener('click', this.outsideClickHandler);
          
          // Close on Escape key
          this.escapeHandler = (e) => {
            if (e.key === 'Escape' && this.isOpen()) {
              this.close();
              this.trigger.focus();
            }
          };
          document.addEventListener('keydown', this.escapeHandler);
          
          if (this.side === 'auto') {
            // Calculate optimal position before showing
            this.trigger.addEventListener('click', () => {
              this.calculatePosition();
            });
          }
          
          // Watch for aria-expanded changes to toggle button text
          this.observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
              if (mutation.attributeName === 'aria-expanded') {
                const isOpen = this.trigger.getAttribute('aria-expanded') === 'true';
                this.updateTriggerText(isOpen);
              }
            });
          });
          this.observer.observe(this.trigger, { attributes: true, attributeFilter: ['aria-expanded'] });
        },
        
        destroyed() {
          document.removeEventListener('click', this.outsideClickHandler);
          document.removeEventListener('keydown', this.escapeHandler);
          this.observer?.disconnect();
        },
        
        isOpen() {
          return this.trigger.getAttribute('aria-expanded') === 'true';
        },
        
        close() {
          this.trigger.setAttribute('aria-expanded', 'false');
          this.content.setAttribute('aria-hidden', 'true');
          this.updateTriggerText(false);
        },
        
        updateTriggerText(isOpen) {
          if (this.triggerClosed && this.triggerOpen) {
            this.triggerClosed.style.display = isOpen ? 'none' : '';
            this.triggerOpen.style.display = isOpen ? '' : 'none';
          }
        },
        
        calculatePosition() {
          const rect = this.trigger.getBoundingClientRect();
          const contentHeight = 200; // Estimate or measure
          const contentWidth = 280;
          const padding = 8;
          
          const spaceTop = rect.top;
          const spaceBottom = window.innerHeight - rect.bottom;
          const spaceLeft = rect.left;
          const spaceRight = window.innerWidth - rect.right;
          
          let side = 'bottom';
          
          // Prefer bottom, then top, then right, then left
          if (spaceBottom >= contentHeight + padding) {
            side = 'bottom';
          } else if (spaceTop >= contentHeight + padding) {
            side = 'top';
          } else if (spaceRight >= contentWidth + padding) {
            side = 'right';
          } else if (spaceLeft >= contentWidth + padding) {
            side = 'left';
          }
          
          this.content.setAttribute('data-side', side);
        }
      }
    </script>
    """
  end

  @doc """
  Shows a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.show_popover("my-popover")}>Open</button>
  """
  def show_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "false"}, to: "##{id}-content")
  end

  @doc """
  Hides a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.hide_popover("my-popover")}>Close</button>
  """
  def hide_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "true"}, to: "##{id}-content")
  end

  @doc """
  Toggles a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.toggle_popover("my-popover")}>Toggle</button>
  """
  def toggle_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id} .popover-trigger")
    |> JS.toggle_attribute({"aria-hidden", "false", "true"}, to: "##{id}-content")
  end
end
