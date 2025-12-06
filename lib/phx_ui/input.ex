defmodule PhxUI.Input do
  @moduledoc """
  Displays a form input field.

  ## Accessibility

  - `aria-label` - Label for the input when no visible label is present
  - `aria-describedby` - References helper text or error messages
  - `aria-invalid` - Indicates validation state
  - `aria-required` - Indicates if the field is required
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField

  @doc """
  Renders an input component.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input type="email" name="email" placeholder="Email" />
      <.input type="password" name="password" placeholder="Password" required />
  """

  attr(:field, FormField, doc: "A form field struct retrieved from the form")
  attr(:type, :string, default: "text", doc: "The type of input field")
  attr(:name, :string, default: nil, doc: "The name attribute for the input")
  attr(:value, :string, default: nil, doc: "The value of the input")
  attr(:placeholder, :string, default: nil, doc: "Placeholder text")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id disabled required autocomplete autofocus readonly min max step pattern
                minlength maxlength size multiple accept capture
                aria-label aria-describedby aria-invalid aria-required),
    doc: "Additional HTML attributes including ARIA"
  )

  def input(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns[:id] || field.id)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input_impl()
  end

  def input(assigns) do
    input_impl(assigns)
  end

  defp input_impl(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      class={["input", @class]}
      {@rest}
    />
    """
  end
end
