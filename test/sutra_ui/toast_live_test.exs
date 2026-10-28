defmodule SutraUI.ToastLiveTest do
  # A real endpoint (one named process), so not async.
  use ExUnit.Case, async: false
  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import SutraUI.Toast.Test

  @endpoint SutraUI.ToastLive.Endpoint

  setup_all do
    Application.put_env(:sutra_ui, @endpoint,
      secret_key_base: String.duplicate("s", 64),
      live_view: [signing_salt: "toastlive"],
      server: false,
      render_errors: [formats: [html: SutraUI.ToastLive.ErrorHTML], layout: false]
    )

    start_supervised!(@endpoint)
    :ok
  end

  setup do
    conn = Plug.Test.init_test_session(build_conn(), %{})
    {:ok, view, _html} = live(conn, "/toast")
    %{view: view}
  end

  # What the ToastGroup hook sends: events for the stack's LiveComponent.
  defp hook_event(view, event, payload) do
    view |> with_target("[data-toast-stack]") |> render_hook(event, payload)
  end

  defp send_toast(view, params) do
    render_hook(view, "send", params)
  end

  defp toasts(view) do
    view |> render() |> LazyHTML.from_fragment() |> LazyHTML.query("[data-toast]")
  end

  defp attr(view, id, attr) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("##{id}")
    |> LazyHTML.attribute(attr)
  end

  test "the live group holds a connection notice, hidden until the hook shows it", %{view: view} do
    doc = view |> render() |> LazyHTML.from_fragment()

    assert doc |> LazyHTML.query("section#toast-group") |> LazyHTML.attribute("data-live") == [
             "true"
           ]

    notice = LazyHTML.query(doc, "[data-toast-notice]")
    assert LazyHTML.attribute(notice, "role") == ["alert"]
    assert LazyHTML.attribute(notice, "hidden") == [""]
    assert LazyHTML.attribute(notice, "phx-disconnected") != []
    assert LazyHTML.attribute(notice, "phx-connected") != []
    assert LazyHTML.text(notice) =~ "Can't reach the server"
  end

  test "a sent toast appears with its kind, text and timing", %{view: view} do
    send_toast(view, %{"kind" => "success", "body" => "Saved", "id" => "a"})
    assert_toast(view, :success, "Saved")
    assert attr(view, "toast-a", "data-duration") == ["5000"]
    assert attr(view, "toast-a", "role") == ["status"]
  end

  test "an error stays until dismissed", %{view: view} do
    send_toast(view, %{"kind" => "error", "body" => "Broke", "id" => "e"})
    assert attr(view, "toast-e", "data-duration") == ["0"]
    assert attr(view, "toast-e", "role") == ["alert"]
  end

  test "an action keeps a toast until dismissed unless a duration is given", %{view: view} do
    send_toast(view, %{"kind" => "info", "body" => "Deleted", "id" => "u", "action" => "1"})
    assert attr(view, "toast-u", "data-duration") == ["0"]
    assert attr(view, "toast-u", "data-countdown") == []

    send_toast(view, %{
      "kind" => "info",
      "body" => "Deleted",
      "id" => "u2",
      "action" => "1",
      "duration" => 8000
    })

    assert attr(view, "toast-u2", "data-duration") == ["8000"]
    assert attr(view, "toast-u2", "data-countdown") == ["true"]
    assert render(view) =~ "Undo"
  end

  test "several toasts stack", %{view: view} do
    send_toast(view, %{"kind" => "info", "body" => "One", "id" => "1"})
    send_toast(view, %{"kind" => "warning", "body" => "Two", "id" => "2"})
    assert Enum.count(toasts(view)) == 2
    assert_toast(view, :info, "One")
    assert_toast(view, :warning, "Two")
    refute_toast(view, :error)
  end

  test "sending the same id again replaces the toast and restarts its timer", %{view: view} do
    send_toast(view, %{"kind" => "info", "body" => "First", "id" => "same"})
    assert attr(view, "toast-same", "data-version") == ["0"]
    send_toast(view, %{"kind" => "info", "body" => "Second", "id" => "same"})
    assert Enum.count(toasts(view)) == 1
    assert attr(view, "toast-same", "data-version") == ["1"]
    assert render(view) =~ "Second"
  end

  test "update changes a toast in place", %{view: view} do
    send_toast(view, %{"kind" => "info", "body" => "Uploading…", "id" => "up", "duration" => 0})
    render_hook(view, "update", %{"id" => "up", "kind" => "success", "body" => "Uploaded"})
    assert Enum.count(toasts(view)) == 1
    assert_toast(view, :success, "Uploaded")
    refute_toast(view, :info)
    assert attr(view, "toast-up", "data-version") == ["1"]
  end

  test "the hook's dismiss and remove events reach the component", %{view: view} do
    send_toast(view, %{"kind" => "info", "body" => "Bye", "id" => "d2"})

    hook_event(view, "dismiss", %{"id" => "d2"})

    assert attr(view, "toast-d2", "data-state") == ["closing"]

    hook_event(view, "remove", %{"id" => "d2"})

    assert Enum.count(toasts(view)) == 0
  end

  test "more than three fold into \"+n more\"", %{view: view} do
    for n <- 1..5, do: send_toast(view, %{"kind" => "info", "body" => "T#{n}", "id" => "#{n}"})
    html = render(view)
    doc = LazyHTML.from_fragment(html)
    assert doc |> LazyHTML.query("[data-toast][data-folded=true]") |> Enum.count() == 2
    assert doc |> LazyHTML.query("[data-toast]:not([data-folded])") |> Enum.count() == 3
    assert doc |> LazyHTML.query("[data-toast-more]") |> LazyHTML.text() =~ "+2 more"
  end

  test "a toast sent from a LiveComponent appears", %{view: view} do
    view |> element("#from-component") |> render_click()
    assert_toast(view, :success, "Sent by a component")
  end

  test "a server flash becomes a toast, once", %{view: view} do
    render_hook(view, "flash", %{"kind" => "info", "body" => "Flash saved"})
    assert_toast(view, :info, "Flash saved")
    assert attr(view, "toast-flash-info", "data-flash") == ["info"]
    # an unrelated re-render must not add it again
    send_toast(view, %{"kind" => "info", "body" => "Other", "id" => "o"})
    assert Enum.count(toasts(view)) == 2
  end

  test "the same flash shows again after the flash was cleared", %{view: view} do
    render_hook(view, "flash", %{"kind" => "info", "body" => "Again"})
    hook_event(view, "remove", %{"id" => "flash-info"})
    assert Enum.count(toasts(view)) == 0
    render_hook(view, "lv:clear-flash", %{"key" => "info"})
    render_hook(view, "flash", %{"kind" => "info", "body" => "Again"})
    assert_toast(view, :info, "Again")
  end

  test "put_toast on a socket queues a toast that the group shows", %{view: view} do
    render_hook(view, "put_toast", %{"kind" => "success", "body" => "Queued for the group"})
    assert_toast(view, :success, "Queued for the group")
  end

  test "the browser can ask for a toast", %{view: view} do
    hook_event(view, "toast", %{"kind" => "success", "body" => "Copied"})

    assert_toast(view, :success, "Copied")
  end

  test "the 0.4 push event still works (variant, title, description)", %{view: view} do
    hook_event(view, "toast", %{
      "variant" => "destructive",
      "title" => "Failed",
      "description" => "Try again"
    })

    assert_toast(view, :error, "Failed")
    assert_toast(view, :error, "Try again")
  end

  test "a bad kind from the browser falls back to info instead of crashing", %{view: view} do
    hook_event(view, "toast", %{"kind" => "loud", "body" => "Hm"})
    assert_toast(view, :info, "Hm")
  end

  test "assert_toast fails with a clear message when nothing matches", %{view: view} do
    assert_raise ExUnit.AssertionError, ~r/expected a error toast containing "x"/, fn ->
      assert_toast(view, :error, "x")
    end
  end

  describe "confirm" do
    test "confirm_dialog: the verb pushes its event with the values", %{view: view} do
      import SutraUI.Confirm.Test
      confirm(view, "#retire")
      assert_toast(view, :info, "Retired 7")
    end

    test "confirm on a plain element clicks it (data-confirm is ignored in tests)", %{view: view} do
      import SutraUI.Confirm.Test
      confirm(view, "#plain")
      assert_toast(view, :info, "Plain done")
    end
  end
end
