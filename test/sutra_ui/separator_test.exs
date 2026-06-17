defmodule SutraUI.SeparatorTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Separator

  describe "separator/1 rendering" do
    test "renders as hr element by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator />
        """)

      assert html =~ "<hr"
      assert html =~ ~s(class="separator")
      assert html =~ ~s(data-orientation="horizontal")
    end

    test "renders horizontal separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator orientation="horizontal" />
        """)

      assert html =~ "<hr"
      assert html =~ ~s(class="separator")
      assert html =~ ~s(data-orientation="horizontal")
    end

    test "renders vertical separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator orientation="vertical" />
        """)

      assert html =~ "<hr"
      assert html =~ ~s(class="separator")
      assert html =~ ~s(data-orientation="vertical")
    end
  end

  describe "separator/1 decorative" do
    test "renders presentational separator by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator />
        """)

      assert html =~ ~s(role="presentation")
      assert html =~ ~s(aria-hidden="true")
    end

    test "renders semantic separator when decorative is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator decorative={false} />
        """)

      assert html =~ ~s(role="separator")
      refute html =~ "aria-hidden"
    end

    test "sets aria-orientation for semantic vertical separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator orientation="vertical" decorative={false} />
        """)

      assert html =~ ~s(role="separator")
      assert html =~ ~s(aria-orientation="vertical")
    end
  end

  describe "separator/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator class="my-8" />
        """)

      assert html =~ "my-8"
      assert html =~ "separator"
    end
  end

  describe "separator/1 global attributes" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator id="custom-sep" />
        """)

      assert html =~ ~s(id="custom-sep")
    end

    test "passes through aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Separator.separator decorative={false} aria-label="Section break" />
        """)

      assert html =~ ~s(aria-label="Section break")
    end
  end
end
