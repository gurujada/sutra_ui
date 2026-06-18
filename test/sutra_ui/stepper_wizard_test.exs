defmodule SutraUI.StepperWizardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.StepperWizard

  describe "stepper_wizard/1" do
    test "renders navigation and the active step panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="checkout" current="payment">
          <:step id="shipping" label="Shipping">Shipping form</:step>
          <:step id="payment" label="Payment">Payment form</:step>
          <:step id="confirm" label="Confirm">Confirm order</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ ~s(id="checkout")
      assert html =~ "stepper-wizard"
      assert html =~ "Shipping"
      assert html =~ "Payment"
      assert html =~ "Confirm"
      assert html =~ "Payment form"
      refute html =~ "Shipping form"
      refute html =~ "Confirm order"
      assert html =~ ~s(role="tabpanel")
      assert html =~ ~s(aria-labelledby="checkout-step-payment")
    end

    test "defaults to the first step when current is omitted" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="signup">
          <:step id="account" label="Account">Account fields</:step>
          <:step id="profile" label="Profile">Profile fields</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ "Account fields"
      refute html =~ "Profile fields"
      assert html =~ ~s(aria-labelledby="signup-step-account")
    end

    test "derives complete and pending states from current step order" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="checkout" current="payment">
          <:step id="shipping" label="Shipping">Shipping form</:step>
          <:step id="payment" label="Payment">Payment form</:step>
          <:step id="confirm" label="Confirm">Confirm order</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ ~s(data-state="complete")
      assert html =~ ~s(data-state="current")
      assert html =~ ~s(data-state="pending")
    end

    test "step labels are not navigation controls" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="checkout" current="payment">
          <:step id="shipping" label="Shipping">Shipping form</:step>
          <:step id="payment" label="Payment">Payment form</:step>
        </StepperWizard.stepper_wizard>
        """)

      refute html =~ ~s(<button)
      refute html =~ "phx-click"
      refute html =~ "phx-value-step"
    end

    test "errors map marks matching steps as error" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard
          id="checkout"
          current="confirm"
          errors={%{"payment" => "Required"}}
        >
          <:step id="shipping" label="Shipping">Shipping form</:step>
          <:step id="payment" label="Payment">Payment form</:step>
          <:step id="confirm" label="Confirm">Confirm order</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ ~s(data-state="error")
      assert html =~ "Required"
    end

    test "renders actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="checkout">
          <:step id="shipping" label="Shipping">Shipping form</:step>
          <:actions>
            <button type="button">Continue</button>
          </:actions>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ "stepper-wizard-actions"
      assert html =~ "Continue"
    end

    test "passes outline variant to the underlying stepper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="checkout" variant="outline">
          <:step id="shipping" label="Shipping">Shipping form</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ "stepper-outline"
    end

    test "falls back to the first step when current does not match a step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <StepperWizard.stepper_wizard id="signup" current="missing">
          <:step id="account" label="Account">Account fields</:step>
          <:step id="profile" label="Profile">Profile fields</:step>
        </StepperWizard.stepper_wizard>
        """)

      assert html =~ "Account fields"
      refute html =~ "Profile fields"
      assert html =~ ~s(aria-labelledby="signup-step-account")
    end
  end
end
