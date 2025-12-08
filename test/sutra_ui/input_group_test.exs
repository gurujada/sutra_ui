defmodule SutraUI.InputGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.InputGroup

  describe "input_group/1 rendering" do
    test "renders input group container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group"
      assert html =~ "<input"
    end

    test "renders prefix slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:prefix>$</:prefix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-prefix"
      assert html =~ "$"
    end

    test "renders suffix slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:suffix>USD</:suffix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-suffix"
      assert html =~ "USD"
    end

    test "renders both prefix and suffix" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:prefix>$</:prefix>
          <:suffix>USD</:suffix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-prefix"
      assert html =~ "input-group-suffix"
      assert html =~ "$"
      assert html =~ "USD"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <textarea></textarea>
          <:footer>Footer content</:footer>
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-footer"
      assert html =~ "Footer content"
    end
  end

  describe "input_group/1 slot types" do
    test "renders icon type prefix" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:prefix type="icon">
            <span class="icon">search</span>
          </:prefix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-prefix-icon"
    end

    test "renders interactive type suffix" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:suffix type="interactive">
            <button>Copy</button>
          </:suffix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-suffix-interactive"
    end

    test "renders text type as default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group>
          <:prefix type="text">$</:prefix>
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group-text"
    end
  end

  describe "input_group_horizontal/1" do
    test "renders horizontal input group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group_horizontal>
          <:prefix_label>https://</:prefix_label>
          <input type="text" />
          <:suffix_label>.com</:suffix_label>
        </InputGroup.input_group_horizontal>
        """)

      assert html =~ "input-group-horizontal"
      assert html =~ "input-group-label-start"
      assert html =~ "input-group-label-end"
      assert html =~ "https://"
      assert html =~ ".com"
    end

    test "renders with only prefix label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group_horizontal>
          <:prefix_label>@</:prefix_label>
          <input type="text" />
        </InputGroup.input_group_horizontal>
        """)

      assert html =~ "input-group-label-start"
      assert html =~ "@"
    end
  end

  describe "input_group/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <InputGroup.input_group class="my-custom-class">
          <input type="text" />
        </InputGroup.input_group>
        """)

      assert html =~ "input-group"
      assert html =~ "my-custom-class"
    end
  end
end
