defmodule SutraUI.DropdownMenu do
  @moduledoc """
  A dropdown menu component that displays a list of actions or options.

  The dropdown menu provides a trigger button that opens a popover menu
  with common keyboard navigation support:

  - Click to open/close the menu
  - Arrow keys (Up/Down) for navigation
  - Home/End keys to jump to first/last item
  - Enter/Space to activate items
  - Escape to close the menu
  - Mouse hover to highlight items
  - Automatic closure when clicking outside

  ## Requirements

  - A unique `id` attribute is **required** for the JavaScript hook
  - The component uses CSS anchor positioning for popover placement

  ## Examples

      # Basic dropdown menu
      <.dropdown_menu id="user-menu">
        <:trigger>Options</:trigger>
        <.dropdown_item><a href="/profile">Profile</a></.dropdown_item>
        <.dropdown_item><.link navigate={~p"/settings"}>Settings</.link></.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item variant="destructive">
          <.link href={~p"/logout"} method="delete">Logout</.link>
        </.dropdown_item>
      </.dropdown_menu>

      # With icons and shortcuts
      <.dropdown_menu id="file-menu">
        <:trigger>File</:trigger>
        <.dropdown_item shortcut="Ctrl+N">
          <a href="/new">New</a>
        </.dropdown_item>
        <.dropdown_item shortcut="Ctrl+O">
          <a href="/open">Open</a>
        </.dropdown_item>
      </.dropdown_menu>

      # With groups and labels
      <.dropdown_menu id="settings-menu">
        <:trigger>Settings</:trigger>
        <.dropdown_label>Account</.dropdown_label>
        <.dropdown_item><a href="/profile">Profile</a></.dropdown_item>
        <.dropdown_item><a href="/billing">Billing</a></.dropdown_item>
        <.dropdown_separator />
        <.dropdown_label>Danger Zone</.dropdown_label>
        <.dropdown_item variant="destructive">
          <button phx-click="delete_account">Delete Account</button>
        </.dropdown_item>
      </.dropdown_menu>

      # With disabled items
      <.dropdown_menu id="edit-menu">
        <:trigger>Edit</:trigger>
        <.dropdown_item><button phx-click="cut">Cut</button></.dropdown_item>
        <.dropdown_item><button phx-click="copy">Copy</button></.dropdown_item>
        <.dropdown_item disabled><button>Paste</button></.dropdown_item>
      </.dropdown_menu>

      # Custom positioning
      <.dropdown_menu id="actions-menu" side="top" align="end">
        <:trigger>Actions</:trigger>
        <.dropdown_item><button phx-click="action1">Action 1</button></.dropdown_item>
        <.dropdown_item><button phx-click="action2">Action 2</button></.dropdown_item>
      </.dropdown_menu>

  ## Accessibility

  - The trigger button has `aria-haspopup="menu"` and `aria-expanded` attributes
  - The menu has `role="menu"` and is referenced by `aria-controls`
  - Menu items have `role="menuitem"`
  - The active item is tracked via `aria-activedescendant`
  - Disabled items have `aria-disabled="true"`
  - Keyboard navigation follows the common WAI-ARIA menu interactions
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a dropdown menu component.

  ## Attributes

  - `id` - Required. Unique identifier for the dropdown (needed for JS hook)
  - `side` - Which side the dropdown opens on. Values: `top`, `bottom`, `left`, `right`. Default: `bottom`
  - `align` - Alignment relative to trigger. Values: `start`, `center`, `end`. Default: `start`
  - `class` - Additional CSS classes for the container
  - `trigger_class` - Additional CSS classes for the trigger button
  - `menu_class` - Additional CSS classes for the menu
  - `chevron` - Show the chevron beside the trigger content. Default: `true`. Pass `false`
    for an icon-only trigger (a trigger whose only content is an icon and an `sr-only`
    label also hides it through CSS)

  ## Slots

  - `trigger` - Required. Content for the trigger button
  - `inner_block` - Required. Menu content (use `dropdown_item/1`,
    `dropdown_separator/1`, and `dropdown_label/1`)
  """
  attr(:id, :string, required: true, doc: "Unique identifier (required for hook)")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")

  attr(:side, :string,
    default: "bottom",
    values: ~w(top bottom left right),
    doc: "Popover position relative to trigger"
  )

  attr(:align, :string,
    default: "start",
    values: ~w(start end center),
    doc: "Popover alignment"
  )

  attr(:trigger_class, :string,
    default: nil,
    doc: "Additional CSS classes for the trigger button"
  )

  attr(:menu_class, :string, default: nil, doc: "Additional CSS classes for the menu")

  attr(:chevron, :boolean,
    default: true,
    doc: "Show the chevron beside the trigger content (false for icon-only triggers)"
  )

  attr(:rest, :global, doc: "Additional HTML attributes for the container")

  slot(:trigger, required: true, doc: "Content for the trigger button")
  slot(:inner_block, required: true, doc: "Menu items and content")

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script")

  def dropdown_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class={["dropdown-menu", @class]}
      phx-hook=".DropdownMenu"
      {@rest}
    >
      <button
        type="button"
        id={"#{@id}-trigger"}
        class={["dropdown-menu-trigger", @trigger_class]}
        aria-haspopup="menu"
        aria-controls={"#{@id}-menu"}
        aria-expanded="false"
      >
        {render_slot(@trigger)}
        <svg
          :if={@chevron}
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="dropdown-menu-chevron size-4"
          aria-hidden="true"
        >
          <path d="m6 9 6 6 6-6" />
        </svg>
      </button>
      <div
        id={"#{@id}-popover"}
        data-popover
        data-side={@side}
        data-align={@align}
        class="dropdown-menu-popover"
        aria-hidden="true"
      >
        <div
          role="menu"
          id={"#{@id}-menu"}
          class={["dropdown-menu-content", @menu_class]}
          aria-labelledby={"#{@id}-trigger"}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>

    <script :type={ColocatedHook} name=".DropdownMenu" runtime nonce={@nonce}>
      {
        mounted() {
          this.initDropdownMenu();
        },

        updated() {
          this.updateMenuItems();
          if (this.isOpen()) this.fit(this.popover, this.trigger, this.wantedSide);
        },

        destroyed() {
          this.fitObserver?.disconnect();
          window.removeEventListener('resize', this.resizeHandler);
          if (this.documentClickHandler) {
            document.removeEventListener('click', this.documentClickHandler);
          }
          if (this.popoverEventHandler) {
            document.removeEventListener('sutra-ui:popover', this.popoverEventHandler);
          }
          this.trigger?.removeEventListener('click', this.triggerClickHandler);
          this.el.removeEventListener('keydown', this.keydownHandler);
          this.menu?.removeEventListener('mousemove', this.mouseMoveHandler);
          this.menu?.removeEventListener('mouseleave', this.mouseLeaveHandler);
          this.menu?.removeEventListener('click', this.menuClickHandler);
        },

        initDropdownMenu() {
          this.trigger = this.el.querySelector(':scope > button');
          this.popover = this.el.querySelector(':scope > [data-popover]');
          this.menu = this.popover?.querySelector('[role="menu"]');

          if (!this.trigger || !this.menu || !this.popover) {
            console.error('Dropdown menu initialization failed', this.el);
            return;
          }

          this.wantedSide = this.popover.getAttribute('data-side');
          this.menuItems = [];
          this.activeIndex = -1;

          this.triggerClickHandler = () => this.handleTriggerClick();
          this.keydownHandler = (e) => this.handleKeydown(e);
          this.mouseMoveHandler = (e) => this.handleMouseMove(e);
          this.mouseLeaveHandler = () => this.handleMouseLeave();
          this.menuClickHandler = (e) => this.handleMenuClick(e);

          this.trigger.addEventListener('click', this.triggerClickHandler);
          this.el.addEventListener('keydown', this.keydownHandler);
          this.menu.addEventListener('mousemove', this.mouseMoveHandler);
          this.menu.addEventListener('mouseleave', this.mouseLeaveHandler);
          this.menu.addEventListener('click', this.menuClickHandler);

          this.documentClickHandler = (event) => {
            if (!this.el.contains(event.target)) {
              this.closePopover();
            }
          };
          document.addEventListener('click', this.documentClickHandler);

          this.popoverEventHandler = (event) => {
            if (event.detail.source !== this.el) {
              this.closePopover(false);
            }
          };
          document.addEventListener('sutra-ui:popover', this.popoverEventHandler);

          // Fit the menu inside the viewport each time it opens (and when the window changes).
          this.fitObserver = new MutationObserver(() => {
            if (this.isOpen()) this.fit(this.popover, this.trigger, this.wantedSide);
          });
          this.fitObserver.observe(this.popover, { attributes: true, attributeFilter: ['aria-hidden'] });
          this.resizeHandler = () => {
            if (this.isOpen()) this.fit(this.popover, this.trigger, this.wantedSide);
          };
          window.addEventListener('resize', this.resizeHandler);
        },

        isOpen() {
          return this.trigger?.getAttribute('aria-expanded') === 'true';
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

        updateMenuItems() {
          if (!this.menu) return;
          this.menuItems = Array.from(
            this.menu.querySelectorAll('[role^="menuitem"]')
          ).filter(item => item.getAttribute('aria-disabled') !== 'true');
        },

        closePopover(focusOnTrigger = true) {
          if (this.trigger.getAttribute('aria-expanded') === 'false') return;
          this.trigger.setAttribute('aria-expanded', 'false');
          this.trigger.removeAttribute('aria-activedescendant');
          this.popover.setAttribute('aria-hidden', 'true');

          if (focusOnTrigger) {
            this.trigger.focus();
          }

          this.setActiveItem(-1);
        },

        openPopover(initialSelection = false) {
          document.dispatchEvent(new CustomEvent('sutra-ui:popover', {
            detail: { source: this.el }
          }));

          this.trigger.setAttribute('aria-expanded', 'true');
          this.popover.setAttribute('aria-hidden', 'false');
          this.updateMenuItems();

          if (this.menuItems.length > 0 && initialSelection) {
            if (initialSelection === 'first') {
              this.setActiveItem(0);
            } else if (initialSelection === 'last') {
              this.setActiveItem(this.menuItems.length - 1);
            }
          }
        },

        setActiveItem(index) {
          if (this.activeIndex > -1 && this.menuItems[this.activeIndex]) {
            this.menuItems[this.activeIndex].classList.remove('active');
          }
          this.activeIndex = index;
          if (this.activeIndex > -1 && this.menuItems[this.activeIndex]) {
            const activeItem = this.menuItems[this.activeIndex];
            activeItem.classList.add('active');
            if (activeItem.id) {
              this.trigger.setAttribute('aria-activedescendant', activeItem.id);
            }
          } else {
            this.trigger.removeAttribute('aria-activedescendant');
          }
        },

        handleTriggerClick() {
          const isExpanded = this.trigger.getAttribute('aria-expanded') === 'true';
          if (isExpanded) {
            this.closePopover();
          } else {
            this.openPopover(false);
          }
        },

        handleKeydown(event) {
          const isExpanded = this.trigger.getAttribute('aria-expanded') === 'true';

          if (event.key === 'Escape') {
            if (isExpanded) this.closePopover();
            return;
          }

          if (!isExpanded) {
            if (['Enter', ' '].includes(event.key)) {
              event.preventDefault();
              this.openPopover(false);
            } else if (event.key === 'ArrowDown') {
              event.preventDefault();
              this.openPopover('first');
            } else if (event.key === 'ArrowUp') {
              event.preventDefault();
              this.openPopover('last');
            }
            return;
          }

          if (this.menuItems.length === 0) return;

          let nextIndex = this.activeIndex;

          switch (event.key) {
            case 'ArrowDown':
              event.preventDefault();
              nextIndex = this.activeIndex === -1 ? 0 : Math.min(this.activeIndex + 1, this.menuItems.length - 1);
              break;
            case 'ArrowUp':
              event.preventDefault();
              nextIndex = this.activeIndex === -1 ? this.menuItems.length - 1 : Math.max(this.activeIndex - 1, 0);
              break;
            case 'Home':
              event.preventDefault();
              nextIndex = 0;
              break;
            case 'End':
              event.preventDefault();
              nextIndex = this.menuItems.length - 1;
              break;
            case 'Enter':
            case ' ':
              event.preventDefault();
              if (this.activeIndex > -1) {
                const item = this.menuItems[this.activeIndex];
                const clickable = item.querySelector('a, button') || item;
                clickable.click();
              }
              this.closePopover();
              return;
          }

          if (nextIndex !== this.activeIndex) {
            this.setActiveItem(nextIndex);
          }
        },

        handleMouseMove(event) {
          const menuItem = event.target.closest('[role^="menuitem"]');
          if (menuItem && this.menuItems.includes(menuItem)) {
            const index = this.menuItems.indexOf(menuItem);
            if (index !== this.activeIndex) {
              this.setActiveItem(index);
            }
          }
        },

        handleMouseLeave() {
          this.setActiveItem(-1);
        },

        handleMenuClick(event) {
          if (event.target.closest('[role^="menuitem"]')) {
            this.closePopover();
          }
        }
      }
    </script>
    """
  end

  @doc """
  Renders a menu item wrapper.

  The inner content can be any element - `<a>`, `<button>`, `<.link>`, etc.

  ## Attributes

  - `variant` - Visual variant. Values: `default`, `destructive`. Default: `default`
  - `disabled` - Whether the item is disabled. Default: `false`
  - `shortcut` - Keyboard shortcut to display (e.g., "Ctrl+N")
  - `class` - Additional CSS classes

  ## Examples

      <.dropdown_item><a href="/profile">Profile</a></.dropdown_item>
      <.dropdown_item shortcut="Ctrl+S"><button phx-click="save">Save</button></.dropdown_item>
      <.dropdown_item variant="destructive"><button phx-click="delete">Delete</button></.dropdown_item>
      <.dropdown_item disabled><button>Unavailable</button></.dropdown_item>
  """
  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:disabled, :boolean, default: false)
  attr(:shortcut, :string, default: nil, doc: "Keyboard shortcut to display")
  attr(:class, :string, default: nil)

  attr(:rest, :global)

  slot(:inner_block, required: true)

  def dropdown_item(assigns) do
    ~H"""
    <div
      role="menuitem"
      class={[
        "dropdown-menu-item",
        @variant == "destructive" && "dropdown-menu-item-destructive",
        @disabled && "dropdown-menu-item-disabled",
        @class
      ]}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      <span class="dropdown-menu-item-content">
        {render_slot(@inner_block)}
      </span>
      <kbd :if={@shortcut} class="dropdown-menu-shortcut">{@shortcut}</kbd>
    </div>
    """
  end

  @doc """
  Renders a separator between menu items.

  ## Examples

      <.dropdown_item><a href="/profile">Profile</a></.dropdown_item>
      <.dropdown_separator />
      <.dropdown_item><a href="/logout">Logout</a></.dropdown_item>
  """
  attr(:class, :string, default: nil)

  def dropdown_separator(assigns) do
    ~H"""
    <div role="separator" class={["dropdown-menu-separator", @class]}></div>
    """
  end

  @doc """
  Renders a non-interactive label for a group of items.

  ## Examples

      <.dropdown_label>Account</.dropdown_label>
      <.dropdown_item><a href="/profile">Profile</a></.dropdown_item>
      <.dropdown_item><a href="/settings">Settings</a></.dropdown_item>
  """
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def dropdown_label(assigns) do
    ~H"""
    <div class={["dropdown-menu-label", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
