defmodule Mix.Tasks.SutraUi.Install do
  @shortdoc "Installs Sutra UI into your Phoenix application"

  @moduledoc """
  Installs Sutra UI into your Phoenix application.

      $ mix sutra_ui.install

  This task will:

  1. Add the CSS import to your `assets/css/app.css`
  2. Add `use SutraUI` to your web module

  ## Runtime Hooks

  Sutra UI uses Phoenix 1.8+ runtime colocated hooks. No JavaScript configuration
  is required - hooks are automatically injected at runtime. Just use the components
  and they work out of the box!

  ## Options

  * `--no-css` - Skip CSS setup
  * `--no-web` - Skip web module setup
  * `--dry-run` - Show what would be changed without making changes

  """

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          no_css: :boolean,
          no_web: :boolean,
          dry_run: :boolean
        ]
      )

    dry_run? = Keyword.get(opts, :dry_run, false)

    app_name = Mix.Project.config()[:app]
    web_module = web_module_name(app_name)

    unless Keyword.get(opts, :no_css), do: setup_css(dry_run?)
    unless Keyword.get(opts, :no_web), do: setup_web_module(web_module, dry_run?)

    Mix.shell().info("""

    #{IO.ANSI.green()}✓ Sutra UI installed#{IO.ANSI.reset()}

    Next: Start your server with `mix phx.server`

    Docs: https://hexdocs.pm/sutra_ui
    """)
  end

  defp setup_css(dry_run?) do
    css_path = "assets/css/app.css"

    if File.exists?(css_path) do
      content = File.read!(css_path)

      if String.contains?(content, "sutra_ui") do
        Mix.shell().info("#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} CSS already configured")
      else
        css_additions = """

        /* Sutra UI: Add source path for Tailwind to scan */
        @source "../../deps/sutra_ui/lib";

        /* Sutra UI: Import component styles */
        @import "../../deps/sutra_ui/priv/static/sutra_ui.css";
        """

        # Insert after the first @import "tailwindcss" line
        new_content =
          if String.contains?(content, "@import \"tailwindcss\"") do
            String.replace(
              content,
              ~r/@import "tailwindcss"[^;]*;/,
              "\\0#{css_additions}",
              global: false
            )
          else
            # Fallback: prepend to file
            css_additions <> "\n" <> content
          end

        if dry_run? do
          Mix.shell().info(
            "#{IO.ANSI.blue()}[dry-run]#{IO.ANSI.reset()} Would update #{css_path}"
          )

          Mix.shell().info("  Adding @source and @import for sutra_ui")
        else
          File.write!(css_path, new_content)
          Mix.shell().info("#{IO.ANSI.green()}[updated]#{IO.ANSI.reset()} #{css_path}")
        end
      end
    else
      Mix.shell().info(
        "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} #{css_path} not found - please add manually"
      )
    end
  end

  defp setup_web_module(web_module, dry_run?) do
    web_path = find_web_module_path(web_module)

    if web_path && File.exists?(web_path) do
      content = File.read!(web_path)

      if String.contains?(content, "use SutraUI") do
        Mix.shell().info(
          "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} Web module already has Sutra UI"
        )
      else
        # Add use SutraUI to html_helpers
        new_content =
          if String.contains?(content, "defp html_helpers") do
            String.replace(
              content,
              ~r/(defp html_helpers.*do\s+quote do\s+)/s,
              "\\1use SutraUI\n        ",
              global: false
            )
          else
            content
          end

        if new_content != content do
          if dry_run? do
            Mix.shell().info(
              "#{IO.ANSI.blue()}[dry-run]#{IO.ANSI.reset()} Would update #{web_path}"
            )

            Mix.shell().info("  Adding use SutraUI to html_helpers")
          else
            File.write!(web_path, new_content)
            Mix.shell().info("#{IO.ANSI.green()}[updated]#{IO.ANSI.reset()} #{web_path}")
          end
        else
          Mix.shell().info(
            "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} Could not find html_helpers in #{web_path}"
          )
        end
      end
    else
      Mix.shell().info(
        "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} Web module not found - please add `use SutraUI` manually"
      )
    end
  end

  defp web_module_name(app_name) do
    app_name
    |> to_string()
    |> Macro.camelize()
    |> Kernel.<>("Web")
  end

  defp find_web_module_path(web_module) do
    # Convert MyAppWeb to my_app_web
    file_name =
      web_module
      |> Macro.underscore()
      |> Kernel.<>(".ex")

    # Look in lib/
    path = Path.join("lib", file_name)

    if File.exists?(path) do
      path
    else
      # Try lib/app_name_web.ex pattern
      nil
    end
  end
end
