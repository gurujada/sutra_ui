defmodule SutraUI.TimelineTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Timeline

  test "renders timeline items" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Timeline.timeline>
        <:item title="Created" time="09:00" description="Workspace created" />
        <:item title="Published" state="current">Live now</:item>
      </Timeline.timeline>
      """)

    assert html =~ ~s(class="timeline )
    assert html =~ "Created"
    assert html =~ "09:00"
    assert html =~ "Workspace created"
    assert html =~ ~s(data-state="current")
    assert html =~ "Live now"
  end
end
