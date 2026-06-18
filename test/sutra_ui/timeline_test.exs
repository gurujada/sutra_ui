defmodule SutraUI.TimelineTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Timeline

  describe "timeline/1" do
    test "renders items from the item slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline>
          <:item time="2h ago">
            <h3>Deployed</h3>
            <p>All checks passed.</p>
          </:item>
        </Timeline.timeline>
        """)

      assert html =~ "<ol"
      assert html =~ "timeline"
      assert html =~ "timeline-item"
      assert html =~ "2h ago"
      assert html =~ "<h3>Deployed</h3>"
      assert html =~ "<p>All checks passed.</p>"
    end

    test "renders a dot and connector by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline>
          <:item>Event</:item>
        </Timeline.timeline>
        """)

      assert html =~ "timeline-dot"
      assert html =~ "timeline-line"
      assert html =~ "Event"
    end

    test "renders an icon marker" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline>
          <:item icon="✓">Completed</:item>
        </Timeline.timeline>
        """)

      assert html =~ "✓"
      assert html =~ "timeline-marker-icon"
      refute html =~ "timeline-dot"
    end

    test "renders multiple items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline>
          <:item>Created</:item>
          <:item>Published</:item>
        </Timeline.timeline>
        """)

      assert html =~ "Created"
      assert html =~ "Published"
    end

    test "omits time element when time is not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline>
          <:item>Event</:item>
        </Timeline.timeline>
        """)

      refute html =~ "<time"
    end

    test "passes root attributes through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline id="activity" aria-label="Activity">
          <:item>Event</:item>
        </Timeline.timeline>
        """)

      assert html =~ ~s(id="activity")
      assert html =~ ~s(aria-label="Activity")
    end

    test "applies custom root and item classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Timeline.timeline class="my-timeline">
          <:item class="my-item">
            Event
          </:item>
        </Timeline.timeline>
        """)

      assert html =~ "my-timeline"
      assert html =~ "my-item"
    end
  end
end
