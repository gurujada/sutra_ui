defmodule SutraUI.DatePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  import SutraUI.ComponentCase,
    only: [assert_selector: 2, refute_selector: 2, get_attribute: 3]

  alias SutraUI.DatePicker
  alias SutraUI.DateRules

  defp render_picker(fun, attrs), do: render_component(fun, Map.new(attrs))

  defp date(attrs), do: render_picker(&DatePicker.date_picker/1, attrs)
  defp range(attrs), do: render_picker(&DatePicker.date_range_picker/1, attrs)
  defp time(attrs), do: render_picker(&DatePicker.time_picker/1, attrs)
  defp datetime(attrs), do: render_picker(&DatePicker.datetime_picker/1, attrs)

  defp json(html, selector, attr), do: html |> get_attribute(selector, attr) |> Jason.decode!()

  describe "date_picker" do
    test "a native date input in a closed wrapper; the hook reads the rest from data attributes" do
      html = date(id: "due", name: "due", value: ~D[2027-03-15], label: "Due")

      assert_selector(html, ~s(input#due[type="date"][name="due"][value="2027-03-15"]))
      assert get_attribute(html, "#due-wrapper", "data-state") == "closed"
      assert get_attribute(html, "#due-wrapper", "data-kind") == "date"
      assert get_attribute(html, "#due-wrapper", "data-label") == "Due"
      assert get_attribute(html, "#due-wrapper", "phx-hook") == "SutraUI.DatePicker.DatePicker"
      assert get_attribute(html, "#due-ui", "phx-update") == "ignore"
      refute html =~ "<script"
      refute html =~ ~r/\sstyle=/
    end

    test "an ISO string works, and nonsense is empty" do
      assert_selector(
        date(id: "d", name: "d", value: "2027-03-15"),
        ~s(input[value="2027-03-15"])
      )

      assert get_attribute(date(id: "d", name: "d", value: "tomorrow"), "input", "value") == ""
      assert get_attribute(date(id: "d", name: "d"), "input", "value") == ""
    end

    test "id, name and value come from a form field" do
      form = to_form(%{"due" => "2027-03-15"}, as: :task)
      html = date(field: form[:due], label: "Due")

      assert_selector(html, ~s(input#task_due[name="task[due]"][value="2027-03-15"]))
    end

    test "disabled and required reach the native input and the wrapper" do
      html = date(id: "d", name: "d", disabled: true, required: true)

      assert_selector(html, "input#d[disabled][required]")
      assert_selector(html, "#d-wrapper[data-disabled]")
    end

    test "rules are resolved for the hook and the native input" do
      rules = %DateRules{
        min: ~D[2027-01-01],
        max: ~D[2027-12-31],
        disabled_weekdays: [7],
        disabled_dates: [~D[2027-03-17]]
      }

      html = date(id: "d", name: "d", rules: rules)

      assert get_attribute(html, "input#d", "min") == "2027-01-01"
      assert get_attribute(html, "input#d", "max") == "2027-12-31"
      map = json(html, "#d-wrapper", "data-rules")
      assert map["min"] == "2027-01-01"
      assert map["disabledWeekdays"] == [7]
      assert map["disabledDates"] == ["2027-03-17"]
      assert map["today"] =~ ~r/^\d{4}-\d\d-\d\d$/
    end

    test "relative bounds are the place's today" do
      html =
        date(
          id: "d",
          name: "d",
          rules: %DateRules{min: :today, max: {:today, 5}},
          zone: "Asia/Kolkata"
        )

      map = json(html, "#d-wrapper", "data-rules")

      assert map["min"] == map["today"]
      assert Date.diff(Date.from_iso8601!(map["max"]), Date.from_iso8601!(map["today"])) == 5
      assert get_attribute(html, "#d-wrapper", "data-zone") == "Asia/Kolkata"
    end

    test "presets: defaults, none, labels, and custom values" do
      keys = fn html -> html |> json("#d-wrapper", "data-presets") |> Enum.map(& &1["key"]) end

      assert keys.(date(id: "d", name: "d")) == ~w(today tomorrow next_monday end_of_week)
      assert keys.(date(id: "d", name: "d", presets: [])) == []

      html =
        date(
          id: "d",
          name: "d",
          presets: [
            :today,
            {"soon", "Soon"},
            %{key: "term", label: "Start of term", value: ~D[2026-11-02]}
          ]
        )

      assert [
               %{"label" => "Today"},
               %{"label" => "Soon"},
               %{"label" => "Start of term", "value" => "2026-11-02"}
             ] =
               json(html, "#d-wrapper", "data-presets")
    end

    test "no id, name or field is an error" do
      assert_raise ArgumentError, ~r/id/, fn -> date([]) end
    end
  end

  describe "date_range_picker" do
    test "two native inputs, name[start] and name[end]" do
      html =
        range(
          id: "p",
          name: "f[period]",
          value: %{start: ~D[2027-03-01], end: ~D[2027-03-07]},
          label: "Period"
        )

      assert_selector(html, ~s(input#p[name="f[period][start]"][value="2027-03-01"]))
      assert_selector(html, ~s(input#p-end[name="f[period][end]"][value="2027-03-07"]))
      assert get_attribute(html, "#p-wrapper", "data-kind") == "range"
    end

    test "the key names are configurable" do
      html = range(id: "p", name: "f[when]", start_key: "from", end_key: "to")

      assert_selector(html, ~s(input[name="f[when][from]"]))
      assert_selector(html, ~s(input[name="f[when][to]"]))
    end

    test "values as a tuple or with string keys" do
      assert_selector(
        range(id: "p", name: "p", value: {~D[2027-03-01], ~D[2027-03-02]}),
        ~s(input[value="2027-03-02"])
      )

      assert_selector(
        range(id: "p", name: "p", value: %{"start" => "2027-03-01", "end" => "2027-03-09"}),
        ~s(input[value="2027-03-09"])
      )
    end

    test "range presets by default; preset_key adds the key input" do
      html =
        range(id: "p", name: "f[period]", preset_key: true, value: %{"preset" => "last_7_days"})

      assert json(html, "#p-wrapper", "data-presets") |> Enum.map(& &1["key"]) ==
               ~w(last_7_days last_30_days this_month)

      assert_selector(
        html,
        ~s(input[type="hidden"][name="f[period][preset]"][value="last_7_days"])
      )

      refute_selector(range(id: "p", name: "p"), ~s(input[type="hidden"]))
    end

    test "range length rules go to the hook" do
      html = range(id: "p", name: "p", rules: %DateRules{min_length: 2, max_length: 14})
      map = json(html, "#p-wrapper", "data-rules")
      assert map["minLength"] == 2 and map["maxLength"] == 14
    end
  end

  describe "time_picker" do
    test "a native time input with the step in seconds" do
      html = time(id: "t", name: "t", value: ~T[09:30:00], step: 15)

      assert_selector(html, ~s(input#t[type="time"][value="09:30"][step="900"]))
      assert get_attribute(html, "#t-wrapper", "data-step") == "15"
      assert get_attribute(html, "#t-wrapper", "data-kind") == "time"
    end

    test "a string value, and the step from the rules" do
      html = time(id: "t", name: "t", value: "14:05", rules: %DateRules{step: 5})

      assert_selector(html, ~s(input[value="14:05"][step="300"]))
      assert json(html, "#t-wrapper", "data-rules")["step"] == 5
    end

    test "no value, no presets" do
      html = time(id: "t", name: "t")
      assert get_attribute(html, "input", "value") == ""
      assert json(html, "#t-wrapper", "data-presets") == []
    end
  end

  describe "datetime_picker" do
    test "an instant shows as the wall time in the zone and posts with its offset" do
      html = datetime(id: "s", name: "s", zone: "Asia/Kolkata", value: ~U[2027-03-15 03:30:00Z])

      assert_selector(
        html,
        ~s(input#s[type="datetime-local"][value="2027-03-15T09:00"])
      )

      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") ==
               "2027-03-15T09:00:00+05:30"

      assert get_attribute(html, "#s-wrapper", "data-resolution") == "ok"
      assert get_attribute(html, "#s-wrapper", "data-zone") == "Asia/Kolkata"
    end

    test "the posted input starts disabled, so a page without JavaScript posts the browser's wall time once" do
      html = datetime(id: "s", name: "s", zone: "Asia/Kolkata", value: "2027-03-15T09:00")

      assert_selector(html, ~s(input[type="datetime-local"][name="s"]))
      assert_selector(html, ~s(input[type="hidden"][name="s"][disabled]))
    end

    test "a string with an offset is shown in the zone" do
      html =
        datetime(id: "s", name: "s", zone: "America/New_York", value: "2027-03-15T09:00:00+05:30")

      assert_selector(html, ~s(input[value="2027-03-14T23:30"]))
    end

    test "a skipped wall time keeps what was typed and posts nothing (New York, 8 Mar 2026)" do
      html =
        datetime(id: "s", name: "s", zone: "America/New_York", value: ~N[2026-03-08 02:30:00])

      assert get_attribute(html, "#s-wrapper", "data-resolution") == "gap"
      assert_selector(html, ~s(input[type="datetime-local"][value="2026-03-08T02:30"]))
      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") == ""
    end

    test "a repeated wall time is ambiguous and posts nothing until the offset says which (1 Nov 2026)" do
      html =
        datetime(id: "s", name: "s", zone: "America/New_York", value: ~N[2026-11-01 01:30:00])

      assert get_attribute(html, "#s-wrapper", "data-resolution") == "ambiguous"
      assert get_attribute(html, ~s(input[data-dp="posted"]), "value") == ""

      first =
        datetime(id: "s", name: "s", zone: "America/New_York", value: "2026-11-01T01:30:00-04:00")

      second =
        datetime(id: "s", name: "s", zone: "America/New_York", value: "2026-11-01T01:30:00-05:00")

      assert get_attribute(first, ~s(input[data-dp="posted"]), "value") =~ "-04:00"
      assert get_attribute(second, ~s(input[data-dp="posted"]), "value") =~ "-05:00"
    end

    test "empty" do
      html = datetime(id: "s", name: "s", zone: "Etc/UTC")
      assert get_attribute(html, "#s-wrapper", "data-resolution") == "empty"
    end

    test "a zone is required" do
      assert_raise ArgumentError, ~r/zone/, fn -> datetime(id: "s", name: "s", zone: nil) end
    end

    test "the hint words are configurable" do
      html = datetime(id: "s", name: "s", zone: "Asia/Kolkata", hint_label: "ahí")
      assert get_attribute(html, "#s-wrapper", "data-hint-label") == "ahí"
    end
  end
end
