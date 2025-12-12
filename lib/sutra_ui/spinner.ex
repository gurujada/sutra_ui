defmodule SutraUI.Spinner do
  @moduledoc """
  A loading indicator component.

  The spinner provides visual feedback for loading states. It includes proper
  accessibility attributes for screen readers.

  ## Sizes

  - `sm` - Small (12px)
  - `default` - Default (16px)
  - `lg` - Large (24px)
  - `xl` - Extra large (32px)

  ## Accessibility

  The component includes proper ARIA attributes:
  - `role="status"` indicates a live region
  - `aria-label` provides screen reader description
  - Visually hidden text for screen readers when no text slot is provided

  ## Examples

      # Basic spinner
      <.spinner />

      # With custom label
      <.spinner label="Processing..." />

      # Different sizes
      <.spinner size="sm" />
      <.spinner size="lg" />

      # With visible text
      <.spinner>
        <:text>Loading data...</:text>
      </.spinner>

      # In a button
      <.button disabled>
        <.spinner size="sm" />
        Processing...
      </.button>
  """

  use Phoenix.Component

  import SutraUI.Icon

  @doc """
  Renders a spinner component.

  ## Attributes

  * `size` - Size variant. One of `sm`, `default`, `lg`, `xl`. Defaults to `default`.
  * `label` - Accessibility label for screen readers. Defaults to `"Loading"`.
  * `class` - Additional CSS classes.

  ## Slots

  * `text` - Optional visible text to display next to the spinner.
  """
  attr(:size, :string,
    default: "default",
    values: ~w(sm default lg xl),
    doc: "Size variant"
  )

  attr(:label, :string,
    default: "Loading",
    doc: "Accessibility label for screen readers"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:text, doc: "Optional visible text to display")

  def spinner(assigns) do
    ~H"""
    <div
      class={["spinner", @class]}
      role="status"
      aria-label={@label}
      {@rest}
    >
      <.icon name="lucide-loader-2" class={["animate-spin", size_class(@size)]} />
      <span :if={@text != []} class="spinner-text">
        {render_slot(@text)}
      </span>
      <span :if={@text == []} class="sr-only">{@label}</span>
    </div>
    """
  end

  @doc """
  Renders just the spinner icon without wrapper.

  Useful in tight spaces like buttons where you need maximum layout control.

  ## Examples

      <.button disabled>
        <.spinner_icon size="sm" />
        Loading...
      </.button>
  """
  attr(:size, :string,
    default: "default",
    values: ~w(sm default lg xl),
    doc: "Size variant"
  )

  attr(:label, :string,
    default: "Loading",
    doc: "Accessibility label for screen readers"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  def spinner_icon(assigns) do
    ~H"""
    <span role="status" aria-label={@label} {@rest}>
      <.icon name="lucide-loader-2" class={["animate-spin", size_class(@size), @class]} />
    </span>
    """
  end

  defp size_class("sm"), do: "size-3"
  defp size_class("default"), do: "size-4"
  defp size_class("lg"), do: "size-6"
  defp size_class("xl"), do: "size-8"
end
