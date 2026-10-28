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
    # A trigger that reads `open` renders twice (closed, open) and CSS shows one. One that does
    # not renders once, so an element with an `id` inside it is not duplicated in the DOM.
    closed = ~H"{render_slot(@trigger, false)}"
    open = ~H"{render_slot(@trigger, true)}"

    assigns =
      assign(assigns,
        trigger_closed: closed,
        trigger_open: if(same_markup?(closed, open), do: nil, else: open)
      )

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
        <span :if={@trigger_open} class="popover-trigger-closed">
          {@trigger_closed}
        </span>
        <span :if={@trigger_open} class="popover-trigger-open">
          {@trigger_open}
        </span>
        <%= if !@trigger_open do %>
          {@trigger_closed}
        <% end %>
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
            this.refit();
          });
          this.fitObserver.observe(this.content, { attributes: true, attributeFilter: ['aria-hidden'] });
          this.resizeHandler = () => {
            this.refit();
          };
          window.addEventListener('resize', this.resizeHandler);
          // The card is fixed: follow the trigger when the page or a scrolling ancestor moves.
          this.scrollHandler = (e) => {
            if (!this.isOpen() || this.content.contains(e.target)) return;
            cancelAnimationFrame(this.scrollFrame);
            this.scrollFrame = requestAnimationFrame(() => this.refit());
          };
          window.addEventListener('scroll', this.scrollHandler, { capture: true, passive: true });

          if (this.side === 'auto') {
            // Calculate optimal position before showing
            this.positionClickHandler = () => {
              this.calculatePosition();
            };
            this.trigger.addEventListener('click', this.positionClickHandler);
          }
        },
        
        updated() {
          this.refit();
        },

        destroyed() {
          this.fitObserver?.disconnect();
          window.removeEventListener('resize', this.resizeHandler);
          window.removeEventListener('scroll', this.scrollHandler, { capture: true });
          cancelAnimationFrame(this.scrollFrame);
          document.removeEventListener('click', this.outsideClickHandler);
          document.removeEventListener('keydown', this.escapeHandler);
          this.trigger?.removeEventListener('click', this.positionClickHandler);
        },
        
        // fit:start (the same code is in popover.ex and dropdown_menu.ex; a test keeps them equal)
        // Place the open card with position: fixed from the trigger's rectangle, so a scrolling or
        // overflow-hidden ancestor cannot clip it; flip, shift and cap it to stay on screen.
        // Returns false when the trigger has scrolled out of view. CSSOM only, never a style
        // attribute.
        fit(content, trigger, wanted) {
          if (!content || !trigger) return false;
          const margin = 8;
          const gap = 4;
          const vw = document.documentElement.clientWidth;
          const vh = document.documentElement.clientHeight;
          const t = trigger.getBoundingClientRect();
          const scrolled = content.scrollTop;

          // The visible part of the trigger: the viewport minus what scrolling ancestors clip.
          let clip = { left: 0, top: 0, right: vw, bottom: vh };
          for (let p = trigger.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
            const cs = getComputedStyle(p);
            if (cs.overflowX === 'visible' && cs.overflowY === 'visible') continue;
            const r = p.getBoundingClientRect();
            clip = { left: Math.max(clip.left, r.left), top: Math.max(clip.top, r.top), right: Math.min(clip.right, r.right), bottom: Math.min(clip.bottom, r.bottom) };
          }
          const visible = t.right > clip.left && t.left < clip.right && t.bottom > clip.top && t.top < clip.bottom;

          content.style.position = 'fixed';
          content.style.margin = '0px';
          content.style.translate = 'none';
          content.style.right = 'auto';
          content.style.bottom = 'auto';
          content.style.left = '0px';
          content.style.top = '0px';
          content.style.transitionProperty = 'opacity, scale, display, visibility';
          content.style.minWidth = t.width + 'px';
          content.style.maxWidth = (vw - 2 * margin) + 'px';
          content.style.maxHeight = '';
          if (wanted && wanted !== 'auto') content.setAttribute('data-side', wanted);

          let w = content.offsetWidth;
          const h = content.offsetHeight;
          const below = vh - margin - t.bottom - gap;
          const above = t.top - gap - margin;
          let side = content.getAttribute('data-side') || 'bottom';
          if (side === 'bottom' && h > below && (h <= above || above > below)) side = 'top';
          else if (side === 'top' && h > above && (h <= below || below > above)) side = 'bottom';
          else if (side === 'right' && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = 'left';
          else if (side === 'left' && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = 'right';
          content.setAttribute('data-side', side);

          const align = content.getAttribute('data-align') || 'start';
          let left;
          let top;
          if (side === 'bottom' || side === 'top') {
            const room = Math.max(side === 'bottom' ? below : above, 120);
            content.style.maxHeight = room + 'px';
            w = content.offsetWidth;
            left = align === 'end' ? t.right - w : align === 'center' ? t.left + (t.width - w) / 2 : t.left;
            top = side === 'bottom' ? t.bottom + gap : t.top - gap - Math.min(h, room);
          } else {
            left = side === 'right' ? t.right + gap : t.left - gap - w;
            top = align === 'end' ? t.bottom - h : align === 'center' ? t.top + (t.height - h) / 2 : t.top;
            top = Math.max(margin, Math.min(top, vh - margin - h));
          }
          left = Math.max(margin, Math.min(left, vw - margin - w));
          content.style.left = left + 'px';
          content.style.top = top + 'px';

          // An ancestor with a transform makes `fixed` relative to itself: measure and correct. The
          // box's own open animation scales it around its centre, which is allowed for.
          const r = content.getBoundingClientRect();
          const dx = r.left - (left + (content.offsetWidth - r.width) / 2);
          const dy = r.top - (top + (content.offsetHeight - r.height) / 2);
          if (Math.abs(dx) > 0.5) content.style.left = (left - dx) + 'px';
          if (Math.abs(dy) > 0.5) content.style.top = (top - dy) + 'px';
          content.scrollTop = scrolled;
          return visible;
        },
        // fit:end

        isOpen() {
          return this.trigger.getAttribute('aria-expanded') === 'true';
        },

        // Re-place the open card; close it when its trigger has scrolled out of view.
        refit() {
          if (this.isOpen() && !this.fit(this.content, this.trigger, this.side)) this.close();
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

  defp same_markup?(a, b), do: to_bin(a) == to_bin(b)
  defp to_bin(r), do: r |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
end
