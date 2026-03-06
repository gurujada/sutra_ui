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
    {:sutra_ui, "~> 0.3.0"},
    {:jason, "~> 1.0"}  # Required for dropdown_menu and live_select
  ]
end
```

Then fetch dependencies:

```bash
mix deps.get
```

## Step 2: Run the Installer

```bash
mix sutra_ui.install
```

This will:

1. Add `@source` and `@import` lines to your `assets/css/app.css`
2. Add `use SutraUI` to the `html_helpers` function in your web module

The installer will also warn you if `core_components.ex` still exists (see Step 3).

> #### Manual CSS setup {: .tip}
>
> If the installer can't find your `app.css` or you prefer to do it manually, add these lines to `assets/css/app.css`:
>
> ```css
> @import "tailwindcss";
>
> /* Add Sutra UI source paths for Tailwind to scan */
> @source "../../deps/sutra_ui/lib";
>
> /* Import Sutra UI component styles */
> @import "../../deps/sutra_ui/priv/static/sutra_ui.css";
>
> /* Your app's custom styles below... */
> ```

## Step 3: Delete core_components.ex

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
      
      use SutraUI  # Already added by the installer
      
      # ... other imports
    end
  end
end
```

> #### Why delete core_components? {: .info}
>
> Phoenix generates `core_components.ex` with basic UI components. Sutra UI provides enhanced versions of all these components plus 40+ more. Keeping both would cause naming conflicts and confusion.

## Step 4: Runtime Hooks (No JS Setup Required)

Sutra UI uses Phoenix 1.8+ runtime colocated hooks. You do **not** need to add
anything to `assets/js/app.js`.

Just render the components and their hooks are loaded automatically at runtime.

> #### Deployment Note {: .warning}
>
> Runtime hooks are still compiled with your app code. Ensure your deployment runs `mix compile` **before** `assets.deploy`:
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

## Step 5: Verify Installation

Create a simple test to verify everything works:

```heex
<.button>Hello Sutra UI!</.button>

<.button variant="destructive">
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mr-2 size-4" aria-hidden="true"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
  Delete
</.button>

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
