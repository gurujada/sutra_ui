defmodule SutraUI.Icon do
  @moduledoc """
  Icon component for rendering Lucide icons.

  Sutra UI uses [Lucide icons](https://lucide.dev/icons/) as the standard icon system,
  matching the shadcn/ui ecosystem. Icons are rendered as inline SVGs using the
  `lucide_icons` package.

  ## Accessibility

  By default, icons are decorative and have `aria-hidden="true"`. If an icon conveys
  meaningful information, provide an `aria-label` attribute, which will automatically
  remove `aria-hidden` and make the icon accessible to screen readers.

  ## Examples

      # Decorative icon (default - hidden from screen readers)
      <.icon name="x" />
      <.icon name="loader-circle" class="ml-1 size-3 animate-spin" />

      # Meaningful icon (provide aria-label)
      <.icon name="eye" aria-label="Visible" />
      <.icon name="trash-2" aria-label="Delete" />

      # Custom size
      <.icon name="check" class="size-6" />

  ## Icon Names

  Icon names use kebab-case matching Lucide icon names.
  Browse all icons at [lucide.dev/icons](https://lucide.dev/icons/).

  Common icons:
  - `check` - Checkmark
  - `x` - Close/cancel
  - `search` - Search
  - `settings` - Settings/gear
  - `user` - User profile
  - `chevron-down` - Dropdown indicator
  - `loader-circle` - Loading spinner (use with `animate-spin`)

  > #### Note {: .info}
  > The `lucide-` prefix is optional. Both `<.icon name="check" />` and
  > `<.icon name="lucide-check" />` work identically.
  """

  use Phoenix.Component

  # Pre-load all icon SVGs at compile time for performance
  @priv_dir :code.priv_dir(:lucide_icons) |> List.to_string()
  @icons_dir Path.join(@priv_dir, "node_modules/lucide-static/icons")

  # Build a map of icon_name (atom) -> svg_content (binary) at compile time
  @icon_svgs @icons_dir
             |> Path.join("*.svg")
             |> Path.wildcard()
             |> Enum.map(fn path ->
               name =
                 path
                 |> Path.basename(".svg")
                 |> String.replace("-", "_")
                 |> String.to_atom()

               svg = File.read!(path)
               {name, svg}
             end)
             |> Map.new()

  @doc """
  Renders a Lucide icon.

  ## Attributes

  * `name` - Required. The Lucide icon name (e.g., `check`, `x`, `chevron-down`)
  * `class` - Additional CSS classes. Defaults to `"size-4"`

  ## Examples

      <.icon name="x" />
      <.icon name="check" class="size-6 text-green-500" />
      <.icon name="alert-triangle" aria-label="Warning" />
  """
  attr(:name, :string, required: true, doc: "The icon name (e.g., 'check', 'x', 'chevron-down')")
  attr(:class, :any, default: "size-4", doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(aria-label aria-hidden title role),
    doc: "Additional HTML attributes"
  )

  def icon(assigns) do
    # Strip "lucide-" prefix if present for backward compatibility
    # Convert to atom format (kebab-case -> snake_case)
    icon_name_str =
      assigns.name
      |> String.replace_prefix("lucide-", "")
      |> String.replace("-", "_")

    # Try to convert to existing atom, return nil if not found
    icon_name =
      try do
        String.to_existing_atom(icon_name_str)
      rescue
        ArgumentError -> nil
      end

    svg = if icon_name, do: Map.get(@icon_svgs, icon_name), else: nil

    if svg do
      # Normalize class to a string - it can be a string, list, or nil
      class = normalize_class(assigns.class)

      # Build attributes map for the SVG
      # If aria-label is provided, the icon is meaningful - don't hide from screen readers
      # Otherwise, default to aria-hidden="true" for decorative icons
      attrs =
        assigns.rest
        |> Map.put(:class, class)
        |> then(fn attrs ->
          if Map.has_key?(attrs, :"aria-label") do
            attrs
          else
            Map.put(attrs, :"aria-hidden", "true")
          end
        end)

      # Use Lucideicons.Icon.insert_attrs to properly merge attributes with SVG
      icon_html = Lucideicons.Icon.insert_attrs(svg, attrs)

      assigns = assign(assigns, :icon_html, icon_html)

      ~H"""
      {@icon_html}
      """
    else
      # Fallback for unknown icons - render a placeholder
      assigns = assign(assigns, :class, normalize_class(assigns.class))

      ~H"""
      <span class={@class} aria-hidden="true">?</span>
      """
    end
  end

  # Normalize class attribute to a string
  # Handles strings, lists (with potential nils), and nil
  defp normalize_class(class) when is_binary(class), do: class
  defp normalize_class(nil), do: "size-4"

  defp normalize_class(class) when is_list(class) do
    class
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end
end
