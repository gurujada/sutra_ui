# PhxUI Usage Rules for LLMs

This document provides guidelines for AI assistants when working with the PhxUI component library.

## Overview

PhxUI is a pure Phoenix LiveView UI component library with no external dependencies. Components use colocated JavaScript hooks where interactivity is needed.

## Core Principles

### 1. CSS-First Styling

All component styling is defined in `priv/static/phx_ui.css`. When modifying components:

- **DO**: Use CSS classes from `phx_ui.css`
- **DO**: Add new CSS classes to `phx_ui.css` when needed
- **DON'T**: Add inline Tailwind classes directly in component templates
- **DON'T**: Use helper functions to generate Tailwind class strings

**Pattern for class attributes:**
```elixir
# Good - uses CSS class with optional user override
class={["component-class", @class]}

# Avoid - inline Tailwind
class={["flex items-center gap-2", @class]}
```

### 2. Required ID Attributes

Components that require JavaScript hooks or generate DOM references **must** have a required `id` attribute:

```elixir
# Good - explicit required ID
attr(:id, :string, required: true, doc: "Unique identifier for the component")

# Avoid - auto-generated IDs
attr(:id, :string, default: fn -> "component-#{System.unique_integer()}" end)
```

**Rationale:**
- Predictable IDs aid debugging
- Prevents LiveView diffing issues on reconnect
- User maintains control over their DOM

### 3. Event Naming Convention

Custom JavaScript events use the `phx-ui:` namespace:

```javascript
// Good
this.el.dispatchEvent(new CustomEvent('phx-ui:component-action', { detail: {...} }))

// Avoid
this.el.dispatchEvent(new CustomEvent('component-action', { detail: {...} }))
```

### 4. Attribute Types

Use appropriate attribute types:

| Attribute | Type | Notes |
|-----------|------|-------|
| `class` | `:string` | Always `:string`, merged internally with list pattern |
| `id` | `:string` | Required for hook-based components |
| `disabled` | `:boolean` | Boolean attributes |
| `value` | `:string` or `:any` | Depends on component needs |
| `errors` | `:list` | List of error messages |

### 5. Slot Conventions

Slots should follow consistent patterns:

```elixir
# Simple content slot
slot(:inner_block, doc: "Main content")

# Named slot with attributes
slot :item, doc: "List items" do
  attr(:value, :string, required: true)
  attr(:disabled, :boolean)
end
```

## Component Patterns

### Basic Component Structure

```elixir
defmodule PhxUI.ComponentName do
  @moduledoc """
  Brief description of the component.

  ## Examples

      <.component_name id="my-component" required_attr="value">
        Content here
      </.component_name>

  ## Accessibility

  - List ARIA attributes used
  - Keyboard navigation support
  - Screen reader considerations
  """

  use Phoenix.Component

  @doc """
  Renders the component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Main content")

  def component_name(assigns) do
    ~H"""
    <div id={@id} class={["component-class", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
```

### Hook-Based Component Structure

```elixir
defmodule PhxUI.InteractiveComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Required for JavaScript hook")
  # ... other attrs

  def interactive_component(assigns) do
    ~H"""
    <div id={@id} class="component-class" phx-hook=".ComponentHook" data-option={@option}>
      {render_slot(@inner_block)}
    </div>

    <script :type={ColocatedHook} name=".ComponentHook">
      export default {
        mounted() {
          // Initialize component
        },
        updated() {
          // Handle LiveView updates
        },
        destroyed() {
          // Cleanup
        }
      }
    </script>
    """
  end
end
```

## Available Components

### Foundation
- `icon/1` - Icon rendering (requires icon CSS setup)
- `button/1` - Buttons with variants: primary, secondary, outline, ghost, link, destructive
- `badge/1` - Status badges
- `spinner/1` - Loading indicators
- `kbd/1` - Keyboard shortcut display

### Form Controls
- `label/1` - Form labels
- `input/1` - Text inputs (text, email, password, number, etc.)
- `textarea/1` - Multi-line text input
- `checkbox/1` - Checkbox input
- `switch/1` - Toggle switch
- `radio_group/1`, `radio/1` - Radio button groups
- `field/1`, `fieldset/1` - Field containers with label/description/error
- `select/1` - Custom select dropdown (JS hook)
- `slider/1` - Range slider (JS hook)
- `range_slider/1` - Dual-handle range slider (JS hook)
- `live_select/1` - Async searchable select (JS hook)

### Layout & Data Display
- `card/1` - Card container with header/content/footer slots
- `header/1` - Page header with title/subtitle/actions
- `table/1` - Data table with column definitions
- `skeleton/1` - Loading placeholder
- `empty/1` - Empty state display
- `alert/1` - Alert/callout messages
- `progress/1` - Progress bar

### Navigation & Interactive
- `breadcrumb/1` - Breadcrumb navigation
- `pagination/1` - Page navigation
- `accordion/1` - Collapsible content sections
- `tabs/1` - Tab panels (JS hook)
- `dropdown_menu/1` - Dropdown menu (JS hook)
- `toast/1`, `toaster/1` - Toast notifications (JS hook)

### Advanced UI
- `avatar/1` - User avatars with fallback
- `tooltip/1` - CSS-only hover tooltips
- `dialog/1` - Modal dialogs
- `popover/1` - Click-triggered popups
- `command/1` - Command palette with search (JS hook)
- `carousel/1` - CSS scroll-snap carousel

### Layout Helpers
- `filter_bar/1` - Filter bar for index pages
- `input_group/1` - Input with prefix/suffix
- `item/1` - Versatile list item
- `loading_state/1` - Loading indicator with message
- `simple_form/1` - Form wrapper with auto-styling

### Navigation
- `nav_pills/1` - Responsive navigation pills
- `sidebar/1` - Collapsible sidebar navigation
- `tab_nav/1` - Server-side routed tab navigation
- `theme_switcher/1` - Light/dark theme toggle

## CSS Class Naming

CSS classes in `phx_ui.css` follow these conventions:

```css
/* Component base */
.component-name { }

/* Variants */
.component-name-variant { }

/* States */
.component-name-disabled { }
.component-name-active { }

/* Sub-elements */
.component-name-header { }
.component-name-content { }
.component-name-footer { }
```

## Testing Components

Tests are in `test/phx_ui/` and use `ComponentCase`:

```elixir
defmodule PhxUI.ComponentNameTest do
  use ComponentCase, async: true

  import PhxUI.ComponentName

  describe "component_name/1" do
    test "renders with required attributes" do
      html = render_component(&component_name/1, id: "test", required: "value")
      assert html =~ ~s(id="test")
    end

    test "applies custom class" do
      html = render_component(&component_name/1, id: "test", class: "custom")
      assert html =~ "custom"
    end
  end
end
```

## Common Mistakes to Avoid

1. **Missing required `id`** on hook-based components
2. **Inline Tailwind** instead of CSS classes
3. **Auto-generating IDs** instead of requiring them
4. **Missing accessibility attributes** (ARIA, roles, keyboard support)
5. **Not updating moduledoc examples** when changing required attrs
6. **Forgetting to add new components** to `lib/phx_ui.ex` imports

## File Structure

```
lib/
  phx_ui/
    component_name.ex    # Component module
  phx_ui.ex              # Main module with imports
priv/
  static/
    phx_ui.css           # All component styles
test/
  phx_ui/
    component_name_test.exs
  support/
    component_case.ex    # Test helpers
```

## Adding a New Component

1. Create `lib/phx_ui/component_name.ex` with moduledoc and examples
2. Add CSS classes to `priv/static/phx_ui.css`
3. Add import to `lib/phx_ui.ex` in `__using__` macro
4. Update component list in `lib/phx_ui.ex` moduledoc
5. Create tests in `test/phx_ui/component_name_test.exs`
6. Update this file if the component introduces new patterns
