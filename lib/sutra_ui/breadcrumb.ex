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
                {separator_svg(@separator)}
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

  defp separator_svg("chevron") do
    assigns = %{}

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-4"
      aria-hidden="true"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
    """
  end

  defp separator_svg("slash") do
    assigns = %{}

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-4"
      aria-hidden="true"
    >
      <path d="M22 2 2 22" />
    </svg>
    """
  end
end
