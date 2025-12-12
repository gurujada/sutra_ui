defmodule SutraUI.Breadcrumb do
  @moduledoc """
  Displays the path to the current resource using a hierarchy of links.

  Breadcrumbs help users understand their location within a site and
  navigate back to parent pages.

  ## Examples

      <.breadcrumb>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/products"}>Products</:item>
        <:item>Current Page</:item>
      </.breadcrumb>

  ## Accessibility

  - Uses `<nav>` element with `aria-label="Breadcrumb"`
  - Uses ordered list for semantic structure
  - Current page marked with `aria-current="page"`
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a breadcrumb navigation component.
  """
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:separator, :string,
    default: "chevron",
    values: ~w(chevron slash),
    doc: "The separator style between items"
  )

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot :item, required: true, doc: "Breadcrumb items" do
    attr(:navigate, :string, doc: "The path to navigate to (makes it a link)")
    attr(:href, :string, doc: "External URL (makes it a link)")
    attr(:class, :string, doc: "Additional CSS classes for the item")
  end

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class={["breadcrumb", @class]} {@rest}>
      <ol class="breadcrumb-list">
        <%= for {item, index} <- Enum.with_index(@item) do %>
          <li class={["breadcrumb-item", item[:class]]}>
            <%= if index > 0 do %>
              <span class="breadcrumb-separator" aria-hidden="true">
                <.icon name={separator_icon_name(@separator)} class="size-4" />
              </span>
            <% end %>
            <%= if item[:navigate] do %>
              <.link navigate={item[:navigate]} class="breadcrumb-link">
                {render_slot([item])}
              </.link>
            <% else %>
              <%= if item[:href] do %>
                <.link href={item[:href]} class="breadcrumb-link">
                  {render_slot([item])}
                </.link>
              <% else %>
                <span class="breadcrumb-page" aria-current="page">
                  {render_slot([item])}
                </span>
              <% end %>
            <% end %>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp separator_icon_name("chevron"), do: "lucide-chevron-right"
  defp separator_icon_name("slash"), do: "lucide-slash"
end
