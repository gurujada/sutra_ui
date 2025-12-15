defmodule SutraUI.Icon do
  @moduledoc """
  Icon component for rendering Lucide icons.

  Sutra UI uses [Lucide icons](https://lucide.dev/icons/) as the standard icon system,
  matching the shadcn/ui ecosystem. Icons are rendered as CSS classes and the actual
  SVG is injected via the `assets/vendor/lucide.js` plugin.

  ## Examples

      # Decorative icon (default - aria-hidden)
      <.icon name="lucide-x" />
      <.icon name="lucide-refresh-cw" class="ml-1 size-3 animate-spin" />

      # Meaningful icon (provide aria-label)
      <.icon name="lucide-eye" aria-label="Visible" />
      <.icon name="lucide-trash-2" aria-label="Delete" />

  ## Icon Names

  Icon names must start with `lucide-` followed by the kebab-case icon name.
  Browse all icons at [lucide.dev/icons](https://lucide.dev/icons/).

  Common icons:
  - `lucide-check` - Checkmark
  - `lucide-x` - Close/cancel
  - `lucide-search` - Search
  - `lucide-settings` - Settings/gear
  - `lucide-user` - User profile
  - `lucide-chevron-down` - Dropdown indicator
  - `lucide-loader-circle` - Loading spinner (use with `animate-spin`)

  ## Accessibility

  By default, icons are decorative and have `aria-hidden="true"`. If an icon conveys
  meaningful information, provide an `aria-label` attribute, which will automatically
  remove `aria-hidden` and make the icon accessible to screen readers.
  """

  use Phoenix.Component

  @doc """
  Renders a [Lucide Icon](https://lucide.dev).

  ## Examples

      # Decorative icon (default)
      <.icon name="lucide-x" />
      <.icon name="lucide-refresh-cw" class="ml-1 size-3 animate-spin" />

      # Meaningful icon with aria-label
      <.icon name="lucide-eye" aria-label="Visible" />
      <.icon name="lucide-trash-2" aria-label="Delete" />

      # With title (tooltip on hover)
      <.icon name="lucide-eye" title="Visible" />
  """
  attr(:name, :string, required: true, doc: "The Lucide icon name (must start with 'lucide-')")
  attr(:class, :any, default: "size-4", doc: "Additional CSS classes")
  attr(:title, :string, default: nil, doc: "Title attribute for tooltip on hover")
  attr(:rest, :global, include: ~w(aria-label role))

  def icon(%{name: "lucide-" <> _} = assigns) do
    # If aria-label is provided, the icon is meaningful, so don't hide it from screen readers
    # Otherwise, default to aria-hidden="true" for decorative icons
    assigns =
      assign_new(assigns, :aria_hidden, fn ->
        if assigns[:rest][:"aria-label"], do: nil, else: "true"
      end)

    ~H"""
    <span
      class={[@name, @class]}
      title={@title}
      aria-hidden={@aria_hidden}
      {@rest}
    />
    """
  end
end
