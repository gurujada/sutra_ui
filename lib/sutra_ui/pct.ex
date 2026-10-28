defmodule SutraUI.Pct do
  @moduledoc false
  # A percentage as an integer 0..100 for a `data-pct` attribute. The stylesheet maps
  # `[data-pct="N"]` to `--pct: N%`, so components position by percentage without an inline
  # `style` attribute (which a strict Content-Security-Policy blocks).

  @spec pct(number() | nil) :: 0..100
  def pct(nil), do: 0

  def pct(value) when is_number(value) do
    value |> round() |> max(0) |> min(100)
  end
end
