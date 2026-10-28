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

      <.carousel id="card-carousel" show_indicators={false} gap="gap-4" loop>
        <:item>
          <div class="card">Card 1</div>
        </:item>
        <:item>
          <div class="card">Card 2</div>
        </:item>
      </.carousel>

      <.carousel id="sized-carousel" width="w-96" height="h-72">
        <:item>Slide 1</:item>
        <:item>Slide 2</:item>
      </.carousel>

      <.carousel id="product-carousel" item_class="w-full md:w-1/2 lg:w-1/3">
        <:item :for={product <- @products}>
          <.product_card product={product} />
        </:item>
      </.carousel>

  ## Accessibility

  - Uses semantic HTML structure with ARIA roles
  - `aria-live="polite"` announces slide changes to screen readers
  - Carousel items can be navigated via scroll
  - Indicators provide visual feedback for current position
  - Works with keyboard navigation (arrow keys when focused)
  - Each slide has `aria-roledescription="slide"` for clarity
  """

  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a carousel component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the carousel")
  attr(:show_indicators, :boolean, default: true, doc: "Whether to show navigation indicators")
  attr(:show_arrows, :boolean, default: true, doc: "Whether to show prev/next arrow buttons")
  attr(:loop, :boolean, default: false, doc: "Whether to loop back to first slide after last")
  attr(:item_class, :string, default: nil, doc: "Additional CSS classes for each carousel item")

  attr(:gap, :string,
    default: nil,
    doc:
      "Tailwind gap class between items (e.g., 'gap-4'). A CSS length ('1rem') still works as an inline style but is deprecated and goes away in 0.5; it needs `style-src 'unsafe-inline'`"
  )

  attr(:width, :string,
    default: nil,
    doc: "Tailwind width class (e.g., 'w-96'). A CSS length ('400px') is deprecated like `gap`"
  )

  attr(:height, :string,
    default: nil,
    doc: "Tailwind height class (e.g., 'h-72'). A CSS length ('300px') is deprecated like `gap`"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes for the carousel container")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :item, required: true, doc: "Carousel items" do
    attr(:class, :string, doc: "Additional CSS classes for this specific item")
  end

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script")

  def carousel(assigns) do
    item_count = length(assigns.item)
    assigns = assign(assigns, :item_count, item_count)

    ~H"""
    <div
      id={@id}
      class={["carousel", SutraUI.Dimension.classes([@width, @height]), @class]}
      phx-hook=".Carousel"
      data-loop={@loop}
      {SutraUI.Dimension.style_attr(width: @width, height: @height)}
      {@rest}
    >
      <div
        class={["carousel-viewport", SutraUI.Dimension.classes([@gap])]}
        {SutraUI.Dimension.style_attr(gap: @gap)}
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
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-6"
          aria-hidden="true"
        >
          <path d="m15 18-6-6 6-6" />
        </svg>
      </button>

      <button
        :if={@show_arrows && @item_count > 1}
        type="button"
        class="carousel-next"
        aria-label="Next slide"
        data-carousel-next
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-6"
          aria-hidden="true"
        >
          <path d="m9 18 6-6-6-6" />
        </svg>
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

      <div
        id={"#{@id}-live-region"}
        class="sr-only"
        aria-live="polite"
        aria-atomic="true"
        data-carousel-live-region
      >
        Slide 1 of {@item_count}
      </div>
    </div>

    <script :type={ColocatedHook} name=".Carousel" runtime nonce={@nonce}>
      {
        mounted() {
          this.viewport = this.el.querySelector('.carousel-viewport');
          this.items = Array.from(this.el.querySelectorAll('[data-carousel-item]'));
          this.indicators = Array.from(this.el.querySelectorAll('[data-carousel-indicator]'));
          this.prevBtn = this.el.querySelector('[data-carousel-prev]');
          this.nextBtn = this.el.querySelector('[data-carousel-next]');
          this.liveRegion = this.el.querySelector('[data-carousel-live-region]');
          this.currentIndex = 0;
          this.loop = this.el.dataset.loop === 'true';
          this.indicatorHandlers = [];
          
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
            const handler = () => this.scrollToItem(index);
            this.indicatorHandlers.push({ indicator, handler });
            indicator.addEventListener('click', handler);
          });
          
          // Arrow button clicks
          this.prevHandler = () => this.prev();
          this.nextHandler = () => this.next();
          if (this.prevBtn) {
            this.prevBtn.addEventListener('click', this.prevHandler);
          }
          if (this.nextBtn) {
            this.nextBtn.addEventListener('click', this.nextHandler);
          }
          
          // Keyboard navigation
          this.keydownHandler = (e) => this.handleKeydown(e);
          this.viewport.addEventListener('keydown', this.keydownHandler);
          
          // Initial button state
          this.updateButtonStates();
        },
        
        destroyed() {
          if (this.observer) {
            this.observer.disconnect();
          }
          this.indicatorHandlers?.forEach(({ indicator, handler }) => {
            indicator.removeEventListener('click', handler);
          });
          this.indicatorHandlers = [];
          this.prevBtn?.removeEventListener('click', this.prevHandler);
          this.nextBtn?.removeEventListener('click', this.nextHandler);
          this.viewport?.removeEventListener('keydown', this.keydownHandler);
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

          // Update live region to announce slide change
          if (this.liveRegion) {
            this.liveRegion.textContent = `Slide ${index + 1} of ${this.items.length}`;
          }

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
