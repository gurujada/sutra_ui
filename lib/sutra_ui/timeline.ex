defmodule SutraUI.Timeline do
  @moduledoc """
  A vertical list of chronological events.

  Timeline follows Preline's vertical event pattern while using Sutra UI tokens
  and slots. It works for activity feeds, release histories, audit trails, and
  onboarding milestones.
  """

  use Phoenix.Component

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :item, required: true do
    attr(:title, :string, required: true, doc: "Event title")
    attr(:time, :string, doc: "Event time or label")
    attr(:description, :string, doc: "Optional event description")
    attr(:state, :string, values: ~w(default current complete muted), doc: "Visual state")
    attr(:icon, :string, doc: "Optional marker text")
  end

  def timeline(assigns) do
    ~H"""
    <ol class={["timeline", @class]} {@rest}>
      <%= for item <- @item do %>
        <li class="timeline-item" data-state={item[:state] || "default"}>
          <div class="timeline-marker" aria-hidden="true">
            <span>
              <%= if item[:icon] do %>
                {item.icon}
              <% else %>
                <span class="timeline-dot"></span>
              <% end %>
            </span>
          </div>
          <div class="timeline-content">
            <div class="timeline-header">
              <h3>{item.title}</h3>
              <time :if={item[:time]}>{item.time}</time>
            </div>
            <p :if={item[:description]}>{item.description}</p>
            <%= if item[:inner_block] do %>
              {render_slot(item)}
            <% end %>
          </div>
        </li>
      <% end %>
    </ol>
    """
  end
end
