defmodule PhxUI.DialogTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Dialog

  describe "dialog/1 rendering" do
    test "renders as native dialog element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Test Title</:title>
          Content here
        </Dialog.dialog>
        """)

      assert html =~ "<dialog"
      assert html =~ "dialog"
    end

    test "renders with correct id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="my-dialog">
          <:title>Title</:title>
          <:description>Description</:description>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(id="my-dialog")
      assert html =~ ~s(id="my-dialog-title")
      assert html =~ ~s(id="my-dialog-description")
    end

    test "renders title slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>My Dialog Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ "My Dialog Title"
      assert html =~ "<header>"
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          <:description>This is a description</:description>
          Content
        </Dialog.dialog>
        """)

      assert html =~ "This is a description"
      assert html =~ ~s(id="test-dialog-description")
    end

    test "renders inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          <p>Main content here</p>
        </Dialog.dialog>
        """)

      assert html =~ "<p>Main content here</p>"
      assert html =~ "<section>"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          Content
          <:footer>
            <button>Cancel</button>
            <button>Confirm</button>
          </:footer>
        </Dialog.dialog>
        """)

      assert html =~ "<button>Cancel</button>"
      assert html =~ "<button>Confirm</button>"
      assert html =~ "<footer>"
    end
  end

  describe "dialog/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" class="my-dialog-class">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ "my-dialog-class"
    end
  end

  describe "dialog/1 accessibility" do
    test "has aria-labelledby pointing to title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(aria-labelledby="test-dialog-title")
    end

    test "has aria-describedby pointing to description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          <:description>Description</:description>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(aria-describedby="test-dialog-description")
    end

    test "renders close button with aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" on_cancel="close">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(type="submit")
    end
  end

  describe "dialog/1 cancel event" do
    test "renders with on_cancel attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" on_cancel="close_dialog">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(on_cancel="close_dialog")
    end
  end

  describe "show_dialog/2 and hide_dialog/2" do
    test "show_dialog returns JS struct" do
      js = Dialog.show_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_dialog returns JS struct" do
      js = Dialog.hide_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "show_dialog with existing JS struct" do
      js = Phoenix.LiveView.JS.push("some-event") |> Dialog.show_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end

    test "hide_dialog with existing JS struct" do
      js = Phoenix.LiveView.JS.push("some-event") |> Dialog.hide_dialog("test-dialog")
      assert %Phoenix.LiveView.JS{} = js
    end
  end

  describe "dialog/1 phx-hook" do
    test "has phx-hook for dialog behavior" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" on_cancel="close">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ "phx-hook"
    end
  end
end
