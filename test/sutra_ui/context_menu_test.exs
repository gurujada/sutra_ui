defmodule SutraUI.ContextMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.ContextMenu

  test "renders context menu composition" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <ContextMenu.context_menu id="message-menu">
        <:trigger>
          <div>Right click</div>
        </:trigger>
        <ContextMenu.context_menu_label>Actions</ContextMenu.context_menu_label>
        <ContextMenu.context_menu_item shortcut="R">Reply</ContextMenu.context_menu_item>
        <ContextMenu.context_menu_separator />
        <ContextMenu.context_menu_item variant="destructive">Delete</ContextMenu.context_menu_item>
      </ContextMenu.context_menu>
      """)

    assert html =~ ~s(id="message-menu")
    assert html =~ ~s(phx-hook="SutraUI.ContextMenu.ContextMenu")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(role="menu")
    assert html =~ "Actions"
    assert html =~ "Reply"
    assert html =~ "context-menu-item-destructive"
    assert html =~ ~s(role="separator")
  end

  test "renders disabled item" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <ContextMenu.context_menu_item disabled>Unavailable</ContextMenu.context_menu_item>
      """)

    assert html =~ ~s(aria-disabled="true")
  end
end
