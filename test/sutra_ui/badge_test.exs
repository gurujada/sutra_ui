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
end
