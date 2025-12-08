defmodule SutraUI.SimpleFormTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.SimpleForm

  describe "simple_form/1 rendering" do
    test "renders form element with form class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form>
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ "<form"
      assert html =~ ~s(class="form)
    end

    test "renders inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form>
          <label>Username</label>
          <input type="text" name="username" />
        </SimpleForm.simple_form>
        """)

      assert html =~ "<label>Username</label>"
      assert html =~ ~s(name="username")
    end
  end

  describe "simple_form/1 attributes" do
    test "accepts action attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form action="/submit">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(action="/submit")
    end

    test "accepts method attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form method="post">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(method="post")
    end

    test "accepts phx-change attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form phx-change="validate">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(phx-change="validate")
    end

    test "accepts phx-submit attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form phx-submit="save">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(phx-submit="save")
    end

    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form id="my-form">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(id="my-form")
    end
  end

  describe "simple_form/1 custom classes" do
    test "accepts custom class as string" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form class="space-y-4">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ "form"
      assert html =~ "space-y-4"
    end

    test "merges multiple classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form class="my-class another-class">
          <input type="text" />
        </SimpleForm.simple_form>
        """)

      assert html =~ "form"
      assert html =~ "my-class"
      assert html =~ "another-class"
    end
  end

  describe "simple_form/1 form elements" do
    test "supports various input types" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SimpleForm.simple_form>
          <input type="text" />
          <input type="email" />
          <input type="password" />
          <input type="checkbox" />
          <textarea></textarea>
          <select>
            <option>Option</option>
          </select>
        </SimpleForm.simple_form>
        """)

      assert html =~ ~s(type="text")
      assert html =~ ~s(type="email")
      assert html =~ ~s(type="password")
      assert html =~ ~s(type="checkbox")
      assert html =~ "<textarea>"
      assert html =~ "<select>"
    end
  end
end
