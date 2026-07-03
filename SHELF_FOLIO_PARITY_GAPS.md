# Shelf Folio Parity Gaps

This file tracks Sutra UI gaps found while migrating Shelf's `folio-ui` reference
screens into Phoenix LiveView with exact visual parity.

## Open

- `SutraUI.Button` only allows a small fixed set of `phx-value-*` attributes in
  its global rest attributes. Shelf screens need values such as
  `phx-value-key`, `phx-value-page`, `phx-value-status`, `phx-value-flag`, and
  `phx-value-doc_id` to preserve event contracts without renaming params.
  Current workaround: normalize those events to `phx-value-id` in LiveViews.
- Folio helper visuals need tokenized size/color variants for file thumbnails,
  progress bars, legend dots, and work icons. Inline `style` strings preserve
  arbitrary values but make parity hard to audit. Current workaround: Shelf maps
  the known Folio palette values to CSS classes and ignores arbitrary values.
- Several Folio screens use compact icon buttons, segmented buttons, radios,
  switches, file inputs, and table-row actions with existing Folio classes.
  Sutra has base button/input primitives, but not a direct Folio-compatible
  segmented-control/file-upload/table-action API yet. Current workaround: keep
  native controls where replacing them would change event contracts or visual
  parity, while moving styling into CSS classes and using Sutra where it already
  fits.
- Dependency colocated hooks are not consistently generated for all Sutra
  components used by Shelf. `command` renders `phx-hook="SutraUI.Command.Command"`
  and `theme_switcher` renders `phx-hook="SutraUI.ThemeSwitcher.ThemeSwitcher"`,
  but the generated `phoenix-colocated/sutra_ui` bundle only exported the dialog
  hook during Shelf verification. Current workaround: Shelf registers explicit
  hook objects for those two exact hook names in `assets/js/app.js`.
- `SutraUI.Input` wraps `type="color"` in `.fieldset` markup, which cannot be
  nested invisibly inside Folio's compact swatch + hex + "Change" label without
  leaving visible browser color-input artifacts. Current workaround: use a
  native color input only for that hidden control while keeping the surrounding
  row backend-backed and styled by Folio CSS.

## Closed

- None yet.
