defmodule SutraUI.Item do
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
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="M12 8v4"/><path d="M12 16h.01"/></svg>
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
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
          </button>
        </:trailing>
      </.item>

      # Item as link
      <.item as="a" href="/profile" variant="default">
        <:leading>
          <div class="item-icon-inline">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/><path d="m9 12 2 2 4-4"/></svg>
          </div>
        </:leading>
        <:title>Your profile has been verified.</:title>
        <:trailing>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4"><path d="m9 18 6-6-6-6"/></svg>
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
