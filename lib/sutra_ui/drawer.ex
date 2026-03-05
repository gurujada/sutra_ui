defmodule SutraUI.Drawer do
  @moduledoc """
  A collapsible drawer navigation component with mobile toggle support.

  The drawer provides a responsive navigation panel that can be toggled open/closed.
  By default, drawers are closed on desktop and require a trigger button or programmatic
  control to open. Use the `open` attribute to make a drawer initially open.

  It supports:
  - Mobile overlay mode with backdrop
  - Desktop persistent mode (via `open` attribute)
  - Left or right positioning
  - Collapsible submenu sections
  - Active page highlighting
  - Custom header and footer sections

  ## JavaScript Hook

  The drawer requires JavaScript for:
  - Mobile toggle functionality
  - Close on backdrop click
  - Close on click outside (when drawer is open)
  - Responsive breakpoint handling
  - Active page link detection and highlighting
  - Managing open/closed state

  The component uses a colocated JavaScript hook that is initialized by
  providing a unique `id` attribute.

  ## Click Outside to Close

  When the drawer is open, clicking anywhere outside of it (except on trigger buttons)
  will automatically close the drawer. This provides an intuitive way to dismiss
  the drawer without requiring an explicit close button.

  ## Examples

  # Basic drawer with trigger button
  <.drawer_trigger for="main-drawer" />
  <.drawer id="main-drawer">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/dashboard">Dashboard</a></li>
    <li><a href="/settings">Settings</a></li>
  </ul>
  </.drawer>

  # Drawer initially open on desktop
  <.drawer_trigger for="app-drawer" />
  <.drawer id="app-drawer" side="left" open>
  <:header>
    <div class="flex items-center gap-2 p-2">
      <img src="/logo.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-semibold">My App</span>
    </div>
  </:header>

  <.drawer_group label="Main">
    <.drawer_item href="/">Home</.drawer_item>
    <.drawer_item href="/dashboard">Dashboard</.drawer_item>
  </.drawer_group>

  <:footer>
    <.drawer_item href="/settings">Settings</.drawer_item>
  </:footer>
  </.drawer>

  # Drawer with collapsible sections
  <.drawer_trigger for="nav-drawer" />
  <.drawer id="nav-drawer">
  <.drawer_group label="Navigation">
    <.drawer_item href="/">Overview</.drawer_item>

    <.drawer_submenu label="Projects" open>
      <.drawer_item href="/projects/active">Active</.drawer_item>
      <.drawer_item href="/projects/archived">Archived</.drawer_item>
    </.drawer_submenu>

    <.drawer_item href="/team">Team</.drawer_item>
  </.drawer_group>
  </.drawer>

  # Right-side drawer with custom trigger
  <.drawer_trigger for="filter-drawer" variant="outline">
  <span>Toggle Filters</span>
  </.drawer_trigger>
  <.drawer id="filter-drawer" side="right">
  <.drawer_group label="Filters">
    <p>Filter options here...</p>
  </.drawer_group>
  </.drawer>

  ## Programmatic Control

  You can control the drawer state from JavaScript using custom events:

      // Toggle drawer
      document.dispatchEvent(new CustomEvent('sutra-ui:drawer', {
        detail: { id: 'main-drawer' }
      }));

      // Open drawer
      document.dispatchEvent(new CustomEvent('sutra-ui:drawer', {
        detail: { id: 'main-drawer', action: 'open' }
      }));

      // Close drawer
      document.dispatchEvent(new CustomEvent('sutra-ui:drawer', {
        detail: { id: 'main-drawer', action: 'close' }
      }));

  ## Accessibility

  - Uses semantic `<aside>` and `<nav>` elements
  - Includes proper ARIA labels and `aria-hidden` state
  - Sets `inert` attribute when closed to prevent keyboard navigation
  - Automatically manages focus when opened/closed
  - Active page links marked with `aria-current="page"`

  ## Mobile Behavior

  On mobile (below breakpoint):
  - Drawer becomes a full-screen overlay
  - Clicking outside the nav closes the drawer
  - Clicking links automatically closes the drawer
  - Use `data-keep-mobile-drawer-open` attribute to prevent auto-close on specific elements

  ## CSS Variables

  The drawer uses these CSS variables:
  - `--drawer-width`: Desktop drawer width (default: 16rem)
  - `--drawer-mobile-width`: Mobile drawer width (default: 18rem)
  - `--drawer`: Background color
  - `--drawer-foreground`: Text color
  - `--drawer-accent`: Hover/active background
  - `--drawer-accent-foreground`: Hover/active text color
  - `--drawer-border`: Border color
  - `--drawer-ring`: Focus ring color
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a drawer navigation component.

  ## Attributes

  - `id` (required) - Unique identifier for the drawer (required for hook)
  - `side` - Which side to position the drawer ("left" or "right", default: "left")
  - `open` - Initial open state for desktop (default: false)
  - `mobile_open` - Initial open state for mobile (default: false)
  - `breakpoint` - Pixel width for mobile breakpoint (default: 768)
  - `label` - ARIA label for navigation (default: "Drawer navigation")
  - `class` - Additional CSS classes for the aside container

  ## Slots

  - `header` - Optional header content (rendered in nav > header)
  - `footer` - Optional footer content (rendered in nav > footer)
  - `inner_block` (required) - Main drawer content (rendered in nav > section)

  ## Toggle Button

  Use `drawer_trigger/1` to create a toggle button for the drawer:

      <.drawer_trigger for="my-drawer" />
      <.drawer id="my-drawer">
        <!-- drawer content -->
      </.drawer>
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the drawer (required for hook)")

  attr(:side, :string,
    default: "left",
    values: ["left", "right", "top", "bottom"],
    doc: "Which side to position the drawer"
  )

  attr(:open, :boolean, default: false, doc: "Initial open state for desktop")
  attr(:mobile_open, :boolean, default: false, doc: "Initial open state for mobile")
  attr(:breakpoint, :integer, default: 768, doc: "Pixel width for mobile breakpoint")
  attr(:label, :string, default: "Drawer navigation", doc: "ARIA label for navigation")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  slot(:header, doc: "Optional header content")
  slot(:footer, doc: "Optional footer content")
  slot(:inner_block, required: true, doc: "Main drawer content")

  def drawer(assigns) do
    ~H"""
    <div
      id={@id}
      class={["drawer", @class]}
      data-side={@side}
      aria-hidden={to_string(!@open)}
      data-initial-open={to_string(@open)}
      data-initial-mobile-open={to_string(@mobile_open)}
      data-breakpoint={@breakpoint}
      phx-hook=".Drawer"
    >
      <div class="drawer-backdrop" aria-hidden="true"></div>
      <aside inert={!@open}>
        <nav aria-label={@label}>
          <header :if={@header != []}>
            {render_slot(@header)}
          </header>

          <section>
            {render_slot(@inner_block)}
          </section>

          <footer :if={@footer != []}>
            {render_slot(@footer)}
          </footer>
        </nav>
      </aside>
    </div>

    <script :type={ColocatedHook} name=".Drawer" runtime>
      {
        mounted() {
          this.initializeDrawer();
        },

        updated() {
          // Re-scan for current page links when content updates
          this.updateCurrentPageLinks();
        },

        destroyed() {
          // Clean up event listeners
          window.removeEventListener('popstate', this.updateCurrentPageLinksHandler);
          window.removeEventListener('sutra-ui:locationchange', this.updateCurrentPageLinksHandler);
          document.removeEventListener('sutra-ui:drawer', this.drawerEventHandler);
          document.removeEventListener('click', this.handleClickOutside);
        },

        initializeDrawer() {
          const initialOpen = this.el.dataset.initialOpen !== 'false';
          const initialMobileOpen = this.el.dataset.initialMobileOpen === 'true';
          const breakpoint = parseInt(this.el.dataset.breakpoint) || 768;

          // Determine initial state based on screen size
          this.open = breakpoint > 0
            ? (window.innerWidth >= breakpoint ? initialOpen : initialMobileOpen)
            : initialOpen;

          this.breakpoint = breakpoint;
          this.drawerId = this.el.id;
          this.backdrop = this.el.querySelector('.drawer-backdrop');
          this.aside = this.el.querySelector('aside');

          // Bind event handlers
          this.updateCurrentPageLinksHandler = () => this.updateCurrentPageLinks();
          this.drawerEventHandler = (event) => this.handleDrawerEvent(event);

          // Listen for navigation events to update current page links
          window.addEventListener('popstate', this.updateCurrentPageLinksHandler);
          window.addEventListener('sutra-ui:locationchange', this.updateCurrentPageLinksHandler);

          // Listen for programmatic control events
          document.addEventListener('sutra-ui:drawer', this.drawerEventHandler);

          // Handle clicks on backdrop to close
          if (this.backdrop) {
            this.backdrop.addEventListener('click', () => this.setState(false));
          }

          // Handle clicks on links to close on mobile
          this.aside.addEventListener('click', (event) => this.handleAsideClick(event));

          // Handle clicks outside drawer to close (for demo containers)
          this.handleClickOutside = (event) => {
            if (this.open && !this.aside.contains(event.target) && !event.target.closest('.drawer-trigger')) {
              this.setState(false);
            }
          };
          document.addEventListener('click', this.handleClickOutside);

          // Initialize state
          this.updateState();
          this.updateCurrentPageLinks();

          // Mark as initialized
          this.el.dataset.drawerInitialized = true;
          this.el.dispatchEvent(new CustomEvent('sutra-ui:initialized'));
        },

        handleDrawerEvent(event) {
          // Ignore events for other drawers
          if (event.detail?.id && event.detail.id !== this.drawerId) return;

          switch (event.detail?.action) {
            case 'open':
              this.setState(true);
              break;
            case 'close':
              this.setState(false);
              break;
            default:
              this.setState(!this.open);
              break;
          }
        },

        handleAsideClick(event) {
          const target = event.target;
          const isMobile = window.innerWidth < this.breakpoint;

          // On mobile, close drawer when clicking links or buttons (unless marked to keep open)
          if (isMobile && target.closest('a, button') && !target.closest('[data-keep-mobile-drawer-open]')) {
            if (document.activeElement) document.activeElement.blur();
            this.setState(false);
          }
        },

        updateCurrentPageLinks() {
          const currentPath = window.location.pathname.replace(/\/$/, '');
          this.el.querySelectorAll('a').forEach(link => {
            // Skip links marked with data-ignore-current
            if (link.hasAttribute('data-ignore-current')) return;

            const linkPath = new URL(link.href).pathname.replace(/\/$/, '');
            if (linkPath === currentPath) {
              link.setAttribute('aria-current', 'page');
            } else {
              link.removeAttribute('aria-current');
            }
          });
        },

        setState(state) {
          this.open = state;
          this.updateState();
        },

        updateState() {
          this.el.setAttribute('aria-hidden', !this.open);
          if (this.open) {
            this.aside.removeAttribute('inert');
          } else {
            this.aside.setAttribute('inert', '');
          }
        }
      }
    </script>
    """
  end

  @doc """
  Renders a drawer group with an optional label/heading.

  ## Attributes

  - `label` - Optional heading text for the group
  - `class` - Additional CSS classes

  ## Examples

      <.drawer_group label="Navigation">
        <.drawer_item href="/">Home</.drawer_item>
        <.drawer_item href="/about">About</.drawer_item>
      </.drawer_group>

      <.drawer_group>
        <.drawer_item href="/settings">Settings</.drawer_item>
      </.drawer_group>
  """
  attr(:label, :string, default: nil, doc: "Optional heading for the group")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  slot(:inner_block, required: true)

  def drawer_group(assigns) do
    ~H"""
    <div role="group" class={@class}>
      <h3 :if={@label}>{@label}</h3>
      <ul>
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  @doc """
  Renders a drawer navigation item (link).

  ## Attributes

  - `href` (required) - URL for the link
  - `variant` - Visual variant ("default" or "outline")
  - `size` - Size variant ("default", "sm", or "lg")
  - `current` - Whether this is the current page
  - `class` - Additional CSS classes
  - `rest` - Additional HTML attributes

  ## Examples

      <.drawer_item href="/">Home</.drawer_item>

      <.drawer_item href="/dashboard" variant="outline">
        Dashboard
      </.drawer_item>

      <.drawer_item href="/settings" current>
        Settings
      </.drawer_item>

      <.drawer_item href="/profile" size="sm">
        Profile
      </.drawer_item>
  """
  attr(:href, :string, required: true, doc: "URL for the link")

  attr(:variant, :string,
    default: "default",
    values: ["default", "outline"],
    doc: "Visual variant"
  )

  attr(:size, :string, default: "default", values: ["default", "sm", "lg"], doc: "Size variant")
  attr(:current, :boolean, default: false, doc: "Whether this is the current page")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(target rel data-ignore-current data-keep-mobile-drawer-open),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true)

  def drawer_item(assigns) do
    ~H"""
    <li>
      <a
        href={@href}
        data-variant={@variant}
        data-size={@size}
        aria-current={if @current, do: "page", else: nil}
        class={@class}
        {@rest}
      >
        <span>{render_slot(@inner_block)}</span>
      </a>
    </li>
    """
  end

  @doc """
  Renders a collapsible drawer submenu.

  ## Attributes

  - `label` (required) - Label text for the submenu
  - `open` - Whether the submenu is initially open (default: false)
  - `class` - Additional CSS classes

  ## Examples

      <.drawer_submenu label="Projects">
        <.drawer_item href="/projects/active">Active</.drawer_item>
        <.drawer_item href="/projects/archived">Archived</.drawer_item>
      </.drawer_submenu>

      <.drawer_submenu label="Admin" open>
        <.drawer_item href="/admin/users">Users</.drawer_item>
        <.drawer_item href="/admin/settings">Settings</.drawer_item>
      </.drawer_submenu>
  """
  attr(:label, :string, required: true, doc: "Label for the submenu")
  attr(:open, :boolean, default: false, doc: "Whether the submenu is initially open")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  slot(:inner_block, required: true)

  def drawer_submenu(assigns) do
    ~H"""
    <li>
      <details open={@open} class={@class}>
        <summary>
          <span>{@label}</span>
        </summary>
        <ul>
          {render_slot(@inner_block)}
        </ul>
      </details>
    </li>
    """
  end

  @doc """
  Renders a separator/divider in the drawer.

  ## Examples

  <.drawer_separator />
  """
  def drawer_separator(assigns) do
    ~H"""
    <hr role="separator" />
    """
  end

  @doc """
  Renders a button to toggle the drawer open/closed.

  ## Attributes

  - `for` (required) - The ID of the drawer to toggle
  - `variant` - Visual variant. One of `primary`, `secondary`, `destructive`, `outline`, `ghost`, `link`. Defaults to `ghost`.
  - `size` - Size variant. One of `default`, `sm`, `lg`, `icon`. Defaults to `icon`.
  - `class` - Additional CSS classes

  ## Examples

  # Default icon button (hamburger menu)
  <.drawer_trigger for="main-drawer" />

  # Custom variant and size
  <.drawer_trigger for="main-drawer" variant="outline" size="sm" />

  # Custom content
  <.drawer_trigger for="main-drawer" variant="primary">
    <span>Menu</span>
  </.drawer_trigger>
  """
  attr(:for, :string, required: true, doc: "ID of the drawer to toggle")

  attr(:variant, :string,
    default: "ghost",
    values: ~w(primary secondary destructive outline ghost link),
    doc: "Visual style variant"
  )

  attr(:size, :string,
    default: "icon",
    values: ~w(default sm lg icon),
    doc: "Size variant"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, doc: "Custom button content (defaults to hamburger icon)")

  def drawer_trigger(assigns) do
    ~H"""
    <button
      type="button"
      class={["drawer-trigger", drawer_trigger_class(@variant, @size), @class]}
      data-for={@for}
      aria-label="Toggle drawer"
      phx-click={Phoenix.LiveView.JS.dispatch("sutra-ui:drawer", detail: %{id: @for})}
      {@rest}
    >
      {render_slot(@inner_block) || default_trigger_icon()}
    </button>
    """
  end

  defp drawer_trigger_class(variant, size) do
    [base, _extra] = SutraUI.Button.button_class(variant, size, nil)
    base
  end

  defp default_trigger_icon do
    # Hamburger icon (3 horizontal lines)
    Phoenix.HTML.raw(
      ~s(<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-menu"><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>)
    )
  end
end
