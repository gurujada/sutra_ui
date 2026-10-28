defmodule SutraUI.PopoverLiveTest do
  # Reuses the toast test endpoint (one named process), so not async.
  use ExUnit.Case, async: false
  @moduletag :capture_log

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint SutraUI.ToastLive.Endpoint

  defmodule Page do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"""
      <SutraUI.Popover.popover id="who">
        <:trigger><SutraUI.Avatar.avatar id="who-face" initials="AR" /></:trigger>
        Details
      </SutraUI.Popover.popover>
      <SutraUI.Popover.popover id="toggle">
        <:trigger :let={open}>{if open, do: "Close", else: "Open"}</:trigger>
        More
      </SutraUI.Popover.popover>
      """
    end
  end

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

  test "an element with an id inside the trigger is rendered once (no duplicate id)" do
    conn = Plug.Test.init_test_session(build_conn(), %{})
    {:ok, view, html} = live_isolated(conn, Page)

    assert [_] = Regex.scan(~r/id="who-face"/, html)
    assert has_element?(view, "#who-face")
  end

  test "a trigger that reads open still shows both words" do
    conn = Plug.Test.init_test_session(build_conn(), %{})
    {:ok, _view, html} = live_isolated(conn, Page)

    assert html =~ "popover-trigger-closed"
    assert html =~ "popover-trigger-open"
    assert html =~ "Close"
    assert html =~ "Open"
  end
end
