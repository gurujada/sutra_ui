defmodule SutraUI.SkeletonTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Skeleton

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
    test "width and height are Tailwind classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton width="w-48" height="h-6" />
        """)

      assert html =~ ~r/class="skeleton [^"]*\bw-48 h-6\b/
      refute html =~ "style="
    end

    test "renders no style attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton />
        """)

      refute html =~ "style"
    end

    test "a CSS length still renders an inline style (deprecated, removed in 0.5)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton width="200px" height="3rem" />
        """)

      assert html =~ ~s(style="width: 200px; height: 3rem")
      refute html =~ ~r/class="[^"]*200px/
    end

    test "percent and auto are CSS lengths; class names are not" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Skeleton.skeleton width="100%" height="w-auto" />
        """)

      assert html =~ ~s(style="width: 100%")
      assert html =~ "w-auto"
    end
  end
end
