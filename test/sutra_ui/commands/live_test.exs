defmodule SutraUI.Commands.LiveTest do
  use ExUnit.Case, async: false
  # async: false because the test endpoint is started once for this module (global name).
  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import SutraUI.Commands.Test

  @endpoint SutraUI.CommandsApp.Endpoint

  setup_all do
    Application.put_env(:sutra_ui, @endpoint,
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "commands-lv-salt"],
      server: false,
      pubsub_server: SutraUI.CommandsApp.PubSub
    )

    start_supervised!({Phoenix.PubSub, name: SutraUI.CommandsApp.PubSub})
    start_supervised!(@endpoint)
    :ok
  end

  defp mount_view(session \\ %{}) do
    conn = Plug.Test.init_test_session(build_conn(), session)
    {:ok, view, _html} = live(conn, "/")
    view
  end

  describe "actions" do
    test "page actions come first, then the app's" do
      view = mount_view()

      assert titles(actions(view)) |> Enum.take(3) == ["Rename this page", "Go home", "Settings"]
    end

    test "a patch clears the page's actions before its handle_params sets its own" do
      view = mount_view()
      assert "Rename this page" in titles(actions(view))

      render_patch(view, "/?page=b")

      assert "Page B action" in titles(actions(view))
      refute "Rename this page" in titles(actions(view))

      render_patch(view, "/")

      refute "Page B action" in titles(actions(view))
    end
  end

  describe "search" do
    test "returns the source's results, each with its own actions" do
      view = mount_view()

      assert [
               %{"title" => "Physics 1", "kind" => "navigate", "children" => children},
               %{"title" => "Physics 2"}
             ] =
               search(view, :workbooks, "phys")

      assert Enum.map(children, & &1["title"]) == ["Open", "Archive"]
    end

    test "an empty query asks the source for its defaults" do
      assert search(mount_view(), :workbooks, "") |> titles() == [
               "Physics 1",
               "Physics 2",
               "Chemistry"
             ]
    end

    test "a source that raises answers with an error, not a crash" do
      view = mount_view()

      render_hook(view, "sutra-ui:command-search", %{
        "source" => "workbooks",
        "query" => "boom",
        "ref" => 7
      })

      assert_push_event(
        view,
        "sutra-ui:command-results",
        %{ref: 7, items: [], error: "Search failed"},
        1000
      )

      assert Process.alive?(view.pid)
    end

    test "an older answer never covers a newer one" do
      view = mount_view()

      render_hook(view, "sutra-ui:command-search", %{
        "source" => "workbooks",
        "query" => "slow one",
        "ref" => 1
      })

      render_hook(view, "sutra-ui:command-search", %{
        "source" => "workbooks",
        "query" => "phys",
        "ref" => 2
      })

      assert_push_event(view, "sutra-ui:command-results", %{ref: 2, items: [_, _]}, 1000)
      refute_push_event(view, "sutra-ui:command-results", %{ref: 1}, 400)
    end

    test "an unknown source is ignored" do
      view = mount_view()

      render_hook(view, "sutra-ui:command-search", %{
        "source" => "nope",
        "query" => "x",
        "ref" => 1
      })

      refute_push_event(view, "sutra-ui:command-results", %{}, 100)
    end
  end

  describe "run" do
    test "runs a server action with validated arguments" do
      view = mount_view()

      assert :ok = run(view, "theme", %{theme: "dark"})
      assert render(view) =~ ~s(<p id="theme">dark</p>)
    end

    test "a choice must be one of the choices" do
      view = mount_view()

      assert {:error, "Pick one of the choices"} = run(view, "theme", %{theme: "mauve"})
      assert {:error, "Pick one of the choices"} = run(view, "theme", %{})
      assert render(view) =~ ~s(<p id="theme">light</p>)
    end

    test "text is trimmed, required and limited" do
      view = mount_view()

      assert :ok = run(view, "note", %{note: "  hi  "})
      assert {:error, "Type a value first"} = run(view, "note", %{note: "   "})

      assert {:error, "Use at most 10 characters"} =
               run(view, "note", %{note: String.duplicate("x", 11)})
    end

    test "a search argument must be a result of that source" do
      view = mount_view()

      assert {:error, "Pick one of the results"} = run(view, "open", %{workbook: "workbook:1"})

      search(view, :workbooks, "phys")

      assert :ok = run(view, "open", %{workbook: "workbook:1"})
      assert {:error, "Pick one of the results"} = run(view, "open", %{workbook: "workbook:3"})
    end

    test "a result's own server action can be run after the search" do
      view = mount_view()
      search(view, :workbooks, "phys")

      assert :ok = run(view, "workbook:1:archive")
    end

    test "an unknown action is refused" do
      assert {:error, "That is no longer available"} = run(mount_view(), "nope")
      assert {:error, "That is no longer available"} = run(mount_view(), "home")
    end

    test "a disabled action is refused with its reason" do
      assert {:error, "Add a title first"} = run(mount_view(), "publish")
    end

    test "allow is checked again before running" do
      assert {:error, "You are not allowed to do that"} = run(mount_view(), "admin")
      assert :ok = run(mount_view(%{"admin" => true}), "admin")
    end

    test "a server error comes back as the message" do
      assert {:error, "It did not work"} = run(mount_view(), "fail")
    end
  end

  describe "telemetry" do
    test "searches and runs are reported" do
      ref = make_ref()
      parent = self()

      :telemetry.attach_many(
        "commands-test-#{inspect(ref)}",
        [[:sutra_ui, :commands, :search], [:sutra_ui, :commands, :run]],
        fn event, measurements, meta, _ -> send(parent, {ref, event, measurements, meta}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach("commands-test-#{inspect(ref)}") end)

      view = mount_view()
      search(view, :workbooks, "phys")
      run(view, "theme", %{theme: "dark"})
      render_hook(view, "sutra-ui:command-ran", %{"id" => "home"})

      assert_receive {^ref, [:sutra_ui, :commands, :search], %{count: 2},
                      %{source: :workbooks, query_length: 4, ok: true}}

      assert_receive {^ref, [:sutra_ui, :commands, :run], _,
                      %{id: "theme", kind: :server, ok: true}}

      assert_receive {^ref, [:sutra_ui, :commands, :run], _, %{id: "home", kind: :client}}
    end
  end
end
