# Sutra UI Patterns

Use this reference when choosing APIs, reviewing component usage, or deciding
how much state belongs in Sutra versus the parent LiveView.

## Source Of Truth

Inspect the component module before using exact attrs or events:

```bash
rg -n "attr\\(|slot\\(|def .*\\(assigns\\)" lib/sutra_ui/{component}.ex
```

Use demo pages for composition examples, but do not treat demo copy or layout as
library API.

## Composition Model

- Start with the smallest primitive that does the job.
- Prefer slot-owned markup for content-heavy components.
- Pass `class` for local layout or size overrides.
- Pass `phx-*`, `aria-*`, and `data-*` as globals when the component exposes
  `:rest`.
- Keep persistence, validation, navigation, and business rules in the parent
  LiveView.
- Use Sutra primitives for structure and behavior, then compose richer app UI
  with slots. For example: `card` + `header` + `table`, `popover` + `calendar`,
  `activity` + `response`, or `tab_nav` + route-backed LiveView state.

Good component shape:

```heex
<.timeline>
  <:item time="12 min ago">
    <div class="flex items-start gap-3">
      <.avatar initials="AM" />
      <p><strong>Alex</strong> created a project</p>
    </div>
  </:item>
</.timeline>
```

Avoid over-specific APIs that force `title`, `subtitle`, `avatar`, `marker`,
`action`, and similar attrs when the item content should just be a slot.

## Icons

Sutra UI does not provide a general icon helper or icon library. If the host
application already has `<.icon>` or Lucide configured, use that app helper.
Otherwise use inline SVG with `aria-hidden="true"` for decorative icons, or an
accessible label for icon-only controls.

Do not invent `SutraUI.Icon`, `icon_name`, or demo-only icon helpers in library
examples. Icon-only buttons must include `aria-label`.

## Forms And Validation

Use Phoenix forms and changesets. Sutra `input/1` accepts
`field={@form[:field]}` and automatically reads `id`, `name`, `value`, and
field errors.

`input/1` hides changeset errors until `Phoenix.Component.used_input?/1` says
the field has been used. This is the right behavior for live validation: typing
in the first field should not show every other empty field error.

Use:

```heex
<.form for={@form} class="form" phx-change="validate" phx-submit="save">
  <.input field={@form[:name]} label="Name" />
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:bio]} type="textarea" label="Bio" rows={4} />
  <.button type="submit">Save</.button>
</.form>
```

For manual errors without a form field, pass `errors={...}` explicitly.

## Native Inputs Versus Sutra Components

- Use `<.input type="date">`, `time`, or `datetime-local` for native browser
  controls and ordinary form submission.
- Use `<.calendar>` when the app needs a visible calendar grid, custom date
  selection, disabled dates, range selection, or composition inside another UI.
- Use `<.select>` for custom searchable/selectable UI. Use
  `<.input type="select">` for ordinary native form selects.
- Use `<.slider>` for single range input and `<.range_slider>` for dual-handle
  range selection.

## Hook-Based Components

Hook-based components need stable `id`s when the component requires one.
Runtime colocated hooks live with components and do not require npm packages.

Use Phoenix events and helpers instead of client framework callbacks:

```heex
<.button phx-click="archive" phx-value-id={@item.id}>Archive</.button>
```

Do not convert this to `on_click`, `onSelect`, `onOpenChange`, or similar
framework-style props unless the component module documents that attr.

## CSS And Theming

Sutra library source uses semantic CSS classes in `priv/static/sutra_ui.css`.
Do not move reusable component styling into HEEx utility strings.

Applications may still use `class` for layout:

```heex
<.card class="max-w-md">
  <:content>...</:content>
</.card>
```

Theme through CSS variables such as `--primary`, `--background`, `--border`,
and `--ring`. Do not hard-code one-off brand colors inside reusable Sutra
components.

## AI Primitives

`response/1` renders model output. It accepts plain text or Markdown, can mark
content as streaming, and can reveal text by chunk, word, character, or line.
The parent LiveView owns provider streaming and passes the current text.

`activity/1` renders safe progress rows. It is not a transcript of private
reasoning. Render steps like "Searching docs", "Reading files", or "Writing
summary", not hidden reasoning.

## Review Checklist

- Exact attrs and slots come from source modules, not memory.
- No invented component props.
- No invented icon helper or icon dependency.
- No external JS/npm dependency was added.
- Hook-based components have stable ids.
- Forms use Phoenix changesets and `used_input?/1` behavior.
- Component content is slot-owned when users need custom markup.
- Docs and demo snippets match rendered previews.
- Accessibility labels, roles, disabled states, and keyboard behavior are not
  removed while customizing UI.
