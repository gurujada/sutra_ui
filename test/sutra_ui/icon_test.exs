defmodule SutraUI.IconTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Icon

  describe "icon/1" do
    test "renders span with icon name as class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-check" />
        """)

      assert html =~ "<span"
      assert html =~ "lucide-check"
    end

    test "renders with default size-4 class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-x" />
        """)

      assert html =~ "size-4"
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-check" class="size-6 text-green-500" />
        """)

      assert html =~ "size-6"
      assert html =~ "text-green-500"
      assert html =~ "lucide-check"
    end

    test "decorative icons have aria-hidden=true by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-star" />
        """)

      assert html =~ ~s(aria-hidden="true")
    end

    test "meaningful icons with aria-label do not have aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-eye" aria-label="Visible" />
        """)

      assert html =~ ~s(aria-label="Visible")
      refute html =~ "aria-hidden"
    end

    test "passes through title attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-info" title="More information" />
        """)

      assert html =~ ~s(title="More information")
    end

    test "passes through role attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="lucide-check" role="img" aria-label="Success" />
        """)

      assert html =~ ~s(role="img")
    end
  end
end
