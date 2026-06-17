defmodule SutraUI.ContextMenu do
  @moduledoc """
  A menu of actions opened by right click, long press, or keyboard.

  Context Menu follows shadcn/ui's trigger/content/item composition and
  Preline's contextmenu trigger behavior, implemented with a colocated hook and
  no external JavaScript dependency.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the context menu")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for the root")
  attr(:menu_class, :any, default: nil, doc: "Additional CSS classes for the menu")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "Right-click target")
  slot(:inner_block, required: true, doc: "Menu content")

  def context_menu(assigns) do
    ~H"""
    <div id={@id} class={["context-menu", @class]} phx-hook=".ContextMenu" {@rest}>
      <div
        id={"#{@id}-trigger"}
        class="context-menu-trigger"
        aria-haspopup="menu"
        aria-controls={"#{@id}-menu"}
        aria-expanded="false"
        tabindex="0"
      >
        {render_slot(@trigger)}
      </div>
      <div
        id={"#{@id}-popover"}
        class="context-menu-popover"
        data-popover
        aria-hidden="true"
      >
        <div
          id={"#{@id}-menu"}
          class={["context-menu-content", @menu_class]}
          role="menu"
          aria-labelledby={"#{@id}-trigger"}
          tabindex="-1"
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>

    <script :type={ColocatedHook} name=".ContextMenu" runtime>
      {
        mounted() {
          this.trigger = this.el.querySelector('.context-menu-trigger');
          this.popover = this.el.querySelector('.context-menu-popover');
          this.menu = this.el.querySelector('[role="menu"]');
          this.activeIndex = -1;

          this.trigger.addEventListener('contextmenu', (event) => this.openAtEvent(event));
          this.trigger.addEventListener('keydown', (event) => this.handleTriggerKeydown(event));
          this.menu.addEventListener('keydown', (event) => this.handleMenuKeydown(event));
          this.menu.addEventListener('mousemove', (event) => this.handleMouseMove(event));
          this.menu.addEventListener('click', (event) => {
            if (event.target.closest('[role^="menuitem"]')) this.close();
          });

          this.documentClickHandler = (event) => {
            if (!this.el.contains(event.target)) this.close(false);
          };
          this.escapeHandler = (event) => {
            if (event.key === 'Escape') this.close();
          };
          document.addEventListener('click', this.documentClickHandler);
          document.addEventListener('keydown', this.escapeHandler);
        },

        destroyed() {
          document.removeEventListener('click', this.documentClickHandler);
          document.removeEventListener('keydown', this.escapeHandler);
        },

        items() {
          return Array.from(this.menu.querySelectorAll('[role^="menuitem"]'))
            .filter((item) => item.getAttribute('aria-disabled') !== 'true');
        },

        openAtEvent(event) {
          event.preventDefault();
          this.open(event.clientX, event.clientY);
        },

        open(x, y) {
          this.trigger.setAttribute('aria-expanded', 'true');
          this.popover.setAttribute('aria-hidden', 'false');
          this.popover.style.left = `${x}px`;
          this.popover.style.top = `${y}px`;
          this.fitInViewport();
          this.setActiveItem(0);
          this.menu.focus();
        },

        close(focusTrigger = true) {
          if (this.popover.getAttribute('aria-hidden') === 'true') return;
          this.trigger.setAttribute('aria-expanded', 'false');
          this.popover.setAttribute('aria-hidden', 'true');
          this.setActiveItem(-1);
          if (focusTrigger) this.trigger.focus();
        },

        fitInViewport() {
          const rect = this.popover.getBoundingClientRect();
          const padding = 8;
          const left = Math.min(rect.left, window.innerWidth - rect.width - padding);
          const top = Math.min(rect.top, window.innerHeight - rect.height - padding);
          this.popover.style.left = `${Math.max(padding, left)}px`;
          this.popover.style.top = `${Math.max(padding, top)}px`;
        },

        setActiveItem(index) {
          const items = this.items();
          items.forEach((item) => item.classList.remove('active'));
          this.activeIndex = index;
          if (items[index]) items[index].classList.add('active');
        },

        handleTriggerKeydown(event) {
          if (event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10')) {
            event.preventDefault();
            const rect = this.trigger.getBoundingClientRect();
            this.open(rect.left, rect.bottom);
          }
        },

        handleMenuKeydown(event) {
          const items = this.items();
          if (items.length === 0) return;

          if (event.key === 'ArrowDown') {
            event.preventDefault();
            this.setActiveItem(Math.min(this.activeIndex + 1, items.length - 1));
          } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            this.setActiveItem(Math.max(this.activeIndex - 1, 0));
          } else if (event.key === 'Home') {
            event.preventDefault();
            this.setActiveItem(0);
          } else if (event.key === 'End') {
            event.preventDefault();
            this.setActiveItem(items.length - 1);
          } else if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            const current = items[this.activeIndex];
            (current?.querySelector('a,button') || current)?.click();
            this.close();
          }
        },

        handleMouseMove(event) {
          const item = event.target.closest('[role^="menuitem"]');
          const items = this.items();
          const index = items.indexOf(item);
          if (index > -1) this.setActiveItem(index);
        }
      }
    </script>
    """
  end

  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:disabled, :boolean, default: false)
  attr(:shortcut, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def context_menu_item(assigns) do
    ~H"""
    <div
      role="menuitem"
      class={[
        "context-menu-item",
        @variant == "destructive" && "context-menu-item-destructive",
        @class
      ]}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      <span class="context-menu-item-content">{render_slot(@inner_block)}</span>
      <kbd :if={@shortcut} class="context-menu-shortcut">{@shortcut}</kbd>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def context_menu_label(assigns) do
    ~H"""
    <div class={["context-menu-label", @class]}>{render_slot(@inner_block)}</div>
    """
  end

  attr(:class, :any, default: nil)

  def context_menu_separator(assigns) do
    ~H"""
    <div role="separator" class={["context-menu-separator", @class]}></div>
    """
  end
end
