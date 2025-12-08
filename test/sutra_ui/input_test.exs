defmodule SutraUI.InputTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Input

  describe "input/1 basic rendering" do
    test "renders an input element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" />
        """)

      assert html =~ "<input"
      assert html =~ ~s(name="email")
    end

    test "renders with type=text by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="username" />
        """)

      assert html =~ ~s(type="text")
    end

    test "renders with placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" placeholder="Enter your email" />
        """)

      assert html =~ ~s(placeholder="Enter your email")
    end

    test "renders with value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" value="test@example.com" />
        """)

      assert html =~ ~s(value="test@example.com")
    end

    test "renders with id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" id="email-field" />
        """)

      assert html =~ ~s(id="email-field")
    end
  end

  describe "input/1 types" do
    test "renders email type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="email" name="email" />
        """)

      assert html =~ ~s(type="email")
    end

    test "renders password type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="password" name="password" />
        """)

      assert html =~ ~s(type="password")
    end

    test "renders number type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="number" name="quantity" />
        """)

      assert html =~ ~s(type="number")
    end

    test "renders file type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="file" name="attachment" />
        """)

      assert html =~ ~s(type="file")
    end

    test "renders search type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="search" name="query" />
        """)

      assert html =~ ~s(type="search")
    end

    test "renders date type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="date" name="birthdate" />
        """)

      assert html =~ ~s(type="date")
    end

    test "renders tel type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="tel" name="phone" />
        """)

      assert html =~ ~s(type="tel")
    end

    test "renders url type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="url" name="website" />
        """)

      assert html =~ ~s(type="url")
    end
  end

  describe "input/1 states" do
    test "renders disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" disabled />
        """)

      assert html =~ "disabled"
    end

    test "renders required state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" required />
        """)

      assert html =~ "required"
    end

    test "renders readonly state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" readonly />
        """)

      assert html =~ "readonly"
    end
  end

  describe "input/1 constraints" do
    test "renders min and max for number input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="number" name="quantity" min="1" max="100" />
        """)

      assert html =~ ~s(min="1")
      assert html =~ ~s(max="100")
    end

    test "renders step for number input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="number" name="price" step="0.01" />
        """)

      assert html =~ ~s(step="0.01")
    end

    test "renders minlength and maxlength" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="username" minlength="3" maxlength="20" />
        """)

      assert html =~ ~s(minlength="3")
      assert html =~ ~s(maxlength="20")
    end

    test "renders pattern" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="zipcode" pattern="[0-9]{5}" />
        """)

      assert html =~ ~s(pattern="[0-9]{5}")
    end
  end

  describe "input/1 accessibility" do
    test "renders aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="search" aria-label="Search products" />
        """)

      assert html =~ ~s(aria-label="Search products")
    end

    test "renders aria-describedby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" aria-describedby="email-help" />
        """)

      assert html =~ ~s(aria-describedby="email-help")
    end

    test "renders aria-invalid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" aria-invalid="true" />
        """)

      assert html =~ ~s(aria-invalid="true")
    end

    test "renders aria-required" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" aria-required="true" />
        """)

      assert html =~ ~s(aria-required="true")
    end
  end

  describe "input/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" class="w-64" />
        """)

      assert html =~ "w-64"
    end
  end

  describe "input/1 form field integration" do
    test "renders with Phoenix form field" do
      # Create a mock form field
      assigns = %{
        form:
          Phoenix.Component.to_form(%{"email" => "test@example.com"},
            as: :user
          )
      }

      html =
        rendered_to_string(~H"""
        <Input.input field={@form[:email]} type="email" />
        """)

      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(id="user_email")
      assert html =~ ~s(value="test@example.com")
    end

    test "form field value can be overridden" do
      assigns = %{
        form: Phoenix.Component.to_form(%{"email" => "original@example.com"}, as: :user)
      }

      html =
        rendered_to_string(~H"""
        <Input.input field={@form[:email]} value="override@example.com" />
        """)

      assert html =~ ~s(value="override@example.com")
    end
  end

  describe "input/1 file input" do
    test "renders with accept attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="file" name="avatar" accept="image/*" />
        """)

      assert html =~ ~s(accept="image/*")
    end

    test "renders with multiple attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="file" name="attachments" multiple />
        """)

      assert html =~ "multiple"
    end
  end
end
