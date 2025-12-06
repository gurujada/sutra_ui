defmodule PhxUI.Badge do
  @moduledoc """
  A small status indicator component.

  Badges are used to display counts, labels, or status indicators.
  They can be rendered as `<span>` or `<a>` elements.

  ## Variants

  - `default` - Default badge style
  - `secondary` - Muted secondary style
  - `destructive` - Error/danger style
  - `outline` - Border only, transparent background

  ## Examples

      # Basic badge
      <.badge>New</.badge>

      # Variants
      <.badge variant="secondary">Draft</.badge>
      <.badge variant="destructive">Error</.badge>
      <.badge variant="outline">Pending</.badge>

      # As a link
      <.badge href="/notifications">5 new</.badge>

      # With icon
      <.badge>
        <.icon name="hero-check" class="size-3" />
        Verified
      </.badge>
  """

  use Phoenix.Component

  @doc """
  Renders a badge component.

  ## Attributes

  * `variant` - Visual style. One of `default`, `secondary`, `destructive`, `outline`. Defaults to `default`.
  * `href` - Optional link URL. Renders as `<a>` instead of `<span>`.
  * `class` - Additional CSS classes.

  ## Slots

  * `inner_block` - Required. The badge content.
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default secondary destructive outline),
    doc: "Visual style variant"
  )

  attr(:href, :string,
    default: nil,
    doc: "Optional link URL"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(id role aria-label),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true, doc: "Badge content")

  def badge(assigns) do
    assigns = assign(assigns, :classes, badge_class(assigns.variant, assigns.class))

    if assigns.href do
      ~H"""
      <a href={@href} class={@classes} {@rest}>
        {render_slot(@inner_block)}
      </a>
      """
    else
      ~H"""
      <span class={@classes} {@rest}>
        {render_slot(@inner_block)}
      </span>
      """
    end
  end

  # Simple semantic CSS class - all styling via @apply in phx_ui.css
  defp badge_class(variant, extra_class) do
    base =
      case variant do
        "default" -> "badge"
        "secondary" -> "badge-secondary"
        "destructive" -> "badge-destructive"
        "outline" -> "badge-outline"
      end

    [base, extra_class]
  end
end
