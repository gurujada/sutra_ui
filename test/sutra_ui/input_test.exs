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

    test "sets aria-invalid when errors present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" errors={["is invalid"]} />
        """)

      assert html =~ ~s(aria-invalid="true")
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

  describe "input/1 with label" do
    test "renders label inside wrapper when label is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="email" name="email" id="email" label="Email Address" />
        """)

      assert html =~ ~s(<span class="label mb-1">Email Address</span>)
      assert html =~ ~s(<input)
      assert html =~ ~s(type="email")
    end

    test "renders no label when label not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="text" name="search" placeholder="Search..." />
        """)

      refute html =~ ~s(<span class="label)
      assert html =~ ~s(<input)
    end

    test "works with form field and label" do
      assigns = %{
        form: Phoenix.Component.to_form(%{"email" => "test@example.com"}, as: :user)
      }

      html =
        rendered_to_string(~H"""
        <Input.input field={@form[:email]} type="email" label="Email" />
        """)

      assert html =~ ~s(<span class="label mb-1">Email</span>)
      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(id="user_email")
    end
  end

  describe "input/1 hidden type" do
    test "renders hidden input without wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="hidden" name="token" value="abc123" />
        """)

      assert html =~ ~s(<input type="hidden")
      assert html =~ ~s(name="token")
      assert html =~ ~s(value="abc123")
      refute html =~ "fieldset"
      refute html =~ "<label"
    end

    test "hidden input ignores label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="hidden" name="token" value="abc123" label="Should not show" />
        """)

      refute html =~ "Should not show"
    end
  end

  describe "input/1 checkbox type" do
    test "renders checkbox input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="terms" />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(name="terms")
    end

    test "renders hidden false value before checkbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="agree" />
        """)

      assert html =~ ~s(<input type="hidden" name="agree" value="false")
      assert html =~ ~s(<input type="checkbox")
    end

    test "renders checkbox with label after input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="terms" label="I agree to the terms" />
        """)

      assert html =~ ~s(<span class="label">I agree to the terms</span>)
    end

    test "renders checkbox as checked when value is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="active" value={true} />
        """)

      assert html =~ "checked"
    end

    test "renders checkbox as checked when checked attribute is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="active" checked={true} />
        """)

      assert html =~ "checked"
    end

    test "renders checkbox errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="checkbox" name="terms" errors={["must be accepted"]} />
        """)

      assert html =~ "must be accepted"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input/1 select type" do
    test "renders native select element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="country"
          options={[{"United States", "us"}, {"Canada", "ca"}]}
        />
        """)

      assert html =~ "<select"
      assert html =~ ~s(name="country")
      assert html =~ "<option"
      assert html =~ "United States"
      assert html =~ ~s(value="us")
    end

    test "renders select with prompt" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="country"
          prompt="Select a country"
          options={[{"United States", "us"}]}
        />
        """)

      assert html =~ ~s(<option value="">Select a country</option>)
    end

    test "renders select with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="country"
          label="Country"
          options={[{"United States", "us"}]}
        />
        """)

      assert html =~ ~s(<span class="label mb-1">Country</span>)
    end

    test "renders select with selected value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="country"
          value="ca"
          options={[{"United States", "us"}, {"Canada", "ca"}]}
        />
        """)

      assert html =~ ~s(<option selected value="ca">Canada</option>)
    end

    test "renders select with multiple" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="countries"
          multiple={true}
          options={[{"United States", "us"}, {"Canada", "ca"}]}
        />
        """)

      assert html =~ "multiple"
    end

    test "renders select errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input
          type="select"
          name="country"
          options={[{"United States", "us"}]}
          errors={["is required"]}
        />
        """)

      assert html =~ "is required"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input/1 textarea type" do
    test "renders textarea element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="textarea" name="bio" />
        """)

      assert html =~ "<textarea"
      assert html =~ ~s(name="bio")
    end

    test "renders textarea with value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="textarea" name="bio" value="Hello world" />
        """)

      assert html =~ "Hello world</textarea>"
    end

    test "renders textarea with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="textarea" name="bio" label="Biography" />
        """)

      assert html =~ ~s(<span class="label mb-1">Biography</span>)
    end

    test "renders textarea with rows" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="textarea" name="bio" rows={6} />
        """)

      assert html =~ ~s(rows="6")
    end

    test "renders textarea errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="textarea" name="bio" errors={["is too short"]} />
        """)

      assert html =~ "is too short"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input/1 range type" do
    test "renders range input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" />
        """)

      assert html =~ ~s(type="range")
      assert html =~ ~s(name="volume")
    end

    test "renders range with slider class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" />
        """)

      assert html =~ "slider"
      assert html =~ "w-full"
    end

    test "renders range with min, max, step" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" min="0" max="100" step="10" />
        """)

      assert html =~ ~s(min="0")
      assert html =~ ~s(max="100")
      assert html =~ ~s(step="10")
    end

    test "renders range with value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" value="50" />
        """)

      assert html =~ ~s(value="50")
    end

    test "renders range with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" label="Volume" />
        """)

      assert html =~ ~s(<span class="label mb-1">Volume</span>)
    end

    test "renders range with CSS custom property for visual fill" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" value="75" min="0" max="100" />
        """)

      assert html =~ "--slider-value: 75"
    end

    test "renders range with oninput handler for live updates" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" />
        """)

      assert html =~ "oninput="
      assert html =~ "--slider-value"
    end

    test "renders range with aria attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" value="50" min="0" max="100" />
        """)

      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-valuenow="50")
    end

    test "renders range errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="range" name="volume" errors={["must be less than 100"]} />
        """)

      assert html =~ "must be less than 100"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input/1 switch type" do
    test "renders switch input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="notifications" />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(role="switch")
      assert html =~ ~s(name="notifications")
    end

    test "renders switch with hidden false value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="enabled" />
        """)

      assert html =~ ~s(<input type="hidden" name="enabled" value="false")
    end

    test "renders switch with switch class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="enabled" />
        """)

      assert html =~ ~s(class="switch)
    end

    test "renders switch with label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="notifications" label="Enable notifications" />
        """)

      assert html =~ ~s(<span class="label">Enable notifications</span>)
    end

    test "renders switch as checked when value is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="active" value={true} />
        """)

      assert html =~ "checked"
      assert html =~ ~s(aria-checked="true")
    end

    test "renders switch as unchecked when value is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="active" value={false} />
        """)

      assert html =~ ~s(aria-checked="false")
    end

    test "renders switch as checked when checked attribute is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="active" checked={true} />
        """)

      assert html =~ "checked"
    end

    test "renders switch errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input type="switch" name="terms" errors={["must be accepted"]} />
        """)

      assert html =~ "must be accepted"
      assert html =~ ~s(aria-invalid="true")
    end

    test "renders switch with form field" do
      assigns = %{
        form: Phoenix.Component.to_form(%{"notifications" => true}, as: :settings)
      }

      html =
        rendered_to_string(~H"""
        <Input.input field={@form[:notifications]} type="switch" label="Notifications" />
        """)

      assert html =~ ~s(name="settings[notifications]")
      assert html =~ ~s(id="settings_notifications")
      assert html =~ "checked"
    end
  end

  describe "input/1 error handling" do
    test "renders error messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" errors={["can't be blank", "is invalid"]} />
        """)

      assert html =~ "can&#39;t be blank"
      assert html =~ "is invalid"
    end

    test "renders error icon with messages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" errors={["is invalid"]} />
        """)

      assert html =~ "<svg"
      assert html =~ "is invalid"
    end

    test "does not render errors section when no errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Input.input name="email" />
        """)

      refute html =~ "text-destructive"
    end
  end

  describe "translate_error/1" do
    test "interpolates values into message" do
      assert Input.translate_error({"must be at least %{count} characters", [count: 3]}) ==
               "must be at least 3 characters"
    end

    test "handles multiple interpolations" do
      assert Input.translate_error({"must be between %{min} and %{max}", [min: 1, max: 10]}) ==
               "must be between 1 and 10"
    end

    test "returns message unchanged when no opts" do
      assert Input.translate_error({"is invalid", []}) == "is invalid"
    end
  end

  describe "translate_errors/2" do
    test "translates errors for a specific field" do
      errors = [
        {:email, {"can't be blank", []}},
        {:email, {"is invalid", []}},
        {:name, {"can't be blank", []}}
      ]

      assert Input.translate_errors(errors, :email) == ["can't be blank", "is invalid"]
    end

    test "returns empty list when no errors for field" do
      errors = [
        {:name, {"can't be blank", []}}
      ]

      assert Input.translate_errors(errors, :email) == []
    end
  end
end
