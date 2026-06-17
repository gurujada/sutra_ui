defmodule SutraUI.Marquee do
  @moduledoc """
  A scrolling content banner that displays items in a continuous loop.

  Useful for announcements, testimonial strips, logo displays, or any
  horizontally scrolling content that needs to repeat seamlessly without
  JavaScript.

  ## Examples

      # Text announcement ticker
      <.marquee>
        <:item>Free shipping on all orders</:item>
        <:item>New collection available</:item>
        <:item>Sign up for 10% off</:item>
      </.marquee>

      # Logo strip
      <.marquee speed="slow" gap="lg">
        <:item><img src="/logo1.svg" alt="Company 1" /></:item>
        <:item><img src="/logo2.svg" alt="Company 2" /></:item>
      </.marquee>

  ## Accessibility

  - Content duplicates use `aria-hidden="true"` to avoid screen reader repetition
  - Respects `prefers-reduced-motion` - animation stops when user preference is set
  - Always ensure individual items have accessible labels where applicable
  """

  use Phoenix.Component

  @doc """
  Renders a marquee scrolling banner.

  ## Attributes

  * `direction` - Scroll direction. One of `left`, `right`. Defaults to `left`.
  * `speed` - Animation speed. One of `slow`, `default`, `fast`. Defaults to `default`.
  * `pause_on_hover` - Whether to pause animation on hover. Defaults to `true`.
  * `fade_edges` - Whether to show gradient fade at edges. Defaults to `true`.
  * `gap` - Gap between items. One of `sm`, `default`, `lg`. Defaults to `default`.
  * `class` - Additional CSS classes.

  ## Slots

  * `item` - Required repeating slot for marquee items.
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
    assigns =
      assigns
      |> assign(:wrapper_classes, marquee_wrapper_classes(assigns))
      |> assign(:track_classes, marquee_track_classes(assigns))

    ~H"""
    <div class={@wrapper_classes} {@rest}>
      <div class={@track_classes}>
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

  defp marquee_wrapper_classes(assigns) do
    classes = ["marquee"]

    classes =
      if assigns.fade_edges, do: classes ++ ["marquee-fade"], else: classes

    classes =
      if assigns.pause_on_hover, do: classes ++ ["marquee-pause-on-hover"], else: classes

    speed =
      case assigns.speed do
        "slow" -> "marquee-slow"
        "fast" -> "marquee-fast"
        _ -> nil
      end

    gap =
      case assigns.gap do
        "sm" -> "marquee-gap-sm"
        "lg" -> "marquee-gap-lg"
        _ -> nil
      end

    classes = classes ++ Enum.reject([speed, gap], &is_nil/1)

    [classes, assigns.class]
  end

  defp marquee_track_classes(assigns) do
    ["marquee-track", assigns.direction == "right" && "marquee-reverse"]
  end
end
