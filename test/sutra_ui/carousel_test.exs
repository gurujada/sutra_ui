defmodule SutraUI.CarouselTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias SutraUI.Carousel

  describe "carousel/1 rendering" do
    test "renders with correct structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Slide 1</:item>
          <:item>Slide 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(id="test-carousel")
      assert html =~ "carousel"
      assert html =~ "Slide 1"
      assert html =~ "Slide 2"
    end

    test "renders viewport container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Slide 1</:item>
        </Carousel.carousel>
        """)

      assert html =~ "carousel-viewport"
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="Carousel")
    end

    test "renders each item with correct classes and attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ "carousel-item"
      assert html =~ ~s(id="test-carousel-item-0")
      assert html =~ ~s(id="test-carousel-item-1")
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-roledescription="slide")
    end

    test "renders correct aria-label for slides" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
          <:item>Item 3</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(aria-label="Slide 1 of 3")
      assert html =~ ~s(aria-label="Slide 2 of 3")
      assert html =~ ~s(aria-label="Slide 3 of 3")
    end
  end

  describe "carousel/1 indicators" do
    test "renders indicators by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ "carousel-indicators"
      assert html =~ "carousel-indicator"
    end

    test "hides indicators when show_indicators is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel" show_indicators={false}>
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      refute html =~ "carousel-indicators"
    end

    test "does not show indicators for single item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Only one item</:item>
        </Carousel.carousel>
        """)

      refute html =~ "carousel-indicators"
    end

    test "renders correct number of indicator buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
          <:item>Item 3</:item>
        </Carousel.carousel>
        """)

      # Count indicator buttons by their data-carousel-indicator attribute
      indicator_count = Regex.scan(~r/data-carousel-indicator="/, html) |> length()
      assert indicator_count == 3
    end

    test "first indicator is active by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ "carousel-indicator-active"
    end

    test "indicators have role=tab" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(role="tab")
      assert html =~ ~s(role="tablist")
    end

    test "indicators have aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(aria-label="Go to slide 1")
      assert html =~ ~s(aria-label="Go to slide 2")
    end
  end

  describe "carousel/1 custom class" do
    test "includes custom class on container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel" class="my-carousel-class">
          <:item>Item</:item>
        </Carousel.carousel>
        """)

      assert html =~ "my-carousel-class"
    end

    test "includes item_class on each item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel" item_class="custom-item-class">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      # Should appear twice (once per item)
      assert String.contains?(html, "custom-item-class")
    end

    test "includes per-item class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item class="specific-class">Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ "specific-class"
    end
  end

  describe "carousel/1 gap" do
    test "applies gap style when specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel" gap="1rem">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ "gap: 1rem"
    end

    test "no gap style when not specified" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
        </Carousel.carousel>
        """)

      refute html =~ "gap:"
    end
  end

  describe "carousel/1 accessibility" do
    test "viewport has tabindex for keyboard focus" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(tabindex="0")
    end

    test "viewport has aria-roledescription" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(aria-roledescription="carousel")
    end

    test "indicators use buttons for navigation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item 1</:item>
          <:item>Item 2</:item>
        </Carousel.carousel>
        """)

      assert html =~ ~s(data-carousel-indicator="0")
      assert html =~ ~s(data-carousel-indicator="1")
    end
  end

  describe "carousel/1 phx-hook" do
    test "has phx-hook for carousel behavior" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Carousel.carousel id="test-carousel">
          <:item>Item</:item>
        </Carousel.carousel>
        """)

      assert html =~ "phx-hook"
    end
  end
end
