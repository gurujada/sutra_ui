defmodule PhxUI.Icon do
  @moduledoc """
  Icon component for rendering Lucide icons.

  Icons are rendered as `<span>` elements with CSS classes that display the icon
  via a CSS sprite or font system. The actual icon rendering depends on your
  Tailwind/CSS setup with Lucide icons.

  ## Accessibility

  By default, icons are decorative and have `aria-hidden="true"`. If an icon conveys
  meaningful information, provide an `aria-label` attribute, which will automatically
  remove `aria-hidden` and make the icon accessible to screen readers.

  ## Examples

      # Decorative icon (default - hidden from screen readers)
      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 animate-spin" />

      # Meaningful icon (provide aria-label)
      <.icon name="hero-eye" aria-label="Visible" />
      <.icon name="hero-trash" aria-label="Delete" />

      # Custom size
      <.icon name="hero-check" class="size-6" />

  ## Icon Names

  Icon names should match your icon system. Common patterns:
  - Heroicons: `hero-{name}` (e.g., `hero-x-mark`, `hero-check`)
  - Lucide: `lucide-{name}` (e.g., `lucide-x`, `lucide-check`)

  The icon name is applied as a CSS class, so ensure your CSS/Tailwind setup
  includes the corresponding icon definitions.
  """

  use Phoenix.Component

  @doc """
  Renders an icon.

  ## Attributes

  * `name` - Required. The icon name (applied as CSS class)
  * `class` - Additional CSS classes. Defaults to `"size-4"`

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-check" class="size-6 text-green-500" />
      <.icon name="hero-exclamation-triangle" aria-label="Warning" />
  """
  attr(:name, :string, required: true, doc: "The icon name (applied as CSS class)")
  attr(:class, :any, default: "size-4", doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(aria-label title role),
    doc: "Additional HTML attributes"
  )

  def icon(assigns) do
    # If aria-label is provided, the icon is meaningful - don't hide from screen readers
    # Otherwise, default to aria-hidden="true" for decorative icons
    aria_hidden =
      if assigns.rest[:"aria-label"] do
        nil
      else
        "true"
      end

    assigns = assign(assigns, :aria_hidden, aria_hidden)

    ~H"""
    <span class={[@name, @class]} aria-hidden={@aria_hidden} {@rest} />
    """
  end
end
