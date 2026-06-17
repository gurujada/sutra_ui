defmodule SutraUI.ContextMenu do
  @moduledoc """
  A right-click or long-press context menu.

  Renders a trigger that opens a positioned menu on right-click.
  Supports nested submenus, checkboxes, radio groups, shortcuts,
  groups with labels, and separators — following shadcn/ui's composition model.

  ## Examples

      <.context_menu id="file-menu">
        <:trigger>
          <.button>Right-click here</.button>
        </:trigger>
        <.context_menu_item>New File</.context_menu_item>
        <.context_menu_separator />
        <.context_menu_checkbox_item checked={true}>Auto-save</.context_menu_checkbox_item>
        <.context_menu_sub>
          <:trigger>Share</:trigger>
          <.context_menu_item>Copy link</.context_menu_item>
          <.context_menu_item>Email</.context_menu_item>
        </.context_menu_sub>
      </.context_menu>
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
      <div id={"#{@id}-popover"} class="context-menu-popover" data-popover aria-hidden="true">
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
          this.documentClickHandler = (e) => { if (!this.el.contains(e.target)) this.close(false); };
          this.documentKeyHandler = (e) => { if (e.key === 'Escape') this.close(); };

          this.trigger.addEventListener('contextmenu', (e) => this.openAtEvent(e));
          this.trigger.addEventListener('keydown', (e) => this.handleTriggerKey(e));
          document.addEventListener('click', this.documentClickHandler);
          document.addEventListener('keydown', this.documentKeyHandler);
          this.menu.addEventListener('keydown', (e) => this.handleMenuKey(e));
          this.menu.addEventListener('mousemove', (e) => this.handleMouseMove(e));
          this.menu.addEventListener('click', (e) => {
            if (e.target.closest('[role^="menuitem"]')) this.close();
          });
        },

        destroyed() {
          document.removeEventListener('click', this.documentClickHandler);
          document.removeEventListener('keydown', this.documentKeyHandler);
        },

        items() { return Array.from(this.menu.querySelectorAll('[role^="menuitem"]')) .filter(i => i.getAttribute('aria-disabled') !== 'true' && i.closest('[role="menu"]') === this.menu); },

        openAtEvent(event) { event.preventDefault(); this.open(event.clientX, event.clientY); },

        open(x, y) {
          this.trigger.setAttribute('aria-expanded', 'true');
          this.popover.setAttribute('aria-hidden', 'false');
          this.popover.style.left = x + 'px';
          this.popover.style.top = y + 'px';
          requestAnimationFrame(() => this.fitViewport());
          this.setActive(0);
          this.menu.focus();
        },

        close(focusTrigger = true) {
          if (this.popover.getAttribute('aria-hidden') === 'true') return;
          this.trigger.setAttribute('aria-expanded', 'false');
          this.popover.setAttribute('aria-hidden', 'true');
          this.setActive(-1);
          if (focusTrigger) this.trigger.focus();
        },

        fitViewport() {
          const r = this.popover.getBoundingClientRect();
          const p = 8;
          this.popover.style.left = Math.max(p, Math.min(r.left, window.innerWidth - r.width - p)) + 'px';
          this.popover.style.top = Math.max(p, Math.min(r.top, window.innerHeight - r.height - p)) + 'px';
        },

        setActive(index) {
          const items = this.items();
          items.forEach(i => i.classList.remove('active'));
          this.activeIndex = index;
          if (items[index]) items[index].classList.add('active');
        },

        handleTriggerKey(e) {
          if (e.key === 'ContextMenu' || (e.shiftKey && e.key === 'F10')) {
            e.preventDefault();
            const r = this.trigger.getBoundingClientRect();
            this.open(r.left, r.bottom);
          }
        },

        handleMenuKey(e) {
          const items = this.items();
          if (!items.length) return;
          if (e.key === 'ArrowDown') { e.preventDefault(); this.setActive(Math.min(this.activeIndex + 1, items.length - 1)); }
          else if (e.key === 'ArrowUp') { e.preventDefault(); this.setActive(Math.max(this.activeIndex - 1, 0)); }
          else if (e.key === 'Home') { e.preventDefault(); this.setActive(0); }
          else if (e.key === 'End') { e.preventDefault(); this.setActive(items.length - 1); }
          else if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); const el = items[this.activeIndex]?.querySelector('a,button') || items[this.activeIndex]; el?.click(); this.close(); }
        },

        handleMouseMove(e) {
          const item = e.target.closest('[role^="menuitem"]');
          const idx = this.items().indexOf(item);
          if (idx > -1) this.setActive(idx);
        }
      }
    </script>
    """
  end

  # -- Item --

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

  # -- Checkbox Item --

  attr(:checked, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def context_menu_checkbox_item(assigns) do
    ~H"""
    <div
      role="menuitemcheckbox"
      class={["context-menu-item", @class]}
      aria-checked={to_attr(@checked)}
      aria-disabled={@disabled && "true"}
      data-state={@checked && "checked"}
      {@rest}
    >
      <span class="context-menu-item-indicator">
        <svg
          :if={@checked}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-4"
          aria-hidden="true"
        >
          <path d="M20 6 9 17l-5-5" />
        </svg>
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- Radio Item --

  attr(:value, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def context_menu_radio_item(assigns) do
    ~H"""
    <div
      role="menuitemradio"
      class={["context-menu-item", @class]}
      aria-checked={to_attr(@checked)}
      aria-disabled={@disabled && "true"}
      data-state={@checked && "checked"}
      data-value={@value}
      {@rest}
    >
      <span class="context-menu-item-indicator">
        <span :if={@checked} class="context-menu-radio-dot"></span>
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- Submenu --

  attr(:class, :any, default: nil)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def context_menu_sub(assigns) do
    ~H"""
    <div class={["context-menu-sub", @class]}>
      <div
        role="menuitem"
        class="context-menu-item context-menu-sub-trigger"
        aria-haspopup="menu"
        aria-expanded="false"
      >
        {render_slot(@trigger)}
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="context-menu-sub-chevron size-4"
          aria-hidden="true"
        >
          <path d="m9 18 6-6-6-6" />
        </svg>
      </div>
      <div class="context-menu-sub-content" data-popover aria-hidden="true">
        <div role="menu">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  # -- Label --

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def context_menu_label(assigns) do
    ~H"""
    <div class={["context-menu-label", @class]} role="presentation">
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- Separator --

  attr(:class, :any, default: nil)

  def context_menu_separator(assigns) do
    ~H"""
    <div role="separator" class={["context-menu-separator", @class]}></div>
    """
  end

  defp to_attr(true), do: "true"
  defp to_attr(false), do: "false"
end
