# Accessibility

Sutra UI is built with accessibility as a core principle. All components follow WAI-ARIA patterns and support keyboard navigation.

## WCAG 2.1 AA Compliance

Sutra UI components are designed to meet WCAG 2.1 Level AA standards:

- **Perceivable** - Text alternatives, adaptable content, distinguishable colors
- **Operable** - Keyboard accessible, enough time, navigable
- **Understandable** - Readable, predictable, input assistance
- **Robust** - Compatible with assistive technologies

## Keyboard Navigation

### Global Patterns

| Key | Action |
|-----|--------|
| `Tab` | Move focus to next focusable element |
| `Shift + Tab` | Move focus to previous focusable element |
| `Enter` / `Space` | Activate focused element |
| `Escape` | Close modal, popover, dropdown |

### Component-Specific Shortcuts

#### Tabs

| Key | Action |
|-----|--------|
| `Arrow Left/Right` | Navigate between tabs |
| `Home` | Go to first tab |
| `End` | Go to last tab |

#### Dropdown Menu

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate menu items |
| `Enter` | Select item |
| `Escape` | Close menu |

#### Select

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate options |
| `Enter` | Select option |
| `Escape` | Close dropdown |
| `Type` | Jump to matching option |

#### Accordion

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate accordion items |
| `Enter` / `Space` | Toggle accordion panel |
| `Home` | Go to first item |
| `End` | Go to last item |

#### Dialog

| Key | Action |
|-----|--------|
| `Escape` | Close dialog |
| `Tab` | Cycle through focusable elements (trapped) |

#### Command Palette

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate results |
| `Enter` | Select item |
| `Escape` | Close palette |

## ARIA Attributes by Component

### Buttons

```heex
<.button>Save</.button>
<!-- Renders with proper button semantics -->

<.button size="icon" aria-label="Close">
  <.icon name="hero-x-mark" />
</.button>
<!-- Icon buttons MUST have aria-label -->

<.button loading>Saving...</.button>
<!-- Sets aria-busy="true" when loading -->
```

### Form Controls

```heex
<.field>
  <:label>Email</:label>
  <.input type="email" name="email" />
  <:error>Invalid email</:error>
</.field>
<!-- Automatically links label, input, and error with aria-describedby -->
```

### Dialog

```heex
<.dialog id="confirm">
  <:title>Confirm Action</:title>
  <:description>Are you sure?</:description>
  Content here
</.dialog>
<!-- Sets aria-labelledby and aria-describedby automatically -->
```

### Tabs

```heex
<.tabs id="settings" default_value="account">
  <:tab value="account">Account</:tab>
  <:panel value="account">Account settings</:panel>
</.tabs>
<!-- Full tablist/tab/tabpanel ARIA pattern -->
```

## Focus Management

### Focus Trapping

Modal components like `dialog` and `command` automatically trap focus:

- Focus moves to the dialog when opened
- Tab cycles through focusable elements within the dialog
- Focus returns to the trigger element when closed

### Focus Indicators

All interactive elements have visible focus indicators using the `--ring` CSS variable:

```css
:root {
  --ring: oklch(0.705 0.015 286.067);  /* Focus ring color */
}
```

Focus indicators are:
- Always visible (never `outline: none`)
- High contrast against backgrounds
- Consistent across all components

### Skip Links

For page-level accessibility, add a skip link at the top of your layout:

```heex
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-background focus:border focus:rounded">
  Skip to main content
</a>

<main id="main-content">
  <!-- Page content -->
</main>
```

## Screen Reader Support

### Live Regions

Toast notifications use `aria-live` to announce messages:

```heex
<.toaster />
<!-- Creates a live region for announcements -->

<.toast>File saved successfully</.toast>
<!-- Announced by screen readers -->
```

### Semantic HTML

Sutra UI uses semantic HTML elements:

- `<button>` for buttons (not `<div>`)
- `<dialog>` for modals
- `<table>` for data tables
- `<nav>` for navigation
- `<form>` for forms

### Hidden Content

Use these utilities for screen reader content:

```heex
<!-- Visually hidden but accessible to screen readers -->
<span class="sr-only">Additional context</span>

<!-- Hidden from screen readers -->
<span aria-hidden="true">Decorative icon</span>
```

## Testing Accessibility

### Recommended Tools

1. **axe DevTools** - Browser extension for automated testing
2. **WAVE** - Web accessibility evaluation tool
3. **VoiceOver** (macOS) / **NVDA** (Windows) - Screen reader testing
4. **Keyboard only** - Navigate without a mouse

### Testing Checklist

- [ ] All interactive elements are focusable with Tab
- [ ] Focus order is logical
- [ ] Focus indicators are visible
- [ ] All images have alt text
- [ ] Form inputs have labels
- [ ] Error messages are associated with inputs
- [ ] Color is not the only means of conveying information
- [ ] Text has sufficient contrast (4.5:1 for normal, 3:1 for large)

## Common Accessibility Patterns

### Icon Buttons

Always provide an `aria-label`:

```heex
<!-- Good -->
<.button size="icon" aria-label="Delete item">
  <.icon name="hero-trash" />
</.button>

<!-- Bad - no accessible name -->
<.button size="icon">
  <.icon name="hero-trash" />
</.button>
```

### Loading States

Use `aria-busy` and announce loading:

```heex
<.button loading aria-busy="true">
  <.spinner class="mr-2" />
  Loading...
</.button>
```

### Disabled States

Use the `disabled` attribute, not just styling:

```heex
<!-- Good -->
<.button disabled>Cannot submit</.button>

<!-- Bad - looks disabled but isn't -->
<.button class="opacity-50 cursor-not-allowed">Cannot submit</.button>
```

### Form Validation

Associate errors with inputs:

```heex
<.field>
  <:label>Password</:label>
  <.input 
    type="password" 
    name="password"
    aria-invalid={@errors != []}
  />
  <:error :for={error <- @errors}>{error}</:error>
</.field>
```

## Next Steps

- [Components Cheatsheet](components.cheatmd) - All components with examples
- [Installation Guide](installation.md) - Setup instructions
- [Theming Guide](theming.md) - Customize your theme
