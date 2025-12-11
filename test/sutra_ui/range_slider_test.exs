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
      # Integer step (default) emits integers
      assert html =~ ~s(data-min="0")
      assert html =~ ~s(data-max="100")
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

      # Integer step (default) emits integers
      assert html =~ ~s(data-min="100")
      assert html =~ ~s(data-max="1000")
      assert html =~ ~s(aria-valuemin="100")
      assert html =~ ~s(aria-valuemax="1000")
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
      assert html =~ ~s(data-float-mode)
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
      assert html =~ ~s(data-float-mode)
      # Float mode preserves float values (may have floating point representation)
      assert html =~ "data-value-min=\"2.55"
      assert html =~ ~s(data-value-max="7.75")
    end

    test "renders with custom step (integer)" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          step: 10
        })

      # Integer step emits integers
      assert html =~ ~s(data-step="10")
      # No data-float-mode attribute when in integer mode
      refute html =~ ~s(data-float-mode)
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

    test "renders pips with default positions when pips is true" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          pips: true
        })

      assert html =~ ~s(class="range-slider-pips")
      assert html =~ ~s(class="range-slider-pip range-slider-pip-large")
      # Default positions: 0, 25, 50, 75, 100
      assert html =~ ~s(left: 0%)
      assert html =~ ~s(left: 25%)
      assert html =~ ~s(left: 50%)
      assert html =~ ~s(left: 75%)
      assert html =~ ~s(left: 100%)
      # Labels for values
      assert html =~ ~s(class="range-slider-pip-label")
      assert html =~ ">0<"
      assert html =~ ">25<"
      assert html =~ ">50<"
      assert html =~ ">75<"
      assert html =~ ">100<"
    end

    test "renders pips with custom positions" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 1000,
          pips: %{mode: :positions, values: [0, 50, 100]}
        })

      assert html =~ ~s(class="range-slider-pips")
      assert html =~ ~s(left: 0%)
      assert html =~ ~s(left: 50%)
      assert html =~ ~s(left: 100%)
      assert html =~ ">0<"
      assert html =~ ">500<"
      assert html =~ ">1000<"
    end

    test "renders pips with count mode" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          pips: %{mode: :count, count: 3}
        })

      assert html =~ ~s(class="range-slider-pips")
      # 3 pips at 0%, 50%, 100%
      assert html =~ ~s(left: 0.0%)
      assert html =~ ~s(left: 50.0%)
      assert html =~ ~s(left: 100.0%)
    end

    test "renders pips with values mode" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          pips: %{mode: :values, values: [10, 30, 90]}
        })

      assert html =~ ~s(class="range-slider-pips")
      assert html =~ ~s(left: 10.0%)
      assert html =~ ~s(left: 30.0%)
      assert html =~ ~s(left: 90.0%)
      assert html =~ ">10<"
      assert html =~ ">30<"
      assert html =~ ">90<"
    end

    test "renders pips with steps mode" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 10,
          step: 2,
          pips: %{mode: :steps}
        })

      assert html =~ ~s(class="range-slider-pips")
      # Steps at 0, 2, 4, 6, 8, 10
      assert html =~ ~s(left: 0.0%)
      assert html =~ ~s(left: 20.0%)
      assert html =~ ~s(left: 40.0%)
      assert html =~ ~s(left: 60.0%)
      assert html =~ ~s(left: 80.0%)
      assert html =~ ~s(left: 100.0%)
    end

    test "does not render pips when pips is nil" do
      html =
        render_component(&range_slider/1, %{
          name: "price"
        })

      refute html =~ ~s(class="range-slider-pips")
    end

    test "pips respect float precision" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 5,
          step: 0.5,
          pips: %{mode: :values, values: [0.5, 2.5, 4.5]}
        })

      assert html =~ ">0.5<"
      assert html =~ ">2.5<"
      assert html =~ ">4.5<"
    end
  end

  describe "integer vs float mode" do
    test "integer step emits integer values in data attributes" do
      html =
        render_component(&range_slider/1, %{
          name: "quantity",
          min: 0,
          max: 100,
          step: 1,
          value_min: 25,
          value_max: 75
        })

      # All values should be integers (no decimal point)
      assert html =~ ~s(data-min="0")
      assert html =~ ~s(data-max="100")
      assert html =~ ~s(data-step="1")
      assert html =~ ~s(data-value-min="25")
      assert html =~ ~s(data-value-max="75")
      assert html =~ ~s(value="25")
      assert html =~ ~s(value="75")
      # No float-mode attribute in integer mode
      refute html =~ ~s(data-float-mode)
    end

    test "integer step with larger increment emits integers" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 1000,
          step: 50,
          value_min: 200,
          value_max: 800
        })

      assert html =~ ~s(data-step="50")
      assert html =~ ~s(data-value-min="200")
      assert html =~ ~s(data-value-max="800")
      refute html =~ ~s(data-float-mode)
    end

    test "float step emits float values in data attributes" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 5,
          step: 0.5,
          value_min: 1.5,
          value_max: 4.0
        })

      # All values should be floats
      assert html =~ ~s(data-min="0.0")
      assert html =~ ~s(data-max="5.0")
      assert html =~ ~s(data-step="0.5")
      assert html =~ ~s(data-value-min="1.5")
      assert html =~ ~s(data-value-max="4.0")
      assert html =~ ~s(value="1.5")
      assert html =~ ~s(value="4.0")
      # Float-mode attribute present
      assert html =~ ~s(data-float-mode)
    end

    test "float step 1.0 emits floats (for whole number float increments)" do
      html =
        render_component(&range_slider/1, %{
          name: "score",
          min: 0,
          max: 10,
          step: 1.0,
          value_min: 3.0,
          value_max: 7.0
        })

      # Even with whole numbers, float step means float output
      assert html =~ ~s(data-min="0.0")
      assert html =~ ~s(data-max="10.0")
      assert html =~ ~s(data-step="1.0")
      assert html =~ ~s(data-value-min="3.0")
      assert html =~ ~s(data-value-max="7.0")
      assert html =~ ~s(data-float-mode)
    end

    test "integer step converts float inputs to integers" do
      html =
        render_component(&range_slider/1, %{
          name: "count",
          min: 0,
          max: 100,
          step: 1,
          value_min: 25.7,
          value_max: 74.3
        })

      # Float inputs are truncated to integers, then snapped to step
      # 25.7 truncates to 25, 74.3 truncates to 74
      assert html =~ ~s(data-value-min="25")
      assert html =~ ~s(data-value-max="74")
      assert html =~ ~s(value="25")
      assert html =~ ~s(value="74")
    end

    test "float step converts integer inputs to floats" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 10,
          step: 0.5,
          value_min: 3,
          value_max: 7
        })

      # Integer inputs should be converted to floats
      assert html =~ ~s(data-value-min="3.0")
      assert html =~ ~s(data-value-max="7.0")
      assert html =~ ~s(value="3.0")
      assert html =~ ~s(value="7.0")
    end

    test "default step (1) uses integer mode" do
      html =
        render_component(&range_slider/1, %{
          name: "default"
        })

      # Default step is 1 (integer), so integer mode
      assert html =~ ~s(data-step="1")
      refute html =~ ~s(data-float-mode)
      assert html =~ ~s(data-value-min="25")
      assert html =~ ~s(data-value-max="75")
    end

    test "hidden input values match the type mode" do
      # Integer mode
      html_int =
        render_component(&range_slider/1, %{
          name: "int_field",
          step: 5,
          value_min: 20,
          value_max: 80
        })

      assert html_int =~ ~s(name="int_field_min" value="20")
      assert html_int =~ ~s(name="int_field_max" value="80")

      # Float mode
      html_float =
        render_component(&range_slider/1, %{
          name: "float_field",
          step: 0.1,
          value_min: 2.5,
          value_max: 7.5
        })

      assert html_float =~ ~s(name="float_field_min" value="2.5")
      assert html_float =~ ~s(name="float_field_max" value="7.5")
    end

    test "aria-valuenow matches the type mode" do
      # Integer mode
      html_int =
        render_component(&range_slider/1, %{
          name: "int_slider",
          step: 1,
          value_min: 30,
          value_max: 70
        })

      assert html_int =~ ~s(aria-valuenow="30")
      assert html_int =~ ~s(aria-valuenow="70")

      # Float mode
      html_float =
        render_component(&range_slider/1, %{
          name: "float_slider",
          step: 0.5,
          value_min: 1.5,
          value_max: 4.5
        })

      assert html_float =~ ~s(aria-valuenow="1.5")
      assert html_float =~ ~s(aria-valuenow="4.5")
    end

    test "pips labels use integer format in integer mode" do
      html =
        render_component(&range_slider/1, %{
          name: "price",
          min: 0,
          max: 100,
          step: 1,
          pips: true
        })

      # Pip labels should be integers
      assert html =~ ">0<"
      assert html =~ ">25<"
      assert html =~ ">50<"
      assert html =~ ">75<"
      assert html =~ ">100<"
    end

    test "pips labels use float format in float mode" do
      html =
        render_component(&range_slider/1, %{
          name: "rating",
          min: 0,
          max: 5,
          step: 0.5,
          pips: %{mode: :positions, values: [0, 50, 100]}
        })

      # Pip labels should be floats
      assert html =~ ">0.0<"
      assert html =~ ">2.5<"
      assert html =~ ">5.0<"
    end
  end
end
