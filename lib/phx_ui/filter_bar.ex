defmodule PhxUI.FilterBar do
  @moduledoc """
  A filter bar component for index pages with consistent styling and layout.

  The filter bar provides a standardized way to add filter controls to list pages,
  with support for multiple filter inputs and an optional clear filters button.

  ## Examples

      # Basic filter bar
      <.filter_bar on_change="filter">
        <:filter>
          <.input type="text" name="search" value={@filters.search} placeholder="Search..." />
        </:filter>
        <:filter>
          <.input
            type="select"
            name="status"
            value={@filters.status}
            options={[{"All Statuses", ""}, {"Active", "active"}, {"Inactive", "inactive"}]}
          />
        </:filter>
      </.filter_bar>

      # With clear button
      <.filter_bar on_change="filter" on_clear="clear_filters" show_clear={@has_filters}>
        <:filter>
          <.input type="text" name="search" value={@search} />
        </:filter>
      </.filter_bar>

      # With custom column count
      <.filter_bar on_change="filter" cols={4}>
        <:filter><.input name="a" /></:filter>
        <:filter><.input name="b" /></:filter>
        <:filter><.input name="c" /></:filter>
        <:filter><.input name="d" /></:filter>
      </.filter_bar>
  """

  use Phoenix.Component

  import PhxUI.Icon, only: [icon: 1]

  @doc """
  Renders a filter bar with consistent layout and styling.

  ## Attributes

  * `on_change` - Required. The phx-change event name.
  * `on_clear` - Optional. The phx-click event name for the clear button.
  * `show_clear` - Whether to show the clear filters button. Defaults to `false`.
  * `cols` - Number of columns in the grid (1-6). Defaults to `3`.
  * `class` - Additional CSS classes.

  ## Slots

  * `filter` - Required. One or more filter input elements.
  """
  attr(:on_change, :string,
    required: true,
    doc: "The phx-change event name"
  )

  attr(:on_clear, :string,
    default: nil,
    doc: "The phx-click event name for clear button"
  )

  attr(:show_clear, :boolean,
    default: false,
    doc: "Whether to show clear filters button"
  )

  attr(:cols, :integer,
    default: 3,
    values: [1, 2, 3, 4, 5, 6],
    doc: "Number of columns in the grid"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  slot(:filter,
    required: true,
    doc: "Filter input elements"
  )

  def filter_bar(assigns) do
    ~H"""
    <div class={["filter-bar", @class]}>
      <.form for={%{}} phx-change={@on_change} class={["filter-bar-grid", grid_class(@cols)]}>
        <div :for={filter <- @filter} class="filter-bar-item">
          {render_slot(filter)}
        </div>
      </.form>

      <div :if={@show_clear && @on_clear} class="filter-bar-actions">
        <button type="button" phx-click={@on_clear} class="filter-bar-clear">
          <.icon name="hero-x-mark" class="size-4" /> Clear Filters
        </button>
      </div>
    </div>
    """
  end

  defp grid_class(1), do: "filter-bar-cols-1"
  defp grid_class(2), do: "filter-bar-cols-2"
  defp grid_class(3), do: "filter-bar-cols-3"
  defp grid_class(4), do: "filter-bar-cols-4"
  defp grid_class(5), do: "filter-bar-cols-5"
  defp grid_class(6), do: "filter-bar-cols-6"
  defp grid_class(_), do: "filter-bar-cols-3"
end
