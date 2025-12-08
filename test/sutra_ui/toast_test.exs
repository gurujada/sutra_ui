defmodule SutraUI.ToastTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Toast

  describe "toast/1 rendering" do
    test "renders toast container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Hello</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(class="toast)
    end

    test "renders title slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Success Message</:title>
        </Toast.toast>
        """)

      assert html =~ "Success Message"
      assert html =~ "toast-title"
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
          <:description>Your changes have been saved.</:description>
        </Toast.toast>
        """)

      assert html =~ "Your changes have been saved."
      assert html =~ "toast-description"
    end

    test "renders action slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
          <:action>
            <button>Undo</button>
          </:action>
        </Toast.toast>
        """)

      assert html =~ "toast-action"
      assert html =~ "<button>Undo</button>"
    end

    test "renders close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ "toast-close"
      assert html =~ ~s(aria-label="Close")
    end
  end

  describe "toast/1 variants" do
    test "renders default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Default</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(class="toast)
      refute html =~ "toast-success"
      refute html =~ "toast-destructive"
    end

    test "renders success variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast" variant="success">
          <:title>Success</:title>
        </Toast.toast>
        """)

      assert html =~ "toast-success"
    end

    test "renders destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast" variant="destructive">
          <:title>Error</:title>
        </Toast.toast>
        """)

      assert html =~ "toast-destructive"
    end
  end

  describe "toast/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast" class="my-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ "my-toast"
    end
  end

  describe "toast/1 accessibility" do
    test "has role=status" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(role="status")
    end

    test "has aria-live=polite" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(aria-live="polite")
    end

    test "close button has aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="test-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(aria-label="Close")
    end
  end

  describe "toast/1 with id" do
    test "uses provided id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Toast.toast id="my-toast">
          <:title>Title</:title>
        </Toast.toast>
        """)

      assert html =~ ~s(id="my-toast")
    end
  end

  describe "toast_container/1 rendering" do
    test "renders toast container" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_container flash={@flash} />
        """)

      assert html =~ ~s(id="toast-container")
      assert html =~ "toast-container"
    end

    test "renders info flash as toast" do
      assigns = %{flash: %{"info" => "Operation successful"}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_container flash={@flash} />
        """)

      assert html =~ "Operation successful"
      assert html =~ ~s(id="toast-info")
    end

    test "renders error flash as destructive toast" do
      assigns = %{flash: %{"error" => "Something went wrong"}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_container flash={@flash} />
        """)

      assert html =~ "Something went wrong"
      assert html =~ ~s(id="toast-error")
      assert html =~ "toast-destructive"
    end

    test "includes custom class" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_container flash={@flash} class="my-container" />
        """)

      assert html =~ "my-container"
    end

    test "has phx-hook for dynamic toasts" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <Toast.toast_container flash={@flash} />
        """)

      assert html =~ ~s(phx-hook="SutraUI.Toast.ToastContainer")
    end
  end
end
