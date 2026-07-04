defmodule Mix.Tasks.SutraUi.InstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    tmp_dir =
      Path.join([
        System.tmp_dir!(),
        "sutra_ui_install_test_#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(tmp_dir)
    File.mkdir_p!(Path.join(tmp_dir, "lib"))

    on_exit(fn ->
      Mix.Task.reenable("sutra_ui.install")
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "injects use SutraUI into html_helpers without touching verified_routes", %{
    tmp_dir: tmp_dir
  } do
    web_path = Path.join(tmp_dir, "lib/sutra_ui_web.ex")

    File.write!(web_path, """
    defmodule SutraUiWeb do
      def verified_routes do
        quote do
          use Phoenix.VerifiedRoutes,
            endpoint: SutraUiWeb.Endpoint,
            router: SutraUiWeb.Router,
            statics: SutraUiWeb.static_paths()
        end
      end

      defp html_helpers do
        quote do
          import Phoenix.Component
          unquote(verified_routes())
        end
      end
    end
    """)

    File.cd!(tmp_dir, fn ->
      capture_io(fn ->
        Mix.Tasks.SutraUi.Install.run(["--no-css"])
      end)
    end)

    updated = File.read!(web_path)

    assert updated =~
             "  def verified_routes do\n    quote do\n      use Phoenix.VerifiedRoutes,\n"

    assert updated =~
             "  defp html_helpers do\n    quote do\n      use SutraUI\n      import Phoenix.Component\n"
  end

  test "reports manual core_components cleanup without deleting the file", %{tmp_dir: tmp_dir} do
    web_path = Path.join(tmp_dir, "lib/sutra_ui_web.ex")
    core_components_path = Path.join(tmp_dir, "lib/sutra_ui_web/components/core_components.ex")

    File.mkdir_p!(Path.dirname(core_components_path))

    File.write!(web_path, """
    defmodule SutraUiWeb do
      defp html_helpers do
        quote do
          import SutraUiWeb.CoreComponents
        end
      end
    end
    """)

    File.write!(core_components_path, "defmodule SutraUiWeb.CoreComponents do\nend\n")

    output =
      File.cd!(tmp_dir, fn ->
        capture_io(fn ->
          Mix.Tasks.SutraUi.Install.run(["--no-css"])
        end)
      end)

    assert File.exists?(core_components_path)
    assert output =~ "Manual steps required"
    assert output =~ "rm lib/sutra_ui_web/components/core_components.ex"
    assert output =~ "import SutraUiWeb.CoreComponents"
  end
end
