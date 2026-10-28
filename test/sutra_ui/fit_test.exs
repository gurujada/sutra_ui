defmodule SutraUI.FitTest do
  use ExUnit.Case, async: true

  # Runtime hooks are inline scripts and cannot import a shared module, so popover and
  # dropdown_menu each carry the same viewport-fitting code between these markers.
  defp fit_block(file) do
    [_, block] = Regex.run(~r{// fit:start.*?\n(.*?)// fit:end}s, File.read!(file))
    block
  end

  test "popover and dropdown_menu carry the same fit() code" do
    assert fit_block("lib/sutra_ui/popover.ex") == fit_block("lib/sutra_ui/dropdown_menu.ex")
  end

  # The shared module (assets/js/fit, used by select) is the source the inline copies repeat.
  test "assets/js/fit carries the same code as the inline copies" do
    lines = fn text ->
      text |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    end

    [_, js] = Regex.run(~r{// fit:start\n(.*?)// fit:end}s, File.read!("assets/js/fit/index.js"))

    # the inline block starts with its comment and `fit(...) {` line and ends with `},`
    inline = lines.(fit_block("lib/sutra_ui/popover.ex"))
    sig = Enum.find_index(inline, &String.starts_with?(&1, "fit(content, trigger, wanted)"))
    body = inline |> Enum.drop(sig + 1) |> Enum.drop(-1)

    assert body == lines.(js)
  end

  test "fit() positions through the CSSOM only" do
    block = fit_block("lib/sutra_ui/popover.ex")
    assert block =~ "content.style.left"
    assert block =~ "content.style.position = 'fixed'"
    refute block =~ ~r/setAttribute\(\s*['"]style['"]/
  end

  test "both hooks fit when the card opens, on resize and after a patch" do
    for file <- ["lib/sutra_ui/popover.ex", "lib/sutra_ui/dropdown_menu.ex"] do
      source = File.read!(file)
      assert source =~ "MutationObserver"
      # the card is fixed, so it follows scrolling (page and ancestors) while open
      assert source =~ "addEventListener('scroll'"
      assert source =~ "capture: true"
      assert source =~ "refit()"
      assert source =~ "attributeFilter: ['aria-hidden']"
      assert source =~ "addEventListener('resize'"
      assert source =~ "disconnect()"
    end
  end

  describe "theme tokens" do
    setup do
      {:ok, css: File.read!("priv/static/sutra_ui.css")}
    end

    test "badge tones exist in light and dark", %{css: css} do
      [light, dark] =
        css |> String.split(~r/^\.dark \{/m, parts: 2) |> then(fn [a, b] -> [a, b] end)

      for tone <- ~w(info warning brand ai), token <- ["--#{tone}:", "--#{tone}-foreground:"] do
        assert light =~ token, "#{token} in :root"
        assert dark =~ token, "#{token} in .dark"
      end

      for tone <- ~w(info warning brand ai) do
        assert css =~ "--color-#{tone}: var(--#{tone});"
      end
    end
  end

  test "a fixed dialog takes no sibling margin (a space-y parent must not shrink it)" do
    css = File.read!("priv/static/sutra_ui.css")
    assert css =~ ~r/\.dialog \{[^}]*margin: 0 !important;/s
  end
end
