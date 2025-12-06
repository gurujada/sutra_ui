defmodule PhxUI.Checkbox do
  @moduledoc """
  A control that allows the user to toggle between checked and not checked.

  ## Accessibility

  - Uses semantic `<input type="checkbox">` element
  - Supports `aria-invalid` for error states
  - Supports `aria-describedby` for helper text and errors
  - Properly associates with labels via `id` and `for` attributes
  - Respects `disabled` and `required` states
  - Keyboard accessible (Space to toggle)
  """

  use Phoenix.Component

  @doc """
  Renders a checkbox input element.

  ## Examples

      <.checkbox name="terms" value="accepted" />
      <.checkbox name="terms" value="accepted" checked />
      <.checkbox name="terms" value="accepted" disabled />
  """

  attr(:name, :string, required: true, doc: "The name attribute for the checkbox input")
  attr(:value, :string, default: "true", doc: "The value attribute for the checkbox input")
  attr(:checked, :boolean, default: false, doc: "Whether the checkbox is checked")
  attr(:disabled, :boolean, default: false, doc: "Whether the checkbox is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id form required aria-invalid aria-describedby aria-required),
    doc: "Additional HTML attributes including ARIA"
  )

  def checkbox(assigns) do
    ~H"""
    <input
      type="checkbox"
      name={@name}
      value={@value}
      checked={@checked}
      disabled={@disabled}
      class={["input", @class]}
      {@rest}
    />
    """
  end
end
