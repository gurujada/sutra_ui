defmodule PhxUI.Item do
  @moduledoc """
  A versatile list item component for displaying content with icons, avatars, and actions.

  Item is a composition-based component that provides a flexible structure for list items,
  cards, and interactive elements. It supports multiple layouts with leading media (icons,
  avatars, images), content sections, and trailing actions.

  ## Variants

  - `default` - Transparent border, minimal styling
  - `outline` - Visible border for separation
  - `muted` - Subtle background for grouping

  ## Features

  - Multiple HTML element types (article, a, div, button)
  - Support for icons, avatars, and images in leading slot
  - Flexible content layout with title and description
  - Optional trailing actions or indicators
  - Accessible focus states

  ## Examples

      # Basic item with title and description
      <.item>
        <:title>Basic Item</:title>
        <:description>A simple item with title and description.</:description>
      </.item>

      # Item with icon
      <.item variant="outline">
        <:leading>
          <div class="item-icon-box">
            <.icon name="hero-shield-exclamation" />
          </div>
        </:leading>
        <:title>Security Alert</:title>
        <:description>New login detected from unknown device.</:description>
        <:trailing>
          <button class="btn-sm-outline">Review</button>
        </:trailing>
      </.item>

      # Item with avatar
      <.item variant="outline">
        <:leading>
          <img src="https://github.com/user.png" alt="User" class="size-10 rounded-full object-cover" />
        </:leading>
        <:title>Username</:title>
        <:description>Last seen 5 months ago</:description>
        <:trailing>
          <button class="btn-icon-outline rounded-full">
            <.icon name="hero-plus" />
          </button>
        </:trailing>
      </.item>

      # Item as link
      <.item as="a" href="/profile" variant="default">
        <:leading>
          <div class="item-icon-inline">
            <.icon name="hero-check-badge" />
          </div>
        </:leading>
        <:title>Your profile has been verified.</:title>
        <:trailing>
          <.icon name="hero-chevron-right" class="size-4" />
        </:trailing>
      </.item>
  """

  use Phoenix.Component

  @doc """
  Renders an item component.

  ## Attributes

  * `variant` - Visual variant: `default`, `outline`, or `muted`. Defaults to `outline`.
  * `as` - HTML element to render: `article`, `a`, `div`, or `button`. Defaults to `article`.
  * `class` - Additional CSS classes.

  ## Slots

  * `title` - Required. The item title.
  * `description` - Optional description below the title.
  * `leading` - Optional leading content (icon, avatar, image).
  * `trailing` - Optional trailing content (actions, indicators).
  """
  attr(:variant, :string,
    default: "outline",
    values: ~w(default outline muted),
    doc: "Visual variant of the item"
  )

  attr(:as, :string,
    default: "article",
    values: ~w(article a div button),
    doc: "HTML element to render"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  attr(:rest, :global,
    include: ~w(id href target rel role tabindex aria-label aria-current),
    doc: "Additional HTML attributes"
  )

  slot(:leading, doc: "Optional leading content (icon, avatar, image)")

  slot(:title,
    required: true,
    doc: "The item title"
  )

  slot(:description, doc: "Optional description below the title")

  slot(:trailing, doc: "Optional trailing content (actions, indicators)")

  def item(assigns) do
    ~H"""
    <.item_dynamic_tag
      name={@as}
      class={[
        "item",
        variant_class(@variant),
        size_class(@leading, @description, @trailing),
        @class
      ]}
      {@rest}
    >
      <div :if={@leading != []} class="item-leading">
        {render_slot(@leading)}
      </div>

      <div class="item-content">
        <h3 class="item-title">
          {render_slot(@title)}
        </h3>
        <p :if={@description != []} class="item-description">
          {render_slot(@description)}
        </p>
      </div>

      <div :if={@trailing != []} class="item-trailing">
        {render_slot(@trailing)}
      </div>
    </.item_dynamic_tag>
    """
  end

  defp variant_class("default"), do: "item-default"
  defp variant_class("outline"), do: "item-outline"
  defp variant_class("muted"), do: "item-muted"

  defp size_class(leading, description, trailing) do
    if leading == [] and trailing == [] and description == [] do
      "item-compact"
    else
      nil
    end
  end

  # Helper component for dynamic HTML elements
  attr(:name, :string, required: true)
  attr(:class, :any, required: true)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  defp item_dynamic_tag(assigns) do
    ~H"""
    <%= case @name do %>
      <% "a" -> %>
        <a class={@class} {@rest}>
          {render_slot(@inner_block)}
        </a>
      <% "button" -> %>
        <button class={@class} {@rest}>
          {render_slot(@inner_block)}
        </button>
      <% "div" -> %>
        <div class={@class} {@rest}>
          {render_slot(@inner_block)}
        </div>
      <% _ -> %>
        <article class={@class} {@rest}>
          {render_slot(@inner_block)}
        </article>
    <% end %>
    """
  end
end
