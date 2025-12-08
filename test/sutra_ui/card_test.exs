defmodule SutraUI.CardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Card

  describe "card/1 rendering" do
    test "renders card container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Card content</:content>
        </Card.card>
        """)

      assert html =~ ~s(class="card)
    end

    test "renders content slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Main content here</:content>
        </Card.card>
        """)

      assert html =~ "Main content here"
      assert html =~ "<section"
    end

    test "renders header slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:header>
            <h2>Card Title</h2>
            <p>Card Description</p>
          </:header>
          <:content>Content</:content>
        </Card.card>
        """)

      assert html =~ "<header"
      assert html =~ "Card Title"
      assert html =~ "Card Description"
    end

    test "renders footer slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Content</:content>
          <:footer>
            <button>Action</button>
          </:footer>
        </Card.card>
        """)

      assert html =~ "<footer"
      assert html =~ "<button>Action</button>"
    end

    test "renders all slots together" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:header>
            <h2>Title</h2>
          </:header>
          <:content>Main content</:content>
          <:footer>Footer content</:footer>
        </Card.card>
        """)

      assert html =~ "<header"
      assert html =~ "<section"
      assert html =~ "<footer"
      assert html =~ "Title"
      assert html =~ "Main content"
      assert html =~ "Footer content"
    end
  end

  describe "card/1 without optional slots" do
    test "renders without header" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Just content</:content>
        </Card.card>
        """)

      refute html =~ "<header"
      assert html =~ "Just content"
    end

    test "renders without footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Just content</:content>
        </Card.card>
        """)

      refute html =~ "<footer"
      assert html =~ "Just content"
    end
  end

  describe "card/1 custom classes" do
    test "includes custom class on card" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card class="my-card">
          <:content>Content</:content>
        </Card.card>
        """)

      assert html =~ "my-card"
    end

    test "includes custom class on header" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:header class="custom-header">Header</:header>
          <:content>Content</:content>
        </Card.card>
        """)

      assert html =~ "custom-header"
    end

    test "includes custom class on content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content class="custom-content">Content</:content>
        </Card.card>
        """)

      assert html =~ "custom-content"
    end

    test "includes custom class on footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card>
          <:content>Content</:content>
          <:footer class="custom-footer">Footer</:footer>
        </Card.card>
        """)

      assert html =~ "custom-footer"
    end
  end

  describe "card/1 with id" do
    test "accepts id attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Card.card id="my-card">
          <:content>Content</:content>
        </Card.card>
        """)

      assert html =~ ~s(id="my-card")
    end
  end
end
