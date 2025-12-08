defmodule SutraUI.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Accordion

  describe "accordion/1 rendering" do
    test "renders accordion container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Section 1" value="item-1">Content 1</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(class="accordion)
    end

    test "renders multiple items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Section 1" value="item-1">Content 1</:item>
          <:item title="Section 2" value="item-2">Content 2</:item>
          <:item title="Section 3" value="item-3">Content 3</:item>
        </Accordion.accordion>
        """)

      assert html =~ "Section 1"
      assert html =~ "Section 2"
      assert html =~ "Section 3"
      assert html =~ "Content 1"
      assert html =~ "Content 2"
      assert html =~ "Content 3"
    end

    test "renders item with proper structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Test Title" value="test-item">Test Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "accordion-item"
      assert html =~ "accordion-header"
      assert html =~ "accordion-trigger"
      assert html =~ "accordion-content"
      assert html =~ "Test Title"
      assert html =~ "Test Content"
    end
  end

  describe "accordion/1 type attribute" do
    test "defaults to single type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(data-type="single")
    end

    test "accepts multiple type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion type="multiple">
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(data-type="multiple")
    end
  end

  describe "accordion/1 default_value" do
    test "opens item by default when default_value matches" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion default_value="item-1">
          <:item title="Item 1" value="item-1">Content 1</:item>
          <:item title="Item 2" value="item-2">Content 2</:item>
        </Accordion.accordion>
        """)

      # Check the first item is open
      assert html =~ ~s(data-state="open")
      assert html =~ ~s(aria-expanded="true")
    end

    test "keeps items closed when no default_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item 1" value="item-1">Content 1</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(aria-expanded="false")
    end

    test "accepts list of default values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion type="multiple" default_value={["item-1", "item-2"]}>
          <:item title="Item 1" value="item-1">Content 1</:item>
          <:item title="Item 2" value="item-2">Content 2</:item>
          <:item title="Item 3" value="item-3">Content 3</:item>
        </Accordion.accordion>
        """)

      # Both item-1 and item-2 should be open
      assert String.contains?(html, ~s(data-state="open"))
    end
  end

  describe "accordion/1 disabled items" do
    test "renders disabled item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Disabled Item" value="disabled" disabled={true}>Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "accordion-disabled"
      assert html =~ "disabled"
    end
  end

  describe "accordion/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion class="my-accordion">
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "my-accordion"
    end
  end

  describe "accordion/1 accessibility" do
    test "renders trigger as button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "<button"
      assert html =~ ~s(type="button")
    end

    test "has aria-expanded attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "aria-expanded"
    end

    test "has aria-controls linking to content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="test-item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(aria-controls="accordion-content-test-item")
      assert html =~ ~s(id="accordion-content-test-item")
    end

    test "content has role=region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ ~s(role="region")
    end

    test "renders chevron icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Accordion.accordion>
          <:item title="Item" value="item">Content</:item>
        </Accordion.accordion>
        """)

      assert html =~ "accordion-chevron"
      assert html =~ "hero-chevron-down"
    end
  end
end
