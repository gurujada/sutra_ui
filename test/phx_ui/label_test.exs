defmodule PhxUI.LabelTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Label

  describe "label/1" do
    test "renders a label element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label>Email</Label.label>
        """)

      assert html =~ "<label"
      assert html =~ "Email"
    end

    test "renders with for attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="email-input">Email</Label.label>
        """)

      assert html =~ ~s(for="email-input")
    end

    test "renders without for attribute when not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label>Terms</Label.label>
        """)

      # Should not have a for attribute pointing to nothing
      refute html =~ ~s(for=")
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label class="gap-3">Email</Label.label>
        """)

      assert html =~ "gap-3"
    end

    test "renders with id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label id="email-label">Email</Label.label>
        """)

      assert html =~ ~s(id="email-label")
    end

    test "renders with data-test attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label data-test="email-label">Email</Label.label>
        """)

      assert html =~ ~s(data-test="email-label")
    end

    test "renders inner content as slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label for="password">
          Password
          <span class="required">*</span>
        </Label.label>
        """)

      assert html =~ "Password"
      assert html =~ ~s(<span class="required">*</span>)
    end

    test "can wrap input elements" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Label.label>
          <input type="checkbox" name="terms" />
          Accept terms
        </Label.label>
        """)

      assert html =~ "<label"
      assert html =~ ~s(<input type="checkbox")
      assert html =~ "Accept terms"
    end
  end
end
