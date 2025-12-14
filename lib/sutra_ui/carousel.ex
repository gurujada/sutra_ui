defmodule SutraUI.Carousel do
  @moduledoc """
  A carousel component using scroll-snap for smooth navigation.

  This carousel uses native CSS scroll-snap for smooth, performant scrolling.
  Indicators provide navigation and show current position.

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

      <.carousel id="card-carousel" show_indicators={false} gap="1rem" loop>
        <:item>
          <div class="card">Card 1</div>
        </:item>
        <:item>
          <div class="card">Card 2</div>
        </:item>
      </.carousel>

      <.carousel id="sized-carousel" width="400px" height="300px">
        <:item>Slide 1</:item>
        <:item>Slide 2</:item>
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
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a carousel component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the carousel")
  attr(:show_indicators, :boolean, default: true, doc: "Whether to show navigation indicators")
  attr(:show_arrows, :boolean, default: true, doc: "Whether to show prev/next arrow buttons")
  attr(:loop, :boolean, default: false, doc: "Whether to loop back to first slide after last")
  attr(:item_class, :string, default: nil, doc: "Additional CSS classes for each carousel item")
  attr(:gap, :string, default: nil, doc: "Gap between items (CSS value, e.g., '1rem', '16px')")

  attr(:width, :string,
    default: nil,
    doc: "Width of the carousel (CSS value, e.g., '400px', '100%')"
  )

  attr(:height, :string,
    default: nil,
    doc: "Height of the carousel (CSS value, e.g., '300px', 'auto')"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes for the carousel container")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :item, required: true, doc: "Carousel items" do
    attr(:class, :string, doc: "Additional CSS classes for this specific item")
  end

  def carousel(assigns) do
    item_count = length(assigns.item)
    assigns = assign(assigns, :item_count, item_count)

    style =
      [
        assigns.width && "width: #{assigns.width}",
        assigns.height && "height: #{assigns.height}"
      ]
      |> Enum.filter(& &1)
      |> Enum.join("; ")

    assigns = assign(assigns, :container_style, if(style != "", do: style, else: nil))

    ~H"""
    <div
      id={@id}
      class={["carousel", @class]}
      phx-hook=".Carousel"
      data-loop={@loop}
      style={@container_style}
      {@rest}
    >
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
            data-carousel-item={index}
            class={["carousel-item", @item_class, item[:class]]}
            role="group"
            aria-roledescription="slide"
            aria-label={"Slide #{index + 1} of #{@item_count}"}
          >
            {render_slot([item])}
          </div>
        <% end %>
      </div>

      <button
        :if={@show_arrows && @item_count > 1}
        type="button"
        class="carousel-prev"
        aria-label="Previous slide"
        data-carousel-prev
        disabled={!@loop}
      >
        <.icon name="lucide-chevron-left" class="size-6" />
      </button>

      <button
        :if={@show_arrows && @item_count > 1}
        type="button"
        class="carousel-next"
        aria-label="Next slide"
        data-carousel-next
      >
        <.icon name="lucide-chevron-right" class="size-6" />
      </button>

      <div :if={@show_indicators && @item_count > 1} class="carousel-indicators" role="tablist">
        <%= for index <- 0..(@item_count - 1) do %>
          <button
            type="button"
            data-carousel-indicator={index}
            class={["carousel-indicator", index == 0 && "carousel-indicator-active"]}
            role="tab"
            aria-label={"Go to slide #{index + 1}"}
            aria-selected={if index == 0, do: "true", else: "false"}
          />
        <% end %>
      </div>
    </div>

    <script :type={ColocatedHook} name=".Carousel" runtime>
      {
        mounted() {
          this.viewport = this.el.querySelector('.carousel-viewport');
          this.items = Array.from(this.el.querySelectorAll('[data-carousel-item]'));
          this.indicators = Array.from(this.el.querySelectorAll('[data-carousel-indicator]'));
          this.prevBtn = this.el.querySelector('[data-carousel-prev]');
          this.nextBtn = this.el.querySelector('[data-carousel-next]');
          this.currentIndex = 0;
          this.loop = this.el.dataset.loop === 'true';
          
          // Set up intersection observer for indicators
          if (this.indicators.length > 0 || this.prevBtn || this.nextBtn) {
            this.observer = new IntersectionObserver(
              (entries) => this.handleIntersection(entries),
              {
                root: this.viewport,
                threshold: 0.5
              }
            );
            
            this.items.forEach(item => this.observer.observe(item));
          }
          
          // Indicator clicks
          this.indicators.forEach((indicator, index) => {
            indicator.addEventListener('click', () => this.scrollToItem(index));
          });
          
          // Arrow button clicks
          if (this.prevBtn) {
            this.prevBtn.addEventListener('click', () => this.prev());
          }
          if (this.nextBtn) {
            this.nextBtn.addEventListener('click', () => this.next());
          }
          
          // Keyboard navigation
          this.viewport.addEventListener('keydown', (e) => this.handleKeydown(e));
          
          // Initial button state
          this.updateButtonStates();
        },
        
        destroyed() {
          if (this.observer) {
            this.observer.disconnect();
          }
        },
        
        handleIntersection(entries) {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              const index = parseInt(entry.target.dataset.carouselItem, 10);
              this.setActiveIndicator(index);
            }
          });
        },
        
        setActiveIndicator(index) {
          this.currentIndex = index;
          
          this.indicators.forEach((indicator, i) => {
            const isActive = i === index;
            indicator.classList.toggle('carousel-indicator-active', isActive);
            indicator.setAttribute('aria-selected', String(isActive));
          });
          
          this.updateButtonStates();
        },
        
        updateButtonStates() {
          if (!this.loop) {
            if (this.prevBtn) {
              this.prevBtn.disabled = this.currentIndex === 0;
            }
            if (this.nextBtn) {
              this.nextBtn.disabled = this.currentIndex === this.items.length - 1;
            }
          }
        },
        
        scrollToItem(index) {
          const item = this.items[index];
          if (item) {
            item.scrollIntoView({
              behavior: 'smooth',
              block: 'nearest',
              inline: 'start'
            });
          }
        },
        
        prev() {
          if (this.currentIndex > 0) {
            this.scrollToItem(this.currentIndex - 1);
          } else if (this.loop) {
            this.scrollToItem(this.items.length - 1);
          }
        },
        
        next() {
          if (this.currentIndex < this.items.length - 1) {
            this.scrollToItem(this.currentIndex + 1);
          } else if (this.loop) {
            this.scrollToItem(0);
          }
        },
        
        handleKeydown(e) {
          switch(e.key) {
            case 'ArrowLeft':
              e.preventDefault();
              this.prev();
              break;
            case 'ArrowRight':
              e.preventDefault();
              this.next();
              break;
            case 'Home':
              e.preventDefault();
              this.scrollToItem(0);
              break;
            case 'End':
              e.preventDefault();
              this.scrollToItem(this.items.length - 1);
              break;
          }
        }
      }
    </script>
    """
  end
end
