defmodule SutraUI.CommandTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Command

  describe "command/1 rendering" do
    test "renders with correct structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="test-command">
          <Command.command_item id="item-1">Item 1</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(id="test-command")
      assert html =~ "command"
      assert html =~ "Item 1"
    end

    test "renders search input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="test-command" placeholder="Search...">
          <Command.command_item id="item-1">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(placeholder="Search...")
      assert html =~ "<input"
      assert html =~ ~s(role="combobox")
    end

    test "renders search icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="test-command">
          <Command.command_item id="item-1">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ "lucide-search"
    end
  end

  describe "command_item/1" do
    test "renders item with correct id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="my-item">My Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(id="my-item")
      assert html =~ "My Item"
    end

    test "includes keywords in data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item" keywords={["search", "find"]}>Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(data-keywords="search find")
    end

    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item" disabled>Disabled Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(aria-disabled="true")
    end

    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item" class="my-class">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ "my-class"
    end

    test "has role=menuitem" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(role="menuitem")
    end
  end

  describe "command_group/1" do
    test "renders group with heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_group heading="Actions">
            <Command.command_item id="item">Item</Command.command_item>
          </Command.command_group>
        </Command.command>
        """)

      assert html =~ "Actions"
      assert html =~ ~s(role="group")
    end

    test "renders group without heading" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_group>
            <Command.command_item id="item">Item</Command.command_item>
          </Command.command_group>
        </Command.command>
        """)

      assert html =~ ~s(role="group")
    end

    test "has role=group with aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_group heading="Group">
            <Command.command_item id="item">Item</Command.command_item>
          </Command.command_group>
        </Command.command>
        """)

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-label="Group")
    end
  end

  describe "command_separator/1" do
    test "renders separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item1">Item 1</Command.command_item>
          <Command.command_separator />
          <Command.command_item id="item2">Item 2</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(role="separator")
      assert html =~ "<hr"
    end
  end

  describe "command_dialog/1" do
    test "renders dialog wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command_dialog id="cmd-dialog">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command_dialog>
        """)

      assert html =~ ~s(id="cmd-dialog")
      assert html =~ "command-dialog"
      assert html =~ "<dialog"
    end

    test "includes on_cancel attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command_dialog id="cmd-dialog" on_cancel="close_palette">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command_dialog>
        """)

      assert html =~ ~s(on_cancel="close_palette")
    end

    test "passes placeholder to inner command" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command_dialog id="cmd-dialog" placeholder="Type to search...">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command_dialog>
        """)

      assert html =~ ~s(placeholder="Type to search...")
    end
  end

  describe "command/1 accessibility" do
    test "has aria-autocomplete on input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(aria-autocomplete="list")
    end

    test "has aria-expanded on input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(aria-expanded="true")
    end

    test "has aria-controls linking to menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="test-cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(aria-controls="test-cmd-menu")
      assert html =~ ~s(id="test-cmd-menu")
    end

    test "menu has role=menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ ~s(role="menu")
    end
  end

  describe "show_command_dialog/2 and hide_command_dialog/2" do
    test "show_command_dialog returns JS struct" do
      js = Command.show_command_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_command_dialog returns JS struct" do
      js = Command.hide_command_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "show_command_dialog with existing JS struct" do
      js = Phoenix.LiveView.JS.push("event") |> Command.show_command_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_command_dialog with existing JS struct" do
      js = Phoenix.LiveView.JS.push("event") |> Command.hide_command_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end
  end

  describe "command/1 phx-hook" do
    test "has phx-hook for command behavior" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Command.command id="cmd">
          <Command.command_item id="item">Item</Command.command_item>
        </Command.command>
        """)

      assert html =~ "phx-hook"
    end
  end
end
