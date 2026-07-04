---
name: sutra-ui
description: Use when building, modifying, or reviewing Phoenix LiveView UI with Sutra UI components, including forms, validation, overlays, calendars, steppers, timelines, file uploads, menus, AI response/activity surfaces, theming, and component composition. Use this to avoid hallucinated Sutra APIs and preserve Sutra UI's Phoenix-native, CSS-first, no-external-JS design philosophy.
---

# Sutra UI

Sutra UI is a Phoenix LiveView component library inspired by shadcn/ui. It is
CSS-first, uses Phoenix patterns, and avoids external JavaScript/npm dependencies.

## Public Surface

Use these from application code:

- `use SutraUI` in the Phoenix web module's `html_helpers`.
- Render components as function components such as `<.button>`, `<.input>`,
  `<.popover>`, `<.calendar>`, `<.activity>`, and `<.response>`.
- Pass Phoenix globals (`phx-*`, `data-*`, `aria-*`) through component attrs.
- Use documented slots for custom content instead of inventing many narrow attrs.
- Use exposed JS helper functions only when the component module documents them.

Do not use these from application code:

- Do not call private helpers or internal CSS/JS implementation details.
- Do not invent attrs such as `on_click`, `completed`, `content_class`, or
  framework-style callback props unless the component module documents them.
- Do not add React, npm packages, Alpine, Stimulus, or third-party JS widgets.
- Do not replace Phoenix form validation, uploads, navigation, or events with
  client-side state machines.

For exact attrs, slots, or event names, inspect the component module in
`lib/sutra_ui/*.ex`. This skill teaches Sutra's composition model; source code
is the API authority.

## Load The Relevant Reference

- For exact copy-paste component examples, read `cheatsheets/components.cheatmd`.
- For forms, changesets, validation, uploads, and selection controls, read
  `cheatsheets/forms.cheatmd`.
- For component philosophy, forms, hook behavior, CSS rules, and API selection,
  read `skill/patterns.md`.
- For common UI compositions, including popover + calendar, wizard forms,
  activity feeds, uploads, menus, and AI surfaces, read `skill/recipes.md`.
- For editing Sutra UI internals or adding components, read `usage_rules.md`.

When building a full interface, start from the recipes and component
cheatsheet, then inspect the relevant modules for exact attrs and slots before
writing HEEx.

## Core Rules

- Compose atomic primitives. Prefer a small Sutra component plus slots over a
  large custom wrapper with many attrs.
- Keep app state in the parent LiveView. Sutra components render and emit normal
  Phoenix events; they do not own business workflows.
- Use `field={@form[:name]}` for Phoenix form fields. Sutra `input/1` reads
  `id`, `name`, `value`, and touched-field errors from the form field.
- Use `Phoenix.Component.used_input?/1` behavior for live validation. Do not
  show all empty-field errors just because one field was edited.
- Use native inputs for native jobs. `<.input type="date">` is the browser date
  input; `<.calendar>` is a composable calendar grid for custom date flows.
- Hook-based components need stable ids. Do not auto-generate changing ids.
- In Sutra library source, component styling belongs in `priv/static/sutra_ui.css`
  with semantic classes. In application templates, use `class` for layout and
  local composition, but do not rewrite component internals with utility soup.
- Sutra UI does not export a general icon component or icon set. Use the host
  app's existing icon helper when present, otherwise use inline accessible SVG.
  Do not invent `SutraUI.Icon` or assume the demo app's `<.icon>` helper exists
  in user applications.
- For AI interfaces, show safe user-facing progress. Do not render private
  reasoning; use `activity/1` for visible steps and `response/1` for streamed
  text or Markdown.

## Component Map

- Foundation: `button`, `badge`, `spinner`, `kbd`
- Forms: `input`, `textarea`, `checkbox`, `switch`, `radio_group`, `select`,
  `slider`, `range_slider`, `live_select` (LiveComponent), `input_otp`, `file_upload`,
  `simple_form`, `input_group`, `filter_bar`, `label`
- Layout/data: `card`, `header`, `table`, `item`, `separator`, `marquee`,
  `calendar`, `timeline`, `tree_view`, `stepper`, `stepper_wizard`, `drawer`
- Feedback: `alert`, `flash`, `progress`, `skeleton`, `empty`,
  `loading_state`, `toast`
- Overlays/actions: `dialog`, `popover`, `tooltip`, `hover_card`,
  `dropdown_menu`, `context_menu`, `command`
- Navigation: `tabs`, `accordion`, `breadcrumb`, `pagination`, `tab_nav`
- Display: `avatar`, `carousel`, `theme_switcher`
- AI: `response`, `activity`

## Minimal Form Shape

```heex
<.form for={@form} phx-change="validate" phx-submit="save" class="form">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:password]} type="password" label="Password" />
  <.button type="submit">Save</.button>
</.form>
```

```elixir
def handle_event("validate", %{"user" => params}, socket) do
  changeset =
    %User{}
    |> Accounts.change_user(params)
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end
```

## Common Mistakes

- Passing a callback prop when Phoenix should use `phx-click`, `phx-change`,
  `phx-submit`, `JS`, or parent LiveView state.
- Using `calendar/1` as a drop-in replacement for `<input type="date">`.
- Building a separate date picker component before composing `popover/1`,
  `calendar/1`, and a parent LiveView.
- Showing all form errors immediately instead of respecting touched input state.
- Treating `activity/1` as private reasoning output instead of safe progress.
- Hiding custom content behind rigid attrs when a slot would be simpler.
- Copying demo-specific layout or marketing copy into reusable app components.
