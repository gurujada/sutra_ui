defmodule SutraUI.TimelineTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.Timeline

  describe "timeline/1" do
    test "renders as ordered list" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item>Event 1</:item>
</Timeline.timeline>|)
      assert html =~ "<ol"
      assert html =~ "timeline"
    end

    test "renders items with content" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item>
    <p>Deployed v2.4</p>
  </:item>
  <:item><span>Merged PR</span></:item>
</Timeline.timeline>|)
      assert html =~ "Deployed v2.4"
      assert html =~ "Merged PR"
    end

    test "renders items with custom content" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item>
    <div class="custom"><img src="/a.png" />Jane completed a task</div>
  </:item>
</Timeline.timeline>|)
      assert html =~ "custom"
      assert html =~ "Jane completed a task"
    end

    test "renders marker dot" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item>Test</:item>
</Timeline.timeline>|)
      assert html =~ "timeline-dot"
    end

    test "renders state classes" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item state="complete">Done</:item>
  <:item state="current">Active</:item>
</Timeline.timeline>|)
      assert html =~ ~s(data-state="complete")
      assert html =~ ~s(data-state="current")
    end

    test "renders time label" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item time="2h ago">Event</:item>
</Timeline.timeline>|)
      assert html =~ "2h ago"
      assert html =~ "timeline-time"
      assert html =~ "timeline-dot"
    end

    test "renders custom icon in marker" do
      assigns = %{}
      html = rendered_to_string(~H|<Timeline.timeline>
  <:item icon="✓">Completed</:item>
</Timeline.timeline>|)
      assert html =~ "✓"
      assert html =~ "timeline-marker-icon"
    end
  end
end
