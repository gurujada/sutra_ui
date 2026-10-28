# Builds the browser modules in assets/js/<widget>/ into priv/static/<widget>.js (run with
# `mix assets.build`, a maintainers' step: the built files are committed and ship on Hex).
# Each built file starts with a comment holding its source hash.
{:ok, _} = Application.ensure_all_started(:esbuild)
{hash, _} = Code.eval_file(Path.join(__DIR__, "js_hash.exs"))

widgets =
  "assets/js/*/index.js"
  |> Path.wildcard()
  |> Enum.map(&(&1 |> Path.dirname() |> Path.basename()))

for widget <- widgets do
  banner = "/* sutra_ui #{widget} source-hash:#{hash.(widget)} (built by mix assets.build; do not edit) */"

  0 =
    Esbuild.install_and_run(:sutra_ui, [
      "assets/js/#{widget}/index.js",
      "--bundle",
      "--format=esm",
      "--target=es2022",
      "--outfile=priv/static/#{widget}.js",
      "--banner:js=#{banner}"
    ])
end
