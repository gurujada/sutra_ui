defmodule SutraUI.Dimension do
  @moduledoc false
  # `width`, `height` and `gap` take Tailwind classes. Until 0.5 a CSS length (digits plus a
  # unit, or `auto`) is still accepted and rendered as an inline style, as before 0.4.1.
  # That inline style is the one thing a strict `style-src 'self'` policy blocks; it goes
  # away in 0.5.

  @length ~r/^[+-]?(\d+\.?\d*|\.\d+)(px|rem|em|ex|ch|%|vw|vh|vmin|vmax|svw|svh|lvw|lvh|dvw|dvh|cm|mm|in|pt|pc)$|^auto$/

  @doc "True when the value is a CSS length rather than a class name."
  def css_length?(value) when is_binary(value), do: Regex.match?(@length, String.trim(value))
  def css_length?(_), do: false

  @doc "The values that are class names (CSS lengths and nils are dropped)."
  def classes(values), do: Enum.filter(values, &(is_binary(&1) and not css_length?(&1)))

  @doc "Global attributes for the element: `[style: ...]` when a length is present, else `[]`."
  def style_attr(pairs) do
    case style(pairs) do
      nil -> []
      style -> [style: style]
    end
  end

  @doc "An inline style string for the `{property, value}` pairs whose value is a CSS length."
  def style(pairs) do
    case for({prop, value} <- pairs, css_length?(value), do: "#{prop}: #{String.trim(value)}") do
      [] -> nil
      parts -> Enum.join(parts, "; ")
    end
  end
end
