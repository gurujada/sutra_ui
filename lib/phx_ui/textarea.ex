defmodule PhxUI.Textarea do
  @moduledoc """
  Displays a multi-line text input field.

  ## Accessibility

  - `aria-label` - Label for the textarea when no visible label is present
  - `aria-describedby` - References helper text or error messages
  - `aria-invalid` - Indicates validation state
  """

  use Phoenix.Component

  @doc """
  Renders a textarea component.

  ## Examples

      <.textarea name="bio" placeholder="Tell us about yourself" />
      <.textarea name="bio" rows={6} />
      <.textarea name="bio" disabled />
  """

  attr(:name, :string, default: nil, doc: "The name attribute")
  attr(:value, :string, default: nil, doc: "The value")
  attr(:placeholder, :string, default: nil, doc: "Placeholder text")
  attr(:rows, :integer, default: 3, doc: "Number of visible text lines")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id disabled required readonly autofocus minlength maxlength
                aria-label aria-describedby aria-invalid),
    doc: "Additional HTML attributes"
  )

  def textarea(assigns) do
    ~H"""
    <textarea
      name={@name}
      placeholder={@placeholder}
      rows={@rows}
      class={["textarea", @class]}
      {@rest}
    >{@value}</textarea>
    """
  end
end
