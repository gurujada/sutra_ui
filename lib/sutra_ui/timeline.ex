defmodule SutraUI.Timeline do
  @moduledoc """
  A vertical list of chronological events with dot markers and connector lines.

  Timeline provides the chrome — the marker, the connector line, and the
  timestamp. You own the content of each event via the `:item` slot.

  ## Examples

      <.timeline>
        <:item time="2 hours ago">
          <h4>Deployed v2.4</h4>
          <p>Pushed to production, all checks green.</p>
        </:item>

        <:item time="Yesterday" icon="📝">
          <h4>Draft saved</h4>
        </:item>
      </.timeline>

      # Colored markers — use marker_class to style individual markers
      <.timeline>
        <:item time="12 min ago" icon="A" marker_class="bg-primary text-primary-foreground">
          <p><strong>Alex</strong> created a new project</p>
        </:item>
        <:item time="1 hour ago" icon="S" marker_class="bg-secondary text-secondary-foreground">
          <p><strong>Sarah</strong> left a comment</p>
        </:item>
      </.timeline>

  ## Slot Attributes

  The `:item` slot accepts:

  * `time` - Timestamp shown above the item content.
  * `icon` - Text or emoji shown in the marker. Falls back to a dot.
  * `marker_class` - CSS classes for the marker element (e.g. to color it).
  * `class` - Additional CSS classes for this item.

  ## Accessibility

  - Uses an ordered list (`<ol>`) to convey sequence.
  - The marker and connector line are decorative (`aria-hidden="true"`).
  - The timestamp uses a semantic `<time>` element.
  """

  use Phoenix.Component

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :item, required: true do
    attr(:time, :string, doc: "Timestamp shown above the item content")
    attr(:icon, :string, doc: "Text or emoji shown in the marker")
    attr(:marker_class, :any, doc: "CSS classes for the marker element")
    attr(:class, :any, doc: "Additional CSS classes for this item")
  end

  def timeline(assigns) do
    ~H"""
    <ol class={["timeline", @class]} {@rest}>
      <.timeline_entry
        :for={item <- @item}
        time={item[:time]}
        icon={item[:icon]}
        marker_class={item[:marker_class]}
        class={item[:class]}
      >
        {render_slot(item)}
      </.timeline_entry>
    </ol>
    """
  end

  attr(:time, :string, default: nil, doc: "Timestamp shown above the item content")
  attr(:icon, :string, default: nil, doc: "Text or emoji shown in the marker")
  attr(:marker_class, :any, default: nil, doc: "CSS classes for the marker element")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for this item")
  attr(:rest, :global, include: ~w(id), doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Timeline item content")

  defp timeline_entry(assigns) do
    ~H"""
    <li class={["timeline-item", @class]} {@rest}>
      <div class="timeline-marker" aria-hidden="true">
        <span class={["timeline-marker-icon", @marker_class]}>
          <span :if={@icon}>{@icon}</span>
          <span :if={!@icon} class="timeline-dot"></span>
        </span>
        <span class="timeline-line"></span>
      </div>
      <div class="timeline-content">
        <time :if={@time} class="timeline-time">{@time}</time>
        {render_slot(@inner_block)}
      </div>
    </li>
    """
  end
end
