defmodule SutraUI.ThemeSwitcher do
  @moduledoc """
  A component that allows users to toggle between light and dark themes.

  The theme switcher manages theme persistence in localStorage and respects
  the user's system preferences (prefers-color-scheme). It toggles the `.dark`
  class on the document root element.

  ## Theme Management

  The theme switcher integrates with a theme system that:
  - Persists theme preference in localStorage (key: 'sutra-ui:theme')
  - Applies theme before page load to prevent flash of unstyled content
  - Syncs theme changes across browser tabs
  - Respects system preferences (prefers-color-scheme) as fallback

  The component dispatches `sutra-ui:set-theme` events to integrate with this system.

  ## Examples

      # Basic theme switcher
      <.theme_switcher id="theme-toggle" />

      # With custom tooltip
      <.theme_switcher id="theme-toggle" tooltip="Switch theme" />

      # With custom tooltip position
      <.theme_switcher id="theme-toggle" tooltip="Switch theme" tooltip_side="left" />

      # Different button variants
      <.theme_switcher id="theme-toggle" variant="ghost" />
      <.theme_switcher id="theme-toggle" size="sm" />

      # Different icon size
      <.theme_switcher id="theme-toggle" icon_class="size-5" />

      # Custom classes
      <.theme_switcher id="theme-toggle" class="ml-auto" />

  ## Theme Initialization

  Add this script to your root layout's `<head>` to prevent flash of unstyled content:

      <script>
        (function() {
          const theme = localStorage.getItem('sutra-ui:theme') ||
            (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
          if (theme === 'dark') document.documentElement.classList.add('dark');
          
          window.addEventListener('sutra-ui:set-theme', (e) => {
            const newTheme = e.detail?.theme;
            if (newTheme === 'dark') {
              document.documentElement.classList.add('dark');
            } else {
              document.documentElement.classList.remove('dark');
            }
            localStorage.setItem('sutra-ui:theme', newTheme);
          });
        })();
      </script>
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a theme switcher button.

  The button displays a sun icon in dark mode and a moon icon in light mode.
  Clicking the button toggles between themes.

  ## Attributes

  - `id` (required) - Unique identifier for the theme switcher. Required for the JavaScript hook.
  - `variant` - Button variant: "primary", "secondary", "destructive", "outline", "ghost", "link". Defaults to "outline".
  - `size` - Button size: "default", "sm", "lg", "icon". Defaults to "icon".
  - `tooltip` - Tooltip text shown on hover. Defaults to "Toggle theme".
  - `tooltip_side` - Tooltip position: "top", "bottom", "left", "right". Defaults to "bottom".
  - `icon_class` - CSS class for icon sizing (e.g., "size-4", "size-5"). Defaults to "size-4".
  - `class` - Additional CSS classes to apply to the button.
  - `rest` - Additional HTML attributes passed to the button element.
  """
  attr(:id, :string, required: true, doc: "Unique identifier (required for JavaScript hook)")

  attr(:variant, :string,
    default: "outline",
    values: ~w(primary secondary destructive outline ghost link),
    doc: "The visual variant of the button"
  )

  attr(:size, :string,
    default: "icon",
    values: ~w(default sm lg icon),
    doc: "The size variant of the button"
  )

  attr(:tooltip, :string,
    default: nil,
    doc: "Tooltip text displayed on hover (optional)"
  )

  attr(:tooltip_side, :string,
    default: "bottom",
    values: ~w(top bottom left right),
    doc: "Position of the tooltip relative to the button"
  )

  attr(:icon_class, :string,
    default: "size-4",
    doc: "CSS class for icon sizing (e.g., size-4, size-5)"
  )

  attr(:class, :string,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(aria-label),
    doc: "Additional HTML attributes"
  )

  def theme_switcher(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      phx-hook=".ThemeSwitcher"
      data-tooltip={@tooltip}
      data-side={@tooltip_side}
      aria-label={@tooltip || "Toggle theme"}
      class={[button_class(@variant, @size), @class]}
      {@rest}
    >
      <span class="theme-switcher-dark">
        <.icon name="hero-sun" class={@icon_class} />
      </span>
      <span class="theme-switcher-light">
        <.icon name="hero-moon" class={@icon_class} />
      </span>
    </button>

    <script :type={ColocatedHook} name=".ThemeSwitcher">
      export default {
        mounted() {
          // Handle click events to toggle theme
          // Check current theme and toggle to the opposite
          this.el.addEventListener('click', () => {
            const isDark = document.documentElement.classList.contains('dark');
            const newTheme = isDark ? 'light' : 'dark';
            window.dispatchEvent(new CustomEvent('sutra-ui:set-theme', { detail: { theme: newTheme } }));
          });
        }
      }
    </script>
    """
  end

  # Generate the appropriate CSS class based on variant and size combination
  # Follows the same pattern as the button component
  defp button_class(variant, size) do
    case {size, variant} do
      # Default size
      {"default", "primary"} -> "btn"
      {"default", variant} -> "btn-#{variant}"
      # Small size
      {"sm", "primary"} -> "btn-sm"
      {"sm", variant} -> "btn-sm-#{variant}"
      # Large size
      {"lg", "primary"} -> "btn-lg"
      {"lg", variant} -> "btn-lg-#{variant}"
      # Icon size
      {"icon", "primary"} -> "btn-icon"
      {"icon", variant} -> "btn-icon-#{variant}"
    end
  end
end
