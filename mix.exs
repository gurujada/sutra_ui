defmodule SutraUI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/gurujada/sutra_ui"

  def project do
    [
      app: :sutra_ui,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),

      # Hex
      description:
        "Sutra UI - We define the rules, so you don't have to. A Phoenix LiveView component library with 44 accessible components and CSS-first theming.",
      package: package(),

      # Docs
      name: "Sutra UI",
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.0"},
      {:lucide_icons,
       github: "lucide-icons/lucide",
       tag: "0.552.0",
       sparse: "icons",
       app: false,
       compile: false,
       depth: 1},
      # Dev/Test
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:lazy_html, "~> 0.1", only: :test},
      {:jason, "~> 1.0", optional: true}
    ]
  end

  defp package do
    [
      maintainers: ["Chivukula Virinchi"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/sutra_ui"
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md": [title: "Overview"],
        "guides/installation.md": [title: "Installation"],
        "guides/theming.md": [title: "Theming"],
        "guides/accessibility.md": [title: "Accessibility"],
        "guides/colocated-hooks.md": [title: "JavaScript Hooks"],
        "cheatsheets/components.cheatmd": [title: "Components Cheatsheet"],
        "cheatsheets/forms.cheatmd": [title: "Forms Cheatsheet"],
        "usage_rules.md": [title: "LLM Usage Rules"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.*/,
        Cheatsheets: ~r/cheatsheets\/.*/,
        Reference: ~r/(usage_rules|CHANGELOG).*/
      ],
      groups_for_modules: [
        Foundation: [
          SutraUI.Icon,
          SutraUI.Button,
          SutraUI.Badge,
          SutraUI.Spinner,
          SutraUI.Kbd
        ],
        "Form Controls": [
          SutraUI.Label,
          SutraUI.Input,
          SutraUI.Textarea,
          SutraUI.Checkbox,
          SutraUI.Switch,
          SutraUI.RadioGroup,
          SutraUI.Select,
          SutraUI.Slider,
          SutraUI.RangeSlider,
          SutraUI.LiveSelect,
          SutraUI.Field,
          SutraUI.SimpleForm,
          SutraUI.InputGroup,
          SutraUI.FilterBar
        ],
        Layout: [
          SutraUI.Card,
          SutraUI.Header,
          SutraUI.Table,
          SutraUI.Item,
          SutraUI.Sidebar
        ],
        Feedback: [
          SutraUI.Alert,
          SutraUI.Progress,
          SutraUI.Skeleton,
          SutraUI.Empty,
          SutraUI.LoadingState,
          SutraUI.Toast
        ],
        Overlay: [
          SutraUI.Dialog,
          SutraUI.Popover,
          SutraUI.Tooltip,
          SutraUI.DropdownMenu,
          SutraUI.Command
        ],
        Navigation: [
          SutraUI.Tabs,
          SutraUI.Accordion,
          SutraUI.Breadcrumb,
          SutraUI.Pagination,
          SutraUI.NavPills,
          SutraUI.TabNav
        ],
        Display: [
          SutraUI.Avatar,
          SutraUI.Carousel,
          SutraUI.ThemeSwitcher
        ]
      ],
      nest_modules_by_prefix: [SutraUI]
    ]
  end
end
