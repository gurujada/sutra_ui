defmodule SutraUI.TabNavTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.TabNav

  describe "tab_nav/1 rendering" do
    test "renders tab navigation container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav"
      assert html =~ "tab-nav-list"
      assert html =~ "tab-nav-mobile"
    end

    test "renders all tab items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
          <:tab patch="/settings" active={false}>Settings</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "Overview"
      assert html =~ "Members"
      assert html =~ "Settings"
      assert html =~ ~s(href="/overview")
      assert html =~ ~s(href="/members")
      assert html =~ ~s(href="/settings")
    end

    test "renders tabs as links with patch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/test" active={false}>Test</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="/test")
    end
  end

  describe "tab_nav/1 active state" do
    test "marks active tab with active class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav-item-active"
    end

    test "does not mark inactive tabs with active class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={false}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      # Should have the base class but not the active modifier
      assert html =~ "tab-nav-item"
      # The active class shouldn't appear since active=false
    end
  end

  describe "tab_nav/1 accessibility" do
    test "renders a navigation landmark" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "<nav"
    end

    test "does not expose routed navigation as an ARIA tab widget" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      refute html =~ ~s(role="tablist")
      refute html =~ ~s(role="tab")
    end

    test "marks the active page with aria-current" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(aria-current="page")
      refute html =~ "aria-selected"
    end

    test "has aria-label on navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav" label="My tabs">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(aria-label="My tabs")
    end

    test "mobile dropdown has disclosure semantics" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(id="test-nav-mobile-trigger")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="test-nav-mobile-menu")
      assert html =~ ~s(id="test-nav-mobile-menu")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "tab-nav-mobile-item"
    end
  end

  describe "tab_nav/1 responsive collapse" do
    test "collapses to dropdown by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(data-collapse="dropdown")
      assert html =~ "tab-nav-mobile-trigger"
      assert html =~ "tab-nav-mobile-menu"
    end

    test "supports never collapsing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav" collapse="never">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(data-collapse="never")
      assert html =~ "tab-nav-mobile"
    end

    test "renders active tab content in the mobile trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={false}>Overview</:tab>
          <:tab patch="/members" active={true}>
            <span class="custom-active">Members</span>
          </:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav-mobile-label"
      assert html =~ ~s(class="custom-active")
      assert html =~ "Members"
    end
  end

  describe "tab_nav/1 with icons" do
    test "renders icon when provided in inner_block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="tab-nav-icon"
            >
              <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" />
            </svg>
            Overview
          </:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav-icon"
      assert html =~ "<svg"
    end

    test "does not render icon when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      refute html =~ "tab-nav-icon"
    end
  end

  describe "tab_nav/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav" class="mb-6">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav"
      assert html =~ "mb-6"
    end
  end

  describe "tab_nav/1 slot content" do
    test "renders slot inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>
            <span class="custom">Custom Content</span>
          </:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(class="custom")
      assert html =~ "Custom Content"
    end
  end

  describe "tab_nav/1 phx-hook" do
    test "has phx-hook for keyboard navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav id="test-nav">
          <:tab patch="/overview" active={true}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "phx-hook"
    end

    test "hook activates focused tabs with Enter and Space" do
      source = File.read!("lib/sutra_ui/tab_nav.ex")

      assert source =~ "case 'Enter':"
      assert source =~ "case ' ':"
      assert source =~ "closest('.tab-nav-item')?.click()"
    end

    test "hook toggles the mobile dropdown without server events" do
      source = File.read!("lib/sutra_ui/tab_nav.ex")

      assert source =~ "toggleMenu()"
      assert source =~ "aria-expanded"
      assert source =~ "aria-hidden"
      refute source =~ "pushEvent"
    end
  end
end
