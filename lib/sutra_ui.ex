defmodule SutraUI do
  @moduledoc """
  Sutra UI - We define the rules, so you don't have to.

  A pure Phoenix LiveView UI component library with **55 components**,
  CSS-first theming, and colocated JavaScript hooks. Built for Phoenix 1.8+ and
  Phoenix LiveView 1.2+ with Tailwind CSS v4.

  ## Quick Start

      # mix.exs
      {:sutra_ui, "~> 0.4.1"}

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
  | Elixir | 1.20+ | Matches the package constraint |
  | Phoenix | **1.8+** | Required for colocated hooks |
  | Phoenix LiveView | **1.2+** | Current supported LiveView line |
  | Tailwind CSS | **v4** | CSS-first configuration |

  > #### Why Phoenix 1.8+? {: .info}
  >
  > Sutra UI uses [colocated hooks](colocated-hooks.md) - JavaScript hooks defined
  > alongside components. Runtime hooks need no app-side hook file; extracted
  > hooks such as `dialog` and animated `response` are merged into LiveSocket.

  ## Components by Category

  ### Foundation

  Basic building blocks for any interface.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Button` | Buttons with 6 variants and 4 sizes |
  | `SutraUI.Badge` | Status indicators |
  | `SutraUI.Spinner` | Loading indicators |
  | `SutraUI.Kbd` | Keyboard shortcut display |
  | `SutraUI.Time` | `relative_time` and `local_time`: one shown zone, a viewer hint, 24-hour clock (hook) |

  ### Form Controls

  Complete form toolkit with validation support.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Input` | Text, email, password, number, date inputs |
  | `SutraUI.Textarea` | Multi-line text input |
  | `SutraUI.Checkbox` | Checkbox input |
  | `SutraUI.Switch` | Toggle switch |
  | `SutraUI.RadioGroup` | Radio button groups |
  | `SutraUI.Select` | Form select: real `<select>` with a styled list, bottom sheet on phones (hook) |
  | `SutraUI.Slider` | Range slider (hook) |
  | `SutraUI.RangeSlider` | Dual-handle range (hook) |
  | `SutraUI.LiveSelect` | LiveComponent async searchable select (hook) |
  | `SutraUI.Label` | Form labels |
  | `SutraUI.SimpleForm` | Form with auto-styling |
  | `SutraUI.InputGroup` | Input with prefix/suffix |
  | `SutraUI.InputOTP` | One-time password inputs (hook) |
  | `SutraUI.FileUpload` | LiveView upload dropzone |
  | `SutraUI.FilterBar` | Filter controls layout (deprecated, removed in 0.6) |

  ### Layout

  Structure and organize content.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Card` | Content container |
  | `SutraUI.Header` | Page headers |
  | `SutraUI.Table` | Data tables |
  | `SutraUI.Item` | List items |
  | `SutraUI.Drawer` | Navigation drawer (hook) |
  | `SutraUI.Stepper` | Multi-step progress indicators |
  | `SutraUI.StepperWizard` | Multi-step wizard shell |
  | `SutraUI.TreeView` | Hierarchical navigation trees |

  ### Feedback

  Communicate status and progress.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Alert` | Alert messages |
  | `SutraUI.Flash` | Phoenix flash messages |
  | `SutraUI.Toast` | Toasts and flashes in one stack: `toast_group`, `Toast.send/3` (hook) |
  | `SutraUI.Progress` | Progress bars |
  | `SutraUI.Skeleton` | Loading placeholders |
  | `SutraUI.Empty` | Empty states |
  | `SutraUI.LoadingState` | Loading indicators |

  ### Overlay

  Layered UI elements.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Dialog` | Modal dialogs (hook) |
  | `SutraUI.Confirm` | Confirmation dialogs and a styled `data-confirm` (hook) |
  | `SutraUI.Popover` | Click-triggered popups (hook) |
  | `SutraUI.Tooltip` | Hover and focus tooltips (hook) |
  | `SutraUI.DropdownMenu` | Dropdown menus (hook) |
  | `SutraUI.ContextMenu` | Right-click action menus (hook) |
  | `SutraUI.HoverCard` | Hover preview cards (hook) |
  | `SutraUI.Command` | Command menu and dialog (hook) |
  | `SutraUI.Commands.Palette` | Command palette with shortcuts and server search (`command_palette`) |

  ### Navigation

  Help users move through your app.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Tabs` | Tab panels (hook) |
  | `SutraUI.Accordion` | Collapsible sections |
  | `SutraUI.Breadcrumb` | Breadcrumb trails |
  | `SutraUI.Pagination` | Page navigation |
  | `SutraUI.TabNav` | Routed tab-style navigation |

  ### Display

  Present content and media.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Avatar` | User avatars |
  | `SutraUI.Carousel` | Image carousels (hook) |
  | `SutraUI.ThemeSwitcher` | Light/dark theme event button (hook) |
  | `SutraUI.Separator` | Visual content dividers |
  | `SutraUI.Marquee` | Scrolling content banners |
  | `SutraUI.Calendar` | Monthly calendar grid |
  | `SutraUI.DatePicker` | Date, range, time and datetime pickers (hook) |
  | `SutraUI.Timeline` | Chronological event lists |

  ### AI

  Composable primitives for AI-assisted interfaces.

  | Component | Description |
  |-----------|-------------|
  | `SutraUI.Response` | Text responses with reveal styles, or streamed Markdown |
  | `SutraUI.Activity` | Safe user-facing agent progress with slot-owned rows |

  ## Theming

  Sutra UI uses CSS variables compatible with [shadcn/ui themes](https://ui.shadcn.com/themes).

      :root {
        --primary: oklch(0.65 0.20 260);
        --primary-foreground: oklch(0.98 0 0);
      }

  See the [Theming Guide](theming.md) for complete customization options.

  ## Accessibility

  Sutra UI components use accessibility patterns appropriate to their behavior:

  - Semantic HTML elements
  - ARIA roles and attributes for composite widgets
  - Keyboard navigation for interactive components
  - Focus management where applicable
  - Screen reader support for status-style components

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
  Opens a `SutraUI.Confirm.confirm_dialog/1` by id. See `SutraUI.Confirm`.

      <.button phx-click={SutraUI.open_confirm("retire-confirm")}>Retire</.button>
  """
  defdelegate open_confirm(id), to: SutraUI.Confirm

  @doc "Like `open_confirm/1`, chained onto other JS commands."
  defdelegate open_confirm(js, id), to: SutraUI.Confirm

  # Every module `use SutraUI` imports, with the `only` list of those that import a part.
  @imports [
    {SutraUI.Button, nil},
    {SutraUI.Badge, nil},
    {SutraUI.Spinner, nil},
    {SutraUI.Kbd, nil},
    {SutraUI.Label, nil},
    {SutraUI.Input, nil},
    {SutraUI.Textarea, nil},
    {SutraUI.Checkbox, nil},
    {SutraUI.Switch, nil},
    {SutraUI.RadioGroup, nil},
    {SutraUI.Select, nil},
    {SutraUI.Slider, nil},
    {SutraUI.Card, nil},
    {SutraUI.Header, nil},
    {SutraUI.Table, nil},
    {SutraUI.Skeleton, nil},
    {SutraUI.Empty, nil},
    {SutraUI.Alert, nil},
    {SutraUI.Flash, nil},
    {SutraUI.Progress, nil},
    {SutraUI.Breadcrumb, nil},
    {SutraUI.Pagination, nil},
    {SutraUI.Accordion, nil},
    {SutraUI.Tabs, nil},
    {SutraUI.DropdownMenu, nil},
    {SutraUI.Toast, [toast: 1, toast_group: 1, toast_container: 1]},
    {SutraUI.Confirm, nil},
    {SutraUI.Avatar, nil},
    {SutraUI.Tooltip, nil},
    {SutraUI.Dialog, nil},
    {SutraUI.Popover, nil},
    {SutraUI.Command, nil},
    {SutraUI.Commands.Palette, nil},
    {SutraUI.Carousel, nil},
    {SutraUI.FilterBar, nil},
    {SutraUI.InputGroup, nil},
    {SutraUI.InputOTP, nil},
    {SutraUI.FileUpload, nil},
    {SutraUI.Item, nil},
    {SutraUI.LoadingState, nil},
    {SutraUI.SimpleForm, nil},
    {SutraUI.Drawer, nil},
    {SutraUI.TabNav, nil},
    {SutraUI.Stepper, nil},
    {SutraUI.StepperWizard, nil},
    {SutraUI.TreeView, nil},
    {SutraUI.ThemeSwitcher, nil},
    {SutraUI.RangeSlider, nil},
    {SutraUI.LiveSelect, [decode: 1, normalize_options: 1]},
    {SutraUI.Separator, nil},
    {SutraUI.Marquee, nil},
    {SutraUI.HoverCard, nil},
    {SutraUI.Calendar, nil},
    {SutraUI.DatePicker, nil},
    {SutraUI.Timeline, nil},
    {SutraUI.ContextMenu, nil},
    {SutraUI.Response, nil},
    {SutraUI.Activity, nil},
    {SutraUI.Time, [relative_time: 1, local_time: 1]}
  ]

  @doc """
  Use Sutra UI in your Phoenix application.

  This macro imports Sutra UI function components for use in your templates.
  `SutraUI.LiveSelect` is a LiveComponent; render it with
  `<.live_component module={SutraUI.LiveSelect} ... />`. The macro imports
  its `decode/1` and `normalize_options/1` helpers.

  ## Example

      defmodule MyAppWeb do
        def html_helpers do
          quote do
            use SutraUI
          end
        end
      end

  ## When a name clashes with your own

  `use SutraUI` imports every component (for example `command_palette/1`, `avatar/1`). If your
  app defines a function with the same name and arity, Elixir reports an ambiguity at the call.
  Leave the Sutra one out with `except` (a list of `name: arity`), then call it as
  `SutraUI.Commands.Palette.command_palette/1` or alias the module:

      use SutraUI, except: [command_palette: 1]

  The option applies to every module `use SutraUI` imports. Plain `import SutraUI.Button` and
  the like stay available for importing a single module.
  """
  defmacro __using__(opts) do
    except = Keyword.get(opts, :except, [])

    for {module, only} <- @imports do
      import_opts =
        case only do
          nil -> [except: except]
          only -> [only: only -- except]
        end

      quote do
        import unquote(module), unquote(import_opts)
      end
    end
  end
end
