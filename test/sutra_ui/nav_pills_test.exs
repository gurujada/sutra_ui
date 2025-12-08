defmodule SutraUI.NavPillsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.NavPills

  describe "nav_pills/1 rendering" do
    test "renders nav pills container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
          <:item label="About" patch="/about" />
        </NavPills.nav_pills>
        """)

      assert html =~ "nav-pills"
      assert html =~ ~s(id="test-nav")
    end

    test "renders desktop navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
          <:item label="About" patch="/about" />
        </NavPills.nav_pills>
        """)

      assert html =~ "nav-pills-desktop"
      assert html =~ ~s(role="navigation")
    end

    test "renders mobile menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
          <:item label="About" patch="/about" />
        </NavPills.nav_pills>
        """)

      assert html =~ "nav-pills-mobile"
      assert html =~ "nav-pills-mobile-trigger"
      assert html =~ "nav-pills-mobile-menu"
    end

    test "renders all navigation items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
          <:item label="About" patch="/about" />
          <:item label="Contact" patch="/contact" />
        </NavPills.nav_pills>
        """)

      assert html =~ "Home"
      assert html =~ "About"
      assert html =~ "Contact"
      assert html =~ ~s(href="/home")
      assert html =~ ~s(href="/about")
      assert html =~ ~s(href="/contact")
    end
  end

  describe "nav_pills/1 active state" do
    test "marks active item in desktop nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="About">
          <:item label="Home" patch="/home" />
          <:item label="About" patch="/about" />
        </NavPills.nav_pills>
        """)

      assert html =~ "nav-pills-item-active"
    end

    test "displays active label in mobile trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Settings">
          <:item label="Home" patch="/home" />
          <:item label="Settings" patch="/settings" />
        </NavPills.nav_pills>
        """)

      # The trigger shows the active label (with whitespace)
      assert html =~ "Settings"
      assert html =~ "nav-pills-mobile-trigger"
    end
  end

  describe "nav_pills/1 with icons" do
    test "renders icon content in items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home">
            <span class="icon">home-icon</span>
          </:item>
        </NavPills.nav_pills>
        """)

      assert html =~ "home-icon"
    end
  end

  describe "nav_pills/1 accessibility" do
    test "includes aria-label for navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home" aria_label="Main navigation">
          <:item label="Home" patch="/home" />
        </NavPills.nav_pills>
        """)

      assert html =~ ~s(aria-label="Main navigation")
    end

    test "uses default aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
        </NavPills.nav_pills>
        """)

      assert html =~ ~s(aria-label="Navigation")
    end

    test "includes aria attributes on mobile menu" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
        </NavPills.nav_pills>
        """)

      assert html =~ ~s(aria-haspopup="true")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(role="menu")
    end
  end

  describe "nav_pills/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home" class="my-custom-class">
          <:item label="Home" patch="/home" />
        </NavPills.nav_pills>
        """)

      assert html =~ "nav-pills"
      assert html =~ "my-custom-class"
    end
  end

  describe "nav_pills/1 hook" do
    test "includes phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <NavPills.nav_pills id="test-nav" active_label="Home">
          <:item label="Home" patch="/home" />
        </NavPills.nav_pills>
        """)

      assert html =~ ~s(phx-hook="SutraUI.NavPills.NavPills")
    end
  end
end
