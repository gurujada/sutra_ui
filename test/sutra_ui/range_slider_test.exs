defmodule SutraUI.RangeSliderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import SutraUI.RangeSlider

  describe "range_slider/1" do
    test "renders with required name attribute" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      assert html =~ ~s(class="range-slider)
      # phoenix_colocated transforms .RangeSlider to full module path
      assert html =~ ~s(phx-hook="SutraUI.RangeSlider.RangeSlider")
      assert html =~ ~s(data-min="0.0")
      assert html =~ ~s(data-max="100.0")
      assert html =~ ~s(name="price_min")
      assert html =~ ~s(name="price_max")
    end

    test "renders with custom min and max values" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 100,
          max: 1000
        })

      assert html =~ ~s(data-min="100.0")
      assert html =~ ~s(data-max="1.0e3")
      assert html =~ ~s(aria-valuemin="100.0")
      assert html =~ ~s(aria-valuemax="1.0e3")
    end

    test "renders with custom value_min and value_max (integers)" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          value_min: 20,
          value_max: 80
        })

      # With integer step, values are emitted as integers
      assert html =~ ~s(data-value-min="20")
      assert html =~ ~s(data-value-max="80")
      assert html =~ ~s(aria-valuenow="20")
      assert html =~ ~s(aria-valuenow="80")
      assert html =~ ~s(value="20")
      assert html =~ ~s(value="80")
    end

    test "renders with float step and values" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 5,
          step: 0.5,
          value_min: 1.5,
          value_max: 4.0
        })

      # With float step, values are emitted as floats
      assert html =~ ~s(data-step="0.5")
      assert html =~ ~s(data-precision="1")
      assert html =~ ~s(data-value-min="1.5")
      assert html =~ ~s(data-value-max="4.0")
    end

    test "renders with high precision float step" do
      html =
        render_component(&range_slider/1, %{
          name: "weight",
          min: 0,
          max: 10,
          step: 0.01,
          value_min: 2.55,
          value_max: 7.75
        })

      assert html =~ ~s(data-step="0.01")
      assert html =~ ~s(data-precision="2")
      assert html =~ ~s(data-value-min="2.55")
      assert html =~ ~s(data-value-max="7.75")
    end

    test "renders with custom step (integer)" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          step: 10
        })

      assert html =~ ~s(data-step="10.0")
      assert html =~ ~s(data-precision="0")
    end

    test "renders with tooltips when enabled" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          tooltips: true,
          value_min: 25,
          value_max: 75
        })

      assert html =~ "data-tooltips"
      assert html =~ ~s(class="range-slider-tooltip")
      assert html =~ "25"
      assert html =~ "75"
    end

    test "does not render tooltips by default" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      refute html =~ ~s(class="range-slider-tooltip")
    end

    test "renders disabled state" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          disabled: true
        })

      assert html =~ ~s(range-slider-disabled)
      assert html =~ "data-disabled"
      assert html =~ ~s(tabindex="-1")
    end

    test "renders with custom id" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          id: "my-custom-slider"
        })

      assert html =~ ~s(id="my-custom-slider")
    end

    test "renders default id based on name" do
      html =
        render_component(&range_slider/1, %{
          name: "price_range"
        })

      assert html =~ ~s(id="range-slider-price_range")
    end

    test "renders two thumbs with correct roles" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      assert html =~ ~s(role="slider")
      assert html =~ ~s(aria-label="Minimum value")
      assert html =~ ~s(aria-label="Maximum value")
      assert html =~ ~s(data-index="0")
      assert html =~ ~s(data-index="1")
    end

    test "renders hidden inputs for form submission" do
      html =
        render_component(&range_slider/1, %{
          name: "budget",
          min: 0,
          max: 1000,
          value_min: 100,
          value_max: 500
        })

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="budget_min")
      assert html =~ ~s(name="budget_max")
      assert html =~ ~s(value="100")
      assert html =~ ~s(value="500")
    end

    test "renders track and range elements" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      assert html =~ ~s(class="range-slider-track")
      assert html =~ ~s(class="range-slider-range")
    end

    test "applies custom class" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          class: "my-custom-class"
        })

      assert html =~ "my-custom-class"
    end

    test "renders with on_slide attribute" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          on_slide: "price_sliding"
        })

      assert html =~ ~s(data-on-slide="price_sliding")
    end

    test "renders with on_change attribute" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          on_change: "price_changed"
        })

      assert html =~ ~s(data-on-change="price_changed")
    end

    test "renders with custom debounce" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          debounce: 100
        })

      assert html =~ ~s(data-debounce="100")
    end

    test "renders data-name attribute" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      assert html =~ ~s(data-name="price")
    end

    test "calculates default values when not provided" do
      # Default is 25% and 75% of range
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100
        })

      # 25% of 0-100 = 25, 75% of 0-100 = 75
      assert html =~ ~s(data-value-min="25")
      assert html =~ ~s(data-value-max="75")
    end

    test "ensures value_min does not exceed value_max" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          value_min: 80,
          value_max: 50
        })

      # Should clamp value_min to value_max
      assert html =~ ~s(data-value-min="50")
      assert html =~ ~s(data-value-max="50")
    end

    test "calculates correct percentages for positioning" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          value_min: 20,
          value_max: 80
        })

      # 20% and 80% positioning
      assert html =~ ~s(left: 20.0%)
      assert html =~ ~s(left: 80.0%)
      assert html =~ ~s(width: 60.0%)
    end

    test "thumbs are focusable when not disabled" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          disabled: false
        })

      assert html =~ ~s(tabindex="0")
    end

    test "includes colocated JavaScript hook" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      # phoenix_colocated extracts the script to a separate JS file
      # The hook name in phx-hook confirms colocated hooks are set up
      assert html =~ ~s(phx-hook="SutraUI.RangeSlider.RangeSlider")
      # The actual JS code is extracted by phoenix_colocated during compilation
    end

    test "snaps values to step" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          step: 10,
          value_min: 23,
          value_max: 77
        })

      # 23 snaps to 20, 77 snaps to 80
      assert html =~ ~s(data-value-min="20")
      assert html =~ ~s(data-value-max="80")
    end

    test "snaps float values to float step" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 5,
          step: 0.5,
          value_min: 1.3,
          value_max: 3.7
        })

      # 1.3 snaps to 1.5, 3.7 snaps to 3.5
      assert html =~ ~s(data-value-min="1.5")
      assert html =~ ~s(data-value-max="3.5")
    end
  end
end
