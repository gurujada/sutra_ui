defmodule SutraUI.DropdownMenu do
  @moduledoc """
  A dropdown menu component that displays a list of actions or options.

  The dropdown menu provides a trigger button that opens a popover menu
  with full keyboard navigation support:

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
  - Keyboard navigation follows WAI-ARIA menu pattern
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

  ## Slots

  - `trigger` - Required. Content for the trigger button
  - `inner_block` - Required. Menu content (use `item/1`, `separator/1`, `label/1`)
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

  attr(:rest, :global, doc: "Additional HTML attributes for the container")

  slot(:trigger, required: true, doc: "Content for the trigger button")
  slot(:inner_block, required: true, doc: "Menu items and content")

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

    <script :type={ColocatedHook} name=".DropdownMenu" runtime>
      {
        mounted() {
          this.initDropdownMenu();
        },

        updated() {
          this.updateMenuItems();
        },

        destroyed() {
          if (this.documentClickHandler) {
            document.removeEventListener('click', this.documentClickHandler);
          }
          if (this.popoverEventHandler) {
            document.removeEventListener('sutra:popover', this.popoverEventHandler);
          }
        },

        initDropdownMenu() {
          this.trigger = this.el.querySelector(':scope > button');
          this.popover = this.el.querySelector(':scope > [data-popover]');
          this.menu = this.popover?.querySelector('[role="menu"]');

          if (!this.trigger || !this.menu || !this.popover) {
            console.error('Dropdown menu initialization failed', this.el);
            return;
          }

          this.menuItems = [];
          this.activeIndex = -1;

          this.trigger.addEventListener('click', () => this.handleTriggerClick());
          this.el.addEventListener('keydown', (e) => this.handleKeydown(e));
          this.menu.addEventListener('mousemove', (e) => this.handleMouseMove(e));
          this.menu.addEventListener('mouseleave', () => this.handleMouseLeave());
          this.menu.addEventListener('click', (e) => this.handleMenuClick(e));

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
          document.addEventListener('sutra:popover', this.popoverEventHandler);
        },

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
          document.dispatchEvent(new CustomEvent('sutra:popover', {
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
