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
| `command_palette` | `.CommandPalette` | Extracted | Command palette (imports `sutra_ui/commands`) |
| `context_menu` | `.ContextMenu` | Runtime | Right-click menu behavior |
| `drawer` | `.Drawer` | Runtime | Drawer open/close state |
| `dropdown_menu` | `.DropdownMenu` | Runtime | Menu positioning, keyboard nav |
| `file_upload` | `SutraUI.FileUpload.FileUpload` | Runtime | Drag/drop state when an upload is provided |
| `hover_card` | `.HoverCard` | Runtime | Delayed hover/focus preview |
| `input_otp` | `.InputOTP` | Runtime | Paste distribution and keyboard movement |
| `live_select` | `.LiveSelect` | Runtime | Async search, tags |
| `popover` | `.Popover` | Runtime | Popover dismissal and positioning |
| `range_slider` | `.RangeSlider` | Runtime | Dual-handle slider |
| `date_picker`, `date_range_picker`, `time_picker`, `datetime_picker` | `.DatePicker` | Extracted | Segmented field, calendar popover or sheet, zones (imports `sutra_ui/dates`, which bundles `fit` and `time`) |
| `select` | `.Select` | Extracted | Styled list over the real `<select>` (imports `sutra_ui/select`, which bundles `fit`) |
| `slider` | `.Slider` | Runtime | Range input behavior |
| `tab_nav` | `.TabNav` | Runtime | Routed navigation keyboard focus and mobile dropdown |
| `tabs` | `.Tabs` | Runtime | Keyboard navigation |
| `relative_time` | `.RelativeTime` | Extracted | Shared page timer for relative words (imports `sutra_ui/time`) |
| `local_time` | `.LocalTime` | Extracted | Viewer-zone hint (imports `sutra_ui/time`) |
| `toast_group` | `.ToastGroup` | Extracted | Toast timers, exit animation, connection notice (imports `sutra_ui/toast`) |
| `confirm_host` | `.ConfirmHost` | Extracted | Catches `data-confirm` before LiveView and phoenix_html (imports `sutra_ui/confirm`) |
| `theme_switcher` | `.ThemeSwitcher` | Runtime | Theme toggle event dispatch |
| `tooltip` | `.Tooltip` | Runtime | Tooltip visibility and positioning |
| `tree_view` | `SutraUI.TreeView.TreeView` | Runtime | Keyboard navigation when `id` is set |

Extracted hooks without `runtime` are exceptions. If you use one, merge the
generated `phoenix-colocated/sutra_ui` hooks into your LiveSocket.

## Library Modules (`sutra_ui/<widget>`)

Small behaviour (open/close, focus, keys, up to a few hundred lines) stays in the colocated
hook. A widget with real logic gets one source module in the library's `assets/js/<widget>/`,
with its own tests, and a thin hook that imports it. `relative_time` and `local_time`
(`sutra_ui/time`), the command palette (`sutra_ui/commands`), the toast stack (`sutra_ui/toast`) and
`data-confirm` (`sutra_ui/confirm`) use it.

A runtime hook is an inline `<script>` and cannot import, so a hook that uses a module is an
**extracted** hook: your app's esbuild bundles it, and resolves `sutra_ui/time` through `deps`
in `NODE_PATH`, the way it resolves `phoenix` and `phoenix_live_view` (the root `package.json`
exports it). No npm, no extra config:

```elixir
# the component
<script :type={Phoenix.LiveView.ColocatedHook} name=".RelativeTime">
  import {RelativeTime} from "sutra_ui/time"
  export default RelativeTime
</script>
```

```javascript
// app.js, as for dialog
import {hooks as sutraHooks} from "phoenix-colocated/sutra_ui"
const liveSocket = new LiveSocket("/live", Socket, {hooks: {...sutraHooks}, ...})
```

### Adding a module (maintainers)

1. Create `assets/js/<widget>/index.js`: plain ES modules with JSDoc types, no dependencies
   (locale, zone and number formatting come from the browser's `Intl`). Put tests beside the
   source as `*.test.js` and run them with `node --test assets/js/`.
2. Export the hook objects (`mounted`, `updated`, `destroyed`) from `index.js`.
3. Add `"./<widget>": "./priv/static/<widget>.js"` to the `exports` of the root `package.json`.
4. Run `mix assets.build` (the `esbuild` Hex package, dev only; it needs no npm). It bundles
   each `assets/js/*/index.js` to `priv/static/<widget>.js` with a first line holding the
   source hash. Commit the built file: it ships on Hex.
5. In the component, add the thin extracted hook shown above.

`test/sutra_ui/assets_test.exs` fails when a built file is older than its source (the hash in
its first line no longer matches `assets/js/<widget>/`, tests excluded), when `package.json`
does not export the widget, or when its version differs from `mix.exs`.

## Content-Security-Policy

Runtime hooks render an inline `<script>` that registers the hook, so a strict
`script-src` blocks them unless the script carries a nonce. Every Sutra UI component that
renders a runtime hook accepts a `nonce` attribute and puts it on that script:

```heex
<.dropdown_menu id="actions" nonce={@csp_nonce}>...</.dropdown_menu>
<.tooltip id="tip" tooltip="Hi" nonce={@csp_nonce}>...</.tooltip>
```

Generate a nonce per request in a plug, put it in `conn.assigns`, send the same value in the
`Content-Security-Policy` header, and render the theme script with it in the root layout:

```heex
<head>
  <SutraUI.ThemeSwitcher.theme_script nonce={@csp_nonce} />
</head>
```

With that, an app can use:

```
script-src 'self' 'nonce-<nonce>'; style-src 'self'
```

Neither `script-src` nor `style-src` needs `'unsafe-inline'`. What Sutra UI renders that a CSP sees:

| Output | Where | Policy needed |
|--------|-------|---------------|
| Runtime hook `<script>` | every component with a runtime hook (`nonce` attribute) | `script-src` nonce |
| Pre-paint theme script | `theme_script/1` (`nonce` attribute) | `script-src` nonce |
| `onerror=` handler | `avatar` without an `id` | `script-src-attr 'unsafe-inline'`; pass an `id` instead |

No component renders a `style=` attribute (apart from that deprecated form). Run-time numbers (progress, slider and range slider
positions, upload progress) are rendered as `data-pct` attributes (an integer 0-100) that the
stylesheet maps to a `--pct` custom property; hooks that move things while you drag set styles
through the DOM (`el.style.left = ...`), which a CSP allows. Collapsed accordion panels use the
`hidden` class, and the popover trigger shows its open or closed content by `aria-expanded`.
`skeleton` (`width`, `height`) and `carousel` (`width`, `height`, `gap`) take Tailwind classes. Passing
a CSS length (`"200px"`, `"1rem"`, `"auto"`) still renders an inline style in 0.4.x, which
`style-src 'self'` blocks: that form is deprecated and goes away in 0.5. Extracted hooks (`dialog`, `response`) are bundled into your JavaScript and need
no nonce.

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

- [Live Demo](https://sutraui.gurujada.com) - Browse interactive component examples
- [Components Cheatsheet](components.cheatmd) - All components with examples
- [Accessibility Guide](accessibility.md) - Keyboard navigation patterns
- [Installation Guide](installation.md) - Setup instructions
