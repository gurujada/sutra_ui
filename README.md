# PhxUI

A pure Phoenix LiveView UI component library. No dependencies, no nonsense.

## Features

- **Pure LiveView** - No external JavaScript dependencies
- **Colocated Hooks** - JavaScript hooks live with their components
- **Accessible** - WCAG 2.1 AA compliant
- **Tailwind CSS** - Just utility classes, no custom CSS files
- **shadcn/ui inspired** - Clean, composable design

## Installation

Add `phx_ui` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phx_ui, "~> 0.1.0"}
  ]
end
```

## Setup

### 1. Import Components

In your `my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    use PhxUI
    # ... other imports
  end
end
```

### 2. Configure Tailwind

Add PhxUI to your Tailwind content paths in `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
    "../deps/phx_ui/**/*.*ex"  // Add this line
  ],
  // ...
}
```

### 3. Import Colocated Hooks

Some PhxUI components (like `slider` and `select`) include colocated JavaScript hooks. Import them in your `app.js`:

```javascript
import { hooks as colocatedHooks } from "phoenix-colocated/phx_ui"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    ...colocatedHooks,
    // ...your other hooks
  }
})
```

The colocated hooks are automatically extracted from the component files during compilation. Components that use hooks reference them with a dot prefix (e.g., `phx-hook=".Slider"`).

## Usage

```heex
<.button>Click me</.button>

<.button variant="destructive">Delete</.button>

<.dialog id="confirm-dialog" title="Confirm">
  Are you sure?
  <:footer>
    <.button variant="outline" phx-click={hide_dialog("confirm-dialog")}>
      Cancel
    </.button>
    <.button phx-click="confirm">Confirm</.button>
  </:footer>
</.dialog>
```

## Components

### Form
- `button` - Buttons with variants (primary, secondary, destructive, outline, ghost, link)
- `input` - Text inputs
- `textarea` - Multi-line text
- `checkbox` - Checkboxes
- `switch` - Toggle switches
- `radio_group` - Radio buttons
- `select` - Custom dropdowns with search
- `slider` - Range input sliders
- `field` - Form field wrapper

### Layout
- `card` - Content containers
- `header` - Page headers
- `table` - Data tables

### Interactive
- `accordion` - Collapsible sections
- `tabs` - Tabbed interfaces
- `dropdown_menu` - Dropdown menus

### Overlay
- `dialog` - Modal dialogs
- `popover` - Floating content
- `tooltip` - Hover tooltips

### Feedback
- `alert` - Alert messages
- `badge` - Status badges
- `progress` - Progress bars
- `spinner` - Loading indicators

### Data Display
- `avatar` - User avatars
- `icon` - Lucide icons
- `skeleton` - Loading placeholders
- `empty` - Empty states

## Accessibility

All components follow WAI-ARIA patterns:
- Proper roles and ARIA attributes
- Keyboard navigation
- Focus management
- Screen reader support

## License

MIT
