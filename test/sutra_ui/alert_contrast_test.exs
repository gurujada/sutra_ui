defmodule SutraUI.AlertContrastTest do
  use ExUnit.Case, async: true

  @css Path.expand("../../priv/static/sutra_ui.css", __DIR__)

  test "alert tone text has at least 4.5:1 contrast in both default themes" do
    css = File.read!(@css)
    [_, light] = Regex.run(~r/:root\s*\{(.*?)\n\}/s, css)
    [_, dark] = Regex.run(~r/\.dark\s*\{(.*?)\n\}/s, css)

    [_, rule] =
      Regex.run(~r/\.alert-info,\s*\.alert-success,\s*\.alert-warning\s*\{(.*?)\n    \}/s, css)

    assert rule =~ ~r/section\s*\{\s*color:\s*inherit;/

    share =
      case Regex.run(
             ~r/color:\s*color-mix\(in oklab,\s*var\(--alert-tone\)\s+([\d.]+)%,\s*var\(--card-foreground\)\)/,
             rule
           ) do
        [_, percent] ->
          number(percent) / 100

        nil ->
          assert rule =~ "color: var(--alert-tone)"
          1.0
      end

    for theme <- [light, dark], tone <- ~w(info success warning) do
      foreground = oklab(theme, "card-foreground")
      color = oklab(theme, tone)
      mixed = Enum.zip_with(color, foreground, fn a, b -> a * share + b * (1 - share) end)
      ratio = contrast(mixed, oklab(theme, "card"))
      assert ratio >= 4.5, "#{tone} alert contrast is #{Float.round(ratio, 2)}:1"
    end
  end

  defp oklab(css, name) do
    [_, l, c, h] = Regex.run(~r/--#{name}:\s*oklch\(([\d.]+)\s+([\d.]+)\s+([\d.]+)\)/, css)
    [l, c, h] = Enum.map([l, c, h], &number/1)
    angle = h * :math.pi() / 180
    [l, c * :math.cos(angle), c * :math.sin(angle)]
  end

  defp number(string) do
    {value, ""} = Float.parse(string)
    value
  end

  defp contrast(a, b) do
    [low, high] = Enum.sort([luminance(a), luminance(b)])
    (high + 0.05) / (low + 0.05)
  end

  defp luminance([l, a, b]) do
    x = :math.pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
    y = :math.pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
    z = :math.pow(l - 0.0894841775 * a - 1.291485548 * b, 3)
    r = clamp(4.0767416621 * x - 3.3077115913 * y + 0.2309699292 * z)
    g = clamp(-1.2684380046 * x + 2.6097574011 * y - 0.3413193965 * z)
    blue = clamp(-0.0041960863 * x - 0.7034186147 * y + 1.707614701 * z)
    0.2126 * r + 0.7152 * g + 0.0722 * blue
  end

  defp clamp(value), do: max(0.0, min(value, 1.0))
end
