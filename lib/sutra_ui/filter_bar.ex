defmodule SutraUI.FilterBar do
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
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a filter bar with consistent layout and styling.

  ## Attributes

  * `on_change` - Required. The phx-change event name.
  * `on_clear` - Optional. The phx-click event name for the clear button.
  * `show_clear` - Whether to show the clear filters button. Defaults to `false`.
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
    <.form for={%{}} phx-change={@on_change} class={["filter-bar", @class]}>
      <div :for={filter <- @filter} class="filter-bar-item">
        {render_slot(filter)}
      </div>
      <button
        :if={@show_clear && @on_clear}
        type="button"
        phx-click={@on_clear}
        class="filter-bar-clear"
      >
        <.icon name="hero-x-mark" class="size-4" /> Clear
      </button>
    </.form>
    """
  end
end
