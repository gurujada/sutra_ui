defmodule PhxUI.Carousel do
  @moduledoc """
  A CSS-only carousel component using scroll-snap for smooth navigation.

  This carousel uses native CSS scroll-snap for smooth, performant scrolling
  without requiring JavaScript for basic functionality. Indicators use anchor
  links for navigation.

  ## Examples

      <.carousel id="image-carousel">
        <:item>
          <img src="/images/slide1.jpg" alt="Slide 1" />
        </:item>
        <:item>
          <img src="/images/slide2.jpg" alt="Slide 2" />
        </:item>
        <:item>
          <img src="/images/slide3.jpg" alt="Slide 3" />
        </:item>
      </.carousel>

      <.carousel id="card-carousel" show_indicators={false} gap="1rem">
        <:item>
          <div class="card">Card 1</div>
        </:item>
        <:item>
          <div class="card">Card 2</div>
        </:item>
      </.carousel>

      <.carousel id="product-carousel" item_class="w-full md:w-1/2 lg:w-1/3">
        <:item :for={product <- @products}>
          <.product_card product={product} />
        </:item>
      </.carousel>

  ## Accessibility

  - Uses semantic HTML structure
  - Carousel items can be navigated via scroll
  - Indicators provide visual feedback for current position
  - Works with keyboard navigation (arrow keys when focused)
  """

  use Phoenix.Component

  @doc """
  Renders a carousel component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the carousel")
  attr(:show_indicators, :boolean, default: true, doc: "Whether to show navigation indicators")
  attr(:item_class, :string, default: nil, doc: "Additional CSS classes for each carousel item")
  attr(:gap, :string, default: nil, doc: "Gap between items (CSS value, e.g., '1rem', '16px')")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the carousel container")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :item, required: true, doc: "Carousel items" do
    attr(:class, :string, doc: "Additional CSS classes for this specific item")
  end

  def carousel(assigns) do
    item_count = length(assigns.item)
    assigns = assign(assigns, :item_count, item_count)

    ~H"""
    <div id={@id} class={["carousel", @class]} {@rest}>
      <div
        class="carousel-viewport"
        style={@gap && "gap: #{@gap};"}
        tabindex="0"
        role="region"
        aria-label="Carousel"
        aria-roledescription="carousel"
      >
        <%= for {item, index} <- Enum.with_index(@item) do %>
          <div
            id={"#{@id}-item-#{index}"}
            class={["carousel-item", @item_class, item[:class]]}
            role="group"
            aria-roledescription="slide"
            aria-label={"Slide #{index + 1} of #{@item_count}"}
          >
            {render_slot([item])}
          </div>
        <% end %>
      </div>

      <div :if={@show_indicators && @item_count > 1} class="carousel-indicators" role="tablist">
        <%= for index <- 0..(@item_count - 1) do %>
          <a
            href={"##{@id}-item-#{index}"}
            class={["carousel-indicator", index == 0 && "carousel-indicator-active"]}
            role="tab"
            aria-label={"Go to slide #{index + 1}"}
            aria-selected={if index == 0, do: "true", else: "false"}
          />
        <% end %>
      </div>
    </div>
    """
  end
end
