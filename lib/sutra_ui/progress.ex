defmodule SutraUI.Progress do
  @moduledoc """
  Displays an indicator showing the completion progress of a task.

  The progress bar displays a visual indicator of task completion.
  The value should be between 0 and 100.

  ## Examples

      <.progress value={33} />

      <.progress value={66} size="lg" />

      <.progress value={@upload_progress} aria_label="Upload progress" />

  ## Accessibility

  - Uses `role="progressbar"` for screen readers
  - Includes `aria-valuemin`, `aria-valuemax`, and `aria-valuenow`
  - Optional `aria_label` for additional context
  """

  use Phoenix.Component

  @doc """
  Renders a progress bar component.
  """
  attr(:value, :integer, default: 0, doc: "Progress value from 0 to 100")

  attr(:size, :string,
    default: "default",
    values: ~w(default sm lg xl),
    doc: "The size of the progress bar"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:aria_label, :string, default: nil, doc: "Accessible label for screen readers")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  def progress(assigns) do
    # Clamp value between 0 and 100
    assigns = assign(assigns, :clamped_value, clamp(assigns.value, 0, 100))

    ~H"""
    <div
      class={["progress", size_class(@size), @class]}
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={@clamped_value}
      aria-label={@aria_label}
      {@rest}
    >
      <div class="progress-indicator" style={"width: #{@clamped_value}%"}></div>
    </div>
    """
  end

  defp size_class("default"), do: nil
  defp size_class("sm"), do: "progress-sm"
  defp size_class("lg"), do: "progress-lg"
  defp size_class("xl"), do: "progress-xl"

  defp clamp(value, min, _max) when value < min, do: min
  defp clamp(value, _min, max) when value > max, do: max
  defp clamp(value, _min, _max), do: value
end
