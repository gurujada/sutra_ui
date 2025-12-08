defmodule SutraUI.PaginationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Pagination

  describe "pagination/1 rendering" do
    test "renders nav element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      assert html =~ "<nav"
      assert html =~ ~s(class="pagination)
    end

    test "renders pagination list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      assert html =~ "<ul"
      assert html =~ "pagination-list"
    end

    test "renders page numbers" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={3} total_pages={5} />
        """)

      # Page numbers are inside buttons with whitespace
      assert html =~ "phx-value-page=\"1\""
      assert html =~ "phx-value-page=\"2\""
      assert html =~ "phx-value-page=\"3\""
      assert html =~ "phx-value-page=\"4\""
      assert html =~ "phx-value-page=\"5\""
    end

    test "renders prev and next buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={3} total_pages={5} />
        """)

      assert html =~ "pagination-prev"
      assert html =~ "pagination-next"
    end
  end

  describe "pagination/1 current page" do
    test "marks current page as active" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={3} total_pages={5} />
        """)

      assert html =~ "pagination-active"
    end

    test "has aria-current on current page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={2} total_pages={5} />
        """)

      assert html =~ ~s(aria-current="page")
    end
  end

  describe "pagination/1 disabled buttons" do
    test "disables prev button on first page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      # The prev button should be disabled
      assert html =~ ~r/pagination-prev.*disabled/s
    end

    test "disables next button on last page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={5} total_pages={5} />
        """)

      # The next button should be disabled
      assert html =~ ~r/pagination-next.*disabled/s
    end
  end

  describe "pagination/1 ellipsis" do
    test "shows ellipsis for many pages" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={5} total_pages={10} />
        """)

      assert html =~ "pagination-ellipsis"
      assert html =~ "..."
    end
  end

  describe "pagination/1 custom slots" do
    test "renders custom previous content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={3} total_pages={5}>
          <:previous>Prev</:previous>
          <:next>Next</:next>
        </Pagination.pagination>
        """)

      assert html =~ "Prev"
      assert html =~ "Next"
    end
  end

  describe "pagination/1 on_page_change" do
    test "includes phx-click with on_page_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} on_page_change="change_page" />
        """)

      assert html =~ ~s(phx-click="change_page")
    end

    test "includes phx-value-page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} on_page_change="change_page" />
        """)

      assert html =~ "phx-value-page"
    end
  end

  describe "pagination/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} class="my-pagination" />
        """)

      assert html =~ "my-pagination"
    end
  end

  describe "pagination/1 accessibility" do
    test "has aria-label on nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      assert html =~ ~s(aria-label="Pagination")
    end

    test "has aria-label on prev button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      assert html =~ ~s(aria-label="Go to previous page")
    end

    test "has aria-label on next button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Pagination.pagination page={1} total_pages={5} />
        """)

      assert html =~ ~s(aria-label="Go to next page")
    end
  end
end
