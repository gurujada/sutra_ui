defmodule SutraUI.TreeView do
  @moduledoc """
  A hierarchical tree for nested navigation or file structures.

  Tree View uses native `details` and `summary` elements for dependency-free
  disclosure while exposing WAI-ARIA tree roles and Sutra UI styling hooks.
  """

  use Phoenix.Component

  attr(:label, :string, default: "Tree view", doc: "Accessible label")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id), doc: "Additional HTML attributes")

  slot(:inner_block, required: true)

  def tree_view(assigns) do
    ~H"""
    <div class={["tree-view", @class]} role="tree" aria-label={@label} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:label, :string, required: true, doc: "Node label")
  attr(:expanded, :boolean, default: false, doc: "Expand child nodes by default")
  attr(:selected, :boolean, default: false, doc: "Mark node selected")
  attr(:disabled, :boolean, default: false, doc: "Mark node disabled")
  attr(:icon, :string, default: nil, doc: "Optional text icon")
  attr(:href, :string, default: nil, doc: "Optional href for leaf nodes")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global)

  slot(:inner_block)

  def tree_item(assigns) do
    ~H"""
    <details
      :if={@inner_block != []}
      class={["tree-item", @class]}
      open={@expanded}
      role="treeitem"
      aria-selected={bool_string(@selected)}
      aria-disabled={@disabled}
      {@rest}
    >
      <summary class="tree-item-trigger">
        <span class="tree-item-chevron" aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m9 18 6-6-6-6" />
          </svg>
        </span>
        <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
        <span class="tree-item-label">{@label}</span>
      </summary>
      <div class="tree-group" role="group">
        {render_slot(@inner_block)}
      </div>
    </details>
    <div
      :if={@inner_block == []}
      class={["tree-item tree-item-leaf", @class]}
      role="treeitem"
      aria-selected={bool_string(@selected)}
      aria-disabled={@disabled}
      {@rest}
    >
      <a :if={@href} href={@href} class="tree-item-trigger">
        <span class="tree-item-spacer" aria-hidden="true"></span>
        <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
        <span class="tree-item-label">{@label}</span>
      </a>
      <span :if={!@href} class="tree-item-trigger">
        <span class="tree-item-spacer" aria-hidden="true"></span>
        <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
        <span class="tree-item-label">{@label}</span>
      </span>
    </div>
    """
  end

  defp bool_string(true), do: "true"
  defp bool_string(false), do: "false"
end
