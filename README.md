# Sutra UI

*We define the rules, so you don't have to.*

A pure Phoenix LiveView UI component library inspired by shadcn/ui.

Built for **Tailwind CSS v4** and **Phoenix LiveView 1.0+**.

## Why Sutra UI?

- **Zero JavaScript dependencies** - No React, no npm packages, no node_modules bloat. Just Phoenix LiveView.
- **CSS-first theming** - Customize colors with CSS variables. No build step, no config files.
- **Copy-paste friendly** - Like shadcn/ui, components are meant to be understood and modified.
- **Server-driven** - All state lives on the server. No client-side state sync headaches.
- **Production-ready** - 677 tests, full accessibility support, dark mode included.
- **LLM-friendly** - Includes `usage_rules.md` with guidelines for AI assistants working with this codebase.

## Features

- **44 Components** - Buttons, forms, dialogs, tables, and more
- **Pure LiveView** - No external JavaScript frameworks
- **Colocated Hooks** - JS hooks live with their components  
- **CSS Variables** - Override any color in one line
- **Accessible** - WCAG 2.1 AA compliant, keyboard navigable
- **Dark Mode** - Built-in light/dark theme support
- **Lightweight** - ~2500 lines of CSS, minimal JS hooks

## Installation

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:sutra_ui, "~> 0.1.0"},
    {:jason, "~> 1.0"}  # Required for dropdown_menu and live_select
  ]
end
```

Then run:

```bash
mix deps.get
```

### 2. Setup CSS (Tailwind v4)

In your `assets/css/app.css`:

```css
@import "tailwindcss";

/* Add Sutra UI source paths for Tailwind to scan */
@source "../../deps/sutra_ui/lib";

/* Import Sutra UI component styles */
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Your app's custom styles... */
```

### 3. Setup JavaScript Hooks

Sutra UI components use Phoenix LiveView's colocated hooks. In your `assets/js/app.js`:

```javascript
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as sutraUiHooks} from "phoenix-colocated/sutra_ui"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...sutraUiHooks},
  // ... other options
})
```

> **Note:** `phoenix-colocated` is built into Phoenix LiveView 1.0+. No additional package needed.

### 4. Import Components

In your `my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    use SutraUI
    # ... other imports
  end
end
```

Or import specific components:

```elixir
import SutraUI.Button
import SutraUI.Dialog
```

## Usage

```heex
<.button>Click me</.button>

<.button variant="destructive">Delete</.button>

<.dialog id="confirm-dialog">
  <:trigger>
    <.button variant="outline">Open Dialog</.button>
  </:trigger>
  <:title>Confirm Action</:title>
  <:description>Are you sure you want to continue?</:description>
  <:footer>
    <.button variant="outline" phx-click={hide_dialog("confirm-dialog")}>
      Cancel
    </.button>
    <.button phx-click="confirm">Confirm</.button>
  </:footer>
</.dialog>
```

## Theme Customization

Sutra UI uses CSS custom properties for theming. Override them in your `app.css` **after** importing `sutra_ui.css`:

```css
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Custom theme overrides */
:root {
  /* Primary brand color (buttons, links, focus rings) */
  --primary: oklch(0.65 0.20 145);        /* Green */
  --primary-foreground: oklch(0.98 0 0);  /* White text on primary */

  /* Destructive actions (delete buttons, error states) */
  --destructive: oklch(0.55 0.25 30);     /* Red */

  /* Border radius */
  --radius: 0.5rem;
}

/* Dark mode overrides */
.dark {
  --primary: oklch(0.70 0.18 145);
  --destructive: oklch(0.65 0.22 25);
}
```

### Using shadcn/ui Themes

Since Sutra UI uses the same CSS variable names as shadcn/ui, you can copy theme variables directly from [shadcn/ui themes](https://ui.shadcn.com/themes) and paste them into your `app.css`:

```css
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Paste your shadcn theme here - it just works! */
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.141 0.005 285.823);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.141 0.005 285.823);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.141 0.005 285.823);
  --primary: oklch(0.21 0.006 285.885);
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.967 0.001 286.375);
  --secondary-foreground: oklch(0.21 0.006 285.885);
  --muted: oklch(0.967 0.001 286.375);
  --muted-foreground: oklch(0.552 0.016 285.938);
  --accent: oklch(0.967 0.001 286.375);
  --accent-foreground: oklch(0.21 0.006 285.885);
  --destructive: oklch(0.577 0.245 27.325);
  --destructive-foreground: oklch(0.577 0.245 27.325);
  --border: oklch(0.92 0.004 286.32);
  --input: oklch(0.92 0.004 286.32);
  --ring: oklch(0.705 0.015 286.067);
  --radius: 0.5rem;
}

.dark {
  /* Dark mode variables from shadcn */
}
```

### CSS Variables Reference

| Variable | Description | Usage |
|----------|-------------|-------|
| `--background` | Page background | `bg-background` |
| `--foreground` | Default text color | `text-foreground` |
| `--card` | Card backgrounds | `bg-card` |
| `--card-foreground` | Card text | `text-card-foreground` |
| `--popover` | Popover/dropdown backgrounds | `bg-popover` |
| `--popover-foreground` | Popover text | `text-popover-foreground` |
| `--primary` | Primary brand color | `bg-primary`, `text-primary` |
| `--primary-foreground` | Text on primary backgrounds | `text-primary-foreground` |
| `--secondary` | Secondary/muted actions | `bg-secondary` |
| `--secondary-foreground` | Text on secondary | `text-secondary-foreground` |
| `--muted` | Muted backgrounds | `bg-muted` |
| `--muted-foreground` | Muted/placeholder text | `text-muted-foreground` |
| `--accent` | Hover/active states | `bg-accent` |
| `--accent-foreground` | Text on accent | `text-accent-foreground` |
| `--destructive` | Error/danger color | `bg-destructive` |
| `--destructive-foreground` | Text on destructive | `text-destructive-foreground` |
| `--border` | Border color | `border-border` |
| `--input` | Input border color | `border-input` |
| `--ring` | Focus ring color | `ring-ring` |
| `--radius` | Base border radius | Used by `rounded-lg`, etc. |

### Color Format

Sutra UI uses **OKLCH** colors for better perceptual uniformity:

```css
--primary: oklch(0.623 0.214 259.815);
/*         oklch(L     C     H      )
           L = Lightness (0-1)
           C = Chroma (0-0.4, saturation)
           H = Hue (0-360, color wheel)
*/
```

**Common hues:** Red ~30, Orange ~70, Yellow ~100, Green ~145, Cyan ~195, Blue ~260, Purple ~300, Pink ~350

## Components

### Form Controls
- `button` - Buttons with variants (primary, secondary, destructive, outline, ghost, link)
- `input` - Text inputs (text, email, password, number, date, etc.)
- `textarea` - Multi-line text input
- `checkbox` - Checkbox input
- `switch` - Toggle switch
- `radio_group` - Radio button groups
- `select` - Custom dropdown with search
- `slider` - Range slider
- `range_slider` - Dual-handle range slider
- `live_select` - Async searchable select with tags
- `field` - Form field wrapper with label/error
- `simple_form` - Form with auto-styling
- `input_group` - Input with prefix/suffix
- `filter_bar` - Filter controls layout

### Layout
- `card` - Content container with header/footer
- `header` - Page header with title/actions
- `table` - Data table
- `item` - List item component
- `sidebar` - Collapsible sidebar navigation

### Feedback
- `alert` - Alert messages
- `badge` - Status badges
- `progress` - Progress bar
- `spinner` - Loading spinner
- `skeleton` - Loading placeholder
- `empty` - Empty state
- `loading_state` - Loading indicator with message
- `toast` - Toast notifications

### Overlay
- `dialog` - Modal dialogs
- `popover` - Click-triggered popups
- `tooltip` - Hover tooltips
- `dropdown_menu` - Dropdown menus
- `command` - Command palette with search

### Navigation
- `tabs` - Tab panels
- `accordion` - Collapsible sections
- `breadcrumb` - Breadcrumb navigation
- `pagination` - Page navigation
- `nav_pills` - Pill-style navigation
- `tab_nav` - Tab-style navigation

### Display
- `avatar` - User avatars with fallback
- `icon` - Icon component (Lucide icons)
- `carousel` - Image/content carousel
- `kbd` - Keyboard shortcut display
- `label` - Form labels
- `theme_switcher` - Light/dark mode toggle

## For AI Assistants

This library includes `usage_rules.md` with detailed guidelines for AI assistants (LLMs) working with this codebase. The file covers:

- CSS-first styling patterns
- Required ID attributes for hook-based components
- Event naming conventions (`phx-ui:*` namespace)
- Component structure patterns
- Testing conventions

If you're using an AI assistant to help modify or extend Sutra UI components, point it to `usage_rules.md` for context.

## Accessibility

All components follow WAI-ARIA patterns:

- Semantic HTML elements
- Proper ARIA roles and attributes
- Keyboard navigation (Tab, Arrow keys, Enter, Escape)
- Focus management and visible focus indicators
- Screen reader announcements

## Browser Support

- Chrome/Edge 120+
- Firefox 120+
- Safari 17+

Requires support for:
- CSS `@layer`
- CSS custom properties
- CSS `:has()` selector
- `<dialog>` element
- Popover API (progressive enhancement)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Documentation](https://hexdocs.pm/sutra_ui)
- [GitHub](https://github.com/gurujada/sutra_ui)
- [Changelog](CHANGELOG.md)
