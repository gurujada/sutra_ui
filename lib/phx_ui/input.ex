defmodule PhxUI.Input do
  @moduledoc """
  Displays a form input field.

  ## Examples

      # Basic text input
      <.input type="text" name="username" placeholder="Username" />

      # Email input with form field
      <.input field={@form[:email]} type="email" />

      # Password input with required attribute
      <.input type="password" name="password" placeholder="Password" required />

      # Number input with min/max constraints
      <.input type="number" name="age" min="0" max="120" />

      # Search input with autocomplete disabled
      <.input type="search" name="query" placeholder="Search..." autocomplete="off" />

      # Input with ARIA attributes for accessibility
      <.input
        type="text"
        name="phone"
        aria-label="Phone number"
        aria-describedby="phone-help"
      />

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

  attr(:field, FormField, default: nil, doc: "A form field struct retrieved from the form")
  attr(:id, :string, default: nil, doc: "The id attribute for the input")
  attr(:type, :string, default: "text", doc: "The type of input field")
  attr(:name, :string, default: nil, doc: "The name attribute for the input")
  attr(:value, :any, default: nil, doc: "The value of the input")
  attr(:placeholder, :string, default: nil, doc: "Placeholder text")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(disabled required autocomplete autofocus readonly min max step pattern
                minlength maxlength size multiple accept capture
                aria-label aria-describedby aria-invalid aria-required),
    doc: "Additional HTML attributes including ARIA"
  )

  def input(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns[:id] || field.id)
    |> assign(:name, assigns[:name] || field.name)
    |> assign(:value, assigns[:value] || field.value)
    |> input_impl()
  end

  def input(assigns) do
    input_impl(assigns)
  end

  defp input_impl(assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      class={["input", @class]}
      {@rest}
    />
    """
  end
end
