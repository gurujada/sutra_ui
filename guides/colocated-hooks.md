# JavaScript Hooks

Sutra UI uses **colocated hooks**, a Phoenix 1.8+ feature that allows JavaScript hooks to be defined alongside their components. Most hooks use the runtime form. Extracted-hook components such as `dialog` and animated `response` still need the generated `phoenix-colocated/sutra_ui` hooks merged into your LiveSocket.

## What Are Colocated Hooks?

Colocated hooks are JavaScript hooks defined directly within component files using a special `<script>` tag. Sutra UI uses the runtime form by default:

```elixir
def my_component(assigns) do
  ~H"""
  <div id={@id} phx-hook=".MyHook">
    Content here
  </div>

  <script :type={Phoenix.LiveView.ColocatedHook} name=".MyHook" runtime>
    {
      mounted() {
        this.el.dataset.ready = "true"
      }
    }
  </script>
  """
end
```

> #### Phoenix 1.8+ Required {: .warning}
>
> Runtime colocated hooks require Phoenix 1.8 or later. They are rendered by the component and do not need to be imported in `assets/js/app.js`.

## How Sutra UI Uses Colocated Hooks

Several Sutra UI components use colocated hooks for interactivity:

| Component | Hook | Mode | Purpose |
|-----------|------|------|---------|
| `dialog` | `.Dialog` | Extracted | Show/hide modal (div-based for screen share compatibility) |
| `response` | `SutraUI.Response.Response` | Extracted | Smooth text reveal |
| `carousel` | `.Carousel` | Runtime | Scroll snap, navigation |
| `command` | `.Command` | Runtime | Command palette behavior |
| `command_dialog` | `.CommandDialog` | Runtime | Native dialog show/hide helpers |
| `context_menu` | `.ContextMenu` | Runtime | Right-click menu behavior |
| `drawer` | `.Drawer` | Runtime | Drawer open/close state |
| `dropdown_menu` | `.DropdownMenu` | Runtime | Menu positioning, keyboard nav |
| `file_upload` | `SutraUI.FileUpload.FileUpload` | Runtime | Drag/drop state when an upload is provided |
| `hover_card` | `.HoverCard` | Runtime | Delayed hover/focus preview |
| `input_otp` | `.InputOTP` | Runtime | Paste distribution and keyboard movement |
| `live_select` | `.LiveSelect` | Runtime | Async search, tags |
| `nav_pills` | `.NavPills` | Runtime | Mobile dropdown behavior |
| `popover` | `.Popover` | Runtime | Popover dismissal and positioning |
| `range_slider` | `.RangeSlider` | Runtime | Dual-handle slider |
| `select` | `.Select` | Runtime | Dropdown behavior, search |
| `slider` | `.Slider` | Runtime | Range input behavior |
| `tab_nav` | `.TabNav` | Runtime | Routed navigation keyboard focus |
| `tabs` | `.Tabs` | Runtime | Keyboard navigation |
| `toast` | `.ToastContainer` | Runtime | Toast push events and dismissal |
| `theme_switcher` | `.ThemeSwitcher` | Runtime | Theme toggle event dispatch |
| `tooltip` | `.Tooltip` | Runtime | Tooltip visibility and positioning |
| `tree_view` | `SutraUI.TreeView.TreeView` | Runtime | Keyboard navigation when `id` is set |

Extracted hooks without `runtime` are exceptions. If you use one, merge the
generated `phoenix-colocated/sutra_ui` hooks into your LiveSocket.

## The Hook Name Convention

Most Sutra UI colocated hook scripts use short dot names (e.g., `.Tabs`).
When `phx-hook` lives in the same component that renders the script, reference
that short name:

```heex
<!-- The phx-hook value matches the script name -->
<div id="my-dialog" phx-hook=".Dialog" class="dialog">
```

Phoenix also generates a fully qualified hook name such as
`SutraUI.TreeView.TreeView`. Sutra uses that form when the rendered
`phx-hook` must point at a hook from another generated scope or from a
conditional assignment.

## Custom Events

Public Sutra UI browser events use the `sutra-ui:` namespace.

```javascript
document.dispatchEvent(new CustomEvent('sutra-ui:drawer', {
  detail: { id: 'main-drawer', action: 'open' }
}))
```

### Listening to Events

Listen for Sutra UI events in your LiveView:

```javascript
document.addEventListener('sutra-ui:drawer', (e) => {
  // Update local UI or analytics from e.detail.
})
```

LiveSelect search is a LiveView event (not a `sutra-ui:*` browser event):

```elixir
def handle_event("live_select_change", %{"text" => text, "id" => id}, socket) do
  options = MyApp.search_options(text)
  send_update(SutraUI.LiveSelect, id: id, options: options)
  {:noreply, socket}
end
```

### Event Reference

| Event | Component | Detail |
|-------|-----------|--------|
| `sutra-ui:drawer` | Drawer | `{ id }` toggles; `{ id, action }` opens/closes when `action` is `"open"` or `"close"` |
| `sutra-ui:set-theme` | ThemeSwitcher | `{ theme }` |
| `sutra-ui:range-slide` | RangeSlider | `{ min, max }` |
| `sutra-ui:range-change` | RangeSlider | `{ min, max }` |

## Using JS Commands with Hooks

Sutra UI provides helper functions that work with colocated hooks:

```heex
<%# Show a dialog %>
<.button phx-click={SutraUI.Dialog.show_dialog("my-dialog")}>Open</.button>

<%# Hide a dialog %>
<.button phx-click={SutraUI.Dialog.hide_dialog("my-dialog")}>Close</.button>
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
    <div id={"#{@id}-tracker"} phx-hook=".TrackedDialog" data-dialog-id={@id}>
      <.dialog id={@id} show={@show} on_cancel={@on_cancel}>
        <:title :if={@title != []}>{render_slot(@title)}</:title>
        <:description :if={@description != []}>{render_slot(@description)}</:description>
        {render_slot(@inner_block)}
        <:footer :if={@footer != []}>{render_slot(@footer)}</:footer>
      </.dialog>
    </div>

    <script :type={ColocatedHook} name=".TrackedDialog" runtime>
      {
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

Runtime hooks are compiled with the component. Ensure `mix compile` runs before asset bundling:

```elixir
# mix.exs - custom release alias
defp aliases do
  [
    "assets.deploy": [
      "compile",  # Compile first
      "esbuild default --minify",
      "phx.digest"
    ]
  ]
end
```

### Development Mode

In development, runtime hooks are compiled and reloaded when you change component files.

### Production Builds

Runtime hooks are rendered by their components. Extracted hooks are bundled by
Phoenix and must be merged into your LiveSocket as shown in the installation
guide.

## Troubleshooting

### Hook not mounting

**Symptoms:** Component renders but interactions don't work.

**Causes:**
1. Missing `phx-hook` attribute
2. Wrong hook name (`.HookName` for local colocated hooks, or the generated fully qualified name for extracted/cross-scope hooks)
3. Phoenix version < 1.8

**Fix:**
```heex
<!-- Ensure hook is specified -->
<div id="my-id" phx-hook=".HookName">
```

### "Hook not found" errors

**Symptoms:** Console error about missing hook.

**Cause:** Component not compiled, runtime hook script not rendered, or hook name mismatch.

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

## Extracted Hooks

For special cases, Phoenix also supports extracted colocated hooks without the
`runtime` attribute:

```heex
<script :type={ColocatedHook} name=".ExtractedHook">
  export default {
    mounted() {
      // Bundled into app JavaScript by Phoenix
    }
  }
</script>
```

Use extracted hooks only when bundler processing is required. Sutra UI's default
is runtime hooks.

## Next Steps

- [Components Cheatsheet](components.cheatmd) - All components with examples
- [Accessibility Guide](accessibility.md) - Keyboard navigation patterns
- [Installation Guide](installation.md) - Setup instructions
