defmodule SutraUI.Label do
  @moduledoc """
  Renders an accessible label for form controls.

  Labels are essential for form accessibility, providing a text description
  that is programmatically associated with form controls. When properly linked
  via the `for` attribute, clicking the label will focus the associated input.

  ## Examples

      # Basic label with for attribute
      <.label for="email">Email address</.label>
      <.input id="email" name="email" type="email" />

      # Label with custom styling
      <.label for="terms" class="font-bold">Accept Terms</.label>

      # Required field indicator (styled via CSS)
      <.label for="name" class="required">Full Name</.label>

      # Label with additional attributes
      <.label for="phone" id="phone-label">Phone Number</.label>

  ## Accessibility

  - Always use the `for` attribute to associate labels with their form controls
  - The `for` value must match the `id` of the associated input element
  - Clicking a properly associated label will focus/activate its form control
  - Screen readers announce the label text when the user focuses the input
  - Avoid using placeholder text as a substitute for labels
  - For required fields, consider adding visual indicators and `aria-required`
    on the input rather than relying solely on the label text
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
