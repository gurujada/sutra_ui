defmodule SutraUI.Sidebar do
  @moduledoc """
  A collapsible sidebar navigation component with mobile toggle support.

  The sidebar provides a responsive navigation panel that can be toggled open/closed.
  By default, sidebars are closed on desktop and require a trigger button or programmatic
  control to open. Use the `open` attribute to make a sidebar initially open.

  It supports:
  - Mobile overlay mode with backdrop
  - Desktop persistent mode (via `open` attribute)
  - Left or right positioning
  - Collapsible submenu sections
  - Active page highlighting
  - Custom header and footer sections

  ## JavaScript Hook

  The sidebar requires JavaScript for:
  - Mobile toggle functionality
  - Close on backdrop click
  - Close on click outside (when sidebar is open)
  - Responsive breakpoint handling
  - Active page link detection and highlighting
  - Managing open/closed state

  The component uses a colocated JavaScript hook that is initialized by
  providing a unique `id` attribute.

  ## Click Outside to Close

  When the sidebar is open, clicking anywhere outside of it (except on trigger buttons)
  will automatically close the sidebar. This provides an intuitive way to dismiss
  the sidebar without requiring an explicit close button.

  ## Examples

  # Basic sidebar with trigger button
  <.sidebar_trigger for="main-sidebar" />
  <.sidebar id="main-sidebar">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/dashboard">Dashboard</a></li>
    <li><a href="/settings">Settings</a></li>
  </ul>
  </.sidebar>

  # Sidebar initially open on desktop
  <.sidebar_trigger for="app-sidebar" />
  <.sidebar id="app-sidebar" side="left" open>
  <:header>
    <div class="flex items-center gap-2 p-2">
      <img src="/logo.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-semibold">My App</span>
    </div>
  </:header>

  <.sidebar_group label="Main">
    <.sidebar_item href="/">Home</.sidebar_item>
    <.sidebar_item href="/dashboard">Dashboard</.sidebar_item>
  </.sidebar_group>

  <:footer>
    <.sidebar_item href="/settings">Settings</.sidebar_item>
  </:footer>
  </.sidebar>

  # Sidebar with collapsible sections
  <.sidebar_trigger for="nav-sidebar" />
  <.sidebar id="nav-sidebar">
  <.sidebar_group label="Navigation">
    <.sidebar_item href="/">Overview</.sidebar_item>

    <.sidebar_submenu label="Projects" open>
      <.sidebar_item href="/projects/active">Active</.sidebar_item>
      <.sidebar_item href="/projects/archived">Archived</.sidebar_item>
    </.sidebar_submenu>

    <.sidebar_item href="/team">Team</.sidebar_item>
  </.sidebar_group>
  </.sidebar>

  # Right-side sidebar with custom trigger
  <.sidebar_trigger for="filter-sidebar" variant="outline">
  <span>Toggle Filters</span>
  </.sidebar_trigger>
  <.sidebar id="filter-sidebar" side="right">
  <.sidebar_group label="Filters">
    <p>Filter options here...</p>
  </.sidebar_group>
  </.sidebar>

  ## Programmatic Control

  You can control the sidebar state from JavaScript using custom events:

      // Toggle sidebar
      document.dispatchEvent(new CustomEvent('sutra-ui:sidebar', {
        detail: { id: 'main-sidebar' }
      }));

      // Open sidebar
      document.dispatchEvent(new CustomEvent('sutra-ui:sidebar', {
        detail: { id: 'main-sidebar', action: 'open' }
      }));

      // Close sidebar
      document.dispatchEvent(new CustomEvent('sutra-ui:sidebar', {
        detail: { id: 'main-sidebar', action: 'close' }
      }));

  ## Accessibility

  - Uses semantic `<aside>` and `<nav>` elements
  - Includes proper ARIA labels and `aria-hidden` state
  - Sets `inert` attribute when closed to prevent keyboard navigation
  - Automatically manages focus when opened/closed
  - Active page links marked with `aria-current="page"`

  ## Mobile Behavior

  On mobile (below breakpoint):
  - Sidebar becomes a full-screen overlay
  - Clicking outside the nav closes the sidebar
  - Clicking links automatically closes the sidebar
  - Use `data-keep-mobile-sidebar-open` attribute to prevent auto-close on specific elements

  ## CSS Variables

  The sidebar uses these CSS variables:
  - `--sidebar-width`: Desktop sidebar width (default: 16rem)
  - `--sidebar-mobile-width`: Mobile sidebar width (default: 18rem)
  - `--sidebar`: Background color
  - `--sidebar-foreground`: Text color
  - `--sidebar-accent`: Hover/active background
  - `--sidebar-accent-foreground`: Hover/active text color
  - `--sidebar-border`: Border color
  - `--sidebar-ring`: Focus ring color
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a sidebar navigation component.

  ## Attributes

  - `id` (required) - Unique identifier for the sidebar (required for hook)
  - `side` - Which side to position the sidebar ("left" or "right", default: "left")
  - `open` - Initial open state for desktop (default: false)
  - `mobile_open` - Initial open state for mobile (default: false)
  - `breakpoint` - Pixel width for mobile breakpoint (default: 768)
  - `label` - ARIA label for navigation (default: "Sidebar navigation")
  - `class` - Additional CSS classes for the aside container

  ## Slots

  - `header` - Optional header content (rendered in nav > header)
  - `footer` - Optional footer content (rendered in nav > footer)
  - `inner_block` (required) - Main sidebar content (rendered in nav > section)

  ## Toggle Button

  Use `sidebar_trigger/1` to create a toggle button for the sidebar:

      <.sidebar_trigger for="my-sidebar" />
      <.sidebar id="my-sidebar">
        <!-- sidebar content -->
      </.sidebar>
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the sidebar (required for hook)")

  attr(:side, :string,
    default: "left",
    values: ["left", "right", "top", "bottom"],
    doc: "Which side to position the sidebar"
  )

  attr(:open, :boolean, default: false, doc: "Initial open state for desktop")
  attr(:mobile_open, :boolean, default: false, doc: "Initial open state for mobile")
  attr(:breakpoint, :integer, default: 768, doc: "Pixel width for mobile breakpoint")
  attr(:label, :string, default: "Sidebar navigation", doc: "ARIA label for navigation")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  slot(:header, doc: "Optional header content")
  slot(:footer, doc: "Optional footer content")
  slot(:inner_block, required: true, doc: "Main sidebar content")

  def sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      class={["sidebar", @class]}
      data-side={@side}
      aria-hidden={to_string(!@open)}
      data-initial-open={to_string(@open)}
      data-initial-mobile-open={to_string(@mobile_open)}
      data-breakpoint={@breakpoint}
      phx-hook=".Sidebar"
    >
      <div class="sidebar-backdrop" aria-hidden="true"></div>
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

    <script :type={ColocatedHook} name=".Sidebar" runtime>
      {
        mounted() {
          this.initializeSidebar();
        },

        updated() {
          // Re-scan for current page links when content updates
          this.updateCurrentPageLinks();
        },

        destroyed() {
          // Clean up event listeners
          window.removeEventListener('popstate', this.updateCurrentPageLinksHandler);
          window.removeEventListener('sutra-ui:locationchange', this.updateCurrentPageLinksHandler);
          document.removeEventListener('sutra-ui:sidebar', this.sidebarEventHandler);
          document.removeEventListener('click', this.handleClickOutside);
        },

        initializeSidebar() {
          const initialOpen = this.el.dataset.initialOpen !== 'false';
          const initialMobileOpen = this.el.dataset.initialMobileOpen === 'true';
          const breakpoint = parseInt(this.el.dataset.breakpoint) || 768;

          // Determine initial state based on screen size
          this.open = breakpoint > 0
            ? (window.innerWidth >= breakpoint ? initialOpen : initialMobileOpen)
            : initialOpen;

          this.breakpoint = breakpoint;
          this.sidebarId = this.el.id;
          this.backdrop = this.el.querySelector('.sidebar-backdrop');
          this.aside = this.el.querySelector('aside');

          // Bind event handlers
          this.updateCurrentPageLinksHandler = () => this.updateCurrentPageLinks();
          this.sidebarEventHandler = (event) => this.handleSidebarEvent(event);

          // Listen for navigation events to update current page links
          window.addEventListener('popstate', this.updateCurrentPageLinksHandler);
          window.addEventListener('sutra-ui:locationchange', this.updateCurrentPageLinksHandler);

          // Listen for programmatic control events
          document.addEventListener('sutra-ui:sidebar', this.sidebarEventHandler);

          // Handle clicks on backdrop to close
          if (this.backdrop) {
            this.backdrop.addEventListener('click', () => this.setState(false));
          }

          // Handle clicks on links to close on mobile
          this.aside.addEventListener('click', (event) => this.handleAsideClick(event));

          // Handle clicks outside sidebar to close (for demo containers)
          this.handleClickOutside = (event) => {
            if (this.open && !this.aside.contains(event.target) && !event.target.closest('.sidebar-trigger')) {
              this.setState(false);
            }
          };
          document.addEventListener('click', this.handleClickOutside);

          // Initialize state
          this.updateState();
          this.updateCurrentPageLinks();

          // Mark as initialized
          this.el.dataset.sidebarInitialized = true;
          this.el.dispatchEvent(new CustomEvent('sutra-ui:initialized'));
        },

        handleSidebarEvent(event) {
          // Ignore events for other sidebars
          if (event.detail?.id && event.detail.id !== this.sidebarId) return;

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

          // On mobile, close sidebar when clicking links or buttons (unless marked to keep open)
          if (isMobile && target.closest('a, button') && !target.closest('[data-keep-mobile-sidebar-open]')) {
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
  Renders a sidebar group with an optional label/heading.

  ## Attributes

  - `label` - Optional heading text for the group
  - `class` - Additional CSS classes

  ## Examples

      <.sidebar_group label="Navigation">
        <.sidebar_item href="/">Home</.sidebar_item>
        <.sidebar_item href="/about">About</.sidebar_item>
      </.sidebar_group>

      <.sidebar_group>
        <.sidebar_item href="/settings">Settings</.sidebar_item>
      </.sidebar_group>
  """
  attr(:label, :string, default: nil, doc: "Optional heading for the group")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  slot(:inner_block, required: true)

  def sidebar_group(assigns) do
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
  Renders a sidebar navigation item (link).

  ## Attributes

  - `href` (required) - URL for the link
  - `variant` - Visual variant ("default" or "outline")
  - `size` - Size variant ("default", "sm", or "lg")
  - `current` - Whether this is the current page
  - `class` - Additional CSS classes
  - `rest` - Additional HTML attributes

  ## Examples

      <.sidebar_item href="/">Home</.sidebar_item>

      <.sidebar_item href="/dashboard" variant="outline">
        Dashboard
      </.sidebar_item>

      <.sidebar_item href="/settings" current>
        Settings
      </.sidebar_item>

      <.sidebar_item href="/profile" size="sm">
        Profile
      </.sidebar_item>
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
    include: ~w(target rel data-ignore-current data-keep-mobile-sidebar-open),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true)

  def sidebar_item(assigns) do
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
  Renders a collapsible sidebar submenu.

  ## Attributes

  - `label` (required) - Label text for the submenu
  - `open` - Whether the submenu is initially open (default: false)
  - `class` - Additional CSS classes

  ## Examples

      <.sidebar_submenu label="Projects">
        <.sidebar_item href="/projects/active">Active</.sidebar_item>
        <.sidebar_item href="/projects/archived">Archived</.sidebar_item>
      </.sidebar_submenu>

      <.sidebar_submenu label="Admin" open>
        <.sidebar_item href="/admin/users">Users</.sidebar_item>
        <.sidebar_item href="/admin/settings">Settings</.sidebar_item>
      </.sidebar_submenu>
  """
  attr(:label, :string, required: true, doc: "Label for the submenu")
  attr(:open, :boolean, default: false, doc: "Whether the submenu is initially open")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  slot(:inner_block, required: true)

  def sidebar_submenu(assigns) do
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
  Renders a separator/divider in the sidebar.

  ## Examples

  <.sidebar_separator />
  """
  def sidebar_separator(assigns) do
    ~H"""
    <hr role="separator" />
    """
  end

  @doc """
  Renders a button to toggle the sidebar open/closed.

  ## Attributes

  - `for` (required) - The ID of the sidebar to toggle
  - `variant` - Visual variant. One of `primary`, `secondary`, `destructive`, `outline`, `ghost`, `link`. Defaults to `ghost`.
  - `size` - Size variant. One of `default`, `sm`, `lg`, `icon`. Defaults to `icon`.
  - `class` - Additional CSS classes

  ## Examples

  # Default icon button (hamburger menu)
  <.sidebar_trigger for="main-sidebar" />

  # Custom variant and size
  <.sidebar_trigger for="main-sidebar" variant="outline" size="sm" />

  # Custom content
  <.sidebar_trigger for="main-sidebar" variant="primary">
    <span>Menu</span>
  </.sidebar_trigger>
  """
  attr(:for, :string, required: true, doc: "ID of the sidebar to toggle")

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

  def sidebar_trigger(assigns) do
    ~H"""
    <button
      type="button"
      class={["sidebar-trigger", sidebar_trigger_class(@variant, @size), @class]}
      data-for={@for}
      aria-label="Toggle sidebar"
      phx-click={Phoenix.LiveView.JS.dispatch("sutra-ui:sidebar", detail: %{id: @for})}
      {@rest}
    >
      {render_slot(@inner_block) || default_trigger_icon()}
    </button>
    """
  end

  defp sidebar_trigger_class(variant, size) do
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
