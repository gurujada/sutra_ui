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
| `Arrow Left/Right` | Move between tabs (client-only tabs activate as focus moves; URL `patch` tabs only move focus) |
| `Home` / `End` | First / last tab |
| `Enter` / `Space` | Activate the focused tab (URL `patch` tabs: manual activation, so arrowing never patches) |

`navigate` tabs are a `nav` of links: `Tab` moves between them and `Enter` follows one.

#### Dropdown Menu

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate menu items |
| `Enter` / `Space` | Activate item |
| `Escape` | Close menu |

#### Select

| Key | Action |
|-----|--------|
| `Arrow Up/Down` | Navigate options (also opens the list) |
| `Home` / `End`, `PageUp` / `PageDown` | First / last option, a page of options |
| `Enter` / `Space` | Open the list; select the active option |
| `Tab` | Select the active option and move on |
| `Escape` | Close the list |
| Letters (type-ahead) | Jump to the next option starting with what you type; repeated letters cycle |

#### Accordion

| Key | Action |
|-----|--------|
| `Enter` / `Space` | Toggle accordion panel |

#### Dialog

| Key | Action |
|-----|--------|
| `Escape` | Close dialog |
| `Tab` | Cycle through focusable elements (trapped) |

#### Command Palette and `command_dialog`

| Key | Action |
|-----|--------|
| `Mod + K` (configurable) | Open the palette |
| `Arrow Up/Down` | Navigate results |
| `Enter` | Run the active action |
| `Escape` | Back one step (page, argument, confirmation), then close |
| `?` | List the shortcuts |

Shortcuts such as `g h` are never typed into text fields. `command_dialog` is the same div-based
dialog without shortcuts, pages or server search; `Escape` closes it.

#### Date and time pickers

| Key | Action |
|-----|--------|
| Digits | Fill a segment and move to the next |
| `Arrow Up/Down` | Step the segment's value |
| `Arrow Left/Right` | Previous / next segment |
| `Backspace` | Clear the segment |
| In the calendar: arrows, `Page Up/Down`, `Home` / `End` | Day, month, week edges |
| `Escape` | Close the calendar |

#### Segmented and filter tabs

`segmented` is a radio group: arrows move and select, `Tab` leaves the group. `filter_tabs` items are
links or buttons in order: `Tab` moves between them.

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

#### URL tabs

```heex
<.tabs id="course" value={@tab} label="Course sections">
  <:tab value="overview" patch={~p"/courses/#{@id}/overview"}>Overview</:tab>
  <:tab value="notes" patch={~p"/courses/#{@id}/notes"}>Notes</:tab>
  <:panel value="overview">...</:panel>
  <:panel value="notes">...</:panel>
</.tabs>
```

- `patch` tabs use the tabs pattern with **manual activation**: arrows move focus, `Enter` or `Space`
  activates, so a screen-reader user arrowing past a tab does not load it. The active tab has
  `aria-selected="true"`, its panel is `role="tabpanel"` labelled by the tab, and while the server has
  not sent a panel it shows a loading bar with `loading_label` as a `role="status"` announcement.
- `navigate` tabs are a `<nav aria-label>` of links with `aria-current="page"` on the active one;
  they are navigation, not a tablist, because each tab is a page.
- One call cannot mix `patch` and `navigate` tabs: `tabs` raises an `ArgumentError`.
- The app sets `value` from `handle_params`, so reload and direct links land on the right tab.
- The active tab is more than colour: it is `aria-selected` or `aria-current` and underlined.

### Segmented and filter tabs

```heex
<.segmented id="view" label="View" value={@view} click="set_view">
  <:option value="list" label="List" />
  <:option value="grid" label="Grid" />
</.segmented>

<.filter_tabs id="inbox" label="Filter inbox">
  <:item label="All" count={42} active={@filter == "all"} patch={~p"/inbox"} />
  <:item label="Mine" count={3} active={@filter == "mine"} patch={~p"/inbox?filter=mine"} />
</.filter_tabs>
```

- `segmented` is a real radio group (`role="radiogroup"` named by `label`), so it posts in forms.
- `filter_tabs` items that are links carry `aria-current="page"` when active; items that are buttons
  carry `aria-pressed`. A count is read with the label ("Mine 3").

### Select

```heex
<.input type="select" field={@form[:role]} label="Role" options={@roles} prompt="Choose" />
```

- The trigger is a WAI-ARIA select-only combobox (an editable combobox with search) controlling a
  listbox; `aria-expanded`, `aria-activedescendant` and `aria-selected` follow the active option. A
  `<label for>` focuses the trigger.
- The real `<select>` stays in the form (posted value, no-JS) and is hidden from assistive technology.
- A required select that fails the browser's validation gets focus on the **trigger**, marked
  `aria-invalid` with the browser's message under it (`role="alert"`, linked by `aria-describedby`);
  the message goes away when a value is chosen. (The browser's own bubble would vanish as soon as
  focus left the hidden `<select>`.)
- Below 640 px the list is a bottom sheet with the label as its title and a Close button; rows are
  finger-sized and the search box takes focus only when tapped.

### Date and time pickers

```heex
<.date_picker id="due" name="due" label="Due date" />
<.date_range_picker id="range" name="range" label="Dates" />
<.datetime_picker id="at" name="at" label="Starts" zone="Asia/Kolkata" />
```

- The field is segments (day, month, year, hour, minute), each a spin button with its own name
  ("Day", "Month"), in the app's locale order; the browser's own `<input type="date">` is the posted
  field and the whole picker until the hook mounts.
- The calendar is a `role="dialog"` with a grid (`role="grid"`, `aria-label` the month). Today has
  `aria-current="date"`, and so do the **current month** in the month list and the **current year**
  in the year list (also bold and underlined, not colour alone). The chosen day is `aria-selected`
  (or `aria-pressed` in the month and year lists); disabled days (see `SutraUI.DateRules`) are
  `aria-disabled`.
- A range reads its length ("7 days") in a polite live region. A skipped time after a clock change
  is stated in words, never guessed; a repeated hour is a choice between two named offsets.
- Below 640 px the calendar is a bottom sheet with the label as title and a Close button.

### Command palette

```heex
<.command_palette id="palette" actions={@actions} />
```

- A `role="dialog"` named by `label`, containing a combobox over a listbox
  (`aria-activedescendant` follows the active action). Results are announced in a polite live
  region ("3 results"). A disabled action is `aria-disabled` and its reason describes it
  (`aria-describedby`); a danger action shows an icon and a word, not only a colour.
- Shortcut key caps are hidden from screen readers (the action's name is the content); a
  chevron on an action with children is decorative.
- Focus is trapped while it is open; when it closes, focus returns to what opened it (the dialog's job).

### Toasts

```heex
<.toast_group flash={@flash} live />
```

- `info` and `success` toasts are `role="status"` (polite); `warning` and `error` are
  `role="alert"` (assertive). The kind is an icon, a colour and a screen-reader word, never colour
  alone, and a toast has no title unless you pass one.
- The timer pauses on hover and focus, and toasts with an action or an error do not time out.
- A "Can't reach the server" notice is announced after a disconnect and goes on reconnect.
- Stacked toasts beyond three fold into a "+n more" line.

### Confirm dialog

```heex
<.confirm_dialog id="delete" title="Delete this course?" verb="Delete" tone="danger" event="delete">
  Its sections and results go with it.
</.confirm_dialog>
<.confirm_host />
```

- `role="alertdialog"`, named by its title and described by the consequence; the page behind is
  `inert`, focus is trapped, `Escape` means Keep.
- For a danger action focus starts on **Keep**, not on the destructive verb, and returns to the
  trigger when the dialog closes.
- `confirm_host` makes `data-confirm` use the same dialog instead of `window.confirm()`.

### Avatar presence

```heex
<.avatar initials="AR" status="online" />
<.avatar_group id="here" label="Online now" people={[%{name: "Asha", status: "away"}]} />
```

- The state is a dot **and** a screen-reader word ("online", "away", "offline"), so colour is
  never the only signal; the dot itself is `aria-hidden`.
- In an `avatar_group` the group's accessible name includes each status: "Online now: Asha (away)".

### Times

`relative_time` and `local_time` render a `<time datetime title>` with the final words in the
markup, so they read without JavaScript. The browser hook only refreshes the words and adds the
viewer's time; it does not announce changes.

### Badges and empty states

`badge` variants are a word plus colour (the `soft` and `dashed` appearances keep the text); an
`icon` slot is decorative. `empty` renders a heading-level title and its description; the inline
variant is one line of text with its action as a button.

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

Every modal is the div-based `dialog` (visible in a screen share), so they share one focus rule:

- Focus moves to the first focusable element, or to `initial_focus`, when it opens and is trapped
  with `focus_wrap`.
- Focus returns to what opened it on **every** hide (close button, `Escape`, backdrop, a server
  `show` change). This holds for `command_dialog`, `command_palette` and `confirm_dialog` too.
- `inert_page` (on for confirmations) makes the rest of the page inert while it is open.
- `alert` gives `role="alertdialog"`. An open dialog stays open when its parent LiveView re-renders.

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
<.toast_group flash={@flash} live />
<!-- Info and success: role="status", aria-live="polite". Warnings and errors:
     role="alert", aria-live="assertive". The kind is also a word and an icon. -->

<.toast id="saved-toast" kind="success">
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
