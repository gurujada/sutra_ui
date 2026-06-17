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
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ ~s(data-today="true")
    end

    test "renders prev/next navigation buttons" do
      assigns = %{}
      html = rendered_to_string(~H|<Calendar.calendar year={2026} month={6} />|)
      assert html =~ "Previous month"
      assert html =~ "Next month"
    end

    test "handles ISO string dates" do
      assigns = %{}

      html =
        rendered_to_string(~H|<Calendar.calendar year={2026} month={6} selected="2026-06-20" />|)

      assert html =~ ~s(data-selected="true")
    end
  end
end
