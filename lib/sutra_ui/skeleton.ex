defmodule SutraUI.Skeleton do
  @moduledoc """
  Used to show a placeholder while content is loading.

  The skeleton component provides a visual placeholder with an animated pulse effect
  to indicate that content is being loaded.

  ## Examples

      # Basic skeleton for text
      <.skeleton class="h-4 w-[250px]" />

      # Skeleton for a circular avatar
      <.skeleton class="size-10 rounded-full" />

      # Multiple skeletons for a card layout
      <div class="flex items-center gap-4">
        <.skeleton class="size-10 shrink-0 rounded-full" />
        <div class="grid gap-2">
          <.skeleton class="h-4 w-[150px]" />
          <.skeleton class="h-4 w-[100px]" />
        </div>
      </div>

  ## Accessibility

  - Uses `role="status"` to indicate loading state
  - Has `aria-label="Loading..."` for screen readers
  """

  use Phoenix.Component

  @doc """
  Renders a skeleton loading placeholder.
  """
  attr(:width, :string, default: nil, doc: "Width of the skeleton (e.g., '200px', '50%')")
  attr(:height, :string, default: nil, doc: "Height of the skeleton (e.g., '24px', '3rem')")

  attr(:radius, :string,
    default: "md",
    values: ~w(none sm md lg full),
    doc: "Border radius variant"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id role aria-label),
    doc: "Additional HTML attributes"
  )

  def skeleton(assigns) do
    ~H"""
    <div
      class={["skeleton", radius_class(@radius), @class]}
      style={inline_styles(@width, @height)}
      role="status"
      aria-label="Loading..."
      {@rest}
    >
    </div>
    """
  end

  defp radius_class("none"), do: "rounded-none"
  defp radius_class("sm"), do: "rounded-sm"
  defp radius_class("md"), do: nil
  defp radius_class("lg"), do: "rounded-lg"
  defp radius_class("full"), do: "rounded-full"

  defp inline_styles(nil, nil), do: nil

  defp inline_styles(width, height) do
    [
      width && "width: #{width}",
      height && "height: #{height}"
    ]
    |> Enum.filter(& &1)
    |> Enum.join("; ")
  end
end
