defmodule SutraUI.ActivityTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Activity

  describe "activity/1" do
    test "renders activity item content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <:item status="complete">
            <div class="activity-title">Searched docs</div>
          </:item>
          <:item status="running">
            <div class="activity-title">Drafting answer</div>
            <p>Reading examples.</p>
          </:item>
        </Activity.activity>
        """)

      assert html =~ "<ol"
      assert html =~ "activity"
      assert html =~ "Searched docs"
      assert html =~ "Drafting answer"
      assert html =~ "Reading examples."
      assert html =~ ~s(data-status="complete")
      assert html =~ ~s(data-status="running")
    end

    test "defaults item status to pending" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <:item>Waiting</:item>
        </Activity.activity>
        """)

      assert html =~ ~s(data-status="pending")
    end

    test "renders optional ids and classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity class="my-activity" compact>
          <:item id="deploy-failed" status="error" class="my-item">
            Deploy failed
          </:item>
        </Activity.activity>
        """)

      assert html =~ "my-activity"
      assert html =~ "activity-compact"
      assert html =~ ~s(id="deploy-failed")
      assert html =~ "my-item"
      assert html =~ "Deploy failed"
      assert html =~ ~s(data-status="error")
    end

    test "passes root attributes through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity id="agent-progress" aria-label="Agent progress">
          <:item>Started</:item>
        </Activity.activity>
        """)

      assert html =~ ~s(id="agent-progress")
      assert html =~ ~s(aria-label="Agent progress")
    end

    test "sets a default aria label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <:item>Started</:item>
        </Activity.activity>
        """)

      assert html =~ ~s(aria-label="Activity")
    end

    test "renders a custom marker slot for named items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <:marker :let={item}>
            <span class="custom-marker">{item[:status]}</span>
          </:marker>
          <:item status="running">Searching</:item>
        </Activity.activity>
        """)

      assert html =~ "custom-marker"
      assert html =~ "running"
      refute html =~ "activity-dot"
    end

    test "renders activity_item for fully custom rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <Activity.activity_item id="tool-read" status="complete" class="custom-row">
            <:marker>
              <span class="avatar-marker">VR</span>
            </:marker>

            <div class="custom-content">Read source files</div>
          </Activity.activity_item>
        </Activity.activity>
        """)

      assert html =~ ~s(id="tool-read")
      assert html =~ ~s(data-status="complete")
      assert html =~ "custom-row"
      assert html =~ "avatar-marker"
      assert html =~ "custom-content"
      refute html =~ "activity-dot"
    end

    test "can mix named items with custom rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <:item status="complete">Named row</:item>

          <Activity.activity_item status="running">
            Custom row
          </Activity.activity_item>
        </Activity.activity>
        """)

      assert html =~ "Named row"
      assert html =~ "Custom row"
      assert html =~ ~s(data-status="complete")
      assert html =~ ~s(data-status="running")
    end

    test "renders activity_item without a custom marker" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Activity.activity>
          <Activity.activity_item status="running">
            Streaming a row
          </Activity.activity_item>
        </Activity.activity>
        """)

      assert html =~ "Streaming a row"
      assert html =~ ~s(data-status="running")
      assert html =~ "activity-dot"
    end
  end
end
