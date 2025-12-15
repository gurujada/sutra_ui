defmodule SutraUI.ThemeSwitcherTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.ThemeSwitcher

  describe "theme_switcher/1 rendering" do
    test "renders as button element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "<button"
      assert html =~ ~s(type="button")
    end

    test "renders with required id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="my-theme-toggle" />
        """)

      assert html =~ ~s(id="my-theme-toggle")
    end

    test "renders sun icon for dark mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "theme-switcher-dark"
      assert html =~ "<svg"
      # Sun icon has a circle with r="4" at center
      assert html =~ ~s(r="4")
    end

    test "renders moon icon for light mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "theme-switcher-light"
      assert html =~ "<svg"
      # Moon icon path
      assert html =~ "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"
    end
  end

  describe "theme_switcher/1 tooltip" do
    test "has no tooltip by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      refute html =~ ~s(data-tooltip=)
      assert html =~ ~s(aria-label="Toggle theme")
    end

    test "accepts custom tooltip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" tooltip="Switch theme" />
        """)

      assert html =~ ~s(data-tooltip="Switch theme")
      assert html =~ ~s(aria-label="Switch theme")
    end

    test "accepts tooltip side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" tooltip_side="left" />
        """)

      assert html =~ ~s(data-side="left")
    end

    test "defaults tooltip side to bottom" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ ~s(data-side="bottom")
    end
  end

  describe "theme_switcher/1 variants" do
    test "defaults to outline variant with icon size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "btn-icon-outline"
    end

    test "accepts ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" variant="ghost" />
        """)

      assert html =~ "btn-icon-ghost"
    end

    test "accepts primary variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" variant="primary" />
        """)

      assert html =~ "btn-icon"
    end
  end

  describe "theme_switcher/1 sizes" do
    test "defaults to icon size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "btn-icon-outline"
    end

    test "accepts sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" size="sm" />
        """)

      assert html =~ "btn-sm-outline"
    end
  end

  describe "theme_switcher/1 icon class" do
    test "defaults to size-4 icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ "size-4"
    end

    test "accepts custom icon class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" icon_class="size-5" />
        """)

      assert html =~ "size-5"
    end
  end

  describe "theme_switcher/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" class="ml-auto" />
        """)

      assert html =~ "ml-auto"
    end
  end

  describe "theme_switcher/1 hook" do
    test "includes phx-hook attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <ThemeSwitcher.theme_switcher id="theme-toggle" />
        """)

      assert html =~ ~s(phx-hook="SutraUI.ThemeSwitcher.ThemeSwitcher")
    end
  end
end
