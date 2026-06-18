defmodule SutraUI.Timeline do
  @moduledoc """
  A vertical list of chronological events with dot markers and connector lines.

  Timeline provides the chrome. Add each event with the `:item` slot and pass
  the event body as slot content. Use `time` or `icon` only when those
  conveniences help.

  ## Examples

      <.timeline>
        <:item time="2 hours ago">
          <h3>Deployed v2.4</h3>
          <p>Pushed to production, all checks green.</p>
        </:item>

        <:item time="Yesterday" icon="✓">
          <h3>Review completed</h3>
        </:item>
      </.timeline>

      <.timeline>
        <:item time="12 min ago">
          <div class="flex items-center gap-2">
            <strong>Alex</strong>
            <span>created a new project</span>
          </div>
        </:item>
      </.timeline>
  """

  use Phoenix.Component

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :item, required: true do
    attr(:time, :string, doc: "Timestamp shown above the item content")
    attr(:icon, :string, doc: "Text or icon shown in the marker")
    attr(:class, :any, doc: "Additional CSS classes for this item")
  end

  def timeline(assigns) do
    ~H"""
    <ol class={["timeline", @class]} {@rest}>
      <.timeline_entry :for={item <- @item} time={item[:time]} icon={item[:icon]} class={item[:class]}>
        {render_slot(item)}
      </.timeline_entry>
    </ol>
    """
  end

  attr(:time, :string, default: nil, doc: "Timestamp shown above the item content")
  attr(:icon, :string, default: nil, doc: "Text or icon shown in the marker")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for the item")
  attr(:rest, :global, include: ~w(id), doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Timeline item content")

  defp timeline_entry(assigns) do
    ~H"""
    <li class={["timeline-item", @class]} {@rest}>
      <div class="timeline-marker" aria-hidden="true">
        <span :if={@icon} class="timeline-marker-icon">{@icon}</span>
        <span :if={!@icon} class="timeline-dot"></span>
      </div>
      <div class="timeline-line" aria-hidden="true"></div>
      <div class="timeline-content">
        <time :if={@time} class="timeline-time">{@time}</time>
        {render_slot(@inner_block)}
      </div>
    </li>
    """
  end
end
