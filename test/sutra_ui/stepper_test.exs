defmodule SutraUI.StepperTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Stepper

  test "renders steps with computed states" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Stepper.stepper current={2}>
        <:step title="Profile" />
        <:step title="Workspace" />
        <:step title="Invite" />
      </Stepper.stepper>
      """)

    assert html =~ ~s(class="stepper stepper-horizontal)
    assert html =~ ~s(data-state="complete")
    assert html =~ ~s(data-state="current")
    assert html =~ ~s(data-state="pending")
    assert html =~ ~s(aria-current="step")
  end

  test "renders vertical stepper descriptions" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Stepper.stepper orientation="vertical">
        <:step title="Profile" description="Add your details" />
      </Stepper.stepper>
      """)

    assert html =~ "stepper-vertical"
    assert html =~ "Add your details"
  end

  test "allows explicit error state" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Stepper.stepper>
        <:step title="Billing" state="error" />
      </Stepper.stepper>
      """)

    assert html =~ ~s(data-state="error")
    assert html =~ "M12 8v4"
  end
end
