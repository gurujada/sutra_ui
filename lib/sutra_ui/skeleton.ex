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
  attr(:width, :string,
    default: nil,
    doc:
      "Tailwind width class (e.g., 'w-48', 'w-1/2'). A CSS length ('200px') still works as an inline style but is deprecated and goes away in 0.5; it needs `style-src 'unsafe-inline'`"
  )

  attr(:height, :string,
    default: nil,
    doc: "Tailwind height class (e.g., 'h-6'). A CSS length ('24px') is deprecated like `width`"
  )

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
      class={["skeleton", radius_class(@radius), SutraUI.Dimension.classes([@width, @height]), @class]}
      {SutraUI.Dimension.style_attr(width: @width, height: @height)}
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
end
