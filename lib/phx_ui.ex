defmodule PhxUI do
  @moduledoc """
  A pure Phoenix LiveView UI component library.

  No dependencies, no nonsense. Just LiveView components with colocated hooks
  where needed.

  ## Installation

  Add `phx_ui` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:phx_ui, "~> 0.1.0"}
        ]
      end

  ## Usage

  Import all components in your web module:

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use PhxUI
            # ... other imports
          end
        end
      end

  Or import specific components:

      defmodule MyAppWeb.SomeLive do
        use Phoenix.LiveView

        import PhxUI.Button
        import PhxUI.Icon

        # ...
      end

  ## Available Components

  ### Foundation (Phase 1)
  - `PhxUI.Icon` - Icons (requires icon CSS setup)
  - `PhxUI.Button` - Buttons with variants and states
  - `PhxUI.Badge` - Status badges
  - `PhxUI.Spinner` - Loading spinners
  - `PhxUI.Kbd` - Keyboard shortcuts

  ### Form Primitives (Phase 2)
  - `PhxUI.Label` - Form labels
  - `PhxUI.Input` - Text inputs, email, password, etc.
  - `PhxUI.Textarea` - Multi-line text input
  - `PhxUI.Checkbox` - Checkbox input
  - `PhxUI.Switch` - Toggle switch
  - `PhxUI.RadioGroup` - Radio button groups
  - `PhxUI.Field` - Field container with label/description/error
  - `PhxUI.Select` - Custom select dropdown (with JS hook)
  - `PhxUI.Slider` - Range slider (with JS hook)

  ### Layout & Data Display (Phase 3)
  - `PhxUI.Card` - Card container with header, content, footer
  - `PhxUI.Header` - Page header with title, subtitle, actions
  - `PhxUI.Table` - Data table with column definitions
  - `PhxUI.Skeleton` - Loading placeholder
  - `PhxUI.Empty` - Empty state with icon, title, description
  - `PhxUI.Alert` - Alert/callout messages
  - `PhxUI.Progress` - Progress bar indicator

  ### Navigation & Interactive (Phase 4)
  - `PhxUI.Breadcrumb` - Breadcrumb navigation
  - `PhxUI.Pagination` - Page navigation
  - `PhxUI.Accordion` - Collapsible content sections
  - `PhxUI.Tabs` - Tab panels (with JS hook)
  - `PhxUI.DropdownMenu` - Dropdown menu (with JS hook)
  - `PhxUI.Toast` - Toast notifications (with JS hook)

  ### Advanced UI (Phase 5)
  - `PhxUI.Avatar` - User avatars with fallback support
  - `PhxUI.Tooltip` - CSS-only hover tooltips
  - `PhxUI.Dialog` - Modal dialogs
  - `PhxUI.Popover` - Click-triggered popups
  - `PhxUI.Command` - Command palette with search
  - `PhxUI.Carousel` - CSS scroll-snap carousel

  ### Form & Layout Helpers (Phase 6)
  - `PhxUI.FilterBar` - Filter bar for index pages
  - `PhxUI.InputGroup` - Input with prefix/suffix attachments
  - `PhxUI.Item` - Versatile list item component
  - `PhxUI.LoadingState` - Loading indicator with message
  - `PhxUI.SimpleForm` - Simple form wrapper with auto-styling

  ### Navigation (Phase 7)
  - `PhxUI.NavPills` - Responsive navigation pills
  - `PhxUI.Sidebar` - Collapsible sidebar navigation
  - `PhxUI.TabNav` - Server-side routed tab navigation
  - `PhxUI.ThemeSwitcher` - Light/dark theme toggle

  ## Tailwind CSS

  This library uses Tailwind CSS classes. Make sure your project has
  Tailwind configured and includes the PhxUI source in your content paths:

      // tailwind.config.js
      module.exports = {
        content: [
          // ...
          "../deps/phx_ui/**/*.*ex"
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
  Use PhxUI in your Phoenix application.

  This macro imports all available PhxUI components for use in your templates.

  ## Example

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use PhxUI
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      # Phase 1: Foundation
      import PhxUI.Icon
      import PhxUI.Button
      import PhxUI.Badge
      import PhxUI.Spinner
      import PhxUI.Kbd

      # Phase 2: Form Primitives
      import PhxUI.Label
      import PhxUI.Input
      import PhxUI.Textarea
      import PhxUI.Checkbox
      import PhxUI.Switch
      import PhxUI.RadioGroup
      import PhxUI.Field
      import PhxUI.Select
      import PhxUI.Slider

      # Phase 3: Layout & Data Display
      import PhxUI.Card
      import PhxUI.Header
      import PhxUI.Table
      import PhxUI.Skeleton
      import PhxUI.Empty
      import PhxUI.Alert
      import PhxUI.Progress

      # Phase 4: Navigation & Interactive
      import PhxUI.Breadcrumb
      import PhxUI.Pagination
      import PhxUI.Accordion
      import PhxUI.Tabs
      import PhxUI.DropdownMenu
      import PhxUI.Toast

      # Phase 5: Advanced UI
      import PhxUI.Avatar
      import PhxUI.Tooltip
      import PhxUI.Dialog
      import PhxUI.Popover
      import PhxUI.Command
      import PhxUI.Carousel

      # Phase 6: Form & Layout Helpers
      import PhxUI.FilterBar
      import PhxUI.InputGroup
      import PhxUI.Item
      import PhxUI.LoadingState
      import PhxUI.SimpleForm

      # Phase 7: Navigation
      import PhxUI.NavPills
      import PhxUI.Sidebar
      import PhxUI.TabNav
      import PhxUI.ThemeSwitcher
    end
  end
end
