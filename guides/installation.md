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

## Step 2: Delete core_components.ex

Sutra UI provides a complete replacement for Phoenix's default `core_components.ex`, including the `icon/1` component.

**Delete the generated file:**

```bash
rm lib/my_app_web/components/core_components.ex
```

Then remove the import from your `lib/my_app_web.ex`:

```elixir
defmodule MyAppWeb do
  # ...

  defp html_helpers do
    quote do
      # Remove or comment out this line:
      # import MyAppWeb.CoreComponents
      
      use SutraUI  # Add this instead (Step 5)
      
      # ... other imports
    end
  end
end
```

> #### Why delete core_components? {: .info}
>
> Phoenix generates `core_components.ex` with basic UI components. Sutra UI provides enhanced versions of all these components plus 40+ more. Keeping both would cause naming conflicts and confusion.

## Step 3: Configure Tailwind CSS v4

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

## Step 4: Setup Lucide Icons

Sutra UI uses [Lucide icons](https://lucide.dev/) as the standard icon system, matching the shadcn/ui ecosystem.

### Install the lucide-static package

```bash
cd assets && npm install lucide-static
```

### Add Lucide CSS to your app.css

Add this to your `assets/css/app.css` after the Tailwind import:

```css
@import "tailwindcss";

/* Sutra UI setup */
@source "../../deps/sutra_ui/lib";
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Lucide Icons */
@import "lucide-static/font/lucide.css";

/* Your app's custom styles below... */
```

### Usage

Icons use the `lucide-{name}` pattern:

```heex
<.icon name="lucide-check" />
<.icon name="lucide-x" />
<.icon name="lucide-settings" />
<.icon name="lucide-user" />
```

Browse all available icons at [lucide.dev/icons](https://lucide.dev/icons/).

> #### Icon naming {: .tip}
>
> Lucide icon names are in kebab-case. For example:
> - `lucide-chevron-down` (dropdown arrows)
> - `lucide-loader-2` (spinner - use with `animate-spin` class)
> - `lucide-search` (search icon)

## Step 5: Setup JavaScript Hooks

Sutra UI components use colocated JavaScript hooks. Add the hooks import to your `assets/js/app.js`:

```javascript
import { hooks as sutraUiHooks } from "phoenix-colocated/sutra_ui";
```

Then spread them into your LiveSocket configuration:

```javascript
const liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken },
    hooks: { ...sutraUiHooks },  // Add other hooks here too
});
```

> #### Deployment Note {: .warning}
>
> Colocated hooks are extracted at compile time. Ensure your deployment runs `mix compile` **before** `assets.deploy`:
>
> ```elixir
> # mix.exs
> "assets.deploy": [
>   "compile",  # Must come first
>   "esbuild my_app --minify",
>   "tailwind my_app --minify",
>   "phx.digest"
> ]
> ```

## Step 6: Import Components

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

Alternatively, import only the components you need:

```elixir
defmodule MyAppWeb.SomeLive do
  use MyAppWeb, :live_view
  
  import SutraUI.Button
  import SutraUI.Dialog
  import SutraUI.Input
  
  # ...
end
```

## Step 7: Verify Installation

Create a simple test to verify everything works:

```heex
<.button>Hello Sutra UI!</.button>

<.button variant="destructive">
  <.icon name="lucide-trash-2" class="mr-2 size-4" />
  Delete
</.button>

<.button variant="outline" size="sm">Small Outline</.button>
```

If you see styled buttons with icons, you're ready to go!

## Troubleshooting

### Icons not showing

**Cause:** Lucide icons CSS not installed or imported.

**Fix:** Ensure you've installed the package and added the CSS import:

```bash
cd assets && npm install lucide-static
```

```css
/* In app.css */
@import "lucide-static/font/lucide.css";
```

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

### Conflicts with core_components

**Cause:** Both `core_components.ex` and Sutra UI define components like `button/1`, `input/1`, etc.

**Fix:** Delete `lib/my_app_web/components/core_components.ex` and remove its import from your web module (see Step 2).

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
@import "lucide-static/font/lucide.css";

/* Your overrides AFTER sutra_ui.css */
:root {
  --primary: oklch(0.65 0.20 145);
}
```

### Dark mode not working

**Cause:** Missing `dark` class on `<html>` element.

**Fix:** Add the theme switcher or manually toggle the class:

```heex
<.theme_switcher id="theme-toggle" />
```

Or control it manually:

```javascript
document.documentElement.classList.toggle('dark')
```

## Next Steps

- [Theming Guide](theming.md) - Customize colors and styles
- [Components Cheatsheet](components.cheatmd) - Quick reference for all components
- [JavaScript Hooks](colocated-hooks.md) - Understanding colocated hooks
