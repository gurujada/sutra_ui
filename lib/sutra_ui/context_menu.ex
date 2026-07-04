defmodule SutraUI.ContextMenu do
  @moduledoc """
  A right-click and keyboard-accessible context menu.

  Renders a trigger that opens a positioned menu on right-click or keyboard input. Supports
  nested submenus, checkboxes, radio groups, shortcuts, labels, and
  separators — following the shadcn/ui composition model.

  Menu items accept global attributes, so LiveView actions can be attached
  directly with `phx-click`, `phx-value-*`, `phx-target`, and the usual
  Phoenix bindings.

  ## Examples

      <.context_menu id="file-menu">
        <:trigger>
          <div class="rounded-lg border p-4">Right-click here</div>
        </:trigger>
        <.context_menu_item phx-click="new-file">New File</.context_menu_item>
        <.context_menu_separator />
        <.context_menu_checkbox_item checked={@auto_save} phx-click="toggle-autosave">
          Auto-save
        </.context_menu_checkbox_item>
        <.context_menu_sub>
          <:trigger>Share</:trigger>
          <.context_menu_item phx-click="copy-link">Copy link</.context_menu_item>
          <.context_menu_item phx-click="email">Email</.context_menu_item>
        </.context_menu_sub>
      </.context_menu>

  ## Sub-menus

  `context_menu_sub` renders a submenu with its own `:trigger` slot and item
  content. Submenus open on hover (mouse) and on Right-arrow (keyboard), and
  close on Left-arrow or Escape.

  ## Accessibility

  - Trigger has `aria-haspopup="menu"` and `aria-expanded`.
  - Menu uses `role="menu"`, items use `role="menuitem"`.
  - Keyboard navigation: ArrowUp/Down, Home/End, Enter/Space, Escape.
  - Submenu: Right arrow opens, Left arrow / Escape closes.
  - Checkbox items use `role="menuitemcheckbox"` with `aria-checked`.
  - Radio items use `role="menuitemradio"` with `aria-checked`.
  - Disabled items have `aria-disabled="true"`.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the context menu")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for the root")
  attr(:trigger_class, :any, default: nil, doc: "Additional CSS classes for the trigger wrapper")
  attr(:menu_class, :any, default: nil, doc: "Additional CSS classes for the menu")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "Right-click target")
  slot(:inner_block, required: true, doc: "Menu content")

  def context_menu(assigns) do
    ~H"""
    <div id={@id} class={["context-menu", @class]} phx-hook=".ContextMenu" {@rest}>
      <div
        id={"#{@id}-trigger"}
        class={["context-menu-trigger", @trigger_class]}
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
        data-context-menu
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
          this.popover = this.el.querySelector('[data-context-menu]');
          this.menu = this.el.querySelector('[role="menu"]');
          this.activeIndex = -1;
          this.openSubmenu = null;

          this.documentPointerHandler = (e) => {
            if (!this.el.contains(e.target)) this.close(false);
          };
          this.documentContextMenuHandler = (e) => {
            if (!this.el.contains(e.target)) this.close(false);
          };
          this.dismissHandler = () => this.close(false);
          this.documentKeyHandler = (e) => {
            if (e.key === 'Escape') {
              if (this.openSubmenu) { this.closeSubmenu(); return; }
              this.close();
            }
          };

          this.triggerContextMenuHandler = (e) => this.openAtEvent(e);
          this.triggerKeyHandler = (e) => this.handleTriggerKey(e);
          this.menuKeyHandler = (e) => this.handleMenuKey(e);
          this.menuMouseMoveHandler = (e) => this.handleMouseMove(e);
          this.menuMouseLeaveHandler = () => this.setActive(-1);
          this.menuClickHandler = (e) => {
            if (e.target.closest('[role^="menuitem"]') && !e.target.closest('.context-menu-sub-trigger')) {
              this.close();
            }
          };
          this.submenuHandlers = [];

          this.trigger.addEventListener('contextmenu', this.triggerContextMenuHandler);
          this.trigger.addEventListener('keydown', this.triggerKeyHandler);
          document.addEventListener('pointerdown', this.documentPointerHandler);
          document.addEventListener('contextmenu', this.documentContextMenuHandler);
          document.addEventListener('keydown', this.documentKeyHandler);
          window.addEventListener('scroll', this.dismissHandler, true);
          window.addEventListener('resize', this.dismissHandler);
          this.menu.addEventListener('keydown', this.menuKeyHandler);
          this.menu.addEventListener('mousemove', this.menuMouseMoveHandler);
          this.menu.addEventListener('pointerover', this.menuMouseMoveHandler);
          this.menu.addEventListener('mouseleave', this.menuMouseLeaveHandler);
          this.menu.addEventListener('click', this.menuClickHandler);

          // Submenu hover handling
          this.el.querySelectorAll('.context-menu-sub').forEach(sub => {
            const subTrigger = sub.querySelector('.context-menu-sub-trigger');
            const subContent = sub.querySelector('.context-menu-sub-content');
            if (!subTrigger || !subContent) return;

            const mouseEnter = () => {
              const idx = this.items().indexOf(subTrigger);
              if (idx > -1) this.setActive(idx);
              this.openSubmenuEl(sub);
            };
            const mouseLeave = () => this.closeSubmenuEl(sub);
            const keydown = (e) => this.handleSubmenuKey(e, sub);
            const mouseMove = (e) => this.handleSubmenuMouseMove(e, sub);
            const clearActive = () => this.clearSubmenuActive(sub);

            subTrigger.addEventListener('mouseenter', mouseEnter);
            sub.addEventListener('mouseleave', mouseLeave);
            subContent.addEventListener('keydown', keydown);
            subContent.addEventListener('mousemove', mouseMove);
            subContent.addEventListener('pointerover', mouseMove);
            subContent.addEventListener('mouseleave', clearActive);
            this.submenuHandlers.push({ sub, subTrigger, subContent, mouseEnter, mouseLeave, keydown, mouseMove, clearActive });
          });
        },

        destroyed() {
          this.trigger?.removeEventListener('contextmenu', this.triggerContextMenuHandler);
          this.trigger?.removeEventListener('keydown', this.triggerKeyHandler);
          this.menu?.removeEventListener('keydown', this.menuKeyHandler);
          this.menu?.removeEventListener('mousemove', this.menuMouseMoveHandler);
          this.menu?.removeEventListener('pointerover', this.menuMouseMoveHandler);
          this.menu?.removeEventListener('mouseleave', this.menuMouseLeaveHandler);
          this.menu?.removeEventListener('click', this.menuClickHandler);
          this.submenuHandlers?.forEach(({ sub, subTrigger, subContent, mouseEnter, mouseLeave, keydown, mouseMove, clearActive }) => {
            subTrigger.removeEventListener('mouseenter', mouseEnter);
            sub.removeEventListener('mouseleave', mouseLeave);
            subContent.removeEventListener('keydown', keydown);
            subContent.removeEventListener('mousemove', mouseMove);
            subContent.removeEventListener('pointerover', mouseMove);
            subContent.removeEventListener('mouseleave', clearActive);
          });
          this.submenuHandlers = [];
          document.removeEventListener('pointerdown', this.documentPointerHandler);
          document.removeEventListener('contextmenu', this.documentContextMenuHandler);
          document.removeEventListener('keydown', this.documentKeyHandler);
          window.removeEventListener('scroll', this.dismissHandler, true);
          window.removeEventListener('resize', this.dismissHandler);
        },

        items(menu) {
          const m = menu || this.menu;
          return Array.from(m.children).flatMap((child) => {
            if (child.matches('[role^="menuitem"]')) return [child];
            if (child.classList.contains('context-menu-sub')) {
              const trigger = child.querySelector(':scope > .context-menu-sub-trigger');
              return trigger ? [trigger] : [];
            }
            return [];
          })
            .filter(i => i.getAttribute('aria-disabled') !== 'true');
        },

        openAtEvent(event) {
          event.preventDefault();
          this.open(event.clientX, event.clientY);
        },

        open(x, y) {
          this.trigger.setAttribute('aria-expanded', 'true');
          this.popover.setAttribute('aria-hidden', 'false');
          this.popover.style.left = x + 'px';
          this.popover.style.top = y + 'px';
          requestAnimationFrame(() => this.fitViewport());
          this.setActive(-1);
          this.menu.focus();
        },

        close(focusTrigger = true) {
          if (this.popover.getAttribute('aria-hidden') === 'true') return;
          this.closeSubmenu();
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

          if (e.key === 'ArrowRight' && this.activeIndex > -1) {
            const sub = items[this.activeIndex].closest('.context-menu-sub');
            if (sub) { e.preventDefault(); this.openSubmenuEl(sub, true); return; }
          }

          if (e.key === 'ArrowDown') { e.preventDefault(); this.setActive(Math.min(this.activeIndex + 1, items.length - 1)); }
          else if (e.key === 'ArrowUp') { e.preventDefault(); this.setActive(Math.max(this.activeIndex - 1, 0)); }
          else if (e.key === 'Home') { e.preventDefault(); this.setActive(0); }
          else if (e.key === 'End') { e.preventDefault(); this.setActive(items.length - 1); }
          else if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            if (items[this.activeIndex]?.classList.contains('context-menu-sub-trigger')) {
              const sub = items[this.activeIndex].closest('.context-menu-sub');
            if (sub) { this.openSubmenuEl(sub, true); return; }
          }
            const el = items[this.activeIndex]?.querySelector('a,button') || items[this.activeIndex];
            el?.click();
            if (!items[this.activeIndex]?.closest('.context-menu-sub')) this.close();
          }
        },

        handleMouseMove(e) {
          const item = this.items().find(i => i === e.target || i.contains(e.target));
          if (!item) {
            if (this.openSubmenu?.contains(e.target)) return;
            this.setActive(-1);
            return;
          }
          const idx = this.items().indexOf(item);
          if (idx > -1) this.setActive(idx);
        },

        submenuItems(sub) {
          const content = sub.querySelector('.context-menu-sub-content');
          const subMenu = content?.querySelector('[role="menu"]');
          if (!subMenu) return [];

          return Array.from(subMenu.querySelectorAll(':scope > [role^="menuitem"]'))
            .filter(i => i.getAttribute('aria-disabled') !== 'true');
        },

        clearSubmenuActive(sub) {
          this.submenuItems(sub).forEach(i => i.classList.remove('active'));
        },

        setSubmenuActive(sub, index) {
          const items = this.submenuItems(sub);
          items.forEach(i => i.classList.remove('active'));
          if (items[index]) items[index].classList.add('active');
        },

        handleSubmenuMouseMove(e, sub) {
          const items = this.submenuItems(sub);
          const item = items.find(i => i === e.target || i.contains(e.target));
          if (!item) {
            this.clearSubmenuActive(sub);
            return;
          }

          this.setSubmenuActive(sub, items.indexOf(item));
        },

        openSubmenuEl(sub, focusMenu = false) {
          this.closeSubmenu();
          this.openSubmenu = sub;
          const content = sub.querySelector('.context-menu-sub-content');
          const trigger = sub.querySelector('.context-menu-sub-trigger');
          if (content) { content.setAttribute('aria-hidden', 'false'); content.classList.add('open'); }
          if (trigger) trigger.setAttribute('aria-expanded', 'true');

          const subMenu = content?.querySelector('[role="menu"]');
          if (subMenu) {
            const subItems = this.submenuItems(sub);
            this.clearSubmenuActive(sub);
            if (focusMenu) {
              if (subItems[0]) subItems[0].classList.add('active');
              subMenu.focus();
            }
          }
        },

        closeSubmenuEl(sub) {
          const content = sub.querySelector('.context-menu-sub-content');
          const trigger = sub.querySelector('.context-menu-sub-trigger');
          this.clearSubmenuActive(sub);
          if (content) { content.setAttribute('aria-hidden', 'true'); content.classList.remove('open'); }
          if (trigger) trigger.setAttribute('aria-expanded', 'false');
          if (this.openSubmenu === sub) this.openSubmenu = null;
        },

        closeSubmenu() {
          if (this.openSubmenu) { this.closeSubmenuEl(this.openSubmenu); this.menu.focus(); }
        },

        handleSubmenuKey(e, sub) {
          const content = sub.querySelector('.context-menu-sub-content');
          const subMenu = content?.querySelector('[role="menu"]');
          if (!subMenu) return;
          const subItems = Array.from(subMenu.querySelectorAll(':scope > [role^="menuitem"]'))
            .filter(i => i.getAttribute('aria-disabled') !== 'true');
          if (!subItems.length) return;

          let activeIdx = subItems.findIndex(i => i.classList.contains('active'));

          if (e.key === 'ArrowLeft' || e.key === 'Escape') {
            e.preventDefault();
            e.stopPropagation();
            this.closeSubmenuEl(sub);
            this.menu.focus();
          } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            activeIdx = Math.min(activeIdx + 1, subItems.length - 1);
            subItems.forEach(i => i.classList.remove('active'));
            subItems[activeIdx]?.classList.add('active');
          } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            activeIdx = Math.max(activeIdx - 1, 0);
            subItems.forEach(i => i.classList.remove('active'));
            subItems[activeIdx]?.classList.add('active');
          } else if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            const el = subItems[activeIdx]?.querySelector('a,button') || subItems[activeIdx];
            el?.click();
            this.close();
          }
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

  @doc """
  Renders a context menu item. Pass LiveView events via `phx-click` on the item
  or render a link/button inside the slot.
  """
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
      <span class="context-menu-item-content">
        {render_slot(@inner_block)}
      </span>
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

  @doc """
  Renders a checkbox menu item with `role="menuitemcheckbox"`.
  """
  def context_menu_checkbox_item(assigns) do
    ~H"""
    <div
      role="menuitemcheckbox"
      class={["context-menu-item", @class]}
      aria-checked={to_string(@checked)}
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
      <span class="context-menu-item-content">
        {render_slot(@inner_block)}
      </span>
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

  @doc """
  Renders a radio menu item with `role="menuitemradio"`.
  """
  def context_menu_radio_item(assigns) do
    ~H"""
    <div
      role="menuitemradio"
      class={["context-menu-item", @class]}
      aria-checked={to_string(@checked)}
      aria-disabled={@disabled && "true"}
      data-state={@checked && "checked"}
      data-value={@value}
      {@rest}
    >
      <span class="context-menu-item-indicator">
        <span :if={@checked} class="context-menu-radio-dot"></span>
      </span>
      <span class="context-menu-item-content">
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  # -- Submenu --

  attr(:class, :any, default: nil)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  @doc """
  Renders a submenu with a trigger and nested items.
  """
  def context_menu_sub(assigns) do
    ~H"""
    <div class={["context-menu-sub", @class]}>
      <div
        role="menuitem"
        class="context-menu-item context-menu-sub-trigger"
        aria-haspopup="menu"
        aria-expanded="false"
      >
        <span class="context-menu-item-content">
          {render_slot(@trigger)}
        </span>
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
      <div class="context-menu-sub-content" aria-hidden="true">
        <div role="menu" tabindex="-1">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  # -- Label --

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  @doc """
  Renders a non-interactive label for a group of items.
  """
  def context_menu_label(assigns) do
    ~H"""
    <div class={["context-menu-label", @class]} role="presentation">
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- Separator --

  attr(:class, :any, default: nil)

  @doc """
  Renders a separator between menu items.
  """
  def context_menu_separator(assigns) do
    ~H"""
    <div role="separator" class={["context-menu-separator", @class]}></div>
    """
  end
end
