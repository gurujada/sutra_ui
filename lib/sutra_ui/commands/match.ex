defmodule SutraUI.Commands.Match do
  @moduledoc """
  Matching and ranking of commands: the same rules the palette applies in the browser
  (`assets/js/commands/match.js`; `test/fixtures/commands_match.json` holds the cases both
  must agree on).

  A query is split into words. Each word, in order, must match a later token than the one the
  previous word matched, the tokens being the words of the title followed by the words of the
  keywords. A word matches the start of a token (best), the inside of a token, or, for words
  of five letters or more, a token start with one typo. Accents and case are ignored.

      iex> SutraUI.Commands.Match.score("new f", "New file")
      15
      iex> SutraUI.Commands.Match.score("qzx", "New file")
      nil
  """

  @prefix 6
  @infix 3
  @typo 2
  @keyword_penalty 1
  @first_token_bonus 3
  @min_typo_length 5

  @doc "Lower-cases and strips accents."
  @spec normalize(String.t()) :: String.t()
  def normalize(text) do
    text
    |> to_string()
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{M}/u, "")
    |> String.downcase()
  end

  @doc "The words of a text: runs of letters and digits."
  @spec tokens(String.t()) :: [String.t()]
  def tokens(text) do
    ~r/[\p{L}\p{N}]+/u
    |> Regex.scan(normalize(text))
    |> List.flatten()
  end

  @doc "The score of a query against a title and keywords, or `nil` when it does not match."
  @spec score(String.t(), String.t(), [String.t()]) :: non_neg_integer() | nil
  def score(query, title, keywords \\ []) do
    case tokens(query) do
      [] ->
        0

      words ->
        pool =
          Enum.map(tokens(title), &{&1, false}) ++
            Enum.map(tokens(Enum.join(keywords, " ")), &{&1, true})

        match_words(words, pool, 0, 0, false, 0)
    end
  end

  defp match_words([], _pool, _from, total, first_at_start, _n) do
    total + if first_at_start, do: @first_token_bonus, else: 0
  end

  defp match_words([word | rest], pool, from, total, first_at_start, n) do
    case best_token(word, pool, from) do
      nil ->
        nil

      {index, class, keyword?} ->
        points = class - if keyword?, do: @keyword_penalty, else: 0
        start? = first_at_start or (n == 0 and index == 0 and class == @prefix)
        match_words(rest, pool, index + 1, total + points, start?, n + 1)
    end
  end

  defp best_token(word, pool, from) do
    indexed = pool |> Enum.with_index() |> Enum.drop(from)

    Enum.find_value([@prefix, @infix, @typo], fn class ->
      Enum.find_value(indexed, fn {{token, keyword?}, i} ->
        if word_class(word, token) == class, do: {i, class, keyword?}
      end)
    end)
  end

  @doc false
  def word_class(word, token) do
    word_length = String.length(word)

    cond do
      String.starts_with?(token, word) -> @prefix
      word_length >= 2 and String.contains?(token, word) -> @infix
      word_length >= @min_typo_length and typo?(word, token, word_length) -> @typo
      true -> 0
    end
  end

  defp typo?(word, token, word_length) do
    chars = String.graphemes(token)

    Enum.any?([word_length - 1, word_length, word_length + 1], fn length ->
      length <= length(chars) and distance(word, chars |> Enum.take(length) |> Enum.join()) == 1
    end)
  end

  @doc false
  # Optimal string alignment distance (insert, delete, substitute, swap neighbours).
  def distance(a, b) do
    x = String.graphemes(a)
    y = String.graphemes(b)
    rows = length(x) + 1
    cols = length(y) + 1
    xs = List.to_tuple(x)
    ys = List.to_tuple(y)

    table =
      for i <- 0..(rows - 1), j <- 0..(cols - 1), reduce: %{} do
        d ->
          value =
            cond do
              i == 0 ->
                j

              j == 0 ->
                i

              true ->
                cost = if elem(xs, i - 1) == elem(ys, j - 1), do: 0, else: 1
                base = min(min(d[{i - 1, j}] + 1, d[{i, j - 1}] + 1), d[{i - 1, j - 1}] + cost)

                if i > 1 and j > 1 and elem(xs, i - 1) == elem(ys, j - 2) and
                     elem(xs, i - 2) == elem(ys, j - 1) do
                  min(base, d[{i - 2, j - 2}] + 1)
                else
                  base
                end
            end

          Map.put(d, {i, j}, value)
      end

    table[{rows - 1, cols - 1}]
  end

  @doc """
  Items that match the query, best first: score, then shorter title, then original order.
  `text` returns `{title, keywords}` for an item.
  """
  @spec rank(String.t(), [item], (item -> {String.t(), [String.t()]})) :: [item] when item: term()
  def rank(query, items, text) do
    items
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} ->
      {title, keywords} = text.(item)

      case score(query, title, keywords) do
        nil -> []
        s -> [{item, index, s, String.length(title)}]
      end
    end)
    |> Enum.sort_by(fn {_item, index, s, length} -> {-s, length, index} end)
    |> Enum.map(&elem(&1, 0))
  end
end
