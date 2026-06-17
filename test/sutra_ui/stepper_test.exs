defmodule SutraUI.StepperTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.Stepper

  describe "stepper/1" do
    test "renders as ordered list" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper>
  <:step>Step 1</:step>
  <:step>Step 2</:step>
</Stepper.stepper>|)
      assert html =~ "<ol"
      assert html =~ "stepper"
    end

    test "renders step markers with numbers" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper>
  <:step>One</:step>
  <:step>Two</:step>
</Stepper.stepper>|)
      assert html =~ "stepper-marker"
      assert html =~ "1"
      assert html =~ "2"
    end

    test "renders step content" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper>
  <:step>
    <h4>Profile</h4>
    <p>Tell us about yourself</p>
  </:step>
</Stepper.stepper>|)
      assert html =~ "<h4>Profile</h4>"
      assert html =~ "Tell us about yourself"
    end

    test "auto-computes states from current" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper current={2}>
  <:step>One</:step>
  <:step>Two</:step>
  <:step>Three</:step>
</Stepper.stepper>|)
      assert html =~ ~s(data-state="complete")
      assert html =~ ~s(data-state="current")
      assert html =~ ~s(data-state="pending")
    end

    test "accepts explicit states" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper current={0}>
  <:step state="error">Fail</:step>
</Stepper.stepper>|)
      assert html =~ ~s(data-state="error")
    end

    test "marks steps with errors as error state" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper current={2} errors={%{2 => "Required"}}>
  <:step>One</:step>
  <:step>Two</:step>
</Stepper.stepper>|)
      assert html =~ ~s(data-state="error")
      assert html =~ "Required"
    end

    test "treats nil errors as no errors" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper current={1} errors={nil}>
  <:step>One</:step>
</Stepper.stepper>|)
      assert html =~ ~s(data-state="current")
    end

    test "renders vertical orientation" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper orientation="vertical">
  <:step>One</:step>
</Stepper.stepper>|)
      assert html =~ "stepper-vertical"
    end

    test "renders custom icon in marker" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper>
  <:step icon="✓" state="complete">Done</:step>
</Stepper.stepper>|)
      assert html =~ "✓"
    end

    test "renders checkmark icon for complete state" do
      assigns = %{}
      html = rendered_to_string(~H|<Stepper.stepper current={2}>
  <:step>One</:step>
  <:step>Two</:step>
</Stepper.stepper>|)
      assert html =~ "stepper-check"
    end
  end
end
