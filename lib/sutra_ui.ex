defmodule SutraUI do
  @moduledoc """
  Sutra UI - We define the rules, so you don't have to.

  A pure Phoenix LiveView UI component library with **44 accessible components**,
  CSS-first theming, and colocated JavaScript hooks. Built for Phoenix 1.8+ and
  Tailwind CSS v4.

  ## Quick Start

      # mix.exs
      {:sutra_ui, "~> 0.1"}

      # lib/my_app_web.ex
      defp html_helpers do
        quote do
          use SutraUI
        end
      end

      # assets/css/app.css
      @import "tailwindcss";
      @source "../../deps/sutra_ui/lib";
      @import "../../deps/sutra_ui/priv/static/sutra_ui.css";

  See the [Installation Guide](installation.md) for detailed setup instructions.

  ## Requirements

  | Dependency | Version | Notes |
  |------------|---------|-------|
  | Elixir | 1.14+ | |
  | Phoenix | **1.8+** | Required for colocated hooks |
  | Phoenix LiveView | **1.1+** | `ColocatedHook` support |
  | Tailwind CSS | **v4** | CSS-first configuration |

  > #### Why Phoenix 1.8+? {: .info}
  >
  > Sutra UI uses [colocated hooks](colocated-hooks.md) - JavaScript hooks defined
  > alongside components. No separate `hooks.js` file needed.

  ## Components by Category

  ### Foundation

  Basic building blocks for any interface.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Button` | Buttons with 6 variants and 4 sizes |
  | `SutraUI.Badge` | Status indicators |
  | `SutraUI.Spinner` | Loading indicators |
  | `SutraUI.Kbd` | Keyboard shortcut display |

  ### Form Controls

  Complete form toolkit with validation support.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Input` | Text, email, password, number, date inputs |
  | `SutraUI.Textarea` | Multi-line text input |
  | `SutraUI.Checkbox` | Checkbox input |
  | `SutraUI.Switch` | Toggle switch |
  | `SutraUI.RadioGroup` | Radio button groups |
  | `SutraUI.Select` | Searchable dropdown (hook) |
  | `SutraUI.Slider` | Range slider (hook) |
  | `SutraUI.RangeSlider` | Dual-handle range (hook) |
  | `SutraUI.LiveSelect` | Async searchable select (hook) |
  | `SutraUI.Field` | Field wrapper with label/error |
  | `SutraUI.Label` | Form labels |
  | `SutraUI.SimpleForm` | Form with auto-styling |
  | `SutraUI.InputGroup` | Input with prefix/suffix |
  | `SutraUI.FilterBar` | Filter controls layout |

  ### Layout

  Structure and organize content.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Card` | Content container |
  | `SutraUI.Header` | Page headers |
  | `SutraUI.Table` | Data tables |
  | `SutraUI.Item` | List items |
  | `SutraUI.Sidebar` | Navigation sidebar (hook) |

  ### Feedback

  Communicate status and progress.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Alert` | Alert messages |
  | `SutraUI.Toast` | Toast notifications (hook) |
  | `SutraUI.Progress` | Progress bars |
  | `SutraUI.Skeleton` | Loading placeholders |
  | `SutraUI.Empty` | Empty states |
  | `SutraUI.LoadingState` | Loading indicators |

  ### Overlay

  Layered UI elements.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Dialog` | Modal dialogs (hook) |
  | `SutraUI.Popover` | Click-triggered popups (hook) |
  | `SutraUI.Tooltip` | Hover tooltips (CSS-only) |
  | `SutraUI.DropdownMenu` | Dropdown menus (hook) |
  | `SutraUI.Command` | Command palette (hook) |

  ### Navigation

  Help users move through your app.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Tabs` | Tab panels (hook) |
  | `SutraUI.Accordion` | Collapsible sections (hook) |
  | `SutraUI.Breadcrumb` | Breadcrumb trails |
  | `SutraUI.Pagination` | Page navigation |
  | `SutraUI.NavPills` | Pill navigation |
  | `SutraUI.TabNav` | Tab-style navigation |

  ### Display

  Present content and media.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Avatar` | User avatars |
  | `SutraUI.Carousel` | Image carousels (hook) |
  | `SutraUI.ThemeSwitcher` | Light/dark toggle (hook) |

  ## Theming

  Sutra UI uses CSS variables compatible with [shadcn/ui themes](https://ui.shadcn.com/themes).

      :root {
        --primary: oklch(0.65 0.20 260);
        --primary-foreground: oklch(0.98 0 0);
      }

  See the [Theming Guide](theming.md) for complete customization options.

  ## Accessibility

  All components follow WAI-ARIA patterns with:

  - Semantic HTML elements
  - Keyboard navigation
  - Focus management
  - Screen reader support

  See the [Accessibility Guide](accessibility.md) for details.

  ## Guides

  - [Installation](installation.md) - Setup and configuration
  - [Theming](theming.md) - Customize colors and styles
  - [Accessibility](accessibility.md) - ARIA and keyboard support
  - [JavaScript Hooks](colocated-hooks.md) - Colocated hook patterns

  ## Quick Reference

  - [Components Cheatsheet](components.cheatmd) - All components at a glance
  - [Forms Cheatsheet](forms.cheatmd) - Form patterns and validation
  """

  @doc """
  Use Sutra UI in your Phoenix application.

  This macro imports all available Sutra UI components for use in your templates.

  ## Example

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use SutraUI
          end
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      # Phase 1: Foundation
      import SutraUI.Button
      import SutraUI.Badge
      import SutraUI.Spinner
      import SutraUI.Kbd

      # Phase 2: Form Primitives
      import SutraUI.Label
      import SutraUI.Input
      import SutraUI.Textarea
      import SutraUI.Checkbox
      import SutraUI.Switch
      import SutraUI.RadioGroup
      import SutraUI.Field
      import SutraUI.Select
      import SutraUI.Slider

      # Phase 3: Layout & Data Display
      import SutraUI.Card
      import SutraUI.Header
      import SutraUI.Table
      import SutraUI.Skeleton
      import SutraUI.Empty
      import SutraUI.Alert
      import SutraUI.Flash
      import SutraUI.Progress

      # Phase 4: Navigation & Interactive
      import SutraUI.Breadcrumb
      import SutraUI.Pagination
      import SutraUI.Accordion
      import SutraUI.Tabs
      import SutraUI.DropdownMenu
      import SutraUI.Toast

      # Phase 5: Advanced UI
      import SutraUI.Avatar
      import SutraUI.Tooltip
      import SutraUI.Dialog
      import SutraUI.Popover
      import SutraUI.Command
      import SutraUI.Carousel

      # Phase 6: Form & Layout Helpers
      import SutraUI.FilterBar
      import SutraUI.InputGroup
      import SutraUI.Item
      import SutraUI.LoadingState
      import SutraUI.SimpleForm

      # Phase 7: Navigation
      import SutraUI.NavPills
      import SutraUI.Sidebar
      import SutraUI.TabNav
      import SutraUI.ThemeSwitcher

      # Phase 8: Advanced Form Controls
      import SutraUI.RangeSlider
      # LiveSelect is a LiveComponent - only import helper functions, not lifecycle callbacks
      import SutraUI.LiveSelect, only: [decode: 1, normalize_options: 1]
    end
  end
end
