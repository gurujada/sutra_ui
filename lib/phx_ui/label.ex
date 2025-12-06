defmodule PhxUI.Label do
  @moduledoc """
  Renders an accessible label for form controls.
  """

  use Phoenix.Component

  @doc """
  Renders a label element.

  ## Examples

      <.label for="email">Email address</.label>
      <.label for="terms" class="font-bold">Terms</.label>
  """

  attr(:for, :string, default: nil, doc: "The id of the form element this label is for")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")
  slot(:inner_block, required: true, doc: "The label content")

  def label(assigns) do
    ~H"""
    <label for={@for} class={["label", @class]} {@rest}>
      {render_slot(@inner_block)}
    </label>
    """
  end
end
