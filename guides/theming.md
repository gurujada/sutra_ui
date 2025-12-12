# Theming

Sutra UI uses CSS custom properties (variables) for theming, making it easy to customize colors, spacing, and more without modifying component code.

## CSS Variables Overview

All theme values are defined as CSS custom properties in `:root`. Override them in your `app.css` **after** importing `sutra_ui.css`.

```css
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Your theme overrides */
:root {
  --primary: oklch(0.65 0.20 145);
  --primary-foreground: oklch(0.98 0 0);
}
```

## Color Variables Reference

### Core Colors

| Variable | Description | Usage |
|----------|-------------|-------|
| `--background` | Page background | Main app background |
| `--foreground` | Default text color | Body text |
| `--card` | Card backgrounds | Cards, panels |
| `--card-foreground` | Card text | Text on cards |
| `--popover` | Popover/dropdown backgrounds | Menus, tooltips |
| `--popover-foreground` | Popover text | Text in popovers |

### Interactive Colors

| Variable | Description | Usage |
|----------|-------------|-------|
| `--primary` | Primary brand color | Buttons, links, focus rings |
| `--primary-foreground` | Text on primary | Button text |
| `--secondary` | Secondary actions | Secondary buttons |
| `--secondary-foreground` | Text on secondary | Secondary button text |
| `--accent` | Hover/active states | Highlights |
| `--accent-foreground` | Text on accent | Highlight text |

### Semantic Colors

| Variable | Description | Usage |
|----------|-------------|-------|
| `--destructive` | Error/danger color | Delete buttons, errors |
| `--destructive-foreground` | Text on destructive | Error button text |
| `--muted` | Muted backgrounds | Disabled states |
| `--muted-foreground` | Muted text | Placeholders, hints |

### UI Colors

| Variable | Description | Usage |
|----------|-------------|-------|
| `--border` | Border color | Dividers, outlines |
| `--input` | Input border color | Form field borders |
| `--ring` | Focus ring color | Focus indicators |

### Other

| Variable | Description | Default |
|----------|-------------|---------|
| `--radius` | Base border radius | `0.5rem` |

## OKLCH Color Format

Sutra UI uses **OKLCH** colors for better perceptual uniformity across the color spectrum.

```css
--primary: oklch(0.623 0.214 259.815);
/*         oklch(L     C     H      )
           L = Lightness (0-1)
           C = Chroma (0-0.4, saturation)
           H = Hue (0-360, color wheel)
*/
```

### Common Hue Values

| Color | Hue Range |
|-------|-----------|
| Red | ~25-35 |
| Orange | ~60-80 |
| Yellow | ~95-110 |
| Green | ~140-160 |
| Cyan | ~190-210 |
| Blue | ~250-270 |
| Purple | ~290-310 |
| Pink | ~340-360 |

### Example: Creating a Green Theme

```css
:root {
  /* Green primary */
  --primary: oklch(0.65 0.20 145);
  --primary-foreground: oklch(0.98 0 0);
  
  /* Complementary destructive (red) */
  --destructive: oklch(0.55 0.25 30);
  --destructive-foreground: oklch(0.98 0 0);
}
```

## Using shadcn/ui Themes

Sutra UI uses the same CSS variable names as [shadcn/ui](https://ui.shadcn.com/themes), so you can copy themes directly!

### Step 1: Visit shadcn/ui Themes

Go to [ui.shadcn.com/themes](https://ui.shadcn.com/themes) and customize a theme.

### Step 2: Copy the CSS Variables

Click "Copy code" and paste into your `app.css`:

```css
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

/* Paste shadcn theme here - it just works! */
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
  --border: oklch(0.92 0.004 286.32);
  --input: oklch(0.92 0.004 286.32);
  --ring: oklch(0.705 0.015 286.067);
  --radius: 0.5rem;
}

.dark {
  --background: oklch(0.141 0.005 285.823);
  --foreground: oklch(0.985 0 0);
  /* ... dark mode variables */
}
```

## Dark Mode

Sutra UI includes full dark mode support. Dark mode is activated by adding the `dark` class to the `<html>` element.

### Using the Theme Switcher

The easiest way to add dark mode is with the built-in theme switcher:

```heex
<.theme_switcher />
```

This renders a button that toggles between light, dark, and system themes.

### Manual Control

Toggle dark mode programmatically:

```javascript
// Enable dark mode
document.documentElement.classList.add('dark')

// Disable dark mode
document.documentElement.classList.remove('dark')

// Toggle
document.documentElement.classList.toggle('dark')
```

### Respecting System Preference

To automatically match the user's system preference:

```javascript
if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
  document.documentElement.classList.add('dark')
}
```

### Dark Mode Variables

Define dark mode overrides inside `.dark`:

```css
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.1 0 0);
}

.dark {
  --background: oklch(0.1 0 0);
  --foreground: oklch(0.95 0 0);
}
```

## Per-Component Customization

You can override styles for specific components using CSS:

```css
/* Custom button styles */
.btn {
  --radius: 9999px;  /* Fully rounded buttons */
}

/* Custom card styles */
.card {
  --radius: 1rem;  /* Larger radius for cards */
}
```

## Complete Theme Example

Here's a complete custom theme:

```css
@import "../../deps/sutra_ui/priv/static/sutra_ui.css";

:root {
  /* Brand colors - Blue theme */
  --primary: oklch(0.6 0.2 260);
  --primary-foreground: oklch(0.98 0 0);
  
  /* Backgrounds */
  --background: oklch(0.99 0.002 260);
  --foreground: oklch(0.15 0.01 260);
  
  /* Cards & Surfaces */
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.15 0.01 260);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.15 0.01 260);
  
  /* Secondary & Muted */
  --secondary: oklch(0.95 0.01 260);
  --secondary-foreground: oklch(0.2 0.02 260);
  --muted: oklch(0.95 0.01 260);
  --muted-foreground: oklch(0.5 0.02 260);
  --accent: oklch(0.95 0.01 260);
  --accent-foreground: oklch(0.2 0.02 260);
  
  /* Semantic */
  --destructive: oklch(0.55 0.25 25);
  --destructive-foreground: oklch(0.98 0 0);
  
  /* Borders */
  --border: oklch(0.9 0.01 260);
  --input: oklch(0.9 0.01 260);
  --ring: oklch(0.6 0.2 260);
  
  /* Radius */
  --radius: 0.5rem;
}

.dark {
  --primary: oklch(0.7 0.18 260);
  --primary-foreground: oklch(0.1 0 0);
  
  --background: oklch(0.12 0.01 260);
  --foreground: oklch(0.95 0.005 260);
  
  --card: oklch(0.15 0.01 260);
  --card-foreground: oklch(0.95 0.005 260);
  --popover: oklch(0.15 0.01 260);
  --popover-foreground: oklch(0.95 0.005 260);
  
  --secondary: oklch(0.2 0.01 260);
  --secondary-foreground: oklch(0.9 0.005 260);
  --muted: oklch(0.2 0.01 260);
  --muted-foreground: oklch(0.6 0.02 260);
  --accent: oklch(0.25 0.02 260);
  --accent-foreground: oklch(0.9 0.005 260);
  
  --destructive: oklch(0.6 0.22 25);
  --destructive-foreground: oklch(0.98 0 0);
  
  --border: oklch(0.25 0.01 260);
  --input: oklch(0.25 0.01 260);
  --ring: oklch(0.5 0.15 260);
}
```

## Next Steps

- [Components Cheatsheet](components.cheatmd) - See all components
- [Accessibility Guide](accessibility.md) - Ensure your app is accessible
- [Installation Guide](installation.md) - Setup instructions
