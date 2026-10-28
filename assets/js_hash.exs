# The source hash of a widget in assets/js/<widget>/: its files except the tests, in name
# order. `mix assets.build` writes it into the built file's first line and
# test/sutra_ui/assets_test.exs compares it, so a build that is older than its source fails.
fn widget ->
  Path.join(["assets", "js", widget, "**", "*.js"])
  |> Path.wildcard()
  |> Enum.reject(&String.ends_with?(&1, ".test.js"))
  |> Enum.sort()
  |> Enum.map(&[&1, 0, File.read!(&1), 0])
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
  |> binary_part(0, 16)
end
