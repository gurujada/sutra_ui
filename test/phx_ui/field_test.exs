defmodule PhxUI.FieldTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Field

  describe "field/1 basic rendering" do
    test "renders a field container with role=group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field>
          <:label for="username">Username</:label>
          <:input>
            <input id="username" type="text" />
          </:input>
        </Field.field>
        """)

      assert html =~ "<div"
      assert html =~ ~s(role="group")
    end

    test "renders label with for attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field>
          <:label for="email">Email</:label>
          <:input>
            <input id="email" type="email" />
          </:input>
        </Field.field>
        """)

      assert html =~ "<label"
      assert html =~ ~s(for="email")
      assert html =~ "Email"
    end

    test "renders input slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field>
          <:label for="name">Name</:label>
          <:input>
            <input id="name" type="text" placeholder="Enter name" />
          </:input>
        </Field.field>
        """)

      assert html =~ ~s(id="name")
      assert html =~ ~s(placeholder="Enter name")
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field>
          <:label for="username">Username</:label>
          <:input>
            <input id="username" type="text" aria-describedby="username-desc" />
          </:input>
          <:description id="username-desc">Choose a unique username.</:description>
        </Field.field>
        """)

      assert html =~ "Choose a unique username."
      assert html =~ ~s(id="username-desc")
    end

    test "renders error slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field invalid>
          <:label for="password">Password</:label>
          <:input>
            <input id="password" type="password" />
          </:input>
          <:error id="password-error">Password is required</:error>
        </Field.field>
        """)

      assert html =~ "Password is required"
      assert html =~ ~s(id="password-error")
    end
  end

  describe "field/1 orientation" do
    test "renders vertical orientation by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field>
          <:label for="name">Name</:label>
          <:input>
            <input id="name" type="text" />
          </:input>
        </Field.field>
        """)

      # Vertical orientation should not have data-orientation attribute
      refute html =~ "data-orientation"
    end

    test "renders horizontal orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field orientation="horizontal">
          <:input>
            <input id="newsletter" type="checkbox" />
          </:input>
          <:label for="newsletter">Subscribe</:label>
        </Field.field>
        """)

      assert html =~ ~s(data-orientation="horizontal")
    end
  end

  describe "field/1 invalid state" do
    test "renders data-invalid when invalid=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field invalid>
          <:label for="email">Email</:label>
          <:input>
            <input id="email" type="email" />
          </:input>
        </Field.field>
        """)

      assert html =~ "data-invalid"
    end

    test "does not render data-invalid when invalid=false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field invalid={false}>
          <:label for="email">Email</:label>
          <:input>
            <input id="email" type="email" />
          </:input>
        </Field.field>
        """)

      refute html =~ "data-invalid"
    end
  end

  describe "field/1 section slot" do
    test "renders section wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field orientation="horizontal">
          <:section>
            <div>
              <span>MFA Settings</span>
              <span>Enable MFA for security</span>
            </div>
          </:section>
          <:input>
            <input id="mfa" type="checkbox" role="switch" />
          </:input>
        </Field.field>
        """)

      assert html =~ "<section"
      assert html =~ "MFA Settings"
      assert html =~ "Enable MFA for security"
    end
  end

  describe "field/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field class="my-field">
          <:label for="name">Name</:label>
          <:input>
            <input id="name" type="text" />
          </:input>
        </Field.field>
        """)

      assert html =~ "my-field"
    end
  end

  describe "field/1 with id" do
    test "renders with id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.field id="email-field">
          <:label for="email">Email</:label>
          <:input>
            <input id="email" type="email" />
          </:input>
        </Field.field>
        """)

      assert html =~ ~s(id="email-field")
    end
  end

  describe "fieldset/1 basic rendering" do
    test "renders a fieldset element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset>
          <:legend>Profile</:legend>
          <:fields>
            <Field.field>
              <:label for="name">Name</:label>
              <:input>
                <input id="name" type="text" />
              </:input>
            </Field.field>
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ "<fieldset"
      assert html =~ "<legend"
      assert html =~ "Profile"
    end

    test "renders description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset>
          <:legend>Profile</:legend>
          <:description>Enter your profile information</:description>
          <:fields>
            <input type="text" />
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ "Enter your profile information"
    end

    test "renders multiple fields" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset>
          <:legend>Contact</:legend>
          <:fields>
            <Field.field>
              <:label for="email">Email</:label>
              <:input>
                <input id="email" type="email" />
              </:input>
            </Field.field>
            <Field.field>
              <:label for="phone">Phone</:label>
              <:input>
                <input id="phone" type="tel" />
              </:input>
            </Field.field>
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ "Email"
      assert html =~ "Phone"
    end
  end

  describe "fieldset/1 disabled state" do
    test "renders disabled attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset disabled>
          <:legend>Locked</:legend>
          <:fields>
            <input type="text" />
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ "disabled"
    end
  end

  describe "fieldset/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset class="my-fieldset">
          <:legend>Group</:legend>
          <:fields>
            <input type="text" />
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ "my-fieldset"
    end
  end

  describe "fieldset/1 with id" do
    test "renders with id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Field.fieldset id="profile-fieldset">
          <:legend>Profile</:legend>
          <:fields>
            <input type="text" />
          </:fields>
        </Field.fieldset>
        """)

      assert html =~ ~s(id="profile-fieldset")
    end
  end
end
