defmodule PhxUI.KbdTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Kbd

  describe "kbd/1 rendering" do
    test "renders as kbd element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd>K</Kbd.kbd>
        """)

      assert html =~ "<kbd"
      assert html =~ "</kbd>"
      assert html =~ "K"
    end

    test "renders inner block content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd>Ctrl + S</Kbd.kbd>
        """)

      assert html =~ "Ctrl + S"
    end

    test "renders special characters" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd>⌘</Kbd.kbd>
        """)

      assert html =~ "⌘"
    end
  end

  describe "kbd/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd class="ml-2">Enter</Kbd.kbd>
        """)

      assert html =~ "ml-2"
    end
  end

  describe "kbd/1 global attributes" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd id="shortcut-key">K</Kbd.kbd>
        """)

      assert html =~ ~s(id="shortcut-key")
    end

    test "passes through title for tooltip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd title="Press K to search">K</Kbd.kbd>
        """)

      assert html =~ ~s(title="Press K to search")
    end
  end

  describe "kbd/1 styling" do
    test "includes base styling classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Kbd.kbd>K</Kbd.kbd>
        """)

      # Should have some basic styling (not testing exact classes)
      assert html =~ "class="
      assert html =~ "font-mono"
    end
  end
end
