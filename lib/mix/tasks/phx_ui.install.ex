defmodule Mix.Tasks.PhxUi.Install do
  @shortdoc "Installs PhxUI into your Phoenix application"

  @moduledoc """
  Installs PhxUI into your Phoenix application.

      $ mix phx_ui.install

  This task will:

  1. Add the CSS import to your `assets/css/app.css`
  2. Add the JS hooks import to your `assets/js/app.js`
  3. Add `use PhxUI` to your web module

  ## Options

  * `--no-css` - Skip CSS setup
  * `--no-js` - Skip JS hooks setup
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
          no_js: :boolean,
          no_web: :boolean,
          dry_run: :boolean
        ]
      )

    dry_run? = Keyword.get(opts, :dry_run, false)

    Mix.shell().info("\n#{IO.ANSI.cyan()}PhxUI Installation#{IO.ANSI.reset()}\n")

    app_name = Mix.Project.config()[:app]
    web_module = web_module_name(app_name)

    unless Keyword.get(opts, :no_css) do
      setup_css(dry_run?)
    end

    unless Keyword.get(opts, :no_js) do
      setup_js(dry_run?)
    end

    unless Keyword.get(opts, :no_web) do
      setup_web_module(web_module, dry_run?)
    end

    Mix.shell().info("""

    #{IO.ANSI.green()}Installation complete!#{IO.ANSI.reset()}

    Next steps:

    1. Customize your theme colors in assets/css/app.css:

       :root {
         --primary: oklch(0.65 0.20 145);  /* Your brand color */
       }

    2. Start your Phoenix server:

       mix phx.server

    3. Use PhxUI components in your templates:

       <.button>Click me</.button>

    Documentation: https://hexdocs.pm/phx_ui
    """)
  end

  defp setup_css(dry_run?) do
    css_path = "assets/css/app.css"

    if File.exists?(css_path) do
      content = File.read!(css_path)

      if String.contains?(content, "phx_ui") do
        Mix.shell().info("#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} CSS already configured")
      else
        css_additions = """

        /* PhxUI: Add source path for Tailwind to scan */
        @source "../../deps/phx_ui/lib";

        /* PhxUI: Import component styles */
        @import "../../deps/phx_ui/priv/static/phx_ui.css";
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

          Mix.shell().info("  Adding @source and @import for phx_ui")
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

  defp setup_js(dry_run?) do
    js_path = "assets/js/app.js"

    if File.exists?(js_path) do
      content = File.read!(js_path)

      if String.contains?(content, "phoenix-colocated/phx_ui") do
        Mix.shell().info(
          "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} JS hooks already configured"
        )
      else
        # Add import statement
        import_line = ~s|import {hooks as phxUiHooks} from "phoenix-colocated/phx_ui"\n|

        new_content =
          if String.contains?(content, "phoenix_live_view") do
            # Add import after phoenix_live_view import
            String.replace(
              content,
              ~r/(import.*phoenix_live_view.*\n)/,
              "\\1#{import_line}",
              global: false
            )
          else
            # Prepend to file
            import_line <> content
          end

        # Add hooks to LiveSocket if not already spread
        new_content =
          if String.contains?(new_content, "phxUiHooks") and
               not String.contains?(new_content, "...phxUiHooks") do
            # Try to add to existing hooks object
            cond do
              String.contains?(new_content, "hooks: {") ->
                String.replace(
                  new_content,
                  ~r/hooks:\s*\{/,
                  "hooks: {...phxUiHooks, ",
                  global: false
                )

              String.contains?(new_content, "hooks:") ->
                # hooks: someVar -> hooks: {...phxUiHooks, ...someVar}
                new_content

              true ->
                new_content
            end
          else
            new_content
          end

        if dry_run? do
          Mix.shell().info("#{IO.ANSI.blue()}[dry-run]#{IO.ANSI.reset()} Would update #{js_path}")
          Mix.shell().info("  Adding import for phx_ui hooks")
        else
          File.write!(js_path, new_content)
          Mix.shell().info("#{IO.ANSI.green()}[updated]#{IO.ANSI.reset()} #{js_path}")
        end
      end
    else
      Mix.shell().info(
        "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} #{js_path} not found - please add manually"
      )
    end
  end

  defp setup_web_module(web_module, dry_run?) do
    web_path = find_web_module_path(web_module)

    if web_path && File.exists?(web_path) do
      content = File.read!(web_path)

      if String.contains?(content, "use PhxUI") do
        Mix.shell().info(
          "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} Web module already has PhxUI"
        )
      else
        # Add use PhxUI to html_helpers
        new_content =
          if String.contains?(content, "defp html_helpers") do
            String.replace(
              content,
              ~r/(defp html_helpers.*do\s+quote do\s+)/s,
              "\\1use PhxUI\n        ",
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

            Mix.shell().info("  Adding use PhxUI to html_helpers")
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
        "#{IO.ANSI.yellow()}[skip]#{IO.ANSI.reset()} Web module not found - please add `use PhxUI` manually"
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
