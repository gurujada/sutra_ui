defmodule PhxUI.Kbd do
  @moduledoc """
  Displays keyboard input that triggers an action.
  """

  use Phoenix.Component

  @doc """
  Renders a keyboard key indicator.

  ## Examples

      <.kbd>Ctrl</.kbd>
      <.kbd>K</.kbd>
  """

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")
  slot(:inner_block, required: true, doc: "The key content")

  def kbd(assigns) do
    ~H"""
    <kbd class={["kbd", @class]} {@rest}>
      {render_slot(@inner_block)}
    </kbd>
    """
  end
end
