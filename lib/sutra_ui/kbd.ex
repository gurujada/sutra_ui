defmodule SutraUI.Kbd do
  @moduledoc """
  Displays keyboard input that triggers an action.

  The `<kbd>` element represents user input from a keyboard, voice input,
  or any other text entry device. Commonly used to display keyboard shortcuts
  or key combinations in documentation and user interfaces.

  ## Examples

      # Single key
      <.kbd>Enter</.kbd>

      # Key combination (render multiple kbd elements)
      <.kbd>Ctrl</.kbd> + <.kbd>C</.kbd>

      # With custom styling
      <.kbd class="text-sm">Esc</.kbd>

      # Common shortcuts
      <.kbd>⌘</.kbd> + <.kbd>K</.kbd>

  ## Accessibility

  - Uses the semantic `<kbd>` HTML element which is recognized by screen readers
  - Screen readers will announce the content as keyboard input
  - When displaying key combinations, use visible separators (like "+") between
    individual `<kbd>` elements for clarity
  - Consider providing additional context for complex shortcuts using `aria-label`
    on a parent container
  """

  use Phoenix.Component

  @doc """
  Renders a keyboard key indicator.

  ## Examples

      <.kbd>Ctrl</.kbd>
      <.kbd>K</.kbd>
  """

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")
  slot(:inner_block, required: true, doc: "The key content")

  def kbd(assigns) do
    ~H"""
    <kbd class={["kbd", @class]} {@rest}>
      {render_slot(@inner_block)}
    </kbd>
    """
  end
end
