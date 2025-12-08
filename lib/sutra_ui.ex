defmodule SutraUI do
  @moduledoc """
  Sutra UI - We define the rules, so you don't have to.

  A pure Phoenix LiveView UI component library. No dependencies, no nonsense.
  Just LiveView components with colocated hooks where needed.

  ## Installation

  Add `sutra_ui` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:sutra_ui, "~> 0.1.0"}
        ]
      end

  ## Usage

  Import all components in your web module:

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use SutraUI
            # ... other imports
          end
        end
      end

  Or import specific components:

      defmodule MyAppWeb.SomeLive do
        use Phoenix.LiveView

        import SutraUI.Button
        import SutraUI.Icon

        # ...
      end

  ## Available Components

  ### Foundation (Phase 1)
  - `SutraUI.Icon` - Icons (requires icon CSS setup)
  - `SutraUI.Button` - Buttons with variants and states
  - `SutraUI.Badge` - Status badges
  - `SutraUI.Spinner` - Loading spinners
  - `SutraUI.Kbd` - Keyboard shortcuts

  ### Form Primitives (Phase 2)
  - `SutraUI.Label` - Form labels
  - `SutraUI.Input` - Text inputs, email, password, etc.
  - `SutraUI.Textarea` - Multi-line text input
  - `SutraUI.Checkbox` - Checkbox input
  - `SutraUI.Switch` - Toggle switch
  - `SutraUI.RadioGroup` - Radio button groups
  - `SutraUI.Field` - Field container with label/description/error
  - `SutraUI.Select` - Custom select dropdown (with JS hook)
  - `SutraUI.Slider` - Range slider (with JS hook)

  ### Layout & Data Display (Phase 3)
  - `SutraUI.Card` - Card container with header, content, footer
  - `SutraUI.Header` - Page header with title, subtitle, actions
  - `SutraUI.Table` - Data table with column definitions
  - `SutraUI.Skeleton` - Loading placeholder
  - `SutraUI.Empty` - Empty state with icon, title, description
  - `SutraUI.Alert` - Alert/callout messages
  - `SutraUI.Progress` - Progress bar indicator

  ### Navigation & Interactive (Phase 4)
  - `SutraUI.Breadcrumb` - Breadcrumb navigation
  - `SutraUI.Pagination` - Page navigation
  - `SutraUI.Accordion` - Collapsible content sections
  - `SutraUI.Tabs` - Tab panels (with JS hook)
  - `SutraUI.DropdownMenu` - Dropdown menu (with JS hook)
  - `SutraUI.Toast` - Toast notifications (with JS hook)

  ### Advanced UI (Phase 5)
  - `SutraUI.Avatar` - User avatars with fallback support
  - `SutraUI.Tooltip` - CSS-only hover tooltips
  - `SutraUI.Dialog` - Modal dialogs
  - `SutraUI.Popover` - Click-triggered popups
  - `SutraUI.Command` - Command palette with search
  - `SutraUI.Carousel` - CSS scroll-snap carousel

  ### Form & Layout Helpers (Phase 6)
  - `SutraUI.FilterBar` - Filter bar for index pages
  - `SutraUI.InputGroup` - Input with prefix/suffix attachments
  - `SutraUI.Item` - Versatile list item component
  - `SutraUI.LoadingState` - Loading indicator with message
  - `SutraUI.SimpleForm` - Simple form wrapper with auto-styling

  ### Navigation (Phase 7)
  - `SutraUI.NavPills` - Responsive navigation pills
  - `SutraUI.Sidebar` - Collapsible sidebar navigation
  - `SutraUI.TabNav` - Server-side routed tab navigation
  - `SutraUI.ThemeSwitcher` - Light/dark theme toggle

  ### Advanced Form Controls (Phase 8)
  - `SutraUI.RangeSlider` - Dual-handle range slider for selecting value ranges
  - `SutraUI.LiveSelect` - Dynamic searchable select with async options loading

  ## Tailwind CSS

  This library uses Tailwind CSS classes. Make sure your project has
  Tailwind configured and includes the Sutra UI source in your content paths:

      // tailwind.config.js
      module.exports = {
        content: [
          // ...
          "../deps/sutra_ui/**/*.*ex"
        ],
        // ...
      }

  ## Accessibility

  All components are built with accessibility in mind:
  - Proper ARIA attributes
  - Keyboard navigation
  - Focus management
  - Screen reader support

  See individual component docs for specific accessibility notes.
  """

  @doc """
  Use Sutra UI in your Phoenix application.

  This macro imports all available Sutra UI components for use in your templates.

  ## Example

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use SutraUI
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      # Phase 1: Foundation
      import SutraUI.Icon
      import SutraUI.Button
      import SutraUI.Badge
      import SutraUI.Spinner
      import SutraUI.Kbd

      # Phase 2: Form Primitives
      import SutraUI.Label
      import SutraUI.Input
      import SutraUI.Textarea
      import SutraUI.Checkbox
      import SutraUI.Switch
      import SutraUI.RadioGroup
      import SutraUI.Field
      import SutraUI.Select
      import SutraUI.Slider

      # Phase 3: Layout & Data Display
      import SutraUI.Card
      import SutraUI.Header
      import SutraUI.Table
      import SutraUI.Skeleton
      import SutraUI.Empty
      import SutraUI.Alert
      import SutraUI.Progress

      # Phase 4: Navigation & Interactive
      import SutraUI.Breadcrumb
      import SutraUI.Pagination
      import SutraUI.Accordion
      import SutraUI.Tabs
      import SutraUI.DropdownMenu
      import SutraUI.Toast

      # Phase 5: Advanced UI
      import SutraUI.Avatar
      import SutraUI.Tooltip
      import SutraUI.Dialog
      import SutraUI.Popover
      import SutraUI.Command
      import SutraUI.Carousel

      # Phase 6: Form & Layout Helpers
      import SutraUI.FilterBar
      import SutraUI.InputGroup
      import SutraUI.Item
      import SutraUI.LoadingState
      import SutraUI.SimpleForm

      # Phase 7: Navigation
      import SutraUI.NavPills
      import SutraUI.Sidebar
      import SutraUI.TabNav
      import SutraUI.ThemeSwitcher

      # Phase 8: Advanced Form Controls
      import SutraUI.RangeSlider
      import SutraUI.LiveSelect
    end
  end
end
