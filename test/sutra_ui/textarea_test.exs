defmodule SutraUI.TextareaTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Textarea

  describe "textarea/1 basic rendering" do
    test "renders a textarea element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" />
        """)

      assert html =~ "<textarea"
      assert html =~ ~s(name="message")
      assert html =~ "</textarea>"
    end

    test "renders with placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" placeholder="Enter your message" />
        """)

      assert html =~ ~s(placeholder="Enter your message")
    end

    test "renders with value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" value="Hello world" />
        """)

      assert html =~ "Hello world"
    end

    test "renders with id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" id="message-field" />
        """)

      assert html =~ ~s(id="message-field")
    end

    test "renders with rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="bio" rows={5} />
        """)

      assert html =~ ~s(rows="5")
    end
  end

  describe "textarea/1 states" do
    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" disabled />
        """)

      assert html =~ "disabled"
    end

    test "does not render disabled when false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" disabled={false} />
        """)

      refute html =~ ~r/<textarea[^>]*\sdisabled[\s>=]/
    end

    test "renders required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" required />
        """)

      assert html =~ "required"
    end

    test "renders readonly state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" readonly />
        """)

      assert html =~ "readonly"
    end
  end

  describe "textarea/1 constraints" do
    test "renders maxlength" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" maxlength="500" />
        """)

      assert html =~ ~s(maxlength="500")
    end

    test "renders minlength" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" minlength="10" />
        """)

      assert html =~ ~s(minlength="10")
    end
  end

  describe "textarea/1 accessibility" do
    test "renders aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" aria-label="Message input" />
        """)

      assert html =~ ~s(aria-label="Message input")
    end

    test "renders aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" aria-describedby="message-help" />
        """)

      assert html =~ ~s(aria-describedby="message-help")
    end

    test "renders aria-invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" aria-invalid="true" />
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "renders aria-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" aria-required="true" />
        """)

      assert html =~ ~s(aria-required="true")
    end
  end

  describe "textarea/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Textarea.textarea name="message" class="resize-none" />
        """)

      assert html =~ "resize-none"
    end
  end

  describe "textarea/1 form field integration" do
    test "renders with Phoenix form field" do
      assigns = %{
        form: Phoenix.Component.to_form(%{"message" => "Hello"}, as: :post)
      }

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@form[:message]} />
        """)

      assert html =~ ~s(name="post[message]")
      assert html =~ ~s(id="post_message")
      assert html =~ "Hello"
    end

    test "form field value can be overridden" do
      assigns = %{
        form: Phoenix.Component.to_form(%{"message" => "Original"}, as: :post)
      }

      html =
        rendered_to_string(~H"""
        <Textarea.textarea field={@form[:message]} value="Override" />
        """)

      assert html =~ "Override"
    end
  end
end
