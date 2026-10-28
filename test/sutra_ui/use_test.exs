defmodule SutraUI.UseTest do
  use ExUnit.Case, async: true

  @own """
  defmodule SutraUI.UseTest.Own%{n} do
    use SutraUI%{opts}
    def command_palette(_assigns), do: :mine
    def call, do: command_palette(%{})
  end
  """

  defp compile(n, opts) do
    @own
    |> String.replace("%{n}", n)
    |> String.replace("%{opts}", opts)
    |> Code.compile_string()
  end

  test "an app's own command_palette/1 clashes with the import" do
    assert_raise CompileError, fn ->
      ExUnit.CaptureIO.capture_io(:stderr, fn -> compile("A", "") end)
    end
  end

  test "except leaves a name out of every imported module" do
    [{mod, _}] = compile("B", ", except: [command_palette: 1]")
    assert mod.call() == :mine
  end

  test "except also trims the modules imported with only" do
    [{mod, _}] =
      Code.compile_string("""
      defmodule SutraUI.UseTest.OwnC do
        use SutraUI, except: [toast: 1]
        def toast(_assigns), do: :mine
        def call, do: toast(%{})
      end
      """)

    assert mod.call() == :mine
  end
end
