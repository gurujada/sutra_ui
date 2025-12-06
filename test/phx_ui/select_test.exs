defmodule PhxUI.SelectTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Select

  describe "select/1 basic rendering" do
    test "renders a select container with id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(id="country-select")
      assert html =~ ~s(phx-hook="PhxUI.Select.Select")
    end

    test "renders trigger button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ "<button"
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ ~s(aria-expanded="false")
    end

    test "renders listbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(role="listbox")
      assert html =~ ~s(id="country-select-listbox")
    end

    test "renders hidden input for form submission" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select" name="country" value="us">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="country")
      assert html =~ ~s(value="us")
    end

    test "renders with data-select-value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select" value="ca">
          <Select.select_option value="ca" label="Canada" />
        </Select.select>
        """)

      assert html =~ ~s(data-select-value="ca")
    end
  end

  describe "select/1 disabled state" do
    test "renders disabled trigger button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select" disabled>
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~r/<button[^>]*disabled/
    end
  end

  describe "select/1 searchable" do
    test "renders search input when searchable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select" searchable>
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-autocomplete="list")
    end

    test "renders custom search placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select" searchable search_placeholder="Find country...">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(placeholder="Find country...")
    end
  end

  describe "select/1 trigger slot" do
    test "renders custom trigger content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <:trigger>Choose a country</:trigger>
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ "Choose a country"
    end

    test "renders default trigger when no slot provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ "Select..."
    end
  end

  describe "select_option/1" do
    test "renders option with value and label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(role="option")
      assert html =~ ~s(data-value="us")
      assert html =~ ~s(data-label="United States")
      assert html =~ "United States"
    end

    test "renders option with inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_option value="ca">
            <span>🇨🇦</span> Canada
          </Select.select_option>
        </Select.select>
        """)

      assert html =~ "🇨🇦"
      assert html =~ "Canada"
    end

    test "renders disabled option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_option value="mx" label="Mexico" disabled />
        </Select.select>
        """)

      assert html =~ ~s(aria-disabled="true")
    end

    test "renders enabled option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(aria-disabled="false")
    end
  end

  describe "select_group/1" do
    test "renders option group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_group label="Americas">
            <Select.select_option value="us" label="United States" />
            <Select.select_option value="ca" label="Canada" />
          </Select.select_group>
        </Select.select>
        """)

      assert html =~ ~s(role="group")
      assert html =~ "Americas"
    end
  end

  describe "select_separator/1" do
    test "renders separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="test">
          <Select.select_option value="us" label="United States" />
          <Select.select_separator />
          <Select.select_option value="other" label="Other" />
        </Select.select>
        """)

      assert html =~ ~s(role="separator")
    end
  end

  describe "select/1 accessibility" do
    test "links trigger to listbox via aria-controls" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(aria-controls="country-select-listbox")
      assert html =~ ~s(id="country-select-listbox")
    end

    test "links listbox to trigger via aria-labelledby" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Select.select id="country-select">
          <Select.select_option value="us" label="United States" />
        </Select.select>
        """)

      assert html =~ ~s(aria-labelledby="country-select-trigger")
      assert html =~ ~s(id="country-select-trigger")
    end
  end
end
