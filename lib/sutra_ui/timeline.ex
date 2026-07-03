defmodule SutraUI.Timeline do
  @moduledoc """
  A vertical list of chronological events with dot markers and connector lines.

  Timeline provides the chrome — the marker, the connector line, and the
  timestamp. You own the content of each event via the `:item` slot.

  ## Examples

      <.timeline>
        <:marker :let={item}>
          <span class="timeline-marker-icon">
            <span class="size-2 rounded-full bg-primary animate-pulse"></span>
          </span>
        </:marker>

        <:item time="2 hours ago">
          <h4>Deployed v2.4</h4>
          <p>Pushed to production, all checks green.</p>
        </:item>

        <:item time="Yesterday" icon="📝">
          <h4>Draft saved</h4>
        </:item>
      </.timeline>

  ## Slot Attributes

  The `:item` slot accepts:

  * `time` - Timestamp shown above the item content.
  * `icon` - Text or emoji shown in the marker. Falls back to a dot.
  * `class` - Additional CSS classes for this item.

  ## Slots

  * `:item` - Timeline entry content.
  * `:marker` - Optional custom marker. Receives the current `:item` slot attrs
    as the slot argument.

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
    attr(:class, :any, doc: "Additional CSS classes for this item")
  end

  slot(:marker, doc: "Custom marker rendered for each item.")

  def timeline(assigns) do
    ~H"""
    <ol class={["timeline", @class]} {@rest}>
      <.timeline_entry
        :for={item <- @item}
        time={item[:time]}
        icon={item[:icon]}
        class={item[:class]}
        marker={@marker}
        item={item}
      >
        {render_slot(item)}
      </.timeline_entry>
    </ol>
    """
  end

  attr(:time, :string, default: nil, doc: "Timestamp shown above the item content")
  attr(:icon, :string, default: nil, doc: "Text or emoji shown in the marker")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for this item")
  attr(:marker, :any, default: [])
  attr(:item, :any, default: nil)
  attr(:rest, :global, include: ~w(id), doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Timeline item content")

  defp timeline_entry(assigns) do
    ~H"""
    <li class={["timeline-item", @class]} {@rest}>
      <div class="timeline-marker" aria-hidden="true">
        <%= if @marker != [] do %>
          {render_slot(@marker, @item)}
        <% else %>
          <span class="timeline-marker-icon">
            <span :if={@icon}>{@icon}</span>
            <span :if={!@icon} class="timeline-dot"></span>
          </span>
        <% end %>
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
