defmodule SutraUI.ItemTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Item

  describe "item/1 rendering" do
    test "renders as article by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Test Item</:title>
        </Item.item>
        """)

      assert html =~ "<article"
      assert html =~ "item"
      assert html =~ "Test Item"
    end

    test "renders title slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>My Title</:title>
        </Item.item>
        """)

      assert html =~ "item-title"
      assert html =~ "My Title"
    end

    test "renders description slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title</:title>
          <:description>My description text</:description>
        </Item.item>
        """)

      assert html =~ "item-description"
      assert html =~ "My description text"
    end

    test "renders leading slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:leading>
            <span class="icon">star</span>
          </:leading>
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "item-leading"
      assert html =~ "star"
    end

    test "renders trailing slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title</:title>
          <:trailing>
            <button>Action</button>
          </:trailing>
        </Item.item>
        """)

      assert html =~ "item-trailing"
      assert html =~ "Action"
    end
  end

  describe "item/1 variants" do
    test "renders default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item variant="default">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "item-default"
    end

    test "renders outline variant (default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "item-outline"
    end

    test "renders muted variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item variant="muted">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "item-muted"
    end
  end

  describe "item/1 element types" do
    test "renders as article by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "<article"
    end

    test "renders as anchor when as='a'" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item as="a" href="/test">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="/test")
    end

    test "renders as div when as='div'" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item as="div">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "<div"
    end

    test "renders as button when as='button'" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item as="button">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "<button"
    end
  end

  describe "item/1 compact mode" do
    test "applies compact class when only title is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title Only</:title>
        </Item.item>
        """)

      assert html =~ "item-compact"
    end

    test "does not apply compact class when description is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item>
          <:title>Title</:title>
          <:description>Description</:description>
        </Item.item>
        """)

      refute html =~ "item-compact"
    end
  end

  describe "item/1 custom classes" do
    test "accepts custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Item.item class="my-custom-class">
          <:title>Title</:title>
        </Item.item>
        """)

      assert html =~ "item"
      assert html =~ "my-custom-class"
    end
  end
end
