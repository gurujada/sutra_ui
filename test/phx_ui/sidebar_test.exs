defmodule PhxUI.SidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Sidebar

  describe "sidebar/1 rendering" do
    test "renders sidebar as aside element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          <p>Sidebar content</p>
        </Sidebar.sidebar>
        """)

      assert html =~ "<aside"
      assert html =~ "sidebar"
      assert html =~ "Sidebar content"
    end

    test "renders nav element inside" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ "<nav"
    end

    test "renders header slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          <:header>
            <div class="logo">Logo</div>
          </:header>
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ "<header"
      assert html =~ "Logo"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
          <:footer>
            <div>Footer</div>
          </:footer>
        </Sidebar.sidebar>
        """)

      assert html =~ "<footer"
      assert html =~ "Footer"
    end
  end

  describe "sidebar/1 positioning" do
    test "defaults to left side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(data-side="left")
    end

    test "accepts right side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar" side="right">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(data-side="right")
    end
  end

  describe "sidebar/1 state" do
    test "defaults to open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-hidden="false")
      assert html =~ ~s(data-initial-open="true")
    end

    test "can be initially closed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar" open={false}>
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(data-initial-open="false")
    end
  end

  describe "sidebar/1 accessibility" do
    test "includes aria-label on nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar" label="Main menu">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-label="Main menu")
    end

    test "uses default aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(aria-label="Sidebar navigation")
    end
  end

  describe "sidebar_group/1" do
    test "renders group with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_group label="Navigation">
          <li>Item</li>
        </Sidebar.sidebar_group>
        """)

      assert html =~ ~s(role="group")
      assert html =~ "<h3>Navigation</h3>"
      assert html =~ "<ul>"
    end

    test "renders group without label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_group>
          <li>Item</li>
        </Sidebar.sidebar_group>
        """)

      assert html =~ ~s(role="group")
      refute html =~ "<h3>"
    end
  end

  describe "sidebar_item/1" do
    test "renders item as link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_item href="/home">Home</Sidebar.sidebar_item>
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
        <Sidebar.sidebar_item href="/home" current>Home</Sidebar.sidebar_item>
        """)

      assert html =~ ~s(aria-current="page")
    end

    test "accepts variant attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_item href="/home" variant="outline">Home</Sidebar.sidebar_item>
        """)

      assert html =~ ~s(data-variant="outline")
    end

    test "accepts size attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_item href="/home" size="sm">Home</Sidebar.sidebar_item>
        """)

      assert html =~ ~s(data-size="sm")
    end
  end

  describe "sidebar_submenu/1" do
    test "renders collapsible submenu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_submenu label="Projects">
          <Sidebar.sidebar_item href="/active">Active</Sidebar.sidebar_item>
        </Sidebar.sidebar_submenu>
        """)

      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ "Projects"
    end

    test "renders submenu initially open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_submenu label="Projects" open>
          <Sidebar.sidebar_item href="/active">Active</Sidebar.sidebar_item>
        </Sidebar.sidebar_submenu>
        """)

      assert html =~ "<details open"
    end
  end

  describe "sidebar_separator/1" do
    test "renders horizontal rule" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar_separator />
        """)

      assert html =~ "<hr"
      assert html =~ ~s(role="separator")
    end
  end

  describe "sidebar/1 hook" do
    test "includes phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Sidebar.sidebar id="main-sidebar">
          Content
        </Sidebar.sidebar>
        """)

      assert html =~ ~s(phx-hook="PhxUI.Sidebar.Sidebar")
    end
  end
end
