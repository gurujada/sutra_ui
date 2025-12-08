defmodule SutraUI.RadioGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.RadioGroup

  describe "radio_group/1 basic rendering" do
    test "renders a fieldset with radiogroup role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme" label="Choose theme">
          <:radio value="light" label="Light" />
          <:radio value="dark" label="Dark" />
        </RadioGroup.radio_group>
        """)

      assert html =~ "<fieldset"
      assert html =~ ~s(role="radiogroup")
    end

    test "renders with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme" label="Choose theme">
          <:radio value="light" label="Light" />
        </RadioGroup.radio_group>
        """)

      assert html =~ "Choose theme"
    end

    test "renders radio inputs for each option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme">
          <:radio value="light" label="Light" />
          <:radio value="dark" label="Dark" />
          <:radio value="auto" label="Auto" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(type="radio")
      assert html =~ ~s(value="light")
      assert html =~ ~s(value="dark")
      assert html =~ ~s(value="auto")
      assert html =~ "Light"
      assert html =~ "Dark"
      assert html =~ "Auto"
    end

    test "all radios share the same name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="size">
          <:radio value="small" label="Small" />
          <:radio value="large" label="Large" />
        </RadioGroup.radio_group>
        """)

      # Count occurrences of name="size"
      assert length(Regex.scan(~r/name="size"/, html)) == 2
    end

    test "renders with custom id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme" id="theme-selector">
          <:radio value="light" label="Light" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(id="theme-selector")
    end
  end

  describe "radio_group/1 checked state" do
    test "renders checked radio" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme">
          <:radio value="light" label="Light" />
          <:radio value="dark" label="Dark" checked />
        </RadioGroup.radio_group>
        """)

      # The checked attribute should appear
      assert html =~ "checked"
    end
  end

  describe "radio_group/1 disabled state" do
    test "disables all radios when group is disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme" disabled>
          <:radio value="light" label="Light" />
          <:radio value="dark" label="Dark" />
        </RadioGroup.radio_group>
        """)

      # Both inputs should be disabled (use word boundary to avoid matching class names)
      assert length(Regex.scan(~r/<input[^>]*\sdisabled[\s>]/, html)) == 2
    end

    test "disables individual radio" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme">
          <:radio value="light" label="Light" />
          <:radio value="dark" label="Dark" disabled />
        </RadioGroup.radio_group>
        """)

      # Only one input should be disabled (use word boundary to avoid matching class names)
      assert length(Regex.scan(~r/<input[^>]*\sdisabled[\s>]/, html)) == 1
    end
  end

  describe "radio_group/1 required state" do
    test "renders required attribute on radios" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" required>
          <:radio value="free" label="Free" />
          <:radio value="pro" label="Pro" />
        </RadioGroup.radio_group>
        """)

      assert html =~ "required"
    end

    test "renders aria-required on fieldset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" required>
          <:radio value="free" label="Free" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(aria-required="true")
    end
  end

  describe "radio_group/1 errors" do
    test "renders error messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" errors={["Please select a plan"]}>
          <:radio value="free" label="Free" />
        </RadioGroup.radio_group>
        """)

      assert html =~ "Please select a plan"
    end

    test "renders aria-invalid when errors present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" errors={["Error"]}>
          <:radio value="free" label="Free" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "renders multiple errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" errors={["Error 1", "Error 2"]}>
          <:radio value="free" label="Free" />
        </RadioGroup.radio_group>
        """)

      assert html =~ "Error 1"
      assert html =~ "Error 2"
    end
  end

  describe "radio_group/1 accessibility" do
    test "links label to fieldset via aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="theme" label="Choose theme" id="theme-group">
          <:radio value="light" label="Light" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(id="theme-group-label")
      assert html =~ ~s(aria-labelledby="theme-group-label")
    end

    test "links errors to fieldset via aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="plan" id="plan-group" errors={["Required"]}>
          <:radio value="free" label="Free" />
        </RadioGroup.radio_group>
        """)

      assert html =~ ~s(aria-describedby="plan-group-error")
      assert html =~ ~s(id="plan-group-error")
    end
  end

  describe "radio_group/1 description slot" do
    test "renders description in radio slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio_group name="notify">
          <:radio value="all" label="All notifications">
            Receive all notifications including marketing
          </:radio>
        </RadioGroup.radio_group>
        """)

      assert html =~ "Receive all notifications including marketing"
    end
  end

  describe "radio/1 standalone component" do
    test "renders a single radio" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio name="agree" value="yes" label="I agree" />
        """)

      assert html =~ ~s(type="radio")
      assert html =~ ~s(name="agree")
      assert html =~ ~s(value="yes")
      assert html =~ "I agree"
    end

    test "renders checked state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio name="agree" value="yes" label="I agree" checked />
        """)

      assert html =~ "checked"
    end

    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio name="option" value="1" label="Option 1" disabled />
        """)

      assert html =~ "disabled"
    end

    test "renders with description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio name="notify" value="email" label="Email">
          Receive email notifications
        </RadioGroup.radio>
        """)

      assert html =~ "Receive email notifications"
    end

    test "renders errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <RadioGroup.radio name="plan" value="pro" label="Pro" errors={["Required"]} />
        """)

      assert html =~ "Required"
      assert html =~ ~s(aria-invalid="true")
    end
  end
end
