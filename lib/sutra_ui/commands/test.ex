defmodule SutraUI.Commands.Test do
  @moduledoc """
  Search and run command palette actions in LiveView tests, the way the browser does.

      import SutraUI.Commands.Test

      test "finds a workbook and opens it", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/")

        assert "Go home" in titles(actions(view))
        assert [%{"title" => "Physics 1"} | _] = search(view, :workbooks, "phys")
        assert :ok = run(view, "theme", %{theme: "dark"})
        assert {:error, "Pick one of the choices"} = run(view, "theme", %{theme: "mauve"})
      end

  Results are plain maps with string keys, the palette's wire form (`"id"`, `"title"`,
  `"section"`, `"kind"`, `"children"`, ...).
  """

  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  @doc "The actions the palette lists now (what the page's `data-actions` carries)."
  @spec actions(Phoenix.LiveViewTest.View.t()) :: [map()]
  def actions(view) do
    html = render(view)

    case Regex.run(~r/data-actions="([^"]*)"/, html) do
      [_, escaped] ->
        escaped
        |> String.replace("&quot;", "\"")
        |> String.replace("&#39;", "'")
        |> String.replace("&lt;", "<")
        |> String.replace("&gt;", ">")
        |> String.replace("&amp;", "&")
        |> Phoenix.json_library().decode!()

      nil ->
        flunk(
          "no command palette on the page: render <.command_palette commands={@sutra_commands} />"
        )
    end
  end

  @doc "The titles of a list of actions."
  @spec titles([map()]) :: [String.t()]
  def titles(actions), do: Enum.map(actions, & &1["title"])

  @doc """
  Searches a server source and returns its results (actions), waiting for the search task.
  """
  @spec search(Phoenix.LiveViewTest.View.t(), atom() | String.t(), String.t(), keyword()) :: [
          map()
        ]
  def search(view, source, query, opts \\ []) do
    ref = System.unique_integer([:positive])
    source = to_string(source)
    timeout = Keyword.get(opts, :timeout, 1000)

    render_hook(view, "sutra-ui:command-search", %{
      "source" => source,
      "query" => query,
      "ref" => ref
    })

    assert_reply(view, %{})
    assert_push_event(view, "sutra-ui:command-results", %{ref: ^ref} = payload, timeout)

    payload
    |> Phoenix.json_library().encode!()
    |> Phoenix.json_library().decode!()
    |> case do
      %{"error" => error} -> flunk("search #{source} failed: #{error}")
      %{"items" => items} -> items
    end
  end

  @doc """
  Runs a server action by id with arguments, as the palette does. Returns `:ok` or
  `{:error, message}` (not found, disabled, not allowed, or an invalid argument).
  """
  @spec run(Phoenix.LiveViewTest.View.t(), String.t(), map()) :: :ok | {:error, String.t()}
  def run(view, id, args \\ %{}) do
    args = Map.new(args, fn {key, value} -> {to_string(key), value} end)
    render_hook(view, "sutra-ui:command-run", %{"id" => id, "args" => args})

    assert_reply(view, reply)

    case reply do
      %{ok: true} -> :ok
      %{error: message} -> {:error, message}
    end
  end
end
