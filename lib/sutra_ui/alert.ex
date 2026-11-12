defmodule SutraUI.Alert do
  @moduledoc """
  Displays a callout for user attention.

  Alerts are used to communicate important information to users,
  such as success messages, warnings, or errors.

  ## Examples

      <.alert>
        <:icon><!-- Your icon here --></:icon>
        <:title>Success! Your changes have been saved</:title>
      </.alert>

      <.alert variant="destructive">
        <:icon><!-- Your icon here --></:icon>
        <:title>Something went wrong!</:title>
        <:description>Your session has expired. Please log in again.</:description>
      </.alert>

  ## Accessibility

  - Uses `role="status"` by default and `role="alert"` for destructive alerts;
    callers can override the role
  - Semantic heading structure with h2 for title
  """

  use Phoenix.Component

  @doc """
  Renders an alert component.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default info success warning destructive),
    doc: "The visual variant of the alert"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:role, :string, default: nil, doc: "Overrides the announcement role")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:icon, doc: "Optional icon slot")
  slot(:title, doc: "Optional alert title")
  slot(:description, doc: "Optional description content")
  slot(:action, doc: "Optional action after the description")

  def alert(assigns) do
    {rest_role, rest} = Map.pop(assigns.rest, :role)
    {string_role, rest} = Map.pop(rest, "role")

    assigns =
      assign(assigns,
        role: assigns.role || rest_role || string_role || default_role(assigns.variant),
        rest: rest
      )

    ~H"""
    <div
      class={[variant_class(@variant), @class]}
      role={@role}
      {@rest}
    >
      <span :if={@icon != []}>{render_slot(@icon)}</span>
      <h2 :if={@title != []}>{render_slot(@title)}</h2>
      <section :if={@description != []}>
        {render_slot(@description)}
      </section>
      <div :if={@action != []} class="alert-action">{render_slot(@action)}</div>
    </div>
    """
  end

  defp default_role("destructive"), do: "alert"
  defp default_role(_), do: "status"

  defp variant_class("default"), do: "alert"
  defp variant_class("info"), do: "alert-info"
  defp variant_class("success"), do: "alert-success"
  defp variant_class("warning"), do: "alert-warning"
  defp variant_class("destructive"), do: "alert-destructive"
end
