defmodule SutraUI.Separator do
  @moduledoc """
  Visually or semantically separates content with a themed one-pixel rule.

  Renders a `<hr>` by default — semantically correct for horizontal dividers and
  natively understood by assistive technology. For vertical separators inside
  flex containers, set `orientation="vertical"`.

  Matches the shadcn/ui Separator API: decorative by default, with an opt-in
  semantic mode for separators that carry document structure.

  ## Examples

      # Horizontal separator (decorative by default)
      <.separator />

      # Vertical separator — needs a container with an explicit height
      <div class="flex h-5 items-center gap-4">
        <span>Blog</span>
        <.separator orientation="vertical" />
        <span>Docs</span>
      </div>

      # Semantic separator (carries document structure)
      <.separator decorative={false} aria-label="End of account section" />

      # "Or" divider between two separators
      <div class="flex items-center gap-4">
        <.separator class="flex-1" />
        <span class="text-xs text-muted-foreground">OR</span>
        <.separator class="flex-1" />
      </div>

  ## Attributes

  * `orientation` - Direction. One of `horizontal`, `vertical`. Defaults to `horizontal`.
  * `decorative` - When true (default), the separator is hidden from assistive
    technology via `role="presentation"` and `aria-hidden`. Set to `false` when
    the separator carries structural meaning.
  * `class` - Additional CSS classes.
  * `id` - Optional unique identifier.

  ## Accessibility

  - Decorative by default (`role="presentation"`, `aria-hidden="true"`) — matches
    shadcn/ui so screen readers don't announce purely visual rules.
  - Set `decorative={false}` when the separator represents a real thematic break
    in the document; it then exposes `role="separator"` and `aria-orientation`.
  - Vertical separators that are semantic also set `aria-orientation="vertical"`.
  """

  use Phoenix.Component

  @doc """
  Renders a separator component.

  ## Examples

      <.separator />
      <.separator orientation="vertical" />
      <.separator decorative={false} aria-label="Section boundary" />
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
    doc: "Optional unique identifier"
  )

  attr(:rest, :global,
    include: ~w(aria-label aria-labelledby),
    doc: "Additional HTML attributes"
  )

  def separator(assigns) do
    assigns =
      assigns
      |> assign(:role, if(assigns.decorative, do: "presentation", else: "separator"))
      |> assign(:aria_hidden, if(assigns.decorative, do: "true"))
      |> assign(
        :aria_orientation,
        if(assigns.orientation == "vertical" and not assigns.decorative, do: "vertical")
      )
      |> assign(:classes, if(assigns.class, do: ["separator", assigns.class], else: "separator"))

    ~H"""
    <hr
      id={@id}
      class={@classes}
      data-orientation={@orientation}
      role={@role}
      aria-orientation={@aria_orientation}
      aria-hidden={@aria_hidden}
      {@rest}
    />
    """
  end
end
