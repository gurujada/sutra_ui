defmodule PhxUI.Tooltip do
  @moduledoc """
  A popup that displays information related to an element when hovered.

  This is a CSS-only component that uses data attributes for positioning.
  No JavaScript required.

  ## Examples

      <.tooltip tooltip="Add to library">
        <button class="btn">Hover me</button>
      </.tooltip>

      <.tooltip tooltip="Right side tooltip" side="right">
        <button class="btn">Right</button>
      </.tooltip>

      <.tooltip tooltip="Bottom aligned" side="bottom" align="start">
        <button class="btn">Bottom Start</button>
      </.tooltip>

  ## Accessibility

  The tooltip is triggered by both hover and keyboard focus.
  Note: Critical information should not be placed solely in tooltips.
  """

  use Phoenix.Component

  @doc """
  Renders a tooltip component.
  """
  attr(:tooltip, :string, required: true, doc: "The text content to display in the tooltip")

  attr(:side, :string,
    default: "top",
    values: ~w(top bottom left right),
    doc: "The side to position the tooltip"
  )

  attr(:align, :string,
    default: "center",
    values: ~w(start center end),
    doc: "The alignment of the tooltip"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true, doc: "The element that triggers the tooltip on hover")

  def tooltip(assigns) do
    ~H"""
    <span
      data-tooltip={@tooltip}
      data-side={@side}
      data-align={@align}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
