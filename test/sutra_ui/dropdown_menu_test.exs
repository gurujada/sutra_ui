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
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="/profile">Profile</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "dropdown-menu"
      assert html =~ "dropdown-menu-trigger"
      assert html =~ "dropdown-menu-content"
      assert html =~ "Open"
      assert html =~ "Profile"
    end

    test "renders with custom id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="my-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(id="my-dropdown")
      assert html =~ ~s(id="my-dropdown-trigger")
      assert html =~ ~s(id="my-dropdown-menu")
      assert html =~ ~s(id="my-dropdown-popover")
    end

    test "renders chevron icon in trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "lucide-chevron-down"
      assert html =~ "dropdown-menu-chevron"
    end
  end

  describe "dropdown_menu/1 positioning" do
    test "renders with default side (bottom) and align (start)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="start")
    end

    test "renders with custom side and align" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="top" align="end">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-side="top")
      assert html =~ ~s(data-align="end")
    end

    test "renders with center alignment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" align="center">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-align="center")
    end

    test "renders with left side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="left">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-side="left")
    end

    test "renders with right side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" side="right">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(data-side="right")
    end
  end

  describe "dropdown_item/1" do
    test "renders item with inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item><a href="/profile">Profile</a></DropdownMenu.dropdown_item>
        """)

      assert html =~ ~s(role="menuitem")
      assert html =~ "dropdown-menu-item"
      assert html =~ ~s(<a href="/profile">Profile</a>)
    end

    test "renders item with link navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item><a data-phx-link="navigate" href="/settings">Settings</a></DropdownMenu.dropdown_item>
        """)

      assert html =~ ~s(data-phx-link="navigate")
      assert html =~ "Settings"
    end

    test "renders item with button and phx-click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item><button phx-click="do_action">Action</button></DropdownMenu.dropdown_item>
        """)

      assert html =~ ~s(phx-click="do_action")
      assert html =~ "Action"
    end

    test "renders multiple items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="/profile">Profile</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item><a href="/settings">Settings</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item><a href="/logout">Logout</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Profile"
      assert html =~ "Settings"
      assert html =~ "Logout"
      assert length(Regex.scan(~r/role="menuitem"/, html)) == 3
    end

    test "renders item with destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item variant="destructive">
          <button phx-click="delete">Delete</button>
        </DropdownMenu.dropdown_item>
        """)

      assert html =~ "dropdown-menu-item-destructive"
      assert html =~ "Delete"
    end

    test "renders disabled item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item disabled><button>Disabled</button></DropdownMenu.dropdown_item>
        """)

      assert html =~ "dropdown-menu-item-disabled"
      assert html =~ ~s(aria-disabled="true")
      assert html =~ "Disabled"
    end

    test "renders item with shortcut" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item shortcut="Ctrl+S"><button phx-click="save">Save</button></DropdownMenu.dropdown_item>
        """)

      assert html =~ "dropdown-menu-shortcut"
      assert html =~ "Ctrl+S"
      assert html =~ "Save"
    end

    test "renders item with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item class="my-custom-item"><a href="#">Item</a></DropdownMenu.dropdown_item>
        """)

      assert html =~ "my-custom-item"
    end
  end

  describe "dropdown_separator/1" do
    test "renders separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_separator />
        """)

      assert html =~ "dropdown-menu-separator"
      assert html =~ ~s(role="separator")
    end

    test "renders separator with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_separator class="my-separator" />
        """)

      assert html =~ "my-separator"
    end

    test "renders multiple separators in menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item 1</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_separator />
          <DropdownMenu.dropdown_item><a href="#">Item 2</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_separator />
          <DropdownMenu.dropdown_item><a href="#">Item 3</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert length(Regex.scan(~r/dropdown-menu-separator/, html)) == 2
    end
  end

  describe "dropdown_label/1" do
    test "renders dropdown_label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_label>My Account</DropdownMenu.dropdown_label>
        """)

      assert html =~ "dropdown-menu-label"
      assert html =~ "My Account"
    end

    test "renders dropdown_label with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_label class="my-title">Group</DropdownMenu.dropdown_label>
        """)

      assert html =~ "my-title"
    end

    test "renders multiple dropdown_labels for groups" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_label>Account</DropdownMenu.dropdown_label>
          <DropdownMenu.dropdown_item><a href="/profile">Profile</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item><a href="/settings">Settings</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_separator />
          <DropdownMenu.dropdown_label>Actions</DropdownMenu.dropdown_label>
          <DropdownMenu.dropdown_item><a href="/logout">Logout</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "Account"
      assert html =~ "Actions"
      assert length(Regex.scan(~r/dropdown-menu-label/, html)) == 2
    end
  end

  describe "keyboard shortcuts" do
    test "renders item with various shortcut formats" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Edit</:trigger>
          <DropdownMenu.dropdown_item shortcut="⌘S"><button>Save</button></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item shortcut="⌘⇧S"><button>Save As</button></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item shortcut="Ctrl+K"><button>Search</button></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item shortcut="⌥⌘N"><button>New</button></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "⌘S"
      assert html =~ "⌘⇧S"
      assert html =~ "Ctrl+K"
      assert html =~ "⌥⌘N"
    end

    test "renders item without shortcut" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item><a href="#">No Shortcut</a></DropdownMenu.dropdown_item>
        """)

      refute html =~ "dropdown-menu-shortcut"
      assert html =~ "No Shortcut"
    end
  end

  describe "accessibility" do
    test "has correct ARIA attributes on trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-controls="test-dropdown-menu")
      assert html =~ ~s(aria-expanded="false")
    end

    test "has correct ARIA attributes on menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(role="menu")
      assert html =~ ~s(aria-labelledby="test-dropdown-trigger")
    end

    test "popover starts hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(aria-hidden="true")
    end

    test "items have menuitem role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        """)

      assert html =~ ~s(role="menuitem")
    end

    test "separator has separator role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_separator />
        """)

      assert html =~ ~s(role="separator")
    end
  end

  describe "custom classes" do
    test "accepts custom class on container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" class="my-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "my-dropdown"
    end

    test "accepts custom trigger_class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" trigger_class="my-trigger">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "my-trigger"
    end

    test "accepts custom menu_class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown" menu_class="my-menu">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ "my-menu"
    end
  end

  describe "JavaScript hook" do
    test "has phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="test-dropdown">
          <:trigger>Open</:trigger>
          <DropdownMenu.dropdown_item><a href="#">Item</a></DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      assert html =~ ~s(phx-hook=)
      assert html =~ "DropdownMenu"
    end
  end

  describe "complete examples" do
    test "renders full menu with dropdown_labels, items, and separators" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DropdownMenu.dropdown_menu id="settings-menu">
          <:trigger>Settings</:trigger>
          <DropdownMenu.dropdown_label>Account</DropdownMenu.dropdown_label>
          <DropdownMenu.dropdown_item><a href="/profile">Profile</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_item shortcut="Ctrl+B"><a href="/billing">Billing</a></DropdownMenu.dropdown_item>
          <DropdownMenu.dropdown_separator />
          <DropdownMenu.dropdown_label>Danger Zone</DropdownMenu.dropdown_label>
          <DropdownMenu.dropdown_item variant="destructive">
            <button phx-click="delete_account">Delete Account</button>
          </DropdownMenu.dropdown_item>
        </DropdownMenu.dropdown_menu>
        """)

      # Group titles
      assert html =~ "Account"
      assert html =~ "Danger Zone"

      # Items
      assert html =~ "Profile"
      assert html =~ "Billing"
      assert html =~ "Delete Account"

      # Shortcut
      assert html =~ "Ctrl+B"

      # Destructive variant
      assert html =~ "dropdown-menu-item-destructive"

      # Separator
      assert html =~ "dropdown-menu-separator"
    end
  end
end
