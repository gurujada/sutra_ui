# Accessibility

Sutra UI is built with accessibility as a core principle. Components use semantic HTML, ARIA patterns, and keyboard behavior where the component is interactive.

## Accessibility Targets

Sutra UI components are designed with WCAG 2.1 Level AA criteria in mind:

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
| `Enter` / `Space` | Activate item |
| `Escape` | Close menu |

#### Select

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate options |
| `Enter` | Select option |
| `Escape` | Close dropdown |
| Letter key (open listbox) | Jump to the next visible option starting with that letter |

#### Accordion

| Key | Action |
|-----|--------|
| `Enter` / `Space` | Toggle accordion panel |

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
| `Escape` | Close `command_dialog` |

## ARIA Attributes by Component

### Buttons

```heex
<.button>Save</.button>
<!-- Renders with native button semantics -->

<.button size="icon" aria-label="Close">
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
</.button>
<!-- Icon buttons MUST have aria-label -->

<.button loading>Saving...</.button>
<!-- Sets aria-busy="true" when loading -->
```

### Form Controls

```heex
<.input
  id="email"
  name="email"
  type="email"
  label="Email"
  description="We'll use this for account notifications."
  errors={["Invalid email"]}
/>
<!-- Links label, description, and errors; sets aria-invalid when errors are present -->
```

### Dialog

```heex
<.dialog id="confirm" show={@show_confirm} on_cancel="close_confirm">
  <:title>Confirm Action</:title>
  <:description>Are you sure?</:description>
  Content here
</.dialog>
<!-- Sets role="dialog", aria-modal, aria-labelledby, and aria-describedby automatically -->
<!-- Uses a div-based overlay for screen share compatibility -->
```

### Tabs

```heex
<.tabs id="settings" default_value="account">
  <:tab value="account">Account</:tab>
  <:panel value="account">Account settings</:panel>
</.tabs>
<!-- Full tablist/tab/tabpanel ARIA pattern -->
```

### Separator

```heex
<.separator />
<!-- Decorative by default and hidden from assistive technology -->

<.separator decorative={false} aria-label="Account settings" />
<!-- Use semantic mode when the divider communicates document structure -->
```

### Marquee

```heex
<.marquee>
  <:item>New components released weekly</:item>
  <:item>24/7 support available</:item>
</.marquee>
<!-- Duplicated content is hidden from assistive tech and motion stops for reduced-motion users -->
```

### Input OTP

```heex
<.input_otp id="mfa-code" name="code" groups={[3, 3]} />
```

<!-- Each slot has an accessible digit label and the hidden input carries the submitted value -->

### Calendar

```heex
<.calendar selected={@date} />
```

<!-- Uses grid roles, aria-selected for the selected date, and aria-current="date" for today. Compose it with popover and a hidden input when building a date-picker field. -->

### Context Menu

```heex
<.context_menu id="message-menu">
  <:trigger>Right click</:trigger>
  <.context_menu_item>Reply</.context_menu_item>
</.context_menu>
```

<!-- Opens with right click, Shift+F10, or the Context Menu key -->

### AI Primitives

```heex
<.response id="answer" value={@streamed_answer} streaming reveal="word" />
<.response value={@streamed_markdown} format="markdown" streaming />
```

<!-- Sets aria-live="polite" and aria-busy="true" while streaming; Markdown is sanitized by default -->

```heex
<.activity>
  <:item status="complete">Searched documentation</:item>
  <:item status="running">Drafting answer</:item>
</.activity>
```

<!-- Uses an ordered list with a default aria-label; default status markers are decorative -->

## Focus Management

### Focus Trapping

Modal components manage focus according to their implementation:

- `dialog` moves focus to the first focusable element when opened and traps
  focus with `focus_wrap`.
- `command_dialog` uses the native `<dialog>` element and browser modal focus
  behavior.
- If your workflow needs explicit focus restoration to a trigger, handle that in
  the parent LiveView or with app-side JavaScript.

### Focus Indicators

Sutra-styled interactive components include visible focus indicators using the `--ring` CSS variable:

```css
:root {
  --ring: oklch(0.705 0.015 286.067);  /* Focus ring color */
}
```

Focus indicators should be:
- Visible when controls receive keyboard focus
- High contrast against backgrounds
- Consistent with the app theme

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
<.toast_container flash={@flash} />
<!-- Renders toast messages with status/live-region semantics -->

<.toast id="saved-toast">
  <:title>File saved successfully</:title>
</.toast>
<!-- Exposes role="status" and aria-live="polite" -->
```

### Semantic HTML

Sutra UI uses semantic HTML elements:

- `<button>` for buttons (not `<div>`)
- `<div role="dialog">` for modals (div-based for screen share compatibility)
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
- [ ] Error states are exposed to assistive technology
- [ ] Color is not the only means of conveying information
- [ ] Text has sufficient contrast (4.5:1 for normal, 3:1 for large)

## Common Accessibility Patterns

### Icon Buttons

Always provide an `aria-label`. Sutra UI does not provide a general icon helper;
these examples use inline SVG, but your application can use its own icon helper
if one exists.

```heex
<!-- Good -->
<.button size="icon" aria-label="Delete item">
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
</.button>

<!-- Bad - no accessible name -->
<.button size="icon">
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
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

Expose validation errors on inputs:

```heex
<.input
  field={@form[:password]}
  type="password"
  label="Password"
/>
```

With `field={@form[...]}`, `<.input>` reads errors from the Phoenix form field
and only displays them after `Phoenix.Component.used_input?/1` reports that the
field was used. When the input has an `id`, generated helper and error text are
linked through `aria-describedby`. For manual inputs, pass `errors={...}`
directly.

## Next Steps

- [Live Demo](https://sutraui.gurujada.com) - Browse accessible component examples
- [Components Cheatsheet](components.cheatmd) - All components with examples
- [Installation Guide](installation.md) - Setup instructions
- [Theming Guide](theming.md) - Customize your theme
