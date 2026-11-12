defmodule SutraUI.AlertTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Alert

  describe "alert/1 rendering" do
    test "renders alert container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Alert Title</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(class="alert)
    end

    test "renders title slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Important Message</:title>
        </Alert.alert>
        """)

      assert html =~ "Important Message"
      assert html =~ "<h2>"
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Title</:title>
          <:description>This is the description text.</:description>
        </Alert.alert>
        """)

      assert html =~ "This is the description text."
      assert html =~ "<section>"
    end

    test "renders icon slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:icon><span class="test-icon">!</span></:icon>
          <:title>Alert</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(class="test-icon")
      assert html =~ "!"
    end
  end

  describe "alert/1 variants" do
    test "renders default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Default Alert</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(class="alert)
      refute html =~ "alert-destructive"
    end

    test "renders destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert variant="destructive">
          <:title>Error Alert</:title>
        </Alert.alert>
        """)

      assert html =~ "alert-destructive"
    end
  end

  describe "alert/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert class="my-custom-alert">
          <:title>Alert</:title>
        </Alert.alert>
        """)

      assert html =~ "my-custom-alert"
    end
  end

  describe "alert/1 accessibility" do
    test "defaults to status and destructive alerts are assertive" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Alert</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(role="status")

      html =
        rendered_to_string(~H"""
        <Alert.alert variant="destructive">
          <:title>Error</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(role="alert")
    end

    test "caller role overrides the default exactly once" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert variant="destructive" role="status">
          <:title>Error</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(role="status")
      refute html =~ ~s(role="alert")
    end

    test "a role supplied through the global rest map overrides the default" do
      for rest <- [%{role: "status"}, %{"role" => "status"}] do
        html = render_component(&Alert.alert/1, variant: "destructive", rest: rest)
        assert html =~ ~s(role="status")
        refute html =~ ~s(role="alert")
      end
    end

    test "a role spread through HEEx overrides the default" do
      assigns = %{attributes: %{role: "status"}}

      html =
        rendered_to_string(~H"""
        <Alert.alert variant="destructive" {@attributes} />
        """)

      assert html =~ ~s(role="status")
      refute html =~ ~s(role="alert")
    end

    test "description and action render in order without a title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:description>Send failed.</:description>
          <:action><button>Send again</button></:action>
        </Alert.alert>
        """)

      refute html =~ "<h2>"
      assert html =~ "Send failed."
      assert html =~ "<button>Send again</button>"
      assert :binary.match(html, "Send failed.") < :binary.match(html, "Send again")
    end

    test "renders the supported tone classes" do
      for variant <- ~w(info success warning) do
        html = render_component(&Alert.alert/1, variant: variant)
        assert html =~ "alert-#{variant}"
      end
    end

    test "accepts custom id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert id="my-alert">
          <:title>Alert</:title>
        </Alert.alert>
        """)

      assert html =~ ~s(id="my-alert")
    end
  end

  describe "alert/1 without optional slots" do
    test "renders without description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>Just a title</:title>
        </Alert.alert>
        """)

      assert html =~ "Just a title"
      refute html =~ "<section>"
    end

    test "renders without icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Alert.alert>
          <:title>No icon</:title>
        </Alert.alert>
        """)

      assert html =~ "No icon"
    end
  end
end
