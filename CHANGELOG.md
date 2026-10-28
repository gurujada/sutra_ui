# Changelog

All notable changes to Sutra UI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **assets**: Widgets with real logic are one source module in `assets/js/<widget>/` with `node --test` tests, built (esbuild, maintainers only: `mix assets.build`) into the committed `priv/static/<widget>.js` and exported by a root `package.json`. An app's esbuild resolves `import {X} from "sutra_ui/<widget>"` through `deps` in `NODE_PATH`; a test fails when a built file is older than its source. See the JavaScript Hooks guide
- **time**: `relative_time` and `local_time` (see `SutraUI.Time`), and `SutraUI.Time.format/3` with the named formats `:date`, `:short`, `:long`, `:day`, `:time`, `:date_time`, `:day_time`, `:full`, `:month`. Times show in the place's zone on a 24-hour clock ("Mon 5 Oct, 14:30 IST"); the server renders final English words in `<time datetime title>`; `relative_time` takes `length` (`:long` or `:short`); an extracted hook (`sutra_ui/time`) refreshes relative words from one shared page timer and adds the viewer's time when the browser's zone differs. No time zone database is bundled: the app configures one (`tz`), and a missing one raises an error naming the config
- **badge**: Variants `info`, `warning`, `brand` and `ai` on new theme tokens (`--info`, `--warning`, `--brand`, `--ai`, each with a `-foreground`, light and dark); `appearance` `solid` (default), `soft` and `dashed` for every variant; an `icon` slot. `data-variant` and `data-style` are rendered
- **dialog**: `placement` `center` (default), `side` (docked right and full height from 768 px, a bottom sheet below; `size` `md`/`lg`/`xl` sets its width), `sheet` (bottom sheet on phones, centred card above) and `popover` (a card hanging under its `anchor`, or the trigger that opened it, from 640 px; a bottom sheet below). Still div-based; the popover's top is set through the CSSOM (`--popover-top`), never a `style` attribute
- **avatar**: `avatar_group/1`, a stack with "+n" beyond `max`, faces parted by a background-colour ring; one `role="group"` named by `label` and every name, and each face shows its name as a tooltip
- **empty**: `variant="inline"` (one quiet line), the inner block as the one description line, an `action` slot (beside `actions`), `data-variant`, and no description or action markup when none is given
- **tabs**: `segmented/1` (a single choice out of two to six, a real radio group for forms or a standalone `click`) and `filter_tabs/1` ("All · Mine · Waiting" with counts; links with `aria-current` or buttons with `aria-pressed`)
- **popover, dropdown_menu**: An open card flips to the other side or shifts to stay inside the viewport (a dropdown opened near the right edge at 390 px wide ran off-screen), and caps its width to the viewport. Positions are set through the CSSOM, never a `style` attribute
- **command palette**: `SutraUI.Commands` (behaviour: `actions/1` read per socket, `sources/0`, `search/3`), `SutraUI.Commands.Action`, `SutraUI.Commands.Live` (an `on_mount` hook and the palette's events), `SutraUI.Commands.Palette` (`command_palette/1`, `show_palette/2`, `hide_palette/2`), `SutraUI.Commands.Match` and `SutraUI.Commands.Test`. The palette is a div-based `dialog` (visible in a screen share) with the look of `command`: a combobox over a listbox, opened with `mod+k` (configurable) or a button, with arrows, Enter, Escape (back one step, then close), focus trapped and returned, and results announced. Actions are one of navigate, patch, href, push event, JS command, copy or a server function; they can have a danger tone, a `disabled` reason, `confirm`, `children` (pages) or `args` (choice, server search or text, asked in turn). Server actions are looked up again by id, `allow` is checked again and arguments are validated before they run. Search runs in the browser for actions (words in order, starts of words first, one typo in a word of five letters or more, accents and case ignored) and the same rules in Elixir (`Match`, checked against shared fixtures); server sources answer under their own headings from a task, and an older answer never covers a newer one. Shortcuts are chords and sequences (`mod+k`, `g h`), never typed into text fields, and `?` lists them; recent actions are kept in `localStorage`. Telemetry `[:sutra_ui, :commands, :search | :run]`. The browser module is `sutra_ui/commands` (extracted hook, bundled by your esbuild)

### Changed

- **command_dialog**: Now a div-based `SutraUI.Dialog` (it was a native `<dialog>`, invisible in some screen shares): the root element is a `div` with `role="dialog"`, it takes `show`, opens and closes with `show_command_dialog/2` and `hide_command_dialog/2` as before, and the `.CommandDialog` hook is gone. Its CSS is now `.dialog-panel.command-dialog`; styles that targeted the native `dialog.command-dialog` must move. Apps that want shortcuts, pages or server search use `command_palette` instead; the inline `command` is unchanged

## [0.4.1] - 2026-10-28

### Added

- **theme_switcher**: `theme_script/1` renders the pre-paint theme script for the root layout, with an optional `nonce`
- **csp**: Every component that renders a runtime hook script accepts a `nonce` attribute, so apps can use a nonce-based `script-src` instead of `'unsafe-inline'`
- **csp**: No component renders a `style=` attribute any more (except the deprecated CSS-length form of skeleton and carousel `width`/`height`/`gap`), so `style-src 'self'` works when those take classes. Run-time percentages (progress, slider, range slider, upload progress) render `data-pct` / `data-pct-start` / `data-pct-width` (integers 0-100) that the stylesheet maps to custom properties
- **dropdown_menu**: `chevron` attribute (default `true`); `chevron={false}` omits the chevron for icon-only triggers, and an `sr-only` label beside an icon hides it in CSS
- **avatar**: With an `id`, the image-failed fallback runs from a nonce-able hook instead of an inline `onerror` handler

### Changed

- **flash**: The message renders in a `div` (was a `<p>`), so block content is valid; it keeps normal text flow, and icons such as the reconnect spinner sit inline on the text line
- **flash**: Only the close button dismisses; clicking elsewhere on the message (selecting text, following a link) no longer does
- **skeleton, carousel**: `width`, `height` and `gap` take Tailwind classes (`w-48`, `h-72`, `gap-4`). A CSS length (digits plus a unit, or `auto`, e.g. `200px`) still renders as an inline style as before, but that form is **deprecated and goes away in 0.5**; apps that want `style-src 'self'` should pass classes
- **accordion**: Closed panels use the `hidden` class instead of an inline `display: none`
- **popover**: The trigger swaps its closed and open content by `aria-expanded` in CSS instead of toggling inline styles
- **slider, range_slider, progress, file_upload**: Positions and widths come from `data-pct` instead of inline styles (rounded to whole percents until the hook refines them)

### Fixed

- **popover, dropdown_menu**: A closed popover or menu takes no room (`display: none`, with `allow-discrete` and `@starting-style` keeping the animation); closed ones no longer widened phone pages near the right edge
- **dialog**: A dialog taller than the screen scrolls inside the screen; the focus wrap now fills the dialog and the panel keeps its natural width up to its max width
- **button**: Declares `popovertarget`, `popovertargetaction`, `formaction`, `formenctype`, `formmethod`, `formnovalidate`, `formtarget`, `command` and `commandfor` as global attributes, so they pass without compile warnings

## [0.4.0] - 2026-07-04

### Added

- **components**: Added separator, marquee, stepper wizard, hover card, calendar, input OTP, timeline, file upload, context menu, tree view, response, and activity primitives
- **ai**: Added streamed response rendering with text and Markdown reveal modes, plus slot-owned activity rows for user-facing agent progress
- **tests**: Added regression coverage for installer injection, form error visibility, slider styling, and global LiveView button attrs

### Changed

- **docs**: Updated installation, demo copy, component counts, and release-facing examples for `0.4.0`
- **installer**: Preserves web module indentation when inserting `use SutraUI` into `html_helpers`
- **tab_nav**: Uses routed navigation semantics with `aria-current` instead of ARIA tab panel semantics
- **tab_nav**: Owns the former Nav Pills responsive dropdown behavior; it collapses on small screens by default and supports `collapse="never"`

### Removed

- **nav_pills**: Removed the separate `SutraUI.NavPills` component for the major release. Use `SutraUI.TabNav` for routed pill/tab navigation.

### Fixed

- **slider**: Styled standalone sliders through the emitted `.slider` class so they use Sutra UI theme colors instead of browser accent defaults
- **slider**: Normalizes invalid nonpositive `step` values to avoid render-time crashes
- **textarea**: Removed content-based field sizing so the documented `rows` attribute controls the initial height
- **input**: Documented and covered `Phoenix.Component.used_input?/1` behavior so field errors stay hidden until the field is used
- **docs**: Removed stale migration and app-specific scratch markdown that no longer reflected this library

## [0.3.0] - 2026-03-06

### Added

- **drawer**: New `SutraUI.Drawer` component API with `drawer/1`, `drawer_trigger/1`, `drawer_group/1`, `drawer_item/1`, `drawer_submenu/1`, and `drawer_separator/1`
- **input**: New `description` attribute with automatic `aria-describedby` linking across input types
- **install**: New `mix sutra_ui.install` task for CSS setup and `use SutraUI` insertion in `html_helpers`

### Changed

- **docs**: Updated installation flow, cheatsheets, and guides to reflect runtime hooks, unified input patterns, and current APIs
- **live_select**: Updated form integration to structured field payloads (single uses `[value]`, tags use `[id][]`) while preserving backward-compatible decoding
- **component naming**: Sidebar terminology updated to Drawer across library docs, tests, and references

### Breaking Changes

- **sidebar -> drawer**: `SutraUI.Sidebar` and all `sidebar_*` functions were renamed to `SutraUI.Drawer` and `drawer_*`
- **field removed**: `SutraUI.Field` was removed; use unified `SutraUI.Input` with `label`, `description`, and `errors` instead

### Fixed

- **install task**: Corrected `html_helpers` injection matching to avoid inserting `use SutraUI` into `verified_routes`
- **demo/docs parity**: Resolved stale examples for `tab_nav`, form snippets, and LiveSelect event/update patterns

## [0.2.0] - 2026-01-06

### Added

- **input**: Support for `type="switch"` - renders checkbox with `role="switch"` and proper styling
- **input**: Support for `type="range"` - delegates to Slider component with visual fill
- **tab_nav**: Full ARIA tablist pattern with `role="tablist"`, `role="tab"`, `aria-selected`
- **tab_nav**: Keyboard navigation (ArrowLeft/Right, Home, End) with roving tabindex
- **tooltip**: `aria-describedby` linking between trigger and tooltip content
- **tooltip**: `role="tooltip"` on tooltip content element
- **tooltip**: Escape key dismisses tooltip
- **carousel**: `aria-live="polite"` region announces slide changes to screen readers
- **breadcrumb**: Visible focus styles with `focus-visible:ring`

### Changed

- **dialog**: Converted from native `<dialog>` element to div-based overlay for screen sharing compatibility (Zoom, Meet, etc.)
- **dialog**: Now uses `show` attribute for server-controlled visibility (recommended pattern)
- **dialog**: Uses `focus_wrap` from Phoenix.Component for focus management
- **input**: Delegates `type="checkbox"` to `SutraUI.Checkbox`
- **input**: Delegates `type="textarea"` to `SutraUI.Textarea`
- **input**: Delegates `type="switch"` to `SutraUI.Switch`
- **input**: Delegates `type="range"` to `SutraUI.Slider`
- **tooltip**: Changed from CSS `::before` pseudo-element to real `<span role="tooltip">` element

### Breaking Changes

- **dialog**: API changed - use `show={@show_dialog}` and `on_cancel="event"` pattern instead of JS-only control
- **tab_nav**: Now requires `id` attribute (needed for keyboard navigation hook)
- **tooltip**: CSS selector changed from `[data-tooltip]` to `.tooltip-trigger .tooltip-content`

### Fixed

- **dialog**: Now visible during screen sharing (native `<dialog>` top-layer was invisible in Zoom/Meet)
- **tab_nav**: Now properly accessible with screen readers (was missing tablist semantics)
- **tooltip**: Screen readers now announce tooltip content via `aria-describedby`
- **carousel**: Screen readers now announce slide changes
- **breadcrumb**: Keyboard users can now see focus indicator on links

## [0.1.0]

### Added

- Initial release with 43 components
- **Foundation**: button, badge, spinner, kbd
- **Form Controls**: input, textarea, checkbox, switch, radio_group, select, slider, range_slider, live_select, field, simple_form, input_group, filter_bar, label
- **Layout**: card, header, table, item, sidebar
- **Feedback**: alert, progress, skeleton, empty, loading_state, toast, flash
- **Overlay**: dialog, popover, tooltip, dropdown_menu, command
- **Navigation**: tabs, accordion, breadcrumb, pagination, tab_nav
- **Display**: avatar, carousel, theme_switcher
- CSS variables for theme customization (compatible with shadcn/ui themes)
- Dark mode support
- Colocated JavaScript hooks
- Full accessibility (ARIA) support
- Tailwind CSS v4 compatibility
- Zero external icon dependencies - components use inline SVGs
- `usage_rules.md` for AI assistant guidance
