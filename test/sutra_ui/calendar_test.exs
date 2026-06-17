defmodule SutraUI.CalendarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Calendar

  test "renders a month grid" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Calendar.calendar year={2026} month={6} selected="2026-06-17" today="2026-06-17" />
      """)

    assert html =~ "June 2026"
    assert html =~ ~s(role="grid")
    assert html =~ ~s(data-selected="true")
    assert html =~ ~s(aria-current="date")
    assert html =~ ~s(phx-value-date="2026-06-17")
  end

  test "supports monday week start" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Calendar.calendar year={2026} month={6} week_start={1} />
      """)

    assert html =~ ~s(<span role="columnheader">Mon</span>)
  end
end
