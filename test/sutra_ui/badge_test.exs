defmodule SutraUI.BadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Badge

  describe "badge/1 rendering" do
    test "renders as span element by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>New</Badge.badge>
        """)

      assert html =~ "<span"
      assert html =~ "New"
    end

    test "renders inner block content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>
          <span>Icon</span> Status
        </Badge.badge>
        """)

      assert html =~ "<span>Icon</span>"
      assert html =~ "Status"
    end
  end

  describe "badge/1 variants" do
    test "accepts all valid variants" do
      for variant <- ~w(default secondary destructive outline) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <Badge.badge variant={@variant}>Test</Badge.badge>
          """)

        # Should render without error
        assert html =~ "<span"
        assert html =~ "Test"
      end
    end
  end

  describe "badge/1 as link" do
    test "renders as anchor when href is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge href="/notifications">5 new</Badge.badge>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="/notifications")
      assert html =~ "5 new"
    end

    test "does not render as anchor when href is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge>Status</Badge.badge>
        """)

      refute html =~ "<a"
      assert html =~ "<span"
    end
  end

  describe "badge/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge class="my-custom-class">Test</Badge.badge>
        """)

      assert html =~ "my-custom-class"
    end
  end

  describe "badge/1 accessibility" do
    test "passes through aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge aria-label="5 unread notifications">5</Badge.badge>
        """)

      assert html =~ ~s(aria-label="5 unread notifications")
    end

    test "passes through role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge role="status">Active</Badge.badge>
        """)

      assert html =~ ~s(role="status")
    end

    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge id="status-badge">Active</Badge.badge>
        """)

      assert html =~ ~s(id="status-badge")
    end
  end

  describe "badge/1 tones and styles" do
    import SutraUI.HTMLHelpers

    test "the new tones render with data-variant" do
      for variant <- ~w(info warning brand ai) do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <Badge.badge variant={@variant}>Tone</Badge.badge>
          """)

        assert attribute(html, "span", "data-variant") == variant
        assert attribute(html, "span", "data-style") == "solid"
        assert text(html, "span") == "Tone"
      end
    end

    test "soft and dashed styles" do
      for style <- ~w(soft dashed) do
        assigns = %{style: style}

        html =
          rendered_to_string(~H"""
          <Badge.badge variant="warning" style={@style}>Due</Badge.badge>
          """)

        assert attribute(html, "span", "data-style") == style
        assert attribute(html, "span", "data-variant") == "warning"
      end
    end

    test "every variant takes every style" do
      for variant <- ~w(default secondary destructive success outline info warning brand ai),
          style <- ~w(solid soft dashed) do
        assigns = %{variant: variant, style: style}

        html =
          rendered_to_string(~H"""
          <Badge.badge variant={@variant} style={@style}>x</Badge.badge>
          """)

        assert attribute(html, "span", "data-variant") == variant
        assert attribute(html, "span", "data-style") == style
      end
    end

    test "the icon slot renders before the content, hidden from assistive technology" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge variant="success">
          <:icon><svg data-icon="check"></svg></:icon>
          Verified
        </Badge.badge>
        """)

      assert count(html, "span.badge-icon svg[data-icon=check]") == 1
      assert attribute(html, "span.badge-icon", "aria-hidden") == "true"
      assert text(html, "span[data-variant]") == "Verified"
    end

    test "no icon wrapper without the slot, and links keep tone and style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Badge.badge href="/n" variant="ai" style="soft">5 new</Badge.badge>
        """)

      assert count(html, ".badge-icon") == 0
      assert attribute(html, "a", "href") == "/n"
      assert attribute(html, "a", "data-variant") == "ai"
      assert attribute(html, "a", "data-style") == "soft"
    end
  end
end
