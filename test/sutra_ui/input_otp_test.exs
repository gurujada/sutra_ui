defmodule SutraUI.InputOTPTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.InputOTP

  test "renders grouped otp slots and hidden input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputOTP.input_otp id="otp" name="code" value="123456" groups={[3, 3]} />
      """)

    assert html =~ ~s(id="otp")
    assert html =~ ~s(phx-hook="SutraUI.InputOTP.InputOTP")
    assert html =~ ~s(type="hidden" name="code" value="123456")
    assert length(Regex.scan(~r/class="input-otp-slot"/, html)) == 6
    assert html =~ "input-otp-separator"
    assert html =~ ~s(value="1")
    assert html =~ ~s(value="6")
  end

  test "marks slots disabled and invalid" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <InputOTP.input_otp id="otp" name="code" length={4} disabled invalid />
      """)

    assert length(Regex.scan(~r/disabled/, html)) == 4
    assert length(Regex.scan(~r/aria-invalid="true"/, html)) == 4
  end
end
