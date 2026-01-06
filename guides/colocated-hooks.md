# JavaScript Hooks

Sutra UI uses **colocated hooks**, a Phoenix 1.8+ feature that allows JavaScript hooks to be defined alongside their components. No separate `hooks.js` file needed.

## What Are Colocated Hooks?

Colocated hooks are JavaScript hooks defined directly within component files using a special `<script>` tag:

```elixir
def my_component(assigns) do
  ~H"""
  <div id={@id} phx-hook=".MyHook">
    Content here
  </div>

  <script :type={Phoenix.LiveView.ColocatedHook} name=".MyHook">
    export default {
      mounted() {
        console.log("Hook mounted!", this.el)
      }
    }
  </script>
  """
end
```

> #### Phoenix 1.8+ Required {: .warning}
>
> Colocated hooks require Phoenix 1.8 or later. The hooks are extracted at compile time and bundled automatically.

## How Sutra UI Uses Colocated Hooks

Several Sutra UI components use colocated hooks for interactivity:

| Component | Hook | Purpose |
|-----------|------|---------|
| `dialog` | `.Dialog` | Show/hide modal (div-based for screen share compatibility) |
| `tabs` | `.Tabs` | Keyboard navigation |
| `select` | `.Select` | Dropdown behavior, search |
| `dropdown_menu` | `.DropdownMenu` | Menu positioning, keyboard nav |
| `command` | `.Command` | Command palette behavior |
| `toast` | `.Toast` | Auto-dismiss, animations |
| `accordion` | `.Accordion` | Collapse animations |
| `slider` | `.Slider` | Range input behavior |
| `range_slider` | `.RangeSlider` | Dual-handle slider |
| `live_select` | `.LiveSelect` | Async search, tags |
| `carousel` | `.Carousel` | Scroll snap, navigation |
| `theme_switcher` | `.ThemeSwitcher` | Theme persistence |

## The Hook Name Convention

Hook names in Sutra UI **start with a dot** (e.g., `.Dialog`, `.Tabs`). This is required by Phoenix's colocated hook system.

```heex
<!-- The phx-hook value matches the script name -->
<div id="my-dialog" phx-hook=".Dialog" class="dialog">
```

The full hook name becomes `ModuleName.HookName` (e.g., `SutraUI.Dialog.Dialog`), but you only reference the short name with the dot prefix.

## Custom Events

Sutra UI hooks dispatch custom events using the `sutra-ui:` namespace:

```javascript
// Dispatching an event
this.el.dispatchEvent(new CustomEvent('sutra-ui:select-change', {
  detail: { value: selectedValue }
}))
```

### Listening to Events

Listen for Sutra UI events in your LiveView:

```elixir
def handle_event("sutra-ui:select-change", %{"value" => value}, socket) do
  {:noreply, assign(socket, selected: value)}
end
```

Or in JavaScript:

```javascript
document.addEventListener('sutra-ui:select-change', (e) => {
  console.log('Selected:', e.detail.value)
})
```

### Event Reference

| Event | Component | Detail |
|-------|-----------|--------|
| `sutra-ui:select-change` | Select | `{ value }` |
| `sutra-ui:dialog-open` | Dialog | `{ id }` |
| `sutra-ui:dialog-close` | Dialog | `{ id }` |
| `sutra-ui:tab-change` | Tabs | `{ value }` |
| `sutra-ui:toast-dismiss` | Toast | `{ id }` |
| `sutra-ui:slider-change` | Slider | `{ value }` |
| `sutra-ui:range-change` | RangeSlider | `{ min, max }` |

## Using JS Commands with Hooks

Sutra UI provides helper functions that work with colocated hooks:

```elixir
import SutraUI.Dialog

# Show a dialog
<.button phx-click={show_dialog("my-dialog")}>Open</.button>

# Hide a dialog
<.button phx-click={hide_dialog("my-dialog")}>Close</.button>
```

These helpers dispatch events that the hooks listen for:

```elixir
def show_dialog(js \\ %JS{}, id) do
  JS.dispatch(js, "phx:show-dialog", to: "##{id}")
end
```

## Extending Hooks

You can extend Sutra UI hooks in your application by creating your own colocated hooks that build on the component behavior.

### Example: Custom Dialog with Analytics

```elixir
defmodule MyAppWeb.Components.TrackedDialog do
  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Dialog, only: [dialog: 1]

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil
  slot :inner_block, required: true
  slot :title
  slot :description
  slot :footer

  def tracked_dialog(assigns) do
    ~H"""
    <div phx-hook=".TrackedDialog" data-dialog-id={@id}>
      <.dialog id={@id} show={@show} on_cancel={@on_cancel}>
        <:title :if={@title != []}>{render_slot(@title)}</:title>
        <:description :if={@description != []}>{render_slot(@description)}</:description>
        {render_slot(@inner_block)}
        <:footer :if={@footer != []}>{render_slot(@footer)}</:footer>
      </.dialog>
    </div>

    <script :type={ColocatedHook} name=".TrackedDialog">
      export default {
        mounted() {
          const dialogId = this.el.dataset.dialogId
          const dialog = document.getElementById(dialogId)

          dialog.addEventListener('phx:show-dialog', () => {
            // Track dialog open
            analytics.track('dialog_opened', { id: dialogId })
          })
        }
      }
    </script>
    """
  end
end
```

## Build Considerations

### Compilation Order

Colocated hooks are extracted when the component is compiled. Ensure `mix compile` runs before asset bundling:

```elixir
# mix.exs - custom release alias
defp aliases do
  [
    "assets.deploy": [
      "compile",  # Compile first to extract hooks
      "esbuild default --minify",
      "phx.digest"
    ]
  ]
end
```

### Development Mode

In development, hooks are automatically extracted and hot-reloaded when you change component files.

### Production Builds

The hooks are bundled into your JavaScript assets automatically. No additional configuration needed.

## Troubleshooting

### Hook not mounting

**Symptoms:** Component renders but interactions don't work.

**Causes:**
1. Missing `phx-hook` attribute
2. Wrong hook name (must start with `.`)
3. Phoenix version < 1.8

**Fix:**
```heex
<!-- Ensure hook is specified -->
<div id="my-id" phx-hook=".HookName">
```

### "Hook not found" errors

**Symptoms:** Console error about missing hook.

**Cause:** Component not compiled or hook name mismatch.

**Fix:**
```bash
mix compile --force
```

### Events not firing

**Symptoms:** `phx-click` with JS commands doesn't trigger hook.

**Cause:** Event name mismatch between JS command and hook listener.

**Fix:** Verify the event names match:
```elixir
# JS command dispatches:
JS.dispatch("phx:show-dialog", to: "#dialog")

# Hook listens for:
this.el.addEventListener("phx:show-dialog", ...)
```

## Runtime Hooks (Advanced)

For special cases like LiveDashboard integration, you can use runtime hooks that aren't extracted at compile time:

```heex
<script :type={ColocatedHook} name=".RuntimeHook" runtime>
  {
    mounted() {
      // Note: no "export default" for runtime hooks
    }
  }
</script>
```

Runtime hooks have limitations:
- No bundler processing (ES6+ features may not work in older browsers)
- CSP considerations (may need nonce)

## Next Steps

- [Components Cheatsheet](components.cheatmd) - All components with examples
- [Accessibility Guide](accessibility.md) - Keyboard navigation patterns
- [Installation Guide](installation.md) - Setup instructions
