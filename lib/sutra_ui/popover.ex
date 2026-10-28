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
          User Info
        </:trigger>
        <div class="p-4">
          <p>User details go here</p>
          <button class="btn btn-primary">View Profile</button>
        </div>
      </.popover>

      <.popover id="settings-popover" side="auto">
        <:trigger>
          Settings
        </:trigger>
        Settings content...
      </.popover>

  ## With dynamic button text

      <.popover id="toggle-popover">
        <:trigger let={open}>
          {if open, do: "Close", else: "Open"} Popover
        </:trigger>
        Popover content...
      </.popover>

  The trigger slot is rendered inside the component's trigger button. Pass label,
  icon, or inline content rather than another interactive element.

  ## Accessibility

  - Trigger has `aria-expanded` and `aria-controls` attributes
  - Popover content is hidden from screen readers when closed
  - Escape key closes the popover
  - Click outside closes the popover
  - Escape returns focus to the trigger
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

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script")

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
        <span class="popover-trigger-open">
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

    <script :type={ColocatedHook} name=".Popover" runtime nonce={@nonce}>
      {
        mounted() {
          this.trigger = this.el.querySelector('.popover-trigger');
          this.content = this.el.querySelector('[data-popover]');
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
          
          // Fit the card inside the viewport each time it opens (and when the window changes).
          this.fitObserver = new MutationObserver(() => {
            if (this.isOpen()) this.fit(this.content, this.trigger, this.side);
          });
          this.fitObserver.observe(this.content, { attributes: true, attributeFilter: ['aria-hidden'] });
          this.resizeHandler = () => {
            if (this.isOpen()) this.fit(this.content, this.trigger, this.side);
          };
          window.addEventListener('resize', this.resizeHandler);

          if (this.side === 'auto') {
            // Calculate optimal position before showing
            this.positionClickHandler = () => {
              this.calculatePosition();
            };
            this.trigger.addEventListener('click', this.positionClickHandler);
          }
        },
        
        updated() {
          if (this.isOpen()) this.fit(this.content, this.trigger, this.side);
        },

        destroyed() {
          this.fitObserver?.disconnect();
          window.removeEventListener('resize', this.resizeHandler);
          document.removeEventListener('click', this.outsideClickHandler);
          document.removeEventListener('keydown', this.escapeHandler);
          this.trigger?.removeEventListener('click', this.positionClickHandler);
        },
        
        // fit:start (the same code is in popover.ex and dropdown_menu.ex; a test keeps them equal)
        // Keep the open card inside the viewport: flip to the other side when it would run
        // off, then shift it back in. Positions come from the CSSOM (margins), never a style
        // attribute.
        fit(content, trigger, wanted) {
          if (!content || !trigger) return;
          const margin = 8;
          const gap = 4;
          const vw = document.documentElement.clientWidth;
          const vh = window.innerHeight;
          content.style.marginLeft = '';
          content.style.marginRight = '';
          content.style.marginTop = '';
          content.style.marginBottom = '';
          content.style.maxWidth = (vw - 2 * margin) + 'px';
          content.style.maxHeight = '';
          if (wanted && wanted !== 'auto') content.setAttribute('data-side', wanted);

          const t = trigger.getBoundingClientRect();
          const w = content.offsetWidth;
          const h = content.offsetHeight;
          let side = content.getAttribute('data-side') || 'bottom';
          const below = vh - margin - t.bottom - gap;
          const above = t.top - gap - margin;
          if (side === 'bottom' && h > below && (h <= above || above > below)) side = 'top';
          else if (side === 'top' && h > above && (h <= below || below > above)) side = 'bottom';
          else if (side === 'right' && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = 'left';
          else if (side === 'left' && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = 'right';
          content.setAttribute('data-side', side);

          if (side === 'bottom') content.style.maxHeight = Math.max(below, 120) + 'px';
          if (side === 'top') content.style.maxHeight = Math.max(above, 120) + 'px';

          // The box without its open animation's scale, around its centre.
          const r = content.getBoundingClientRect();
          const left = r.left + (r.width - content.offsetWidth) / 2;
          const top = r.top + (r.height - content.offsetHeight) / 2;
          const width = content.offsetWidth;
          const height = content.offsetHeight;
          let dx = 0;
          let dy = 0;
          if (left + width > vw - margin) dx = vw - margin - (left + width);
          if (left + dx < margin) dx = margin - left;
          if (side === 'left' || side === 'right') {
            if (top + height > vh - margin) dy = vh - margin - (top + height);
            if (top + dy < margin) dy = margin - top;
          }
          if (dx) {
            content.style.marginLeft = dx + 'px';
            content.style.marginRight = -dx + 'px';
          }
          if (dy) {
            content.style.marginTop = dy + 'px';
            content.style.marginBottom = -dy + 'px';
          }
        },
        // fit:end

        isOpen() {
          return this.trigger.getAttribute('aria-expanded') === 'true';
        },
        
        close() {
          this.trigger.setAttribute('aria-expanded', 'false');
          this.content.setAttribute('aria-hidden', 'true');
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

      <button phx-click={SutraUI.Popover.show_popover("my-popover")}>Open</button>
  """
  def show_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "false"}, to: "##{id}-content")
  end

  @doc """
  Hides a popover by ID.

  ## Examples

      <button phx-click={SutraUI.Popover.hide_popover("my-popover")}>Close</button>
  """
  def hide_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "true"}, to: "##{id}-content")
  end

  @doc """
  Toggles a popover by ID.

  ## Examples

      <button phx-click={SutraUI.Popover.toggle_popover("my-popover")}>Toggle</button>
  """
  def toggle_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id} .popover-trigger")
    |> JS.toggle_attribute({"aria-hidden", "false", "true"}, to: "##{id}-content")
  end
end
