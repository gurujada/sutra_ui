defmodule SutraUI.HoverCard do
  @moduledoc """
  A rich preview card that appears on hover or keyboard focus.

  Composes a trigger with a floating content card. Shows on hover after a
  configurable delay, hides after a close delay. Useful for user profiles,
  item previews, or any contextual detail that shouldn't require a click.

  Reuses the shared `[data-popover]` positioning system — same `data-side` and
  `data-align` semantics as `Popover` and `Tooltip`.

  ## Examples

      <.hover_card id="user-card">
        <:trigger>
          <.button variant="link">@jane</.button>
        </:trigger>
        <div class="flex items-center gap-3">
          <.avatar src="/jane.jpg" initials="JC" />
          <div>
            <p class="font-medium">Jane Cooper</p>
            <p class="text-sm text-muted-foreground">@jane · Designer</p>
          </div>
        </div>
      </.hover_card>

      <.hover_card id="release-card" side="top" align="start">
        <:trigger>Release notes</:trigger>
        <div>
          <p class="font-medium">v0.4.0</p>
          <p class="text-sm text-muted-foreground">New display primitives.</p>
        </div>
      </.hover_card>

  ## Attributes

  * `id` - Required. Unique identifier.
  * `side` - Side to place the card: `top`, `bottom`, `left`, `right`, or `auto`
    (dynamic viewport-aware placement). Defaults to `bottom`.
  * `align` - Alignment relative to the trigger: `start`, `center`, `end`.
    Defaults to `center`.
  * `open_delay` - Open delay in milliseconds. Defaults to `150`.
  * `close_delay` - Close delay in milliseconds. Defaults to `100`.
  * `class` - Additional CSS classes for the content card.

  ## Slots

  * `:trigger` - Required. The hover/focus target.
  * `:inner_block` - Required. The hover card content.

  ## Accessibility

  - The trigger sets `aria-expanded` and `aria-describedby` linking to the card.
  - The card uses `role="tooltip"` for non-modal descriptive preview content and
    toggles `aria-hidden`.
  - Opens on both `mouseenter` and `focusin` — keyboard users get the same
    preview as mouse users.
  - Escape key closes the card.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the hover card")

  attr(:side, :string,
    default: "bottom",
    values: ~w(top bottom left right auto),
    doc: "Side to place the card — `auto` enables viewport-aware placement"
  )

  attr(:align, :string,
    default: "center",
    values: ~w(start center end),
    doc: "Alignment relative to the trigger"
  )

  attr(:open_delay, :integer, default: 150, doc: "Open delay in milliseconds")
  attr(:close_delay, :integer, default: 100, doc: "Close delay in milliseconds")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for the content card")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "Trigger content (hover/focus target)")
  slot(:inner_block, required: true, doc: "Hover card content")

  def hover_card(assigns) do
    ~H"""
    <div
      id={@id}
      class="hover-card"
      data-open-delay={@open_delay}
      data-close-delay={@close_delay}
      phx-hook=".HoverCard"
      {@rest}
    >
      <span
        id={"#{@id}-trigger"}
        class="hover-card-trigger"
        aria-describedby={"#{@id}-content"}
        aria-expanded="false"
      >
        {render_slot(@trigger)}
      </span>
      <div
        id={"#{@id}-content"}
        class={["hover-card-content", @class]}
        data-popover
        data-side={@side}
        data-align={@align}
        role="tooltip"
        aria-hidden="true"
      >
        {render_slot(@inner_block)}
      </div>
    </div>

    <script :type={ColocatedHook} name=".HoverCard" runtime>
      {
        mounted() {
          this.trigger = this.el.querySelector('.hover-card-trigger');
          this.content = this.el.querySelector('.hover-card-content');
          this.openDelay = Number(this.el.dataset.openDelay || 150);
          this.closeDelay = Number(this.el.dataset.closeDelay || 100);
          this.focusableSelector = 'a,button,input,select,textarea,[tabindex]:not([tabindex="-1"])';
          if (!this.trigger.querySelector(this.focusableSelector)) {
            this.trigger.setAttribute('tabindex', '0');
          }

          this.open = () => {
            clearTimeout(this.closeTimer);
            this.openTimer = setTimeout(() => {
              this.trigger.setAttribute('aria-expanded', 'true');
              this.content.setAttribute('aria-hidden', 'false');
              if (this.content.dataset.side === 'auto') this.calculatePosition();
            }, this.openDelay);
          };

          this.close = () => {
            clearTimeout(this.openTimer);
            this.closeTimer = setTimeout(() => {
              this.trigger.setAttribute('aria-expanded', 'false');
              this.content.setAttribute('aria-hidden', 'true');
            }, this.closeDelay);
          };

          this.handleEscape = (e) => {
            if (e.key === 'Escape' && this.content.getAttribute('aria-hidden') === 'false') {
              this.close();
            }
          };

          this.el.addEventListener('mouseenter', this.open);
          this.el.addEventListener('mouseleave', this.close);
          this.el.addEventListener('focusin', this.open);
          this.el.addEventListener('focusout', this.close);
          this.el.addEventListener('keydown', this.handleEscape);
        },

        destroyed() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          this.el.removeEventListener('mouseenter', this.open);
          this.el.removeEventListener('mouseleave', this.close);
          this.el.removeEventListener('focusin', this.open);
          this.el.removeEventListener('focusout', this.close);
          this.el.removeEventListener('keydown', this.handleEscape);
        },

        calculatePosition() {
          const rect = this.trigger.getBoundingClientRect();
          const contentHeight = this.content.offsetHeight;
          const contentWidth = this.content.offsetWidth;
          const padding = 8;

          const spaceTop = rect.top;
          const spaceBottom = window.innerHeight - rect.bottom;
          const spaceLeft = rect.left;
          const spaceRight = window.innerWidth - rect.right;

          let side = 'bottom';

          if (spaceBottom >= contentHeight + padding) {
            side = 'bottom';
          } else if (spaceTop >= contentHeight + padding) {
            side = 'top';
          } else if (spaceRight >= contentWidth + padding) {
            side = 'right';
          } else if (spaceLeft >= contentWidth + padding) {
            side = 'left';
          }

          this.content.setAttribute('data-side', side);
        }
      }
    </script>
    """
  end
end
