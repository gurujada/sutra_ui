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
      assert html =~ "Clear Filters"
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
  end

  describe "filter_bar/1 grid columns" do
    test "defaults to 3 columns" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <FilterBar.filter_bar on_change="filter">
          <:filter><input name="a" /></:filter>
        </FilterBar.filter_bar>
        """)

      assert html =~ "filter-bar-cols-3"
    end

    test "accepts cols from 1 to 6" do
      for cols <- 1..6 do
        assigns = %{cols: cols}

        html =
          rendered_to_string(~H"""
          <FilterBar.filter_bar on_change="filter" cols={@cols}>
            <:filter><input name="a" /></:filter>
          </FilterBar.filter_bar>
          """)

        assert html =~ "filter-bar-cols-#{cols}"
      end
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
