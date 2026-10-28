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

  describe "empty/1 short form and inline variant" do
    import SutraUI.HTMLHelpers

    test "the inner block is the description line and action is the action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty id="e">
          <:title>No projects</:title>
          Create one to get started.
          <:action><button>New</button></:action>
        </Empty.empty>
        """)

      assert attribute(html, "#e", "data-variant") == "default"
      assert text(html, "h3") == "No projects"
      assert text(html, "header p") == "Create one to get started."
      assert text(html, "section button") == "New"
    end

    test "the description slot wins over the inner block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>T</:title>
          <:description>From the slot</:description>
          From the block
        </Empty.empty>
        """)

      assert text(html, "header p") == "From the slot"
    end

    test "no description or action markup when none is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty>
          <:title>T</:title>
        </Empty.empty>
        """)

      assert count(html, "header p") == 0
      assert count(html, "section") == 0
    end

    test "inline is one quiet line with title, text, icon and action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty id="i" variant="inline" class="mt-2">
          <:icon><svg data-icon="inbox"></svg></:icon>
          <:title>No comments</:title>
          Be the first to reply.
          <:action><button>Reply</button></:action>
        </Empty.empty>
        """)

      assert attribute(html, "#i", "data-variant") == "inline"
      assert count(html, "#i h3") == 0
      assert text(html, "#i .empty-title") == "No comments"
      assert text(html, "#i .empty-text") == "Be the first to reply."
      assert text(html, "#i .empty-action button") == "Reply"
      assert count(html, "#i .empty-icon svg[data-icon=inbox]") == 1
      assert attribute(html, "#i .empty-icon", "aria-hidden") == "true"
    end

    test "outline keeps its variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Empty.empty variant="outline" id="o">
          <:title>T</:title>
        </Empty.empty>
        """)

      assert attribute(html, "#o", "data-variant") == "outline"
    end
  end
end
