defmodule SutraUI.SwitchTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Switch

  describe "switch/1 basic rendering" do
    test "renders a switch input with role=switch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane_mode" />
        """)

      assert html =~ "<input"
      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(role="switch")
      assert html =~ ~s(name="airplane_mode")
    end

    test "renders with default value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane_mode" />
        """)

      assert html =~ ~s(value="true")
    end

    test "renders with custom value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane_mode" value="on" />
        """)

      assert html =~ ~s(value="on")
    end

    test "renders with id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane_mode" id="airplane-switch" />
        """)

      assert html =~ ~s(id="airplane-switch")
    end
  end

  describe "switch/1 checked state" do
    test "renders checked when checked=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="notifications" checked />
        """)

      assert html =~ "checked"
      assert html =~ ~s(aria-checked="true")
    end

    test "renders aria-checked=false when not checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="notifications" checked={false} />
        """)

      assert html =~ ~s(aria-checked="false")
      refute html =~ ~r/<input[^>]*\schecked[\s>=]/
    end
  end

  describe "switch/1 disabled state" do
    test "renders disabled when disabled=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="marketing" disabled />
        """)

      assert html =~ "disabled"
    end

    test "does not render disabled when disabled=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="marketing" disabled={false} />
        """)

      refute html =~ ~r/<input[^>]*\sdisabled[\s>=]/
    end
  end

  describe "switch/1 required state" do
    test "renders required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="terms" required />
        """)

      assert html =~ "required"
    end
  end

  describe "switch/1 accessibility" do
    test "renders aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane" aria-label="Airplane Mode" />
        """)

      assert html =~ ~s(aria-label="Airplane Mode")
    end

    test "renders aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane" aria-labelledby="airplane-label" />
        """)

      assert html =~ ~s(aria-labelledby="airplane-label")
    end

    test "renders aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="notifications" aria-describedby="notifications-desc" />
        """)

      assert html =~ ~s(aria-describedby="notifications-desc")
    end

    test "renders aria-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="terms" aria-required="true" />
        """)

      assert html =~ ~s(aria-required="true")
    end
  end

  describe "switch/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="airplane" class="my-switch" />
        """)

      assert html =~ "my-switch"
    end
  end

  describe "switch/1 form integration" do
    test "renders with form attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Switch.switch name="notifications" form="settings-form" />
        """)

      assert html =~ ~s(form="settings-form")
    end
  end
end
