defmodule SutraUI.Alert do
  @moduledoc """
  Displays a callout for user attention.

  Alerts are used to communicate important information to users,
  such as success messages, warnings, or errors.

  ## Examples

      <.alert>
        <:icon><.icon name="lucide-circle-check" /></:icon>
        <:title>Success! Your changes have been saved</:title>
      </.alert>

      <.alert variant="destructive">
        <:icon><.icon name="lucide-circle-alert" /></:icon>
        <:title>Something went wrong!</:title>
        <:description>Your session has expired. Please log in again.</:description>
      </.alert>

  ## Accessibility

  - Uses `role="alert"` for screen reader announcements
  - Semantic heading structure with h2 for title
  """

  use Phoenix.Component

  @doc """
  Renders an alert component.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default destructive),
    doc: "The visual variant of the alert"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id role),
    doc: "Additional HTML attributes"
  )

  slot(:icon, doc: "Optional icon slot")
  slot(:title, required: true, doc: "The alert title")
  slot(:description, doc: "Optional description content")

  def alert(assigns) do
    ~H"""
    <div
      class={[variant_class(@variant), @class]}
      role="alert"
      {@rest}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% end %>
      <h2>{render_slot(@title)}</h2>
      <%= if @description != [] do %>
        <section>
          {render_slot(@description)}
        </section>
      <% end %>
    </div>
    """
  end

  defp variant_class("default"), do: "alert"
  defp variant_class("destructive"), do: "alert-destructive"
end
