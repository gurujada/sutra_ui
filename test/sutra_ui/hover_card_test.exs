defmodule SutraUI.HoverCardTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias SutraUI.HoverCard

  describe "hover_card/1" do
    test "renders root structure" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<HoverCard.hover_card id="hc"><:trigger>Hover</:trigger>Content here</HoverCard.hover_card>|
        )

      assert html =~ "hover-card"
      assert html =~ "Hover"
      assert html =~ "Content here"
    end

    test "renders content in a div" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<HoverCard.hover_card id="hc"><:trigger>Hover</:trigger>Content</HoverCard.hover_card>|
        )

      assert html =~ "hover-card-content"
      assert html =~ ~s(role="tooltip")
    end

    test "renders with custom side" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<HoverCard.hover_card id="hc" side="top"><:trigger>Hover</:trigger>Content</HoverCard.hover_card>|
        )

      assert html =~ ~s(data-side="top")
    end

    test "renders trigger aria attributes" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<HoverCard.hover_card id="hc"><:trigger>Hover me</:trigger>Content</HoverCard.hover_card>|
        )

      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-describedby)
    end

    test "renders hook" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<HoverCard.hover_card id="hc"><:trigger>Hover</:trigger>Content</HoverCard.hover_card>|
        )

      assert html =~ ".HoverCard"
    end
  end
end
