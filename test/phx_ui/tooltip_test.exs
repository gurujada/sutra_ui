defmodule PhxUI.TooltipTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias PhxUI.Tooltip

  describe "tooltip/1 rendering" do
    test "renders as span element with data-tooltip attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Hello">
          <button>Hover me</button>
        </Tooltip.tooltip>
        """)

      assert html =~ "<span"
      assert html =~ ~s(data-tooltip="Hello")
      assert html =~ "<button>Hover me</button>"
    end

    test "renders inner content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Info">
          <span class="custom-trigger">Custom content</span>
        </Tooltip.tooltip>
        """)

      assert html =~ "custom-trigger"
      assert html =~ "Custom content"
    end
  end

  describe "tooltip/1 sides" do
    test "accepts all valid sides" do
      for side <- ~w(top bottom left right) do
        assigns = %{side: side}

        html =
          rendered_to_string(~H"""
          <Tooltip.tooltip id="test-tooltip" tooltip="Test" side={@side}>
            <button>Hover</button>
          </Tooltip.tooltip>
          """)

        assert html =~ ~s(data-side="#{side}")
      end
    end

    test "defaults to auto side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Test">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-side="auto")
    end
  end

  describe "tooltip/1 alignment" do
    test "accepts all valid alignments" do
      for align <- ~w(start center end) do
        assigns = %{align: align}

        html =
          rendered_to_string(~H"""
          <Tooltip.tooltip id="test-tooltip" tooltip="Test" align={@align}>
            <button>Hover</button>
          </Tooltip.tooltip>
          """)

        assert html =~ ~s(data-align="#{align}")
      end
    end

    test "defaults to center alignment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Test">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-align="center")
    end
  end

  describe "tooltip/1 custom class" do
    test "includes custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Test" class="my-tooltip-class">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ "my-tooltip-class"
    end
  end

  describe "tooltip/1 accessibility" do
    test "passes through id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip tooltip="Test" id="my-tooltip">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(id="my-tooltip")
    end
  end

  describe "tooltip/1 positioning combinations" do
    test "renders with bottom-start positioning" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Bottom start" side="bottom" align="start">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="start")
    end

    test "renders with left-end positioning" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Tooltip.tooltip id="test-tooltip" tooltip="Left end" side="left" align="end">
          <button>Hover</button>
        </Tooltip.tooltip>
        """)

      assert html =~ ~s(data-side="left")
      assert html =~ ~s(data-align="end")
    end
  end
end
