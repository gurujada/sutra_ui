defmodule SutraUI.CalendarTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.Calendar

  describe "calendar/1" do
    test "renders calendar structure" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ "calendar"
      assert html =~ "June"
      assert html =~ "2026"
      assert html =~ ~s(role="grid")
    end

    test "renders weekdays" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={1} />|)
      assert html =~ "Sun"
      assert html =~ "Mon"
      assert html =~ "Sat"
    end

    test "renders day buttons" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ "calendar-day"
      assert length(Regex.scan(~r/class="calendar-week"/, html)) == 6
    end

    test "highlights selected date" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<Calendar.calendar year={2026} month={6} selected={~D[2026-06-15]} />|
        )

      assert html =~ ~s(data-selected="true")
    end

    test "marks today" do
      assigns = %{today: Date.utc_today()}
      html = rendered_to_string(~H|<Calendar.calendar year={@today.year} month={@today.month} />|)
      assert html =~ ~s(data-today="true")
    end

    test "renders prev/next navigation buttons" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ "Previous month"
      assert html =~ "Next month"
    end

    test "disables navigation buttons when no navigation event is provided" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ ~s(aria-label="Previous month" disabled)
      assert html =~ ~s(aria-label="Next month" disabled)
    end

    test "wires navigation buttons when a navigation event is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar year={2026} month={6} nav_event="nav_month" />|)

      assert html =~ ~s(phx-click="nav_month")
      assert html =~ ~s(phx-value-year="2026")
      assert html =~ ~s(phx-value-month="7")
    end

    test "supports any weekday as the first column" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar year={2026} month={6} week_start={2} />|)

      assert html =~ ~r/Tue.*Wed.*Thu.*Fri.*Sat.*Sun.*Mon/s

      assert html =~
               ~r/phx-value-date="2026-05-26".*phx-value-date="2026-05-27".*phx-value-date="2026-05-28".*phx-value-date="2026-05-29".*phx-value-date="2026-05-30".*phx-value-date="2026-05-31".*phx-value-date="2026-06-01"/s
    end

    test "does not render built-in month or year selector menus" do
      assigns = %{}

      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)

      refute html =~ "calendar-select"
      refute html =~ "calendar-caption"
    end

    test "handles ISO string dates" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar year={2026} month={6} selected="2026-06-20" />|)

      assert html =~ ~s(data-selected="true")
    end

    test "defaults to selected date month when year and month are omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar selected={~D[2026-11-20]} />|)

      assert html =~ "November"
      assert html =~ "2026"
      assert html =~ ~s(data-selected="true")
    end

    test "highlights reversed date ranges" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar
  year={2026}
  month={6}
  mode="range"
  selected={~D[2026-06-20]}
  range_end={~D[2026-06-10]}
/>|)

      assert html =~ ~s(data-in-range="true")
    end

    test "marks both range endpoints as selected" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar
  year={2026}
  month={6}
  mode="range"
  selected={~D[2026-06-10]}
  range_end={~D[2026-06-20]}
/>|)

      assert length(Regex.scan(~r/aria-selected="true"/, html)) == 2
      assert length(Regex.scan(~r/calendar-day-selected/, html)) == 2
    end

    test "marks range start and end endpoints" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar
  year={2026}
  month={6}
  mode="range"
  selected={~D[2026-06-10]}
  range_end={~D[2026-06-20]}
/>|)

      assert html =~ ~r/<button[^>]*data-range-start="true"[^>]*phx-value-date="2026-06-10"/
      assert html =~ ~r/<button[^>]*data-range-end="true"[^>]*phx-value-date="2026-06-20"/
      assert html =~ ~r/<button[^>]*data-in-range="true"[^>]*phx-value-date="2026-06-15"/
      assert html =~ "calendar-day-range-start"
      assert html =~ "calendar-day-range-end"
    end
  end
end
