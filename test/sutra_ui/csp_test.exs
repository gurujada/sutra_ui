defmodule SutraUI.CSPTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Avatar
  alias SutraUI.Tooltip

  @lib Path.wildcard("lib/sutra_ui/*.ex")

  test "every runtime hook script accepts a CSP nonce" do
    for file <- @lib,
        line <- File.stream!(file) |> Enum.to_list(),
        String.contains?(line, "ColocatedHook}") and String.contains?(line, "runtime") do
      assert line =~ "nonce={@nonce}", "#{file}: #{String.trim(line)}"
    end
  end

  test "no component renders an inline event handler attribute" do
    for file <- @lib, {line, n} <- file |> File.stream!() |> Enum.with_index(1) do
      refute line =~ ~r/\son[a-z]+=[{"']/, "#{file}:#{n}: #{String.trim(line)}"
    end
  end

  test "a runtime hook script carries the nonce passed to its component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Tooltip.tooltip id="t1" tooltip="Hi" nonce="n0nce">Hover</Tooltip.tooltip>
      """)

    assert html =~ ~r/<script[^>]*nonce="n0nce"/
    assert html =~ "data-phx-runtime-hook"
  end

  test "avatar with an id uses a nonce-able hook instead of an onerror handler" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar id="av1" src="/a.png" alt="A" nonce="n0nce" />
      """)

    refute html =~ "onerror"
    assert html =~ ~s(phx-hook=".Avatar")
    assert html =~ ~r/<script[^>]*nonce="n0nce"/
  end

  test "avatar without an id renders no inline handler and no script" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Avatar.avatar src="/a.png" alt="A" />
      """)

    refute html =~ "onerror"
    refute html =~ "<script"
  end

  # No component renders a `style=` attribute (skeleton and carousel CSS lengths went in 0.5).
  test "no component renders an inline style attribute" do
    for file <- @lib, {line, n} <- file |> File.stream!() |> Enum.with_index(1) do
      refute line =~ ~r/\sstyle=[{"']/, "#{file}:#{n}: #{String.trim(line)}"
    end
  end

  test "hooks never write the style attribute as a string" do
    for file <- @lib, {line, n} <- file |> File.stream!() |> Enum.with_index(1) do
      refute line =~ ~r/setAttribute\(\s*['"]style['"]|\.style\.cssText|\.style\s*=[^=]/,
             "#{file}:#{n}: #{String.trim(line)}"
    end
  end

  describe "percentage tables" do
    setup do
      {:ok, css: File.read!("priv/static/sutra_ui.css")}
    end

    test "every integer 0..100 maps for pct, pct-start and pct-width", %{css: css} do
      for {attr, var} <- [
            {"data-pct", "--pct"},
            {"data-pct-start", "--pct-start"},
            {"data-pct-width", "--pct-width"}
          ],
          n <- 0..100 do
        assert css =~ ~s([#{attr}="#{n}"] { #{var}: #{n}%; }), "#{attr}=#{n}"
      end
    end

    test "components use the variables instead of inline styles", %{css: css} do
      assert css =~ "width: var(--pct, 0%);"
      assert css =~ "left: var(--pct-start, 0%);"
      assert css =~ "width: var(--pct-width, 0%);"
      assert css =~ "--slider-value: var(--pct, 20%);"
    end
  end

  describe "SutraUI.Pct.pct/1" do
    test "rounds and clamps to 0..100" do
      assert SutraUI.Pct.pct(nil) == 0
      assert SutraUI.Pct.pct(-5) == 0
      assert SutraUI.Pct.pct(33.6) == 34
      assert SutraUI.Pct.pct(250) == 100
    end
  end

  test "progress and slider render data-pct" do
    assigns = %{}

    assert rendered_to_string(~H"<SutraUI.Progress.progress value={42.4} />") =~ ~s(data-pct="42")

    assert rendered_to_string(~H'<SutraUI.Slider.slider id="s" name="s" value={30} />') =~
             ~s(data-pct="30")
  end

  test "accordion hides closed content with a class, not a style" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <SutraUI.Accordion.accordion id="acc" default_value="a">
        <:item value="a" title="A">One</:item>
        <:item value="b" title="B">Two</:item>
      </SutraUI.Accordion.accordion>
      """)

    assert html =~ ~r/id="accordion-content-b"/

    assert html =~ ~r/id="accordion-content-b"[^>]*>/ or
             html =~ ~r/class="accordion-content hidden"[^>]*id="accordion-content-b"/

    assert [_] = Regex.scan(~r/class="accordion-content hidden"/, html)
    refute html =~ "style="
  end

  test "popover trigger shows open or closed content by aria-expanded" do
    css = File.read!("priv/static/sutra_ui.css")
    assert css =~ ~r/\.popover-trigger\[aria-expanded="true"\] \.popover-trigger-closed/
    assert css =~ ~r/\.popover-trigger:not\(\[aria-expanded="true"\]\) \.popover-trigger-open/
  end
end
