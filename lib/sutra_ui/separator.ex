defmodule SutraUI.Separator do
  @moduledoc """
  Visually or semantically separates content.

  The separator renders a themed one-pixel rule for horizontal or vertical
  separation.

  ## Examples

      # Horizontal separator
      <.separator />

      # Vertical separator
      <.separator orientation="vertical" />

      # Semantic separator
      <.separator decorative={false} />

      # Decorative separator, hidden from assistive technology
      <.separator decorative />

  ## Accessibility

  - Decorative by default, matching shadcn/ui
  - Set `decorative={false}` when the separator carries document structure
  - `aria-orientation` is set for semantic vertical separators
  """

  use Phoenix.Component

  @doc """
  Renders a separator component.

  ## Attributes

  * `orientation` - Direction. One of `horizontal`, `vertical`. Defaults to `horizontal`.
  * `decorative` - When true, marks separator as purely visual. Defaults to `true`.
  * `class` - Additional CSS classes.

  ## Examples

      <.separator />
      <.separator orientation="vertical" />
      <.separator decorative={false} />
  """
  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "Direction of the separator"
  )

  attr(:decorative, :boolean,
    default: true,
    doc: "When true, marks the separator as purely visual"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:id, :string,
    default: nil,
    doc: "Unique identifier"
  )

  attr(:rest, :global,
    include: ~w(aria-label aria-labelledby),
    doc: "Additional HTML attributes"
  )

  def separator(assigns) do
    assigns =
      assigns
      |> assign(:role, role_attribute(assigns.decorative))
      |> assign(:aria_hidden, if(assigns.decorative, do: "true"))
      |> assign(:aria_orientation, aria_orientation(assigns.orientation, assigns.decorative))

    ~H"""
    <hr
      id={@id}
      class={separator_class(@class)}
      data-orientation={@orientation}
      role={@role}
      aria-orientation={@aria_orientation}
      aria-hidden={@aria_hidden}
      {@rest}
    />
    """
  end

  defp role_attribute(true), do: "presentation"
  defp role_attribute(false), do: "separator"

  defp aria_orientation("vertical", false), do: "vertical"
  defp aria_orientation(_, _), do: nil

  defp separator_class(nil), do: "separator"
  defp separator_class(extra), do: ["separator", extra]
end
