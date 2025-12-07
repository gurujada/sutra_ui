defmodule PhxUI.SkeletonTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Skeleton

  describe "skeleton/1 rendering" do
    test "renders skeleton container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      assert html =~ ~s(class="skeleton)
    end

    test "renders div element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      assert html =~ "<div"
    end
  end

  describe "skeleton/1 dimensions" do
    test "applies width style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton width="200px" />
        """)

      assert html =~ "width: 200px"
    end

    test "applies height style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton height="24px" />
        """)

      assert html =~ "height: 24px"
    end

    test "applies both width and height" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton width="100%" height="3rem" />
        """)

      assert html =~ "width: 100%"
      assert html =~ "height: 3rem"
    end

    test "no style when no dimensions specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      # Empty style attribute is still present but empty
      assert html =~ ~s(style="")
    end
  end

  describe "skeleton/1 radius" do
    test "defaults to md radius (no extra class)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      refute html =~ "rounded-none"
      refute html =~ "rounded-sm"
      refute html =~ "rounded-lg"
      refute html =~ "rounded-full"
    end

    test "renders none radius" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton radius="none" />
        """)

      assert html =~ "rounded-none"
    end

    test "renders sm radius" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton radius="sm" />
        """)

      assert html =~ "rounded-sm"
    end

    test "renders lg radius" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton radius="lg" />
        """)

      assert html =~ "rounded-lg"
    end

    test "renders full radius for circular shapes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton radius="full" />
        """)

      assert html =~ "rounded-full"
    end
  end

  describe "skeleton/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton class="my-skeleton" />
        """)

      assert html =~ "my-skeleton"
    end
  end

  describe "skeleton/1 accessibility" do
    test "has role=status" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      assert html =~ ~s(role="status")
    end

    test "has aria-label for screen readers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      assert html =~ ~s(aria-label="Loading...")
    end
  end

  describe "skeleton/1 with id" do
    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton id="my-skeleton" />
        """)

      assert html =~ ~s(id="my-skeleton")
    end
  end
end
