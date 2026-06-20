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

## Closed

- None yet.
