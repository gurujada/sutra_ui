defmodule SutraUI.Tooltip do
  @moduledoc """
  A popup that displays information related to an element when hovered.

  Supports dynamic positioning that automatically adjusts based on viewport
  boundaries to prevent the tooltip from being clipped.

  ## Examples

      <.tooltip id="add-btn-tip" tooltip="Add to library">
        <button class="btn">Hover me</button>
      </.tooltip>

      <.tooltip id="right-tip" tooltip="Right side tooltip" side="right">
        <button class="btn">Right</button>
      </.tooltip>

      <.tooltip id="auto-tip" tooltip="Auto-positions based on space" side="auto">
        <button class="btn">Smart Position</button>
      </.tooltip>

  ## Accessibility

  - The tooltip is triggered by both hover and keyboard focus
  - Uses `aria-describedby` to associate the tooltip with the trigger element
  - Uses `role="tooltip"` on the tooltip content
  - Screen readers announce the tooltip content when focus enters the trigger
  - Note: Critical information should not be placed solely in tooltips
  """

  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a tooltip component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the tooltip")
  attr(:tooltip, :string, required: true, doc: "The text content to display in the tooltip")

  attr(:side, :string,
    default: "auto",
    values: ~w(top bottom left right auto),
    doc: "The side to position the tooltip (auto for dynamic positioning)"
  )

  attr(:align, :string,
    default: "center",
    values: ~w(start center end),
    doc: "The alignment of the tooltip"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "The element that triggers the tooltip on hover")

  def tooltip(assigns) do
    ~H"""
    <span
      id={@id}
      data-side={@side}
      data-align={@align}
      class={["tooltip-trigger", @class]}
      phx-hook=".Tooltip"
      {@rest}
    >
      <span aria-describedby={"#{@id}-content"}>
        {render_slot(@inner_block)}
      </span>
      <span
        id={"#{@id}-content"}
        role="tooltip"
        class="tooltip-content"
        aria-hidden="true"
      >
        {@tooltip}
      </span>
    </span>

    <script :type={ColocatedHook} name=".Tooltip" runtime>
      {
        mounted() {
          this.tooltipContent = this.el.querySelector('[role="tooltip"]');

          // Show/hide tooltip and update aria-hidden
          this.showTooltip = () => {
            this.calculatePosition();
            this.tooltipContent.setAttribute('aria-hidden', 'false');
          };

          this.hideTooltip = () => {
            this.tooltipContent.setAttribute('aria-hidden', 'true');
          };

          this.el.addEventListener('mouseenter', this.showTooltip);
          this.el.addEventListener('mouseleave', this.hideTooltip);
          this.el.addEventListener('focusin', this.showTooltip);
          this.el.addEventListener('focusout', this.hideTooltip);

          // Handle Escape key to close tooltip
          this.handleEscape = (e) => {
            if (e.key === 'Escape' && this.tooltipContent.getAttribute('aria-hidden') === 'false') {
              this.hideTooltip();
            }
          };
          this.el.addEventListener('keydown', this.handleEscape);
        },

        destroyed() {
          this.el.removeEventListener('mouseenter', this.showTooltip);
          this.el.removeEventListener('mouseleave', this.hideTooltip);
          this.el.removeEventListener('focusin', this.showTooltip);
          this.el.removeEventListener('focusout', this.hideTooltip);
          this.el.removeEventListener('keydown', this.handleEscape);
        },

        calculatePosition() {
          // Only enable dynamic positioning for side="auto"
          if (this.el.dataset.side !== 'auto') return;

          const rect = this.el.getBoundingClientRect();

          // Check available space on each side
          const spaceTop = rect.top;
          const spaceBottom = window.innerHeight - rect.bottom;
          const spaceLeft = rect.left;
          const spaceRight = window.innerWidth - rect.right;

          // Prefer top, then bottom, then right, then left
          let side = 'top';
          if (spaceTop < 50 && spaceBottom > spaceTop) {
            side = 'bottom';
          } else if (spaceTop < 50 && spaceBottom < 50) {
            side = spaceRight > spaceLeft ? 'right' : 'left';
          }

          this.el.setAttribute('data-computed-side', side);
        }
      }
    </script>
    """
  end
end
