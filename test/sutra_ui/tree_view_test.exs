defmodule SutraUI.TreeViewTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.TreeView

  test "renders nested tree items" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <TreeView.tree_view label="Files">
        <TreeView.tree_item label="lib" expanded>
          <TreeView.tree_item label="app.ex" selected />
        </TreeView.tree_item>
      </TreeView.tree_view>
      """)

    assert html =~ ~s(role="tree")
    assert html =~ ~s(aria-label="Files")
    assert html =~ ~s(role="treeitem")
    assert html =~ ~s(open)
    assert html =~ ~s(aria-selected="true")
    assert html =~ "app.ex"
  end

  test "renders leaf link" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <TreeView.tree_item label="README.md" href="/readme" />
      """)

    assert html =~ ~s(href="/readme")
    assert html =~ "README.md"
  end
end
