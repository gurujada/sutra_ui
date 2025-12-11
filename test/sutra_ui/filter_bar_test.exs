defmodule SutraUI.FilterBarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.FilterBar

  describe "filter_bar/1 rendering" do
    test "renders filter bar container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter">
          <:filter>
            <input type="text" name="search" />
          </:filter>
        </FilterBar.filter_bar>
        """)

      assert html =~ "filter-bar"
      assert html =~ ~s(phx-change="filter")
    end

    test "renders multiple filter slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter">
          <:filter>
            <input type="text" name="search" />
          </:filter>
          <:filter>
            <select name="status">
              <option>All</option>
            </select>
          </:filter>
        </FilterBar.filter_bar>
        """)

      assert html =~ ~s(name="search")
      assert html =~ ~s(name="status")
      # Should have 2 filter-bar-item divs
      assert length(Regex.scan(~r/filter-bar-item/, html)) == 2
    end

    test "renders clear button when show_clear and on_clear are provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter" on_clear="clear" show_clear>
          <:filter>
            <input type="text" name="search" />
          </:filter>
        </FilterBar.filter_bar>
        """)

      assert html =~ "filter-bar-clear"
      assert html =~ ~s(phx-click="clear")
      assert html =~ "Clear"
    end

    test "does not render clear button when show_clear is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter" on_clear="clear" show_clear={false}>
          <:filter>
            <input type="text" name="search" />
          </:filter>
        </FilterBar.filter_bar>
        """)

      refute html =~ "filter-bar-clear"
    end

    test "does not render clear button when on_clear is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter" show_clear>
          <:filter>
            <input type="text" name="search" />
          </:filter>
        </FilterBar.filter_bar>
        """)

      refute html =~ "filter-bar-clear"
    end
  end

  describe "filter_bar/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter" class="my-custom-class">
          <:filter><input name="a" /></:filter>
        </FilterBar.filter_bar>
        """)

      assert html =~ "filter-bar"
      assert html =~ "my-custom-class"
    end
  end
end
