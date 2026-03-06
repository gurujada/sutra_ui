# Changelog

All notable changes to Sutra UI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **Navigation**: tabs, accordion, breadcrumb, pagination, nav_pills, tab_nav
- **Display**: avatar, carousel, theme_switcher
- CSS variables for theme customization (compatible with shadcn/ui themes)
- Dark mode support
- Colocated JavaScript hooks
- Full accessibility (ARIA) support
- Tailwind CSS v4 compatibility
- Zero external icon dependencies - components use inline SVGs
- `usage_rules.md` for AI assistant guidance
