defmodule SutraUI.Activity do
  @moduledoc """
  Shows visible progress for agent work, jobs, and multi-step background tasks.

  Activity is a status list, not a transcript of private reasoning. Use it for
  safe, user-facing progress such as "Searching docs", "Reading files", or
  "Drafting answer".

  ## Examples

      <.activity>
        <:item status="complete">
          Searched documentation
        </:item>
        <:item status="running">
          Drafting answer
        </:item>
        <:item status="pending">
          Preparing summary
        </:item>
      </.activity>

      <.activity>
        <.activity_item status="running">
          <:marker>
            <span class="grid size-6 place-items-center rounded-full bg-primary text-primary-foreground">
              <svg viewBox="0 0 24 24" class="size-3" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <circle cx="11" cy="11" r="8" />
                <path d="m21 21-4.3-4.3" />
              </svg>
            </span>
          </:marker>

          Searching local files
        </.activity_item>
      </.activity>

  ## Attributes

  * `compact` - Reduces spacing for dense surfaces. Defaults to `false`.
  * `class` - Additional CSS classes.

  ## Slot Attributes

  The `:item` slot accepts:

  * `status` - One of `pending`, `running`, `complete`, `error`. Defaults to `pending`.
  * `id` - Optional DOM id, useful when rendering LiveView streams.
  * `class` - Additional classes for the item.

  ## Slots

  * `:item` - Activity row content.
  * `:marker` - Optional custom marker rendered for each `:item`. Receives the
    current item slot attrs as the slot argument.

  For fully custom rows, render `activity_item/1` inside `activity/1`.

  ## Accessibility

  - Renders an ordered list with a default `aria-label="Activity"`.
  - Default markers and connector lines are decorative.
  - Pass your own `aria-label` or `aria-labelledby` when the surrounding page
    needs a more specific accessible name.
  """

  use Phoenix.Component

  attr(:compact, :boolean, default: false, doc: "Uses compact spacing")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id aria-label aria-labelledby),
    doc: "Additional HTML attributes"
  )

  slot :item do
    attr(:status, :string, values: ~w(pending running complete error), doc: "Item status")
    attr(:id, :string, doc: "Optional DOM id")
    attr(:class, :any, doc: "Additional classes for the item")
  end

  slot(:marker, doc: "Custom marker rendered for each item.")
  slot(:inner_block, doc: "Custom activity items rendered with activity_item/1")

  def activity(assigns) do
    assigns =
      assigns
      |> assign_new(:item, fn -> [] end)
      |> assign_new(:marker, fn -> [] end)
      |> assign(:rest, activity_attrs(assigns.rest))

    ~H"""
    <ol class={["activity", @compact && "activity-compact", @class]} {@rest}>
      <.activity_row
        :for={item <- @item}
        id={item[:id]}
        status={item[:status] || "pending"}
        class={item[:class]}
        marker={@marker}
        marker_context={item}
      >
        {render_slot(item)}
      </.activity_row>
      {render_slot(@inner_block)}
    </ol>
    """
  end

  defp activity_attrs(rest), do: Map.put_new(rest, :"aria-label", "Activity")

  attr(:id, :string, default: nil, doc: "Optional DOM id")

  attr(:status, :string,
    default: "pending",
    values: ~w(pending running complete error),
    doc: "Item status"
  )

  attr(:class, :any, default: nil, doc: "Additional classes for the item")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:marker, doc: "Custom marker for this item")
  slot(:inner_block, required: true, doc: "Activity item content")

  def activity_item(assigns) do
    assigns = assign_new(assigns, :marker, fn -> [] end)

    ~H"""
    <.activity_row
      id={@id}
      status={@status}
      class={@class}
      marker={@marker}
      marker_context={%{status: @status}}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.activity_row>
    """
  end

  attr(:id, :string, default: nil)
  attr(:status, :string, default: "pending")
  attr(:class, :any, default: nil)
  attr(:marker, :any, default: [])
  attr(:marker_context, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  defp activity_row(assigns) do
    ~H"""
    <li
      id={@id}
      class={["activity-item", @class]}
      data-status={@status}
      {@rest}
    >
      <div class="activity-marker" aria-hidden={@marker == [] && "true"}>
        <%= if @marker != [] do %>
          {render_slot(@marker, @marker_context || %{status: @status})}
        <% else %>
          <span class="activity-dot"></span>
        <% end %>
        <span class="activity-line" aria-hidden="true"></span>
      </div>

      <div class="activity-content">
        {render_slot(@inner_block)}
      </div>
    </li>
    """
  end
end
