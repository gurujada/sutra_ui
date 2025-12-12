defmodule SutraUI.DropdownMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.DropdownMenu

  describe "dropdown_menu/1 rendering" do
    test "renders dropdown with trigger and content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>
            <button>Open</button>
          </:trigger>
          <:item>Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown"
      assert html =~ "dropdown-trigger"
      assert html =~ "dropdown-content"
      assert html =~ "Open"
      assert html =~ "Profile"
    end

    test "renders with custom id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="my-dropdown">
          <:trigger>
            <button>Open</button>
          </:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(id="my-dropdown")
      assert html =~ ~s(id="my-dropdown-content")
    end
  end

  describe "dropdown_menu/1 alignment and side" do
    test "renders with default alignment (start)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-align-start"
    end

    test "renders with center alignment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" align="center">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-align-center"
    end

    test "renders with end alignment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" align="end">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-align-end"
    end

    test "renders with default side (bottom)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-bottom"
    end

    test "renders with top side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="top">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-top"
    end

    test "renders with left side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="left">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-left"
    end

    test "renders with right side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="right">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-right"
    end
  end

  describe "dropdown_menu/1 items" do
    test "renders multiple items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Profile</:item>
          <:item>Settings</:item>
          <:item>Logout</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Profile"
      assert html =~ "Settings"
      assert html =~ "Logout"
      # Should have 3 menuitem buttons
      assert length(Regex.scan(~r/role="menuitem"/, html)) == 3
    end

    test "renders item with destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item variant="destructive">Delete</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-item-destructive"
      assert html =~ "Delete"
    end

    test "renders disabled item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item disabled>Disabled Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-item-disabled"
      assert html =~ "disabled"
      assert html =~ "Disabled Item"
    end

    test "renders item with on_click event" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item on_click="handle_profile">Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "handle_profile"
    end
  end

  describe "dropdown_menu/1 icons" do
    test "renders item with icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item icon="lucide-user">Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-item-icon"
      assert html =~ "lucide-user"
      assert html =~ "Profile"
    end

    test "renders item without icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>No Icon</:item>
        </DropdownMenu.dropdown_menu>
        """)

      # Items without icons get a placeholder for alignment
      assert html =~ "dropdown-item-icon-placeholder"
      refute html =~ ~r/dropdown-item-icon[^-]/
      assert html =~ "No Icon"
    end

    test "renders multiple items with different icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item icon="lucide-user">Profile</:item>
          <:item icon="lucide-settings">Settings</:item>
          <:item icon="lucide-log-out">Logout</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "lucide-user"
      assert html =~ "lucide-settings"
      assert html =~ "lucide-log-out"
    end
  end

  describe "dropdown_menu/1 keyboard shortcuts" do
    test "renders item with shortcut" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item shortcut="⌘K">Search</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-item-shortcut"
      assert html =~ "⌘K"
      assert html =~ "Search"
    end

    test "renders item without shortcut" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>No Shortcut</:item>
        </DropdownMenu.dropdown_menu>
        """)

      refute html =~ "dropdown-item-shortcut"
      assert html =~ "No Shortcut"
    end

    test "renders various shortcut formats" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item shortcut="⌘S">Save</:item>
          <:item shortcut="⌘⇧S">Save As</:item>
          <:item shortcut="Ctrl+K">Search</:item>
          <:item shortcut="⌥⌘N">New</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "⌘S"
      assert html =~ "⌘⇧S"
      assert html =~ "Ctrl+K"
      assert html =~ "⌥⌘N"
    end
  end

  describe "dropdown_menu/1 icon and shortcut combined" do
    test "renders item with both icon and shortcut" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item icon="lucide-scissors" shortcut="⌘X">Cut</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-item-icon"
      assert html =~ "lucide-scissors"
      assert html =~ "dropdown-item-shortcut"
      assert html =~ "⌘X"
      assert html =~ "Cut"
    end

    test "renders complete edit menu with icons and shortcuts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Edit</button></:trigger>
          <:item icon="lucide-undo-2" shortcut="⌘Z">Undo</:item>
          <:item icon="lucide-redo-2" shortcut="⌘⇧Z">Redo</:item>
          <:separator />
          <:item icon="lucide-scissors" shortcut="⌘X">Cut</:item>
          <:item icon="lucide-copy" shortcut="⌘C">Copy</:item>
          <:item icon="lucide-clipboard" shortcut="⌘V">Paste</:item>
        </DropdownMenu.dropdown_menu>
        """)

      # Check icons
      assert html =~ "lucide-undo-2"
      assert html =~ "lucide-redo-2"
      assert html =~ "lucide-scissors"
      assert html =~ "lucide-copy"
      assert html =~ "lucide-clipboard"

      # Check shortcuts
      assert html =~ "⌘Z"
      assert html =~ "⌘⇧Z"
      assert html =~ "⌘X"
      assert html =~ "⌘C"
      assert html =~ "⌘V"

      # Check labels
      assert html =~ "Undo"
      assert html =~ "Redo"
      assert html =~ "Cut"
      assert html =~ "Copy"
      assert html =~ "Paste"
    end
  end

  describe "dropdown_menu/1 separators" do
    test "renders separator between items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Profile</:item>
          <:separator />
          <:item>Logout</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-separator"
      assert html =~ ~s(role="separator")
    end

    test "renders multiple separators" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item 1</:item>
          <:separator />
          <:item>Item 2</:item>
          <:separator />
          <:item>Item 3</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert length(Regex.scan(~r/dropdown-separator/, html)) == 2
    end
  end

  describe "dropdown_menu/1 labels" do
    test "renders label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:label>My Account</:label>
          <:item>Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-label"
      assert html =~ "My Account"
      assert html =~ ~s(role="presentation")
    end

    test "renders multiple labels for groups" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:label>Account</:label>
          <:item>Profile</:item>
          <:item>Settings</:item>
          <:separator />
          <:label>Actions</:label>
          <:item>Logout</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Account"
      assert html =~ "Actions"
      assert length(Regex.scan(~r/dropdown-label/, html)) == 2
    end
  end

  describe "dropdown_menu/1 accessibility" do
    test "has correct ARIA roles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="menu")
      assert html =~ ~s(role="menuitem")
      assert html =~ ~s(aria-orientation="vertical")
    end

    test "items are buttons with type button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Profile</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(type="button")
    end

    test "separator has separator role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
          <:separator />
          <:item>Item 2</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="separator")
    end

    test "label has presentation role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:label>Group</:label>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="presentation")
    end
  end

  describe "dropdown_menu/1 custom class" do
    test "includes custom class on container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" class="my-custom-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "my-custom-dropdown"
    end
  end

  describe "dropdown_menu/1 JavaScript hook" do
    test "has phx-hook for keyboard navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(phx-hook="SutraUI.DropdownMenu.DropdownMenu")
    end

    test "content starts hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-hidden="true")
    end
  end

  describe "dropdown_menu/1 data attributes" do
    test "includes data-align attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" align="center">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-align="center")
    end

    test "includes data-side attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="top">
          <:trigger><button>Open</button></:trigger>
          <:item>Item</:item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-side="top")
    end
  end
end
