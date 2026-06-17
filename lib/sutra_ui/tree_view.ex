defmodule SutraUI.TreeView do
  @moduledoc """
  A hierarchical tree for nested navigation, file browsers, or category structures.

  Uses native `<details>`/`<summary>` elements for dependency-free expand/collapse
  while exposing WAI-ARIA tree roles. Each node can be a folder (collapsible) or
  a leaf (clickable link or plain item). You control the content via inner_block.

  ## Examples

      <.tree_view>
        <.tree_item label="assets" expanded>
          <.tree_item label="css">
            <.tree_item label="main.css" href="/files/main.css" />
          </.tree_item>
          <.tree_item label="img">
            <.tree_item label="hero.jpg" href="/files/hero.jpg" />
          </.tree_item>
        </.tree_item>
        <.tree_item label="src" selected>
          <.tree_item label="app.ex" href="/files/app.ex" />
        </.tree_item>
        <.tree_item label="README.md" href="/files/README.md" />
      </.tree_view>
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

  attr(:label, :string, default: nil, doc: "Node label")
  attr(:expanded, :boolean, default: false, doc: "Expand child nodes by default")
  attr(:selected, :boolean, default: false, doc: "Mark node selected")
  attr(:disabled, :boolean, default: false, doc: "Mark node disabled")
  attr(:href, :string, default: nil, doc: "Optional href for leaf nodes")
  attr(:icon, :string, default: nil, doc: "Custom text/emoji icon for the node")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global)

  slot(:trigger, doc: "Custom trigger content")
  slot(:inner_block, doc: "Child tree items")

  def tree_item(assigns) do
    has_children = assigns.inner_block != []
    assigns = assign(assigns, :has_children, has_children)

    ~H"""
    <details
      :if={@has_children}
      class={["tree-item", @class]}
      open={@expanded}
      role="treeitem"
      aria-selected={to_attr(@selected)}
      aria-disabled={to_attr(@disabled)}
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
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
          <span class="tree-item-label">{@label}</span>
        <% end %>
      </summary>
      <div class="tree-group" role="group">
        {render_slot(@inner_block)}
      </div>
    </details>
    <div
      :if={!@has_children}
      class={["tree-item tree-item-leaf", @class]}
      role="treeitem"
      aria-selected={to_attr(@selected)}
      aria-disabled={to_attr(@disabled)}
      {@rest}
    >
      <a :if={@href} href={@href} class="tree-item-trigger">
        <span class="tree-item-spacer" aria-hidden="true"></span>
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
          <span class="tree-item-label">{@label}</span>
        <% end %>
      </a>
      <span :if={!@href} class="tree-item-trigger">
        <span class="tree-item-spacer" aria-hidden="true"></span>
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
          <span class="tree-item-label">{@label}</span>
        <% end %>
      </span>
    </div>
    """
  end

  defp to_attr(true), do: "true"
  defp to_attr(false), do: "false"
end
