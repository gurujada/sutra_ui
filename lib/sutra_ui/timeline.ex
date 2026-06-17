defmodule SutraUI.Timeline do
  @moduledoc """
  A vertical list of chronological events with connecting lines.

  Timeline provides the chrome (marker dot, connector line, state styling).
  You control the content of each item however you like via inner_block.
  No brittle title/description/time attributes — full flexibility.

  ## Examples

      <.timeline>
        <:item time="12 min ago" state="current">
          <p>Deployed v2.4 to production</p>
        </:item>
        <:item time="1 hour ago" state="complete">
          <p>Merged PR #342 — refactor auth module</p>
        </:item>
        <:item time="2 hours ago">
          <div class="flex items-center gap-2">
            <img src="/avatar.png" class="size-5 rounded-full" />
            <span>Jess opened a new issue</span>
          </div>
        </:item>
      </.timeline>

      # With custom markers
      <.timeline>
        <:item icon="✓" state="complete">
          <h4>Account created</h4>
        </:item>
      </.timeline>
  """

  use Phoenix.Component

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :item, required: true do
    attr(:time, :string, doc: "Optional time label displayed in the marker row")

    attr(:state, :string,
      values: ~w(default current complete muted),
      doc: "Visual state of the marker"
    )

    attr(:icon, :string, doc: "Optional text/emoji displayed inside the marker")
    attr(:class, :any, doc: "Additional CSS classes for this item")
  end

  def timeline(assigns) do
    ~H"""
    <ol class={["timeline", @class]} {@rest}>
      <li
        :for={item <- @item}
        class={["timeline-item", item[:class]]}
        data-state={item[:state] || "default"}
      >
        <div class="timeline-marker">
          <span :if={item[:icon]} class="timeline-marker-icon">
            {item.icon}
          </span>
          <span :if={!item[:icon]} class="timeline-dot"></span>
        </div>
        <div class="timeline-line" aria-hidden="true"></div>
        <div class="timeline-content">
          <time :if={time_label?(item)} class="timeline-time">{item.time}</time>
          {render_slot(item)}
        </div>
      </li>
    </ol>
    """
  end

  defp time_label?(item), do: item[:time] != nil
end
