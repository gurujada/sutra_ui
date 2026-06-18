defmodule SutraUI.Marquee do
  @moduledoc """
  A CSS-only scrolling banner for announcements, logo strips, and repeating
  inline content.

  Content is duplicated internally so the loop stays seamless — no JavaScript
  required. Respects `prefers-reduced-motion` (animation stops automatically).

  ## Examples

      # Announcement ticker
      <.marquee>
        <:item>Free shipping on all orders</:item>
        <:item>New collection available</:item>
        <:item>Sign up for 10% off</:item>
      </.marquee>

      # Logo strip — slow, larger gaps
      <.marquee speed="slow" gap="lg">
        <:item><img src="/logo1.svg" alt="Company 1" /></:item>
        <:item><img src="/logo2.svg" alt="Company 2" /></:item>
      </.marquee>

      # Reverse direction, no edge fade
      <.marquee direction="right" fade_edges={false}>
        <:item>Right-scrolling content</:item>
      </.marquee>

  ## Attributes

  * `direction` - Scroll direction. One of `left`, `right`. Defaults to `left`.
  * `speed` - Animation speed. One of `slow`, `default`, `fast`. Defaults to `default`.
  * `pause_on_hover` - Pause animation on mouse hover. Defaults to `true`.
  * `fade_edges` - Gradient mask at the left/right edges. Defaults to `true`.
  * `gap` - Gap between items. One of `sm`, `default`, `lg`. Defaults to `default`.
  * `class` - Additional CSS classes.

  ## Slots

  * `item` - Required repeating slot for marquee items.

  ## Accessibility

  - The duplicated content track sets `aria-hidden="true"` to avoid screen
    reader repetition.
  - Respects `prefers-reduced-motion` — the CSS animation halts when the user
    has expressed a motion preference.
  - Ensure each item has its own accessible label (e.g. `alt` text on images).
  """

  use Phoenix.Component

  @doc """
  Renders a marquee scrolling banner.

  ## Examples

      <.marquee>
        <:item>Free shipping on all orders</:item>
        <:item>New collection available</:item>
      </.marquee>
  """
  attr(:direction, :string,
    default: "left",
    values: ~w(left right),
    doc: "Scroll direction"
  )

  attr(:speed, :string,
    default: "default",
    values: ~w(slow default fast),
    doc: "Animation speed"
  )

  attr(:pause_on_hover, :boolean,
    default: true,
    doc: "Pause animation on mouse hover"
  )

  attr(:fade_edges, :boolean,
    default: true,
    doc: "Show gradient fade effect at the edges"
  )

  attr(:gap, :string,
    default: "default",
    values: ~w(sm default lg),
    doc: "Gap between items"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:item, required: true, doc: "Items to scroll")

  def marquee(assigns) do
    ~H"""
    <div
      class={[
        "marquee",
        @fade_edges && "marquee-fade",
        @pause_on_hover && "marquee-pause-on-hover",
        @speed == "slow" && "marquee-slow",
        @speed == "fast" && "marquee-fast",
        @gap == "sm" && "marquee-gap-sm",
        @gap == "lg" && "marquee-gap-lg",
        @class
      ]}
      {@rest}
    >
      <div class={["marquee-track", @direction == "right" && "marquee-reverse"]}>
        <div class="marquee-content">
          <%= for item <- @item do %>
            <div class="marquee-item">
              {render_slot(item)}
            </div>
          <% end %>
        </div>
        <div class="marquee-content" aria-hidden="true">
          <%= for item <- @item do %>
            <div class="marquee-item">
              {render_slot(item)}
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
