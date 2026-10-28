defmodule SutraUI.AssetsTest do
  use ExUnit.Case, async: true

  @widgets "assets/js/*/index.js"
           |> Path.wildcard()
           |> Enum.map(&(&1 |> Path.dirname() |> Path.basename()))
  @package "package.json" |> File.read!() |> Jason.decode!()

  test "there is at least one built widget module" do
    assert "time" in @widgets
  end

  for widget <- @widgets do
    test "priv/static/#{widget}.js is built from the current assets/js/#{widget} source" do
      {hash, _} = Code.eval_file("assets/js_hash.exs")
      built = File.read!("priv/static/#{unquote(widget)}.js")

      assert [_, built_hash] = Regex.run(~r{^/\* sutra_ui \S+ source-hash:([0-9a-f]+) }, built),
             "priv/static/#{unquote(widget)}.js has no source hash line: run `mix assets.build`"

      assert built_hash == hash.(unquote(widget)),
             "assets/js/#{unquote(widget)} changed since priv/static/#{unquote(widget)}.js was built: run `mix assets.build` and commit the result"
    end

    test "package.json exports sutra_ui/#{widget}" do
      assert @package["exports"]["./#{unquote(widget)}"] == "./priv/static/#{unquote(widget)}.js"
    end
  end

  test "package.json carries the package version" do
    assert @package["version"] == Mix.Project.config()[:version]
  end
end
