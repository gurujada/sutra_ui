defmodule SutraUI.ContextMenuTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.ContextMenu

  describe "context_menu/1" do
    test "renders root structure" do
      assigns = %{}
      html = rendered_to_string(~H|<ContextMenu.context_menu id="menu">
  <:trigger>Right-click</:trigger>
  <ContextMenu.context_menu_item>Action</ContextMenu.context_menu_item>
</ContextMenu.context_menu>|)
      assert html =~ "context-menu"
      assert html =~ ~s(aria-haspopup="menu")
    end

    test "renders trigger content" do
      assigns = %{}
      html = rendered_to_string(~H|<ContextMenu.context_menu id="menu">
  <:trigger><button>Open</button></:trigger>
  <ContextMenu.context_menu_item>Item</ContextMenu.context_menu_item>
</ContextMenu.context_menu>|)
      assert html =~ "<button>Open</button>"
    end
  end

  describe "context_menu_item/1" do
    test "renders menuitem" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ContextMenu.context_menu_item>Profile</ContextMenu.context_menu_item>|
        )

      assert html =~ ~s(role="menuitem")
      assert html =~ "Profile"
    end

    test "renders destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ContextMenu.context_menu_item variant="destructive">Delete</ContextMenu.context_menu_item>|
        )

      assert html =~ "context-menu-item-destructive"
    end

    test "renders shortcut" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ContextMenu.context_menu_item shortcut="⌘K">Search</ContextMenu.context_menu_item>|
        )

      assert html =~ "⌘K"
      assert html =~ "context-menu-shortcut"
    end

    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ContextMenu.context_menu_item disabled>Locked</ContextMenu.context_menu_item>|
        )

      assert html =~ ~s(aria-disabled="true")
    end
  end

  describe "context_menu_checkbox_item/1" do
    test "renders checkbox menuitem" do
      assigns = %{}
      html = rendered_to_string(~H|<ContextMenu.context_menu_checkbox_item checked={true}>
  Auto-save
</ContextMenu.context_menu_checkbox_item>|)
      assert html =~ ~s(role="menuitemcheckbox")
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(data-state="checked")
    end
  end

  describe "context_menu_radio_item/1" do
    test "renders checked radio menuitem" do
      assigns = %{}

      html =
        rendered_to_string(~H|<ContextMenu.context_menu_radio_item value="grid" checked>
  Grid
</ContextMenu.context_menu_radio_item>|)

      assert html =~ ~s(role="menuitemradio")
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(data-state="checked")
      assert html =~ ~s(data-value="grid")
      assert html =~ "context-menu-radio-dot"
    end

    test "does not render radio dot when unchecked" do
      assigns = %{}

      html =
        rendered_to_string(~H|<ContextMenu.context_menu_radio_item value="list">
  List
</ContextMenu.context_menu_radio_item>|)

      assert html =~ ~s(aria-checked="false")
      refute html =~ "context-menu-radio-dot"
    end
  end

  describe "context_menu_label/1" do
    test "renders label" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<ContextMenu.context_menu_label>Actions</ContextMenu.context_menu_label>|
        )

      assert html =~ "context-menu-label"
      assert html =~ "Actions"
    end
  end

  describe "context_menu_separator/1" do
    test "renders separator" do
      assigns = %{}
      html = rendered_to_string(~H|<ContextMenu.context_menu_separator />|)
      assert html =~ ~s(role="separator")
    end
  end

  describe "context_menu_sub/1" do
    test "renders submenu structure" do
      assigns = %{}
      html = rendered_to_string(~H|<ContextMenu.context_menu_sub>
  <:trigger>Share</:trigger>
  <ContextMenu.context_menu_item>Copy link</ContextMenu.context_menu_item>
</ContextMenu.context_menu_sub>|)
      assert html =~ "context-menu-sub"
      assert html =~ "Share"
      assert html =~ "Copy link"
    end
  end
end
