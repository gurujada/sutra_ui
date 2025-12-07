# PhxUI - Agent Guide

This document is for AI agents working on the PhxUI codebase. It explains the architecture, design philosophy, patterns, and conventions used throughout the library.

## Overview

PhxUI is a **pure Phoenix LiveView UI component library** inspired by shadcn/ui. The key philosophy is:

- **No external JavaScript dependencies** - Everything is LiveView + colocated hooks
- **Semantic CSS classes** - Components use meaningful class names (`.btn`, `.card`, `.live-select`) NOT inline Tailwind
- **All styling in one CSS file** - `priv/static/phx_ui.css` contains all component styles
- **Colocated hooks pattern** - JavaScript lives with its component using `<script :type={ColocatedHook}>`

## Project Structure

```
phx_ui/
├── lib/
│   ├── phx_ui.ex              # Main module with `use PhxUI` macro
│   └── phx_ui/
│       ├── button.ex          # Each component in its own file
│       ├── select.ex
│       ├── live_select.ex     # LiveComponent example
│       └── ...
├── priv/
│   └── static/
│       └── phx_ui.css         # ALL component styles go here
├── test/
│   ├── phx_ui/
│   │   └── *_test.exs         # One test file per component
│   └── support/
│       └── component_case.ex  # Test helpers
└── agents.md                  # This file
```

## Design Philosophy

### 1. Semantic CSS Classes (CRITICAL)

**DO NOT use inline Tailwind classes in components.** Instead:

```elixir
# WRONG - Don't do this
def button(assigns) do
  ~H"""
  <button class="inline-flex items-center justify-center rounded-md text-sm font-medium...">
    {@inner_block}
  </button>
  """
end

# RIGHT - Use semantic classes
def button(assigns) do
  ~H"""
  <button class={["btn", "btn-#{@variant}", "btn-#{@size}"]}>
    {@inner_block}
  </button>
  """
end
```

Then define styles in `priv/static/phx_ui.css`:

```css
@layer components {
    .btn {
        @apply inline-flex items-center justify-center rounded-md text-sm font-medium;
        @apply transition-colors focus-visible:outline-none focus-visible:ring-2;
    }
    
    .btn-primary {
        @apply bg-primary text-primary-foreground hover:bg-primary/90;
    }
    
    .btn-sm {
        @apply h-8 px-3 text-xs;
    }
}
```

### 2. CSS Variables for Theming

All colors use CSS custom properties defined in `:root` and `.dark`:

```css
:root {
    --background: oklch(1 0 0);
    --foreground: oklch(0.141 0.005 285.823);
    --primary: oklch(0.623 0.214 259.815);
    --primary-foreground: oklch(0.985 0 0);
    /* ... */
}

.dark {
    --background: oklch(0.141 0.005 285.823);
    --foreground: oklch(0.985 0 0);
    /* ... */
}
```

Use these via Tailwind's semantic colors: `bg-background`, `text-foreground`, `bg-primary`, etc.

### 3. Component Types

#### Function Components (Most Common)
Simple stateless components that render HTML:

```elixir
defmodule PhxUI.Badge do
  use Phoenix.Component

  attr :variant, :string, default: "default"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["badge", "badge-#{@variant}"]}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
```

#### Function Components with Colocated Hooks
For components needing JavaScript interactivity:

```elixir
defmodule PhxUI.Select do
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  def select(assigns) do
    ~H"""
    <div id={@id} class="select" phx-hook=".Select">
      <!-- component markup -->
      
      <script :type={ColocatedHook} name=".Select">
        export default {
          mounted() {
            // JavaScript logic
          },
          destroyed() {
            // Cleanup
          }
        }
      </script>
    </div>
    """
  end
end
```

**IMPORTANT**: The hook name MUST start with a dot (`.Select`) and match the `phx-hook` attribute exactly.

#### LiveComponents
For stateful components that need their own process:

```elixir
defmodule PhxUI.LiveSelect do
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.ColocatedHook

  def mount(socket) do
    {:ok, assign(socket, :options, [])}
  end

  def update(assigns, socket) do
    # Handle both initial mount AND send_update calls
    socket =
      if Map.has_key?(assigns, :field) do
        # Initial mount - set up all defaults
        socket
        |> assign(:field, assigns.field)
        |> assign_new(:mode, fn -> assigns[:mode] || :single end)
        # ...
      else
        socket
      end

    # Handle options update (from send_update)
    socket =
      if Map.has_key?(assigns, :options) do
        assign(socket, :options, assigns.options)
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("select", params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="live-select" phx-hook=".PhxUI.LiveSelect.LiveSelect">
      <!-- markup -->
      
      <script :type={ColocatedHook} name=".PhxUI.LiveSelect.LiveSelect">
        export default {
          mounted() { /* ... */ }
        }
      </script>
    </div>
    """
  end
end
```

**CRITICAL for LiveComponents**: 
- The `<script>` tag MUST be INSIDE the root element (LiveComponents require single root)
- The `update/2` callback receives ALL assigns on initial mount, but only CHANGED assigns on `send_update`
- Always check `Map.has_key?(assigns, :key)` before accessing assigns that might not be present

### 4. Colocated Hooks Pattern

The colocated hooks pattern keeps JavaScript with its component:

```elixir
<script :type={ColocatedHook} name=".ComponentName">
  export default {
    mounted() {
      // Called when element is added to DOM
      // this.el - the DOM element with phx-hook
      // this.pushEvent("event", payload) - send to parent LiveView
      // this.pushEventTo(selector, "event", payload) - send to specific target
      // this.handleEvent("event", callback) - listen for server pushes
    },
    
    updated() {
      // Called after LiveView patches the DOM
    },
    
    destroyed() {
      // Called when element is removed - cleanup here!
    }
  }
</script>
```

**Hook naming convention**:
- Function components: `.ComponentName` (e.g., `.Select`, `.Slider`, `.Carousel`)
- LiveComponents: `.PhxUI.ModuleName.ComponentName` (e.g., `.PhxUI.LiveSelect.LiveSelect`)

### 5. Event Handling in LiveComponents

LiveComponents communicate with parent LiveViews:

```elixir
# In the LiveComponent - push event to parent
def handle_event("select_option", %{"value" => value}, socket) do
  # Notify parent
  send(self(), {:live_select_change, socket.assigns.id, value})
  {:noreply, socket}
end

# OR use push_event for JS hook communication
socket = push_event(socket, "live_select:updated", %{id: socket.assigns.id})
```

```elixir
# In parent LiveView - handle the event
def handle_info({:live_select_change, id, value}, socket) do
  {:noreply, assign(socket, :selected, value)}
end

# OR handle events sent via pushEvent from JS hook
def handle_event("live_select_change", %{"id" => id, "text" => text}, socket) do
  # Search and send results back
  options = search(text)
  send_update(PhxUI.LiveSelect, id: id, options: options)
  {:noreply, socket}
end
```

### 6. CSS Organization in phx_ui.css

The CSS file is organized by component using `@layer`:

```css
/* Theme variables */
:root { /* light theme */ }
.dark { /* dark theme */ }

/* Base styles */
@layer base {
    * { @apply border-border; }
    body { @apply bg-background text-foreground; }
}

/* Component styles - one section per component */
@layer components {
    /* Button */
    .btn { /* ... */ }
    .btn-primary { /* ... */ }
    
    /* Card */
    .card { /* ... */ }
    .card-header { /* ... */ }
    
    /* Select */
    .select { /* ... */ }
    .select-trigger { /* ... */ }
    .select-content { /* ... */ }
    
    /* LiveSelect */
    .live-select { /* ... */ }
    .live-select-input { /* ... */ }
    .live-select-dropdown { /* ... */ }
}
```

### 7. Accessibility Requirements

All components MUST be accessible:

```elixir
# Proper ARIA attributes
<div role="listbox" aria-expanded={@open} aria-activedescendant={@active_id}>
  <div role="option" aria-selected={@selected} id={@option_id}>
    {option.label}
  </div>
</div>

# Keyboard navigation
<input
  phx-keydown="navigate"
  phx-key="ArrowDown"
  aria-controls="dropdown-id"
/>

# Focus management
<button
  class="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
>
```

### 8. Testing Pattern

Each component has a corresponding test file:

```elixir
defmodule PhxUI.ButtonTest do
  use ComponentCase, async: true

  import PhxUI.Button

  describe "button/1" do
    test "renders with default variant" do
      html = render_component(&button/1, %{})
      assert html =~ "btn"
      assert html =~ "btn-primary"
    end

    test "renders with custom variant" do
      html = render_component(&button/1, %{variant: "destructive"})
      assert html =~ "btn-destructive"
    end
  end
end
```

## Common Patterns

### Variant/Size Pattern
Most components follow this pattern:

```elixir
attr :variant, :string, default: "default", values: ~w(default secondary destructive)
attr :size, :string, default: "default", values: ~w(sm default lg)

def component(assigns) do
  ~H"""
  <div class={[
    "component",
    "component-#{@variant}",
    "component-#{@size}",
    @class
  ]}>
    {render_slot(@inner_block)}
  </div>
  """
end
```

### Slot Pattern
For composable components:

```elixir
slot :header
slot :inner_block, required: true
slot :footer

def card(assigns) do
  ~H"""
  <div class="card">
    <div :if={@header != []} class="card-header">
      {render_slot(@header)}
    </div>
    <div class="card-content">
      {render_slot(@inner_block)}
    </div>
    <div :if={@footer != []} class="card-footer">
      {render_slot(@footer)}
    </div>
  </div>
  """
end
```

### Form Field Integration
Components that work with Phoenix forms:

```elixir
attr :field, Phoenix.HTML.FormField, doc: "Phoenix form field"
attr :name, :string, default: nil
attr :value, :any, default: nil

def input(assigns) do
  # Extract name/value from field or use direct attrs
  assigns = assign_new(assigns, :input_name, fn ->
    if assigns.field, do: assigns.field.name, else: assigns.name
  end)
  
  ~H"""
  <input name={@input_name} value={@value} class="input" />
  """
end
```

## Adding a New Component

1. **Create the component file**: `lib/phx_ui/my_component.ex`

2. **Add CSS styles** to `priv/static/phx_ui.css`:
   ```css
   @layer components {
       .my-component { /* styles */ }
   }
   ```

3. **Add to main module** `lib/phx_ui.ex`:
   ```elixir
   defmacro __using__(_opts) do
     quote do
       # ... existing imports
       import PhxUI.MyComponent
     end
   end
   ```

4. **Create tests** in `test/phx_ui/my_component_test.exs`

5. **Add showcase example** in the test app's showcase_live.ex

## Debugging Tips

### Component not rendering?
- Check that it's imported in `phx_ui.ex`
- Verify CSS classes exist in `phx_ui.css`

### Hook not working?
- Verify `phx-hook` attribute matches script `name` EXACTLY (including the dot)
- Check browser console for JavaScript errors
- Ensure the element has an `id` attribute

### LiveComponent crashes on send_update?
- Check `update/2` handles partial assigns (not all keys present)
- Use `Map.has_key?(assigns, :key)` before accessing

### Styles not applying?
- Verify CSS is being imported in consuming app
- Check CSS selector specificity
- Inspect element to see if classes are present

## Test App

The library is tested via `/home/virinchi/code/elixir-phoenix/my_app/`:

- Showcase page: `lib/my_app_web/live/showcase_live.ex`
- Run: `cd my_app && mix phx.server`
- Visit: http://localhost:4000/showcase

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/phx_ui.ex` | Main module, `use PhxUI` macro, component imports |
| `priv/static/phx_ui.css` | ALL component styles, CSS variables, themes |
| `lib/phx_ui/*.ex` | Individual component modules |
| `test/support/component_case.ex` | Test helpers |

## Don'ts

- **DON'T** use inline Tailwind classes in components
- **DON'T** add external JavaScript dependencies
- **DON'T** forget the dot prefix on colocated hook names
- **DON'T** put `<script>` outside root element in LiveComponents
- **DON'T** access assigns directly in `update/2` without checking existence
- **DON'T** forget to add CSS for new components
- **DON'T** skip accessibility attributes (ARIA, roles, keyboard nav)
