defmodule SutraUI.EmptyTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Empty

  describe "empty/1 rendering" do
    test "renders empty container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>No data</:title>
        </Empty.empty>
        """)

      assert html =~ ~s(class="empty)
    end

    test "renders title slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>No Items Found</:title>
        </Empty.empty>
        """)

      assert html =~ "No Items Found"
      assert html =~ "<h3>"
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>Empty</:title>
          <:description>Start by creating your first item.</:description>
        </Empty.empty>
        """)

      assert html =~ "Start by creating your first item."
      assert html =~ "<p>"
    end

    test "renders icon slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:icon><span class="test-icon">Icon</span></:icon>
          <:title>Empty</:title>
        </Empty.empty>
        """)

      assert html =~ "empty-icon"
      assert html =~ ~s(class="test-icon")
    end

    test "renders actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>Empty</:title>
          <:actions>
            <button>Create New</button>
          </:actions>
        </Empty.empty>
        """)

      assert html =~ "<button>Create New</button>"
      assert html =~ "<section>"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>Empty</:title>
          <:footer>
            <a href="/help">Learn more</a>
          </:footer>
        </Empty.empty>
        """)

      assert html =~ "Learn more"
    end
  end

  describe "empty/1 variants" do
    test "renders default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>Empty</:title>
        </Empty.empty>
        """)

      assert html =~ ~s(class="empty)
      refute html =~ "empty-outline"
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty variant="outline">
          <:title>Empty</:title>
        </Empty.empty>
        """)

      assert html =~ "empty-outline"
    end
  end

  describe "empty/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty class="my-empty">
          <:title>Empty</:title>
        </Empty.empty>
        """)

      assert html =~ "my-empty"
    end
  end

  describe "empty/1 with id" do
    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty id="my-empty">
          <:title>Empty</:title>
        </Empty.empty>
        """)

      assert html =~ ~s(id="my-empty")
    end
  end
end
