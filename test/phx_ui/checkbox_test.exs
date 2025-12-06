defmodule PhxUI.CheckboxTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Checkbox

  describe "checkbox/1 basic rendering" do
    test "renders a checkbox input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" />
        """)

      assert html =~ "<input"
      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(name="terms")
    end

    test "renders with default value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" />
        """)

      assert html =~ ~s(value="true")
    end

    test "renders with custom value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" value="accepted" />
        """)

      assert html =~ ~s(value="accepted")
    end

    test "renders with id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" id="terms-checkbox" />
        """)

      assert html =~ ~s(id="terms-checkbox")
    end
  end

  describe "checkbox/1 checked state" do
    test "renders checked when checked=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" checked />
        """)

      assert html =~ "checked"
    end

    test "does not render checked when checked=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" checked={false} />
        """)

      refute html =~ ~r/<input[^>]*\schecked[\s>=]/
    end
  end

  describe "checkbox/1 disabled state" do
    test "renders disabled when disabled=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" disabled />
        """)

      assert html =~ "disabled"
    end

    test "does not render disabled when disabled=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" disabled={false} />
        """)

      refute html =~ ~r/<input[^>]*\sdisabled[\s>=]/
    end
  end

  describe "checkbox/1 required state" do
    test "renders required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" required />
        """)

      assert html =~ "required"
    end
  end

  describe "checkbox/1 accessibility" do
    test "renders aria-invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" aria-invalid="true" />
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "renders aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" aria-describedby="terms-help" />
        """)

      assert html =~ ~s(aria-describedby="terms-help")
    end

    test "renders aria-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" aria-required="true" />
        """)

      assert html =~ ~s(aria-required="true")
    end
  end

  describe "checkbox/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" class="my-checkbox" />
        """)

      assert html =~ "my-checkbox"
    end
  end

  describe "checkbox/1 form integration" do
    test "renders with form attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Checkbox.checkbox name="terms" form="signup-form" />
        """)

      assert html =~ ~s(form="signup-form")
    end
  end
end
