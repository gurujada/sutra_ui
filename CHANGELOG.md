# Changelog

All notable changes to Sutra UI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
