defmodule PhxUI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/gurujada/phx_ui"

  def project do
    [
      app: :phx_ui,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),

      # Hex
      description: "A pure Phoenix LiveView UI component library. No dependencies, no nonsense.",
      package: package(),

      # Docs
      name: "PhxUI",
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

      # Dev/Test
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:jason, "~> 1.0", optional: true}
    ]
  end

  defp package do
    [
      maintainers: ["Gurujada"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "PhxUI",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"],
      groups_for_modules: [
        Components: ~r/PhxUI\..*/
      ]
    ]
  end
end
