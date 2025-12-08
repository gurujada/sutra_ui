defmodule SutraUI.BreadcrumbTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Breadcrumb

  describe "breadcrumb/1 rendering" do
    test "renders nav element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item>Home</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "<nav"
      assert html =~ ~s(class="breadcrumb)
    end

    test "renders ordered list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item>Home</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "<ol"
      assert html =~ "breadcrumb-list"
    end

    test "renders multiple items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item navigate="/products">Products</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "Home"
      assert html =~ "Products"
      assert html =~ "Current"
    end
  end

  describe "breadcrumb/1 links" do
    test "renders navigate link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/home">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(href="/home")
      assert html =~ "breadcrumb-link"
    end

    test "renders href link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item href="https://example.com">External</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(href="https://example.com")
      assert html =~ "breadcrumb-link"
    end

    test "renders current page without link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item>Current Page</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "breadcrumb-page"
      assert html =~ "Current Page"
    end
  end

  describe "breadcrumb/1 separators" do
    test "renders chevron separator by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "breadcrumb-separator"
      assert html =~ "hero-chevron-right"
    end

    test "renders slash separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb separator="slash">
          <:item navigate="/">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "breadcrumb-separator"
    end

    test "does not render separator before first item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item>Only Item</:item>
        </Breadcrumb.breadcrumb>
        """)

      refute html =~ "breadcrumb-separator"
    end
  end

  describe "breadcrumb/1 custom class" do
    test "includes custom class on nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb class="my-breadcrumb">
          <:item>Home</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "my-breadcrumb"
    end

    test "includes custom class on item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item class="custom-item">Home</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ "custom-item"
    end
  end

  describe "breadcrumb/1 accessibility" do
    test "has aria-label on nav" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item>Home</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(aria-label="Breadcrumb")
    end

    test "current page has aria-current" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(aria-current="page")
    end

    test "separator has aria-hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Breadcrumb.breadcrumb>
          <:item navigate="/">Home</:item>
          <:item>Current</:item>
        </Breadcrumb.breadcrumb>
        """)

      assert html =~ ~s(aria-hidden="true")
    end
  end
end
