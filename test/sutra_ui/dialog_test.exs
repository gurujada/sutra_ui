defmodule SutraUI.DialogTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Dialog

  describe "dialog/1 rendering" do
    test "renders as div-based dialog (screen share compatible)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Test Title</:title>
          Content here
        </Dialog.dialog>
        """)

      assert html =~ ~s(<div)
      assert html =~ ~s(class="dialog)
      assert html =~ ~s(role="dialog")
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

  describe "dialog/1 show attribute" do
    test "adds is-open class when show is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" show={true}>
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(class="dialog is-open")
    end

    test "does not add is-open class when show is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" show={false}>
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(class="dialog)
      refute html =~ "is-open"
    end
  end

  describe "dialog/1 custom class" do
    test "includes custom class on panel" do
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

    test "has role=dialog and aria-modal=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "renders close button with aria-label when on_cancel is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog" on_cancel="close">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(type="button")
    end
  end

  describe "dialog/1 backdrop" do
    test "renders backdrop element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="test-dialog">
          <:title>Title</:title>
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~s(class="dialog-backdrop")
      assert html =~ ~s(aria-hidden="true")
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

      assert html =~ "phx-hook="
      assert html =~ "Dialog"
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

  describe "dialog/1 tall content" do
    test "the focus wrap carries the dialog-focus class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="tall-dialog">
          Content
        </Dialog.dialog>
        """)

      assert html =~ ~r/id="tall-dialog-focus-wrap"[^>]*class="dialog-focus"/ or
               html =~ ~r/class="dialog-focus"[^>]*id="tall-dialog-focus-wrap"/
    end

    test "the wrap fills the screen and the panel keeps its natural width" do
      css = File.read!("priv/static/sutra_ui.css")

      assert css =~ ~r/\.dialog-focus \{\s*@apply flex h-full w-full items-center justify-center;/

      assert css =~
               ~r/\.dialog-panel \{\s*@apply bg-background relative z-10 flex flex-col w-fit /
    end
  end

  describe "dialog/1 placement" do
    import SutraUI.HTMLHelpers

    test "center is the default and stays div-based" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="d"><:title>T</:title>Body</Dialog.dialog>
        """)

      assert attribute(html, "#d", "data-placement") == "center"
      assert attribute(html, "#d", "data-size") == nil
      assert attribute(html, "#d", "data-anchor") == nil
      refute html =~ "<dialog"
      refute html =~ "popover="
    end

    test "side takes a size" do
      for size <- ~w(md lg xl) do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <Dialog.dialog id="d" placement="side" size={@size}><:title>T</:title>Body</Dialog.dialog>
          """)

        assert attribute(html, "#d", "data-placement") == "side"
        assert attribute(html, "#d", "data-size") == size
        assert attribute(html, "#d-panel", "role") == "dialog"
      end
    end

    test "sheet" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="d" placement="sheet"><:title>T</:title>Body</Dialog.dialog>
        """)

      assert attribute(html, "#d", "data-placement") == "sheet"
      assert attribute(html, "#d", "data-size") == nil
    end

    test "popover carries its anchor" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Dialog.dialog id="d" placement="popover" anchor="#course-bar">
          <:title>T</:title>Body
        </Dialog.dialog>
        """)

      assert attribute(html, "#d", "data-placement") == "popover"
      assert attribute(html, "#d", "data-anchor") == "#course-bar"
    end

    test "every placement keeps its title, description and close wiring" do
      for placement <- ~w(center side sheet popover) do
        assigns = %{placement: placement}

        html =
          rendered_to_string(~H"""
          <Dialog.dialog id="d" placement={@placement} on_cancel="close">
            <:title>Why</:title>
            <:description>Because</:description>
            Body
          </Dialog.dialog>
          """)

        assert attribute(html, "#d-panel", "aria-labelledby") == "d-title"
        assert attribute(html, "#d-panel", "aria-describedby") == "d-description"
        assert attribute(html, "#d-panel button", "aria-label") == "Close"
        assert text(html, "#d-title") == "Why"
      end
    end
  end
end
