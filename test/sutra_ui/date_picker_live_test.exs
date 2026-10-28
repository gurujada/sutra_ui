defmodule SutraUI.DatePickerLiveTest do
  # Real LiveView forms: values are posted through the pickers' real inputs, so phx-change,
  # to_form and validation with SutraUI.DateRules (the same struct the calendar disables
  # days with) all run.
  use ExUnit.Case, async: true
  @moduletag :capture_log

  import Phoenix.LiveViewTest
  import Phoenix.Component
  import SutraUI.Test

  import SutraUI.ComponentCase, only: [assert_selector: 2, refute_selector: 2, get_attribute: 3]

  @endpoint SutraUI.DatePickerLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :sutra_ui

    @session [store: :cookie, key: "_date_test", signing_salt: "date_salt"]
    plug(Plug.Session, @session)
  end

  defmodule FormLive do
    use Phoenix.LiveView

    alias SutraUI.DateRules

    @rules %DateRules{
      min: ~D[2027-01-01],
      max: ~D[2027-12-31],
      disabled_weekdays: [7],
      max_length: 7
    }
    @time_rules %DateRules{step: 15}

    def mount(_params, _session, socket) do
      {:ok, assign(socket, form: to_form(%{}, as: :ev), errors: %{}, changes: 0, parsed: nil)}
    end

    def handle_event("validate", %{"ev" => params}, socket) do
      errors =
        %{}
        |> put_errors(:due, DateRules.errors(@rules, params["due"], today: ~D[2026-10-28]))
        |> put_errors(:opens, DateRules.errors(@time_rules, params["opens"]))
        |> put_errors(:period, range_errors(params["period"]))
        |> put_errors(:starts_at, starts_errors(params["starts_at"]))

      form =
        to_form(params, as: :ev, errors: Enum.map(errors, fn {k, [m | _]} -> {k, {m, []}} end))

      {:noreply,
       assign(socket,
         form: form,
         errors: errors,
         changes: socket.assigns.changes + 1,
         parsed: parse(params["starts_at"])
       )}
    end

    defp put_errors(map, _field, []), do: map

    defp put_errors(map, field, errors),
      do: Map.put(map, field, Enum.map(errors, fn {msg, opts} -> interpolate(msg, opts) end))

    defp interpolate(msg, opts),
      do:
        Regex.replace(~r/%\{(\w+)\}/, msg, fn _, k ->
          to_string(opts[String.to_existing_atom(k)])
        end)

    defp range_errors(%{"start" => s, "end" => e}) when s != "" and e != "" do
      case DateRules.check_range(
             @rules,
             Date.from_iso8601!(s),
             Date.from_iso8601!(e),
             ~D[2026-10-28]
           ) do
        :ok -> []
        {:error, reason} -> [{"range: #{reason}", []}]
      end
    end

    defp range_errors(_), do: []

    defp starts_errors(value) do
      case parse(value) do
        {:ok, dt} -> DateRules.errors(%DateRules{}, dt, zone: "Asia/Kolkata")
        {:gap, _, _} -> [{"does not exist on that day (clocks skip forward)", []}]
        {:ambiguous, _, _} -> [{"happens twice that day (clocks go back)", []}]
        _ -> []
      end
    end

    defp parse(nil), do: nil
    defp parse(value), do: SutraUI.Time.parse_datetime(value, "America/New_York")

    def render(assigns) do
      ~H"""
      <.form for={@form} id="ev-form" phx-change="validate">
        <SutraUI.DatePicker.date_picker
          field={@form[:due]}
          label="Due"
          rules={rules(:due)}
          zone="Asia/Kolkata"
          aria-invalid={@errors[:due] && "true"}
        />
        <SutraUI.DatePicker.date_range_picker
          field={@form[:period]}
          label="Period"
          rules={rules(:due)}
          preset_key
        />
        <SutraUI.DatePicker.time_picker field={@form[:opens]} label="Opens" step={15} />
        <SutraUI.DatePicker.datetime_picker
          field={@form[:starts_at]}
          label="Starts"
          zone="America/New_York"
        />
        <p :for={{field, [msg | _]} <- @errors} id={"err-#{field}"}>{msg}</p>
      </.form>
      <p id="changes">{@changes}</p>
      """
    end

    defp rules(:due), do: @rules
  end

  setup_all do
    Application.put_env(:sutra_ui, Endpoint,
      secret_key_base: String.duplicate("d", 64),
      live_view: [signing_salt: "date_lv_salt"],
      server: false
    )

    start_supervised!(Endpoint)
    :ok
  end

  setup do
    conn = Phoenix.ConnTest.build_conn() |> Plug.Test.init_test_session(%{})
    {:ok, view, _html} = live_isolated(conn, FormLive, session: %{})
    {:ok, view: view}
  end

  test "picking a day posts it through the real input and phx-change fires once", %{view: view} do
    html = pick(view, "ev[due]", ~D[2027-03-16], form: "#ev-form")

    assert_selector(html, ~s(input#ev_due[value="2027-03-16"]))
    assert render(view) =~ ~s(id="changes">1<)
    refute_selector(html, "#err-due")
  end

  test "the server refuses what the calendar greys out (before the minimum, and a Sunday)", %{
    view: view
  } do
    html = pick(view, "ev[due]", ~D[2026-12-31], form: "#ev-form")
    assert get_attribute(html, "#err-due", "id") == "err-due"
    assert html =~ "must be on or after 1 Jan 2027"
    assert get_attribute(html, "input#ev_due", "aria-invalid") == "true"

    # 7 Mar 2027 is a Sunday
    html = pick(view, "ev[due]", ~D[2027-03-07], form: "#ev-form")
    assert html =~ "is not available on a weekday"

    html = pick(view, "ev[due]", ~D[2027-03-08], form: "#ev-form")
    refute_selector(html, "#err-due")
  end

  test "a range posts name[start] and name[end] and the length rule applies", %{view: view} do
    html = pick(view, "ev[period]", {~D[2027-03-01], ~D[2027-03-05]}, form: "#ev-form")
    assert_selector(html, ~s(input#ev_period[name="ev[period][start]"][value="2027-03-01"]))
    assert_selector(html, ~s(input#ev_period-end[value="2027-03-05"]))
    refute_selector(html, "#err-period")

    html = pick(view, "ev[period]", {~D[2027-03-01], ~D[2027-03-09]}, form: "#ev-form")
    assert html =~ "range: too_long"
  end

  test "a preset posts its key beside the dates, so a filter can stay relative", %{view: view} do
    html =
      pick(view, "ev[period]", {:preset, :last_7_days}, form: "#ev-form", today: ~D[2027-03-15])

    assert_selector(html, ~s(input[name="ev[period][preset]"][value="last_7_days"]))
    assert_selector(html, ~s(input#ev_period[value="2027-03-09"]))
    assert_selector(html, ~s(input#ev_period-end[value="2027-03-15"]))
  end

  test "a time off the step is refused", %{view: view} do
    html = pick(view, "ev[opens]", ~T[09:20:00], form: "#ev-form")
    assert html =~ "must be a multiple of 15 minutes"
    assert_selector(html, ~s(input#ev_opens[value="09:20"]))

    html = pick(view, "ev[opens]", ~T[09:30:00], form: "#ev-form")
    refute_selector(html, "#err-opens")
  end

  describe "a datetime in a zone with clock changes (New York)" do
    test "an ordinary moment posts its offset and shows as the same wall time", %{view: view} do
      html =
        pick(view, "ev[starts_at]", ~U[2027-03-15 13:00:00Z],
          form: "#ev-form",
          zone: "America/New_York"
        )

      assert_selector(html, ~s(input#ev_starts_at[value="2027-03-15T09:00"]))

      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") ==
               "2027-03-15T09:00:00-04:00"

      assert get_attribute(html, "#ev_starts_at-wrapper", "data-resolution") == "ok"
    end

    test "a skipped hour is shown, never guessed", %{view: view} do
      html = pick(view, "ev[starts_at]", "2026-03-08T02:30", form: "#ev-form")

      assert get_attribute(html, "#ev_starts_at-wrapper", "data-resolution") == "gap"
      assert html =~ "does not exist on that day"
      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") == ""
    end

    test "a repeated hour is ambiguous until an offset says which", %{view: view} do
      html = pick(view, "ev[starts_at]", "2026-11-01T01:30", form: "#ev-form")
      assert get_attribute(html, "#ev_starts_at-wrapper", "data-resolution") == "ambiguous"
      assert html =~ "happens twice"

      html = pick(view, "ev[starts_at]", "2026-11-01T01:30:00-05:00", form: "#ev-form")
      assert get_attribute(html, "#ev_starts_at-wrapper", "data-resolution") == "ok"
      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") =~ "-05:00"
    end
  end

  describe "SutraUI.Test.Dates.params/3" do
    test "builds the nested params a picker posts" do
      assert params("task[due]", ~D[2027-03-15]) == %{"task" => %{"due" => "2027-03-15"}}
      assert params("t[opens]", ~T[09:00:00]) == %{"t" => %{"opens" => "09:00"}}

      assert params("t[p]", {~D[2027-03-01], ~D[2027-03-07]}) ==
               %{"t" => %{"p" => %{"start" => "2027-03-01", "end" => "2027-03-07"}}}

      assert params("t[p]", {~D[2027-03-01], ~D[2027-03-07]}, start_key: "from", end_key: "to") ==
               %{"t" => %{"p" => %{"from" => "2027-03-01", "to" => "2027-03-07"}}}

      assert params("t[at]", ~U[2027-03-15 03:30:00Z], zone: "Asia/Kolkata") ==
               %{"t" => %{"at" => "2027-03-15T09:00:00+05:30"}}

      assert params("t[at]", ~N[2026-03-08 02:30:00], zone: "America/New_York") ==
               %{"t" => %{"at" => "2026-03-08T02:30"}}

      assert %{
               "t" => %{
                 "p" => %{
                   "preset" => "this_month",
                   "start" => "2027-03-01",
                   "end" => "2027-03-31"
                 }
               }
             } =
               params("t[p]", {:preset, :this_month}, today: ~D[2027-03-15])
    end
  end
end
