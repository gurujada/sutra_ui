defmodule SutraUI.DrawerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Drawer

  describe "drawer/1 rendering" do
    test "renders drawer as aside element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          <p>Drawer content</p>
        </Drawer.drawer>
        """)

      assert html =~ "<aside"
      assert html =~ "drawer"
      assert html =~ "Drawer content"
    end

    test "renders nav element inside" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
        </Drawer.drawer>
        """)

      assert html =~ "<nav"
    end

    test "renders header slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          <:header>
            <div class="logo">Logo</div>
          </:header>
          Content
        </Drawer.drawer>
        """)

      assert html =~ "<header"
      assert html =~ "Logo"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
          <:footer>
            <div>Footer</div>
          </:footer>
        </Drawer.drawer>
        """)

      assert html =~ "<footer"
      assert html =~ "Footer"
    end
  end

  describe "drawer/1 positioning" do
    test "defaults to left side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(data-side="left")
    end

    test "accepts right side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer" side="right">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(data-side="right")
    end
  end

  describe "drawer/1 state" do
    test "defaults to closed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(data-initial-open="false")
    end

    test "can be initially open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer" open>
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(aria-hidden="false")
      assert html =~ ~s(data-initial-open="true")
    end
  end

  describe "drawer/1 accessibility" do
    test "includes aria-label on nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer" label="Main menu">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(aria-label="Main menu")
    end

    test "uses default aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(aria-label="Drawer navigation")
    end
  end

  describe "drawer_group/1" do
    test "renders group with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_group label="Navigation">
          <li>Item</li>
        </Drawer.drawer_group>
        """)

      assert html =~ ~s(role="group")
      assert html =~ "<h3>Navigation</h3>"
      assert html =~ "<ul>"
    end

    test "renders group without label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_group>
          <li>Item</li>
        </Drawer.drawer_group>
        """)

      assert html =~ ~s(role="group")
      refute html =~ "<h3>"
    end
  end

  describe "drawer_item/1" do
    test "renders item as link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_item href="/home">Home</Drawer.drawer_item>
        """)

      assert html =~ "<li>"
      assert html =~ "<a"
      assert html =~ ~s(href="/home")
      assert html =~ "Home"
    end

    test "marks current item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_item href="/home" current>Home</Drawer.drawer_item>
        """)

      assert html =~ ~s(aria-current="page")
    end

    test "accepts variant attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_item href="/home" variant="outline">Home</Drawer.drawer_item>
        """)

      assert html =~ ~s(data-variant="outline")
    end

    test "accepts size attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_item href="/home" size="sm">Home</Drawer.drawer_item>
        """)

      assert html =~ ~s(data-size="sm")
    end
  end

  describe "drawer_submenu/1" do
    test "renders collapsible submenu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_submenu label="Projects">
          <Drawer.drawer_item href="/active">Active</Drawer.drawer_item>
        </Drawer.drawer_submenu>
        """)

      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ "Projects"
    end

    test "renders submenu initially open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_submenu label="Projects" open>
          <Drawer.drawer_item href="/active">Active</Drawer.drawer_item>
        </Drawer.drawer_submenu>
        """)

      assert html =~ "<details open"
    end
  end

  describe "drawer_separator/1" do
    test "renders horizontal rule" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_separator />
        """)

      assert html =~ "<hr"
      assert html =~ ~s(role="separator")
    end
  end

  describe "drawer/1 hook" do
    test "includes phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer id="main-drawer">
          Content
        </Drawer.drawer>
        """)

      assert html =~ ~s(phx-hook="SutraUI.Drawer.Drawer")
    end
  end

  describe "drawer_trigger/1" do
    test "renders trigger button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" />
        """)

      assert html =~ "<button"
      assert html =~ ~s(data-for="main-drawer")
      assert html =~ ~s(aria-label="Toggle drawer")
      assert html =~ "phx-click"
    end

    test "renders with default icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" />
        """)

      assert html =~ "<svg"
      assert html =~ "lucide"
    end

    test "accepts custom content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer">Menu</Drawer.drawer_trigger>
        """)

      assert html =~ "Menu"
      refute html =~ "<svg"
    end

    test "applies ghost icon variant by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" />
        """)

      assert html =~ "btn-icon-ghost"
    end

    test "accepts custom variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" variant="outline" />
        """)

      assert html =~ "btn-icon-outline"
    end

    test "accepts custom size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" size="sm" />
        """)

      assert html =~ "btn-sm-ghost"
    end

    test "includes custom classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Drawer.drawer_trigger for="main-drawer" class="my-class" />
        """)

      assert html =~ "my-class"
    end
  end
end
