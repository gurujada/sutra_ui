defmodule SutraUI.HeaderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Header

  describe "header/1 rendering" do
    test "renders header element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Dashboard
        </Header.header>
        """)

      assert html =~ "<header"
      assert html =~ ~s(class="header)
    end

    test "renders title content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          My Page Title
        </Header.header>
        """)

      assert html =~ "My Page Title"
      assert html =~ "header-title"
      assert html =~ "<h1"
    end

    test "renders subtitle slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Title
          <:subtitle>This is a subtitle</:subtitle>
        </Header.header>
        """)

      assert html =~ "This is a subtitle"
      assert html =~ "header-subtitle"
      assert html =~ "<p"
    end

    test "renders actions slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Title
          <:actions>
            <button>Action</button>
          </:actions>
        </Header.header>
        """)

      assert html =~ "<button>Action</button>"
      assert html =~ "header-actions"
    end
  end

  describe "header/1 with actions class" do
    test "adds header-with-actions class when actions present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Title
          <:actions><button>Button</button></:actions>
        </Header.header>
        """)

      assert html =~ "header-with-actions"
    end

    test "does not add header-with-actions class when no actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Title
        </Header.header>
        """)

      refute html =~ "header-with-actions"
    end
  end

  describe "header/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header class="my-header">
          Title
        </Header.header>
        """)

      assert html =~ "my-header"
    end
  end

  describe "header/1 without optional slots" do
    test "renders without subtitle" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Just Title
        </Header.header>
        """)

      assert html =~ "Just Title"
      refute html =~ "header-subtitle"
    end

    test "renders without actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Header.header>
          Just Title
        </Header.header>
        """)

      assert html =~ "Just Title"
      refute html =~ "header-actions"
    end
  end
end
