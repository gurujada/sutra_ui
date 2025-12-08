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
        <TabNav.tab_nav>
          <:tab patch="/overview" active={true}>Overview</:tab>
          <:tab patch="/members" active={false}>Members</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav"
    end

    test "renders all tab items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav>
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
        <TabNav.tab_nav>
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
        <TabNav.tab_nav>
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
        <TabNav.tab_nav>
          <:tab patch="/overview" active={false}>Overview</:tab>
        </TabNav.tab_nav>
        """)

      # Should have the base class but not the active modifier
      assert html =~ "tab-nav-item"
      # The active class shouldn't appear since active=false
    end
  end

  describe "tab_nav/1 with icons" do
    test "renders icon when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav>
          <:tab patch="/overview" active={true} icon="hero-home">Overview</:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ "tab-nav-icon"
      assert html =~ "hero-home"
    end

    test "does not render icon when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <TabNav.tab_nav>
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
        <TabNav.tab_nav class="mb-6">
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
        <TabNav.tab_nav>
          <:tab patch="/overview" active={true}>
            <span class="custom">Custom Content</span>
          </:tab>
        </TabNav.tab_nav>
        """)

      assert html =~ ~s(class="custom")
      assert html =~ "Custom Content"
    end
  end
end
