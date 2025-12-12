defmodule SutraUI.Pagination do
  @moduledoc """
  Pagination with page navigation, next and previous links.

  Provides a complete pagination UI with support for first/last page,
  previous/next navigation, and page number links.

  ## Examples

      <.pagination
        page={@page}
        total_pages={@total_pages}
        on_page_change="page_changed"
      />

      <.pagination
        page={@page}
        total_pages={@total_pages}
        sibling_count={2}
      >
        <:previous>Previous</:previous>
        <:next>Next</:next>
      </.pagination>

  ## Accessibility

  - Uses `<nav>` element with `aria-label="Pagination"`
  - Current page marked with `aria-current="page"`
  - Disabled buttons properly marked
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a pagination component.
  """
  attr(:page, :integer, required: true, doc: "Current page number (1-indexed)")
  attr(:total_pages, :integer, required: true, doc: "Total number of pages")

  attr(:sibling_count, :integer,
    default: 1,
    doc: "Number of sibling pages to show on each side of current page"
  )

  attr(:on_page_change, :string,
    default: nil,
    doc: "Event name to send when page changes (sends page number)"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:previous, doc: "Custom content for previous button")
  slot(:next, doc: "Custom content for next button")

  def pagination(assigns) do
    assigns =
      assign(
        assigns,
        :pages,
        generate_pages(assigns.page, assigns.total_pages, assigns.sibling_count)
      )

    ~H"""
    <nav aria-label="Pagination" class={["pagination", @class]} {@rest}>
      <ul class="pagination-list">
        <li>
          <button
            type="button"
            class="pagination-btn pagination-prev"
            disabled={@page <= 1}
            aria-label="Go to previous page"
            phx-click={@on_page_change}
            phx-value-page={@page - 1}
          >
            <%= if @previous != [] do %>
              {render_slot(@previous)}
            <% else %>
              <.icon name="lucide-chevron-left" class="size-4" />
            <% end %>
          </button>
        </li>

        <%= for page_item <- @pages do %>
          <%= case page_item do %>
            <% :ellipsis -> %>
              <li>
                <span class="pagination-ellipsis" aria-hidden="true">...</span>
              </li>
            <% page_num -> %>
              <li>
                <button
                  type="button"
                  class={["pagination-btn pagination-page", page_num == @page && "pagination-active"]}
                  aria-current={page_num == @page && "page"}
                  phx-click={@on_page_change}
                  phx-value-page={page_num}
                >
                  {page_num}
                </button>
              </li>
          <% end %>
        <% end %>

        <li>
          <button
            type="button"
            class="pagination-btn pagination-next"
            disabled={@page >= @total_pages}
            aria-label="Go to next page"
            phx-click={@on_page_change}
            phx-value-page={@page + 1}
          >
            <%= if @next != [] do %>
              {render_slot(@next)}
            <% else %>
              <.icon name="lucide-chevron-right" class="size-4" />
            <% end %>
          </button>
        </li>
      </ul>
    </nav>
    """
  end

  # Generate page numbers with ellipsis
  defp generate_pages(_current, total, _siblings) when total <= 7 do
    Enum.to_list(1..total)
  end

  defp generate_pages(current, total, siblings) do
    left_sibling = max(current - siblings, 1)
    right_sibling = min(current + siblings, total)

    show_left_ellipsis = left_sibling > 2
    show_right_ellipsis = right_sibling < total - 1

    cond do
      !show_left_ellipsis && show_right_ellipsis ->
        left_range = Enum.to_list(1..(3 + 2 * siblings))
        left_range ++ [:ellipsis, total]

      show_left_ellipsis && !show_right_ellipsis ->
        right_range = Enum.to_list((total - (2 + 2 * siblings))..total)
        [1, :ellipsis] ++ right_range

      show_left_ellipsis && show_right_ellipsis ->
        middle_range = Enum.to_list(left_sibling..right_sibling)
        [1, :ellipsis] ++ middle_range ++ [:ellipsis, total]

      true ->
        Enum.to_list(1..total)
    end
  end
end
