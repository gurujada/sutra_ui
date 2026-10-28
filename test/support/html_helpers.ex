defmodule SutraUI.HTMLHelpers do
  @moduledoc "Reads rendered HTML by selector, so tests assert data attributes, text and names."

  @doc "The text of the elements matching `selector`."
  def text(html, selector), do: html |> query(selector) |> LazyHTML.text() |> String.trim()

  @doc "The first value of attribute `name` on the elements matching `selector`, or nil."
  def attribute(html, selector, name),
    do: html |> query(selector) |> LazyHTML.attribute(name) |> List.first()

  @doc "How many elements match `selector`."
  def count(html, selector), do: html |> query(selector) |> Enum.count()

  defp query(html, selector), do: html |> LazyHTML.from_fragment() |> LazyHTML.query(selector)
end
