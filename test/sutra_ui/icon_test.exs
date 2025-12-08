defmodule SutraUI.IconTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Icon

  describe "icon/1" do
    test "renders with name as class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-check" />
        """)

      assert html =~ "hero-check"
      assert html =~ "<span"
    end

    test "renders with default size-4 class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-x-mark" />
        """)

      assert html =~ "size-4"
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-check" class="size-6 text-green-500" />
        """)

      assert html =~ "size-6"
      assert html =~ "text-green-500"
      assert html =~ "hero-check"
    end

    test "decorative icons have aria-hidden=true by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-star" />
        """)

      assert html =~ ~s(aria-hidden="true")
    end

    test "meaningful icons with aria-label do not have aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-eye" aria-label="Visible" />
        """)

      assert html =~ ~s(aria-label="Visible")
      refute html =~ "aria-hidden"
    end

    test "passes through title attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-info" title="More information" />
        """)

      assert html =~ ~s(title="More information")
    end

    test "passes through role attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-check" role="img" aria-label="Success" />
        """)

      assert html =~ ~s(role="img")
    end

    test "renders as span element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Icon.icon name="hero-check" />
        """)

      # Should be a span, not svg or other element
      assert html =~ ~r/<span[^>]*class="[^"]*hero-check/
    end
  end
end
