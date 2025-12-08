defmodule SutraUI.ProgressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Progress

  describe "progress/1 rendering" do
    test "renders progress container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ ~s(class="progress)
    end

    test "renders progress indicator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ "progress-indicator"
    end

    test "sets correct width style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={75} />
        """)

      assert html =~ "width: 75%"
    end
  end

  describe "progress/1 value clamping" do
    test "clamps value to 0 minimum" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={-10} />
        """)

      assert html =~ "width: 0%"
      assert html =~ ~s(aria-valuenow="0")
    end

    test "clamps value to 100 maximum" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={150} />
        """)

      assert html =~ "width: 100%"
      assert html =~ ~s(aria-valuenow="100")
    end
  end

  describe "progress/1 sizes" do
    test "renders default size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ ~s(class="progress)
      refute html =~ "progress-sm"
      refute html =~ "progress-lg"
      refute html =~ "progress-xl"
    end

    test "renders small size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} size="sm" />
        """)

      assert html =~ "progress-sm"
    end

    test "renders large size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} size="lg" />
        """)

      assert html =~ "progress-lg"
    end

    test "renders extra large size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} size="xl" />
        """)

      assert html =~ "progress-xl"
    end
  end

  describe "progress/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} class="my-progress" />
        """)

      assert html =~ "my-progress"
    end
  end

  describe "progress/1 accessibility" do
    test "has role=progressbar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ ~s(role="progressbar")
    end

    test "has aria-valuemin" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ ~s(aria-valuemin="0")
    end

    test "has aria-valuemax" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} />
        """)

      assert html =~ ~s(aria-valuemax="100")
    end

    test "has aria-valuenow" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={75} />
        """)

      assert html =~ ~s(aria-valuenow="75")
    end

    test "includes aria_label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} aria_label="Upload progress" />
        """)

      assert html =~ ~s(aria-label="Upload progress")
    end
  end

  describe "progress/1 with id" do
    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Progress.progress value={50} id="my-progress" />
        """)

      assert html =~ ~s(id="my-progress")
    end
  end
end
