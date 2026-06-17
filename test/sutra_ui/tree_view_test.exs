defmodule SutraUI.TreeViewTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.TreeView

  describe "tree_view/1" do
    test "renders tree root" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<TreeView.tree_view><TreeView.tree_item label="root" /></TreeView.tree_view>|
        )

      assert html =~ ~s(role="tree")
      assert html =~ "tree-view"
    end
  end

  describe "tree_item/1" do
    test "renders leaf node" do
      assigns = %{}
      html = rendered_to_string(~H|<TreeView.tree_item label="file.txt" />|)
      assert html =~ "file.txt"
      assert html =~ "tree-item-leaf"
      assert html =~ ~s(role="treeitem")
    end

    test "renders collapsible node with children" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<TreeView.tree_item label="folder"><TreeView.tree_item label="nested.txt" /></TreeView.tree_item>|
        )

      assert html =~ "folder"
      assert html =~ "nested.txt"
      assert html =~ "<details"
      assert html =~ "tree-group"
    end

    test "renders expanded node" do
      assigns = %{}
      html = rendered_to_string(~H|<TreeView.tree_item label="open" expanded>
  <TreeView.tree_item label="child" />
</TreeView.tree_item>|)
      assert html =~ ~s(open)
    end

    test "renders selected node" do
      assigns = %{}
      html = rendered_to_string(~H|<TreeView.tree_item label="selected" selected />|)
      assert html =~ ~s(aria-selected="true")
    end

    test "renders href link" do
      assigns = %{}
      html = rendered_to_string(~H|<TreeView.tree_item label="link" href="/file" />|)
      assert html =~ ~s(href="/file")
    end

    test "renders custom trigger content" do
      assigns = %{}

      html =
        rendered_to_string(~H|<TreeView.tree_item>
  <:trigger>
    <span class="custom-node">Custom node</span>
  </:trigger>
</TreeView.tree_item>|)

      assert html =~ "custom-node"
      assert html =~ "Custom node"
    end

    test "renders disabled node" do
      assigns = %{}
      html = rendered_to_string(~H|<TreeView.tree_item label="locked" disabled />|)
      assert html =~ ~s(aria-disabled="true")
    end

    test "renders chevron for collapsible nodes" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<TreeView.tree_item label="dir"><TreeView.tree_item label="f" /></TreeView.tree_item>|
        )

      assert html =~ "tree-item-chevron"
    end
  end
end
