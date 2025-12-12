defmodule SutraUI.FilterBar do
  @moduledoc """
  A filter bar component for index pages with consistent styling and layout.

  The filter bar provides a standardized way to add filter controls to list pages,
  with support for multiple filter inputs and an optional clear filters button.

  Uses a responsive grid layout that adapts to screen sizes.

  ## Examples

      # Basic filter bar (3 columns by default)
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

      # With custom column count
      <.filter_bar on_change="filter" cols={2}>
        <:filter>
          <.input type="text" name="search" value={@search} />
        </:filter>
        <:filter>
          <.input type="select" name="status" value={@status} options={@status_options} />
        </:filter>
      </.filter_bar>

      # With clear button
      <.filter_bar on_change="filter" on_clear="clear_filters" show_clear={@has_filters}>
        <:filter>
          <.input type="text" name="search" value={@search} />
        </:filter>
      </.filter_bar>
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

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
    doc: "Number of columns in the grid (1-6)"
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
    grid_class = grid_cols_class(assigns.cols)
    assigns = assign(assigns, :grid_class, grid_class)

    ~H"""
    <div class={["filter-bar", @class]}>
      <.form for={%{}} phx-change={@on_change} class={["filter-bar-grid", @grid_class]}>
        <div :for={filter <- @filter} class="filter-bar-item">
          {render_slot(filter)}
        </div>
      </.form>

      <div :if={@show_clear && @on_clear} class="filter-bar-actions">
        <button
          type="button"
          phx-click={@on_clear}
          class="filter-bar-clear"
        >
          <.icon name="hero-x-mark" class="size-4" /> Clear
        </button>
      </div>
    </div>
    """
  end

  defp grid_cols_class(cols) do
    case cols do
      1 -> "filter-bar-cols-1"
      2 -> "filter-bar-cols-2"
      3 -> "filter-bar-cols-3"
      4 -> "filter-bar-cols-4"
      5 -> "filter-bar-cols-5"
      6 -> "filter-bar-cols-6"
      _ -> "filter-bar-cols-3"
    end
  end
end
