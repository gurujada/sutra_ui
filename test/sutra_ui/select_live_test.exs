defmodule SutraUI.SelectLiveTest do
  # A real LiveView form: the value is changed through the real <select>, so phx-change,
  # to_form, validation errors and the option check of Phoenix.LiveViewTest all apply.
  use ExUnit.Case, async: true
  @moduletag :capture_log

  import Phoenix.LiveViewTest
  import Phoenix.Component

  import SutraUI.ComponentCase, only: [assert_selector: 2, refute_selector: 2, get_attribute: 3]

  @endpoint SutraUI.SelectLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :sutra_ui

    @session [store: :cookie, key: "_select_test", signing_salt: "select_salt"]
    plug(Plug.Session, @session)
  end

  defmodule FormLive do
    use Phoenix.LiveView

    def mount(_params, _session, socket) do
      form = to_form(%{"role" => "", "tags" => ["a"]}, as: :user)
      {:ok, assign(socket, form: form, changes: [])}
    end

    def handle_event("validate", %{"user" => params}, socket) do
      errors = if params["role"] == "", do: [role: {"can't be blank", []}], else: []
      form = to_form(params, as: :user, errors: errors, action: :validate)
      {:noreply, assign(socket, form: form, changes: [params | socket.assigns.changes])}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="user-form" phx-change="validate">
        <SutraUI.Input.input
          field={@form[:role]}
          type="select"
          label="Role"
          prompt="Choose"
          options={[{"Admin", "admin"}, {"Teacher", "teacher"}]}
        />
        <SutraUI.Input.input
          field={@form[:tags]}
          type="select"
          label="Tags"
          multiple
          options={["a", "b", "c"]}
        />
      </.form>
      <p id="changes">{length(@changes)}</p>
      """
    end
  end

  setup_all do
    Application.put_env(:sutra_ui, Endpoint,
      secret_key_base: String.duplicate("s", 64),
      live_view: [signing_salt: "select_lv_salt"],
      server: false
    )

    start_supervised!(Endpoint)
    :ok
  end

  setup do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})

    {:ok, conn: conn}
  end

  test "changing the real select fires phx-change, updates the trigger and shows errors", %{
    conn: conn
  } do
    {:ok, view, html} = live_isolated(conn, FormLive, session: %{})

    assert html =~ "Choose"

    html =
      view
      |> form("#user-form", user: %{role: "teacher"})
      |> render_change()

    assert render(view) =~ ~s(id="changes">1<)
    assert_selector(html, ~s(select#user_role option[value="teacher"][selected]))
    assert html =~ ~r/data-selected-label[^>]*>Teacher</
    refute_selector(html, "#user_role-error")

    html = view |> form("#user-form", user: %{role: ""}) |> render_change()

    assert_selector(html, "#user_role-error")
    assert get_attribute(html, "button#user_role-trigger", "aria-invalid") == "true"
    assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
  end

  test "a multiple select posts every chosen option", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive, session: %{})

    html = view |> form("#user-form", user: %{tags: ["a", "c"]}) |> render_change()

    assert html =~ ~r/select-chip">a</
    assert html =~ ~r/select-chip">c</
  end

  test "an option that is not in the select cannot be chosen", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, FormLive, session: %{})

    assert_raise ArgumentError, fn ->
      view |> form("#user-form", user: %{role: "root"}) |> render_change()
    end
  end
end
