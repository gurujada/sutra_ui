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
  end
end
