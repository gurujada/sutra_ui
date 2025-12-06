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
  - `PhxUI.Select` - Custom select dropdown (requires JS hook)
  - `PhxUI.Slider` - Range slider (requires JS hook)

  ### Coming Soon
  - Layout components (card, header, table)
  - Interactive components (accordion, tabs, dropdown)
  - Overlay components (dialog, popover, tooltip)
  - And more...

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
    end
  end
end
