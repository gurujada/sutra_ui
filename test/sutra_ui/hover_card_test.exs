defmodule SutraUI.HoverCardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.HoverCard

  test "renders trigger and hidden content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <HoverCard.hover_card id="user-card">
        <:trigger><button>Hover</button></:trigger>
        User details
      </HoverCard.hover_card>
      """)

    assert html =~ ~s(id="user-card")
    assert html =~ ~s(phx-hook="SutraUI.HoverCard.HoverCard")
    assert html =~ ~s(aria-describedby="user-card-content")
    assert html =~ ~s(role="tooltip")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ "User details"
  end
end
