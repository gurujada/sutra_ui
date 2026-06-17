defmodule SutraUI.HoverCard do
  @moduledoc """
  A rich preview card that appears on hover or focus.

  Composes a trigger with a floating content card. Shows on hover after
  a configurable delay, hides after a close delay. Useful for user profiles,
  item previews, or any contextual detail that shouldn't require a click.

  ## Examples

      <.hover_card id="user-card">
        <:trigger>
          <.button variant="link">@jane</.button>
        </:trigger>
        <div class="flex items-center gap-3">
          <.avatar src="/jane.jpg" fallback="JC" />
          <div>
            <p class="font-medium">Jane Cooper</p>
            <p class="text-sm text-muted-foreground">@jane · Designer</p>
          </div>
        </div>
      </.hover_card>
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:id, :string, required: true, doc: "Unique identifier for the hover card")

  attr(:side, :string,
    default: "bottom",
    values: ~w(top bottom left right),
    doc: "Side to place the card"
  )

  attr(:align, :string,
    default: "center",
    values: ~w(start center end),
    doc: "Alignment relative to the trigger"
  )

  attr(:side_offset, :integer, default: 4, doc: "Pixel offset from the trigger side")
  attr(:align_offset, :integer, default: 0, doc: "Pixel offset along the trigger axis")
  attr(:open_delay, :integer, default: 150, doc: "Open delay in milliseconds")
  attr(:close_delay, :integer, default: 100, doc: "Close delay in milliseconds")
  attr(:class, :any, default: nil, doc: "Additional CSS classes for the content card")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "Trigger content (hover target)")
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
        data-side-offset={@side_offset}
        data-align-offset={@align_offset}
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

          this.open = () => {
            clearTimeout(this.closeTimer);
            this.openTimer = setTimeout(() => {
              this.trigger.setAttribute('aria-expanded', 'true');
              this.content.setAttribute('aria-hidden', 'false');
            }, this.openDelay);
          };

          this.close = () => {
            clearTimeout(this.openTimer);
            this.closeTimer = setTimeout(() => {
              this.trigger.setAttribute('aria-expanded', 'false');
              this.content.setAttribute('aria-hidden', 'true');
            }, this.closeDelay);
          };

          this.el.addEventListener('mouseenter', this.open);
          this.el.addEventListener('mouseleave', this.close);
          this.el.addEventListener('focusin', this.open);
          this.el.addEventListener('focusout', this.close);
        },

        destroyed() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          this.el.removeEventListener('mouseenter', this.open);
          this.el.removeEventListener('mouseleave', this.close);
          this.el.removeEventListener('focusin', this.open);
          this.el.removeEventListener('focusout', this.close);
        }
      }
    </script>
    """
  end
end
