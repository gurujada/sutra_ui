# Installation

This guide walks you through setting up Sutra UI in your Phoenix application.

## Prerequisites

Sutra UI requires:

| Dependency | Minimum Version | Notes |
|------------|-----------------|-------|
| Elixir | 1.14+ | Required for LiveView 1.1 |
| Phoenix | **1.8+** | Required for colocated hooks |
| Phoenix LiveView | **1.1+** | `ColocatedHook` support |
| Tailwind CSS | **v4** | CSS-first configuration |

> #### Why Phoenix 1.8+? {: .info}
>
> Sutra UI uses [colocated hooks](colocated-hooks.md) - a Phoenix 1.8+ feature that allows JavaScript hooks to live alongside their components. No separate `hooks.js` file needed.

## Step 1: Add Dependencies

Add `sutra_ui` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sutra_ui, "~> 0.1"},
    {:jason, "~> 1.0"}  # Required for dropdown_menu and live_select
  ]
end
```

Then fetch dependencies:

```bash
mix deps.get
```

## Step 2: Configure Tailwind CSS v4

Sutra UI is built for Tailwind CSS v4, which uses a CSS-first configuration approach.

In your `assets/css/app.css`:

```css
@import "tailwindcss";

/* Add Sutra UI source paths for Tailwind to scan */
@source "../../deps/sutra_ui/lib";

/* Import Sutra UI component styles */
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Your app's custom styles below... */
```

> #### Tailwind v4 Changes {: .tip}
>
> Tailwind v4 uses `@source` directives instead of the `content` array in `tailwind.config.js`. The `@source` directive tells Tailwind where to look for class names to include in your CSS.

## Step 3: Import Components

There are two ways to import Sutra UI components:

### Option A: Import All Components (Recommended)

In your `lib/my_app_web.ex`, add `use SutraUI` to your `html_helpers`:

```elixir
defmodule MyAppWeb do
  # ...

  defp html_helpers do
    quote do
      use SutraUI  # Imports all 44 components
      
      # ... other imports
    end
  end
end
```

### Option B: Selective Import

Import only the components you need:

```elixir
defmodule MyAppWeb.SomeLive do
  use MyAppWeb, :live_view
  
  import SutraUI.Button
  import SutraUI.Dialog
  import SutraUI.Input
  
  # ...
end
```

## Step 4: Verify Installation

Create a simple test to verify everything works:

```heex
<.button>Hello Sutra UI!</.button>

<.button variant="destructive">Delete</.button>

<.button variant="outline" size="sm">Small Outline</.button>
```

If you see styled buttons, you're ready to go!

## Troubleshooting

### Components render but have no styles

**Cause:** Tailwind isn't scanning the Sutra UI source files.

**Fix:** Ensure you have the `@source` directive in your `app.css`:

```css
@source "../../deps/sutra_ui/lib";
```

Then restart your Phoenix server and asset watcher.

### "undefined function" errors for components

**Cause:** Components not imported.

**Fix:** Add `use SutraUI` to your `html_helpers` or import specific components.

### Hook-based components don't work (Select, Dialog, Tabs, etc.)

**Cause:** Colocated hooks require Phoenix 1.8+.

**Fix:** Upgrade Phoenix:

```elixir
# mix.exs
{:phoenix, "~> 1.8"}
```

Then run:

```bash
mix deps.update phoenix
```

### CSS variables not applying

**Cause:** Sutra UI styles not imported or loaded after your overrides.

**Fix:** Ensure the import order is correct:

```css
@import "tailwindcss";
@source "../../deps/sutra_ui/lib";
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Your overrides AFTER sutra_ui.css */
:root {
  --primary: oklch(0.65 0.20 145);
}
```

### Dark mode not working

**Cause:** Missing `dark` class on `<html>` element.

**Fix:** Add the theme switcher or manually toggle the class:

```heex
<.theme_switcher />
```

Or control it manually:

```javascript
document.documentElement.classList.toggle('dark')
```

## Next Steps

- [Theming Guide](theming.md) - Customize colors and styles
- [Components Cheatsheet](components.cheatmd) - Quick reference for all components
- [JavaScript Hooks](colocated-hooks.md) - Understanding colocated hooks
