defmodule SutraUI.Commands.MatchTest do
  use ExUnit.Case, async: true

  alias SutraUI.Commands.Match

  doctest SutraUI.Commands.Match

  @fixture "test/fixtures/commands_match.json" |> File.read!() |> Jason.decode!()

  for %{"query" => q, "title" => t, "keywords" => k, "score" => expected} <- @fixture["score"] do
    test "score(#{inspect(q)}, #{inspect(t)}, #{inspect(k)}) is #{inspect(expected)}" do
      assert Match.score(unquote(q), unquote(t), unquote(k)) == unquote(expected)
    end
  end

  for %{"query" => q, "items" => items, "order" => order} <- @fixture["rank"] do
    test "rank(#{inspect(q)}) orders #{Enum.join(order, ", ")}" do
      items = unquote(Macro.escape(items))

      ranked = Match.rank(unquote(q), items, &{&1["title"], &1["keywords"]})

      assert Enum.map(ranked, & &1["title"]) == unquote(order)
    end
  end

  test "distance counts one swap of neighbours as one edit" do
    assert Match.distance("abcd", "abdc") == 1
    assert Match.distance("kitten", "sitting") == 3
    assert Match.distance("", "abc") == 3
  end
end
