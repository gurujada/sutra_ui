defmodule SutraUI.Badge do
  @moduledoc """
  A small status indicator component.

  Badges are used to display counts, labels, or status indicators.
  They can be rendered as `<span>` or `<a>` elements.

  ## Variants

  - `default` - Default badge style
  - `secondary` - Muted secondary style
  - `destructive` - Error/danger style
  - `success` - Success/positive style
  - `outline` - Border only, transparent background
  - `info`, `warning`, `brand`, `ai` - Theme-token tones (`--info`, `--warning`, `--brand`,
    `--ai`, each with a `-foreground`); override the tokens to retheme

  ## Appearances

  Any variant comes in three appearances: `solid` (default), `soft` (a tinted background with
  tinted text) and `dashed` (a dashed border, for pending or suggested things).

  ## Examples

      # Basic badge
      <.badge>New</.badge>

      # Variants
      <.badge variant="secondary">Draft</.badge>
      <.badge variant="destructive">Error</.badge>
      <.badge variant="outline">Pending</.badge>

      # Tones and appearances
      <.badge variant="info">Info</.badge>
      <.badge variant="warning" appearance="soft">Due soon</.badge>
      <.badge variant="ai" appearance="dashed">Suggested</.badge>

      # As a link
      <.badge href="/notifications">5 new</.badge>

      # With an icon
      <.badge variant="success">
        <:icon><!-- Your icon here --></:icon>
        Verified
      </.badge>
  """

  use Phoenix.Component

  @doc """
  Renders a badge component.

  ## Attributes

  * `variant` - Colour. One of `default`, `secondary`, `destructive`, `success`, `outline`, `info`, `warning`, `brand`, `ai`. Defaults to `default`.
  * `appearance` - `solid` (default), `soft` or `dashed`.
  * `href` - Optional link URL. Renders as `<a>` instead of `<span>`.
  * `class` - Additional CSS classes.

  ## Slots

  * `inner_block` - Required. The badge content.
  * `icon` - Optional. An icon shown before the content (decorative; the content names the badge).
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default secondary destructive success outline info warning brand ai),
    doc: "Colour variant"
  )

  attr(:appearance, :string,
    default: "solid",
    values: ~w(solid soft dashed),
    doc: "Fill: solid, soft (tinted) or dashed (dashed border)"
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
  slot(:icon, doc: "Icon shown before the content")

  def badge(assigns) do
    assigns =
      assign(assigns, :classes, badge_class(assigns.variant, assigns.appearance, assigns.class))

    if assigns.href do
      ~H"""
      <a href={@href} class={@classes} data-variant={@variant} data-appearance={@appearance} {@rest}>
        <span :if={@icon != []} class="badge-icon" aria-hidden="true">{render_slot(@icon)}</span>
        {render_slot(@inner_block)}
      </a>
      """
    else
      ~H"""
      <span class={@classes} data-variant={@variant} data-appearance={@appearance} {@rest}>
        <span :if={@icon != []} class="badge-icon" aria-hidden="true">{render_slot(@icon)}</span>
        {render_slot(@inner_block)}
      </span>
      """
    end
  end

  # Simple semantic CSS class - all styling via @apply in sutra_ui.css
  defp badge_class(variant, appearance, extra_class) do
    base =
      case variant do
        "default" -> "badge"
        "secondary" -> "badge-secondary"
        "destructive" -> "badge-destructive"
        "success" -> "badge-success"
        "outline" -> "badge-outline"
        "info" -> "badge-info"
        "warning" -> "badge-warning"
        "brand" -> "badge-brand"
        "ai" -> "badge-ai"
      end

    [base, appearance != "solid" && "badge-#{appearance}", extra_class]
  end
end
