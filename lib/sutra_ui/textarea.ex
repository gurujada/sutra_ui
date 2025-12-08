defmodule SutraUI.Textarea do
  @moduledoc """
  Displays a multi-line text input field.

  ## Examples

      # Basic textarea
      <.textarea name="bio" placeholder="Tell us about yourself" />

      # Textarea with custom rows
      <.textarea name="description" rows={6} />

      # Disabled textarea
      <.textarea name="readonly_content" disabled />

      # Textarea with form field
      <.textarea field={@form[:message]} />

      # Textarea with character limits
      <.textarea name="summary" minlength="10" maxlength="500" />

      # Textarea with ARIA attributes
      <.textarea
        name="feedback"
        aria-label="Your feedback"
        aria-describedby="feedback-help"
      />

  ## Accessibility

  - `aria-label` - Label for the textarea when no visible label is present
  - `aria-describedby` - References helper text or error messages
  - `aria-invalid` - Indicates validation state
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField

  @doc """
  Renders a textarea component.

  ## Examples

      <.textarea name="bio" placeholder="Tell us about yourself" />
      <.textarea name="bio" rows={6} />
      <.textarea name="bio" disabled />
      <.textarea field={@form[:message]} />
  """

  attr(:field, FormField, doc: "A form field struct retrieved from the form")
  attr(:id, :string, default: nil, doc: "The id attribute")
  attr(:name, :string, default: nil, doc: "The name attribute")
  attr(:value, :string, default: nil, doc: "The value")
  attr(:placeholder, :string, default: nil, doc: "Placeholder text")
  attr(:rows, :integer, default: 3, doc: "Number of visible text lines")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(disabled required readonly autofocus minlength maxlength
                aria-label aria-describedby aria-invalid),
    doc: "Additional HTML attributes"
  )

  def textarea(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns[:id] || field.id)
    |> assign(:name, assigns[:name] || field.name)
    |> assign(:value, assigns[:value] || field.value)
    |> textarea_impl()
  end

  def textarea(assigns) do
    textarea_impl(assigns)
  end

  defp textarea_impl(assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      placeholder={@placeholder}
      rows={@rows}
      class={["textarea", @class]}
      {@rest}
    >{@value}</textarea>
    """
  end
end
