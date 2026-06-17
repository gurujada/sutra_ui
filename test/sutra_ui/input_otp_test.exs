defmodule SutraUI.InputOTPTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.InputOTP

  describe "input_otp/1" do
    test "renders OTP input with slots" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOTP.input_otp id="otp" name="code" length={6} />|)
      assert html =~ "input-otp"
      assert html =~ ~s(name="code")
      assert html =~ "data-otp-slot"
    end

    test "renders correct number of slots" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOTP.input_otp id="otp" name="code" length={4} />|)
      # Count actual <input> elements that are visible slots
      assert length(Regex.scan(~r/<input[^>]*data-otp-slot/, html)) == 4
    end

    test "renders hidden aggregate input" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<InputOTP.input_otp id="otp" name="code" length={6} value="123456" />|
        )

      assert html =~ ~s(value="123456")
    end

    test "renders masked slots" do
      assigns = %{}
      html = rendered_to_string(~H|<InputOTP.input_otp id="otp" name="code" length={4} mask />|)
      assert html =~ ~s(type="password")
    end

    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H|<InputOTP.input_otp id="otp" name="code" length={4} disabled />|)

      assert html =~ ~s(disabled)
    end

    test "renders invalid state" do
      assigns = %{}

      html =
        rendered_to_string(~H|<InputOTP.input_otp id="otp" name="code" length={4} invalid />|)

      assert html =~ ~s(aria-invalid="true")
    end
  end
end
