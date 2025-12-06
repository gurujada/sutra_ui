# PhxUI Migration Tracker

## Overview

Migrating atomic UI components from `gurujada/lib/gurujada_web/components/ui/` to this library.

**Source**: `/home/virinchi/code/elixir-phoenix/gurujada/lib/gurujada_web/components/ui/`
**Target**: `/home/virinchi/code/elixir-phoenix/phx_ui/lib/phx_ui/`

## Principles

- Pure LiveView, no external JS dependencies
- Colocated hooks using `Phoenix.LiveView.ColocatedHook`
- Tailwind CSS only (no custom CSS files, shadcn/ui inspired)
- WCAG 2.1 AA accessible
- 100% test coverage per component
- Tests focus on behavior, not brittle class assertions

---

## Migration Workflow (Per Component)

```
1. ANALYZE
   - Read source component
   - Identify dependencies (other UI components)
   - Identify hooks (ColocatedHook scripts)
   - Document ARIA/accessibility patterns

2. MIGRATE
   - Create lib/phx_ui/{component}.ex
   - Adapt module name (GurujadaWeb.Components.X -> PhxUI.X)
   - Port colocated hooks (if any)
   - Update internal imports
   - Use inline Tailwind classes (shadcn style)

3. TEST
   - Create test/phx_ui/{component}_test.exs
   - Unit tests (render, attributes, slots)
   - Accessibility assertions
   - Behavior-focused (not class-brittle)

4. VERIFY (Quality Gate)
   - [ ] All tests pass
   - [ ] Accessibility checklist complete
   - [ ] Compiles without warnings
```

---

## Component Checklist

### Phase 1: Foundation (Zero Dependencies) ✅ COMPLETE

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| icon | icon.ex | [x] | [x] 8 tests | [x] |
| button | button.ex | [x] | [x] 25 tests | [x] |
| badge | badge.ex | [x] | [x] 9 tests | [x] |
| spinner | spinner.ex | [x] | [x] 16 tests | [x] |
| kbd | kbd.ex | [x] | [x] 7 tests | [x] |

**Total: 65 tests passing**

### Phase 2: Form Primitives ✅ COMPLETE

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| label | label.ex | [x] | [x] 8 tests | [x] |
| input | input.ex | [x] | [x] 29 tests | [x] |
| textarea | textarea.ex | [x] | [x] 18 tests | [x] |
| checkbox | checkbox.ex | [x] | [x] 14 tests | [x] |
| switch | switch.ex | [x] | [x] 15 tests | [x] |
| radio_group | radio_group.ex | [x] | [x] 21 tests | [x] |
| field | field.ex | [x] | [x] 18 tests | [x] |
| select | select.ex (has hook) | [x] | [x] 19 tests | [x] |
| slider | slider.ex (has hook) | [x] | [x] 20 tests | [x] |

**Total: 227 tests passing (65 Phase 1 + 162 Phase 2)**

### Phase 3: Layout Components

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| card | card.ex | [ ] | [ ] | [ ] |
| header | header.ex | [ ] | [ ] | [ ] |
| table | table.ex | [ ] | [ ] | [ ] |
| skeleton | skeleton.ex | [ ] | [ ] | [ ] |
| empty | empty.ex | [ ] | [ ] | [ ] |

### Phase 4: Feedback Components

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| alert | alert.ex | [ ] | [ ] | [ ] |
| progress | progress.ex | [ ] | [ ] | [ ] |
| toast | toast.ex | [ ] | [ ] | [ ] |
| loading_state | loading_state.ex | [ ] | [ ] | [ ] |

### Phase 5: Navigation Components

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| breadcrumb | breadcrumb.ex | [ ] | [ ] | [ ] |
| pagination | pagination.ex | [ ] | [ ] | [ ] |
| nav_pills | nav_pills.ex | [ ] | [ ] | [ ] |

### Phase 6: Interactive Components

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| accordion | accordion.ex | [ ] | [ ] | [ ] |
| tabs | tabs.ex (has hook) | [ ] | [ ] | [ ] |
| tab_nav | tab_nav.ex | [ ] | [ ] | [ ] |
| dropdown_menu | dropdown_menu.ex (has hook) | [ ] | [ ] | [ ] |
| command | command.ex (has hook) | [ ] | [ ] | [ ] |
| carousel | carousel.ex (has hook) | [ ] | [ ] | [ ] |

### Phase 7: Overlay Components

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| tooltip | tooltip.ex | [ ] | [ ] | [ ] |
| popover | popover.ex (has hook) | [ ] | [ ] | [ ] |
| dialog | dialog.ex (has hook) | [ ] | [ ] | [ ] |

### Phase 8: Data Display

| Component | Source File | Migrated | Tests | A11y |
|-----------|-------------|----------|-------|------|
| avatar | avatar.ex | [ ] | [ ] | [ ] |

---

## Skipped Components (Not Generic UI)

These are gurujada-specific, not migrating:
- `org_logo.ex` - Domain specific
- `entity_card.ex` - Domain specific
- `dashboard_section.ex` - Domain specific
- `item.ex` - Domain specific
- `filter_bar.ex` - Domain specific
- `form_input.ex` - Wrapper, use field instead
- `input_group.ex` - Can be done with field
- `simple_form.ex` - App-specific form wrapper
- `theme_switcher.ex` - App-specific

---

## Accessibility Checklist (Per Component)

```
[ ] Keyboard Navigation
    [ ] All interactive elements focusable
    [ ] Tab order logical
    [ ] Enter/Space activates buttons
    [ ] Escape closes overlays
    [ ] Arrow keys for lists/menus

[ ] ARIA Attributes
    [ ] Proper roles
    [ ] aria-label for icon-only elements
    [ ] aria-expanded for expandable content
    [ ] aria-selected for selections
    [ ] aria-disabled for disabled states

[ ] Screen Reader
    [ ] Meaningful announcements
    [ ] Hidden decorative elements (aria-hidden)

[ ] Visual
    [ ] Focus indicators visible
    [ ] Touch targets 44x44px minimum
```

---

## Progress Log

### 2024-XX-XX - Library Created

- [x] Created mix project with `mix new phx_ui`
- [x] Configured mix.exs with dependencies (phoenix_live_view, phoenix_html, ex_doc, floki)
- [x] Created main module `lib/phx_ui.ex` with `use PhxUI` macro
- [x] Created test helper `test/support/component_case.ex`
- [x] Created README.md and LICENSE
- [x] Verified compilation works

### 2024-XX-XX - Phase 1 Complete

- [x] Migrated `icon` component (8 tests)
  - Decorative icons have aria-hidden="true"
  - Meaningful icons with aria-label don't have aria-hidden
  - Passes through title, role attributes
  
- [x] Migrated `button` component (25 tests)
  - All variants: primary, secondary, destructive, outline, ghost, link
  - All sizes: default, sm, lg, icon
  - Navigation: navigate, patch, href
  - States: disabled, loading (aria-busy)
  - Full ARIA support
  
- [x] Migrated `badge` component (9 tests)
  - All variants: default, secondary, destructive, outline
  - Renders as span or anchor (with href)
  - ARIA support
  
- [x] Migrated `spinner` component (16 tests)
  - All sizes: sm, default, lg, xl
  - role="status" with aria-label
  - sr-only text for screen readers
  - Optional visible text slot
  - spinner_icon/1 for tight spaces
  
- [x] Migrated `kbd` component (7 tests)
  - Semantic <kbd> element
  - Passes through id, title

**Next**: Phase 2 - Form Primitives (label, input, textarea, checkbox, switch, radio_group, field, select, slider)

### 2024-XX-XX - Phase 2 Complete

- [x] Migrated `label` component (8 tests)
  - Semantic <label> element
  - for attribute association
  - Works as wrapper or standalone

- [x] Migrated `input` component (29 tests)
  - All input types: text, email, password, number, file, tel, url, search, date, etc.
  - Phoenix form field integration
  - Full ARIA support (aria-label, aria-describedby, aria-invalid, aria-required)
  - Constraints: min, max, step, pattern, minlength, maxlength

- [x] Migrated `textarea` component (18 tests)
  - Multi-line text input
  - Phoenix form field integration
  - ARIA support for error states
  - rows attribute for height

- [x] Migrated `checkbox` component (14 tests)
  - Native checkbox input
  - checked, disabled states
  - ARIA support for validation

- [x] Migrated `switch` component (15 tests)
  - Checkbox with role="switch"
  - aria-checked for state
  - Full accessibility support

- [x] Migrated `radio_group` component (21 tests)
  - radio_group/1 for grouped radios with fieldset
  - radio/1 for standalone radios
  - Error handling and display
  - Required and disabled states
  - ARIA: aria-invalid, aria-describedby, aria-labelledby

- [x] Migrated `field` component (18 tests)
  - field/1 for form field container
  - fieldset/1 for grouping fields
  - Slots: label, input, description, error, section
  - Vertical and horizontal orientations
  - role="group" for accessibility

- [x] Migrated `select` component (19 tests)
  - Custom dropdown select
  - Searchable option with combobox
  - Groups and separators
  - PhxUISelect hook for keyboard navigation
  - ARIA: aria-haspopup, aria-expanded, aria-controls, aria-labelledby

- [x] Migrated `slider` component (20 tests)
  - Native range input with custom styling
  - PhxUISlider hook for visual progress
  - ARIA: aria-valuemin, aria-valuemax, aria-valuenow, aria-valuetext
  - Keyboard accessible (native behavior)

**Next**: Phase 3 - Layout Components (card, header, table, skeleton, empty)

---

## Commands

```bash
# Run tests
cd /home/virinchi/code/elixir-phoenix/phx_ui
mix test

# Run specific test
mix test test/phx_ui/button_test.exs

# Format code
mix format

# Compile
mix compile
```

---

## File Locations

- **Source components**: `/home/virinchi/code/elixir-phoenix/gurujada/lib/gurujada_web/components/ui/`
- **Target components**: `/home/virinchi/code/elixir-phoenix/phx_ui/lib/phx_ui/`
- **Tests**: `/home/virinchi/code/elixir-phoenix/phx_ui/test/phx_ui/`
- **This file**: `/home/virinchi/code/elixir-phoenix/phx_ui/MIGRATION.md`
