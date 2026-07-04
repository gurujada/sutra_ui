# Sutra UI

[![Hex.pm](https://img.shields.io/hexpm/v/sutra_ui.svg)](https://hex.pm/packages/sutra_ui)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sutra_ui)
[![License](https://img.shields.io/hexpm/l/sutra_ui.svg)](https://github.com/gurujada/sutra_ui/blob/main/LICENSE)

*We define the rules, so you don't have to.*

A pure Phoenix LiveView UI component library inspired by shadcn/ui.

Built for **Elixir 1.20+**, **Phoenix 1.8+**, **Phoenix LiveView 1.2+**, and **Tailwind CSS v4**.

## Why Sutra UI?

- **No external JavaScript packages** - No React, no npm packages, no node_modules bloat. Just Phoenix LiveView and colocated hooks.
- **CSS-first theming** - Customize colors with CSS variables and no Tailwind config file.
- **Copy-paste friendly** - Like shadcn/ui, components are meant to be understood and modified.
- **Phoenix-native** - Workflows live in LiveView; small hooks only handle local UI behavior.
- **Production-minded** - Tests, accessibility-minded patterns, and dark mode included.
- **LLM-friendly** - Includes `usage_rules.md` with guidelines for AI assistants working with this codebase.

## Features

- **56 Components** - Buttons, forms, dialogs, tables, calendars, upload fields, AI primitives, and more
- **Pure LiveView** - No external JavaScript frameworks
- **Colocated Hooks** - JS hooks live with their components (Phoenix 1.8+)
- **CSS Variables** - Override any color in one line
- **Accessible** - Semantic markup, ARIA patterns, and keyboard behavior where components are interactive
- **Dark Mode** - Built-in light/dark theme support
- **Lightweight** - CSS-first styling with minimal colocated JS hooks

## Installation

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:sutra_ui, "~> 0.4.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

### 2. Run the Installer

```bash
mix sutra_ui.install
```

This handles CSS setup and adds `use SutraUI` to your web module's `html_helpers`.

### 3. Delete core_components.ex

Sutra UI replaces Phoenix's generated button, input, flash, and related UI helpers. Delete `core_components.ex` and remove its import:

```bash
rm lib/my_app_web/components/core_components.ex
```

In your `my_app_web.ex`, remove the `import MyAppWeb.CoreComponents` line.
If your app uses Phoenix's generated `<.icon>` helper, move that helper to a
separate module or replace those calls before deleting `core_components.ex`.

### 4. Colocated Hooks

Sutra UI uses Phoenix 1.8+ colocated hooks.

Most hooks load at runtime. Components such as `dialog` and animated `response`
use extracted hooks; merge the generated Sutra UI hooks into your LiveSocket:

```js
import {hooks as sutraUiHooks} from "phoenix-colocated/sutra_ui"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...sutraUiHooks}
})
```

### 5. Deployment Setup

Update your deployment aliases in `mix.exs`:

```elixir
"assets.deploy": [
  "compile",  # Required: extracts colocated hooks
  "esbuild my_app --minify",
  "tailwind my_app --minify",
  "phx.digest"
]
```

## Usage

```heex
<.button>Click me</.button>

<.button variant="destructive">Delete</.button>

<.button variant="outline" phx-click="open_confirm">
  Open Dialog
</.button>

<.dialog id="confirm-dialog" show={@show_confirm} on_cancel="close_confirm">
  <:title>Confirm Action</:title>
  <:description>Are you sure you want to continue?</:description>
  <:footer>
    <.button variant="outline" phx-click="close_confirm">
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

/* Paste compatible shadcn theme variables here */
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
  --destructive-foreground: oklch(0.985 0 0);
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

### Foundation
- `button` - Buttons with variants (primary, secondary, destructive, outline, ghost, link)
- `badge` - Status badges
- `spinner` - Loading spinner
- `kbd` - Keyboard shortcut display

### Form Controls
- `input` - Text inputs (text, email, password, number, date, etc.)
- `textarea` - Multi-line text input
- `checkbox` - Checkbox input
- `switch` - Toggle switch
- `radio_group` - Radio button groups
- `select` - Custom dropdown with search
- `slider` - Range slider
- `range_slider` - Dual-handle range slider
- `live_select` - LiveComponent async searchable select with tags
- `label` - Form labels
- `simple_form` - Form with auto-styling
- `input_group` - Input with prefix/suffix
- `input_otp` - One-time password and PIN input
- `file_upload` - LiveView upload dropzone
- `filter_bar` - Filter controls layout

### Layout
- `card` - Content container with header/footer
- `header` - Page header with title/actions
- `table` - Data table
- `item` - List item component
- `drawer` - Collapsible drawer navigation
- `stepper` - Multi-step progress indicator
- `stepper_wizard` - Multi-step wizard shell
- `tree_view` - Hierarchical tree navigation

### Feedback
- `alert` - Alert messages
- `flash` - Phoenix flash messages
- `progress` - Progress bar
- `skeleton` - Loading placeholder
- `empty` - Empty state
- `loading_state` - Loading indicator with message
- `toast` - Toast notifications

### Overlay
- `dialog` - Modal dialogs
- `popover` - Click-triggered popups
- `tooltip` - Hover tooltips
- `hover_card` - Rich hover previews
- `dropdown_menu` - Dropdown menus
- `context_menu` - Right-click action menus
- `command` - Command palette with search

### Navigation
- `tabs` - Tab panels
- `accordion` - Collapsible sections
- `breadcrumb` - Breadcrumb navigation
- `pagination` - Page navigation
- `nav_pills` - Pill-style navigation
- `tab_nav` - Routed tab-style navigation

### Display
- `avatar` - User avatars with fallback
- `carousel` - Image/content carousel
- `theme_switcher` - Light/dark theme event button
- `marquee` - Scrolling content banner
- `separator` - Visual or semantic divider
- `calendar` - Monthly calendar grid
- `timeline` - Chronological event list

### AI
- `response` - Text responses with reveal styles, or streamed Markdown
- `activity` - Safe user-facing agent progress with slot-owned rows

## For AI Assistants

This library includes `usage_rules.md` with detailed guidelines for AI assistants (LLMs) working with this codebase. The file covers:

- CSS-first styling patterns
- Required ID attributes for hook-based components
- Event naming conventions (`sutra-ui:*` namespace)
- Component structure patterns
- Testing conventions

If you're using an AI assistant to help modify or extend Sutra UI components, point it to `usage_rules.md` for context.

## Accessibility

Sutra UI components use accessibility patterns appropriate to their behavior:

- Semantic HTML elements
- ARIA roles and attributes for composite widgets
- Keyboard navigation for interactive components
- Focus management and visible focus indicators where applicable
- Screen reader announcements for status-style components

## Browser Support

- Chrome/Edge 120+
- Firefox 120+
- Safari 17+

Requires support for:
- CSS `@layer`
- CSS custom properties
- CSS `:has()` selector
- Native `<dialog>` element for `command_dialog`

## License

MIT License - see [LICENSE](https://github.com/gurujada/sutra_ui/blob/main/LICENSE) for details.

## Documentation

- **[HexDocs](https://hexdocs.pm/sutra_ui)** - Full API reference
- **[Installation Guide](https://hexdocs.pm/sutra_ui/installation.html)** - Setup for Phoenix 1.8+ and Tailwind v4
- **[Theming Guide](https://hexdocs.pm/sutra_ui/theming.html)** - CSS variables, OKLCH colors, shadcn themes
- **[Accessibility Guide](https://hexdocs.pm/sutra_ui/accessibility.html)** - ARIA patterns, keyboard navigation
- **[JavaScript Hooks](https://hexdocs.pm/sutra_ui/colocated-hooks.html)** - Colocated hooks, custom events
- **[Components Cheatsheet](https://hexdocs.pm/sutra_ui/components.html)** - Quick reference for all 56 components
- **[Forms Cheatsheet](https://hexdocs.pm/sutra_ui/forms.html)** - Form patterns and validation

## Links

- [GitHub](https://github.com/gurujada/sutra_ui)
- [Changelog](CHANGELOG.md)
