defmodule SutraUI.Tooltip do
  @moduledoc """
  A popup that displays information related to an element when hovered.

  Supports dynamic positioning that automatically adjusts based on viewport
  boundaries to prevent the tooltip from being clipped.

  ## Examples

      <.tooltip tooltip="Add to library">
        <button class="btn">Hover me</button>
      </.tooltip>

      <.tooltip tooltip="Right side tooltip" side="right">
        <button class="btn">Right</button>
      </.tooltip>

      <.tooltip tooltip="Auto-positions based on space" side="auto">
        <button class="btn">Smart Position</button>
      </.tooltip>

  ## Accessibility

  The tooltip is triggered by both hover and keyboard focus.
  Note: Critical information should not be placed solely in tooltips.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a tooltip component.
  """
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
  attr(:id, :string, required: true, doc: "Unique identifier for the tooltip")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "The element that triggers the tooltip on hover")

  def tooltip(assigns) do
    ~H"""
    <span
      id={@id}
      data-tooltip={@tooltip}
      data-side={@side}
      data-align={@align}
      class={@class}
      phx-hook=".Tooltip"
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>

    <script :type={ColocatedHook} name=".Tooltip">
      export default {
        mounted() {
          // Only enable dynamic positioning for side="auto"
          if (this.el.dataset.side !== 'auto') return;

          this.calculatePosition = () => {
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
          };
          
          this.el.addEventListener('mouseenter', this.calculatePosition);
          this.el.addEventListener('focusin', this.calculatePosition);
        },
        
        destroyed() {
          if (this.calculatePosition) {
            this.el.removeEventListener('mouseenter', this.calculatePosition);
            this.el.removeEventListener('focusin', this.calculatePosition);
          }
        }
      }
    </script>
    """
  end
end
