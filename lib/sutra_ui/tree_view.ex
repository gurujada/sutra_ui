defmodule SutraUI.TreeView do
  @moduledoc """
  A hierarchical tree for nested navigation, file browsers, or category
  structures.

  Uses native `<details>`/`<summary>` elements for a dependency-free
  expand/collapse baseline. Pass an `id` to enable the colocated JS enhancement:
  roving tabindex, arrow-key navigation, and `aria-expanded` management.

  Each node can be a folder (collapsible) or a leaf (clickable link or
  selectable item). You control the content via the `:trigger` slot or the
  `label`/`icon` attrs.

  ## Examples

      <.tree_view label="Project files">
        <.tree_item label="lib" expanded>
          <.tree_item label="sutra_ui" expanded>
            <.tree_item label="button.ex" href="/files/button.ex" />
            <.tree_item label="calendar.ex" selected />
          </.tree_item>
        </.tree_item>
        <.tree_item label="README.md" href="/files/README.md" />
      </.tree_view>

      # Interactive selection — emit an event when a leaf is clicked
      <.tree_view id="settings-tree" label="Settings" select_event="select_node">
        <.tree_item label="Workspace" expanded value="ws">
          <.tree_item label="General" value="general" selected />
          <.tree_item label="Members" value="members" />
        </.tree_item>
      </.tree_view>

      # Custom trigger content
      <.tree_item expanded>
        <:trigger>
          <svg viewBox="0 0 24 24" class="size-4" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path d="M3 7h5l2 3h11v9H3z" />
          </svg>
          My Folder
        </:trigger>
        <.tree_item label="child.ex" />
      </.tree_item>

  ## Attributes

  `tree_view`:
  * `label` - Accessible label for the tree. Defaults to `"Tree view"`.
  * `id` - Stable DOM id. Required for keyboard enhancement and `select_event`.
  * `select_event` - When set, leaf nodes without `href` emit this event with
    `%{"node" => value}`.
  * `class` - Additional CSS classes.

  `tree_item`:
  * `label` - Node label (used if no `:trigger` slot).
  * `expanded` - Expand child nodes by default. Defaults to `false`.
  * `selected` - Mark node selected.
  * `disabled` - Mark node disabled.
  * `href` - Optional href for leaf nodes (renders as `<a>`).
  * `icon` - Custom text/emoji icon for the node.
  * `value` - Node value, emitted as `%{"node" => value}` when `select_event` is set.
  * `class` - Additional CSS classes.

  ## Slots

  * `:trigger` - Custom trigger content (overrides label/icon).
  * `:inner_block` - Child tree items.

  ## Accessibility

  - Uses `role="tree"` on the container and `role="treeitem"` on each node.
  - Parent nodes set `aria-expanded` based on their open/closed state.
  - `role="group"` on child containers.
  - With `id`, roving tabindex keeps one focusable item active at a time.
    Arrow keys move focus:
    - **Up/Down** — navigate between visible items.
    - **Right** — expand a collapsed parent, or move into its first child.
    - **Left** — collapse an expanded parent, or move to the parent.
    - **Home/End** — jump to first/last visible item.
    - **Enter/Space** — activate the item (click link, emit select event).
  - `<details>`/`<summary>` provides a no-JS baseline — the tree works even if
    JavaScript fails to load.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  attr(:label, :string, default: "Tree view", doc: "Accessible label")
  attr(:id, :string, default: nil, doc: "Stable DOM id for keyboard enhancement")
  attr(:select_event, :string, default: nil, doc: "Event emitted when a leaf node is clicked")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true)

  def tree_view(assigns) do
    assigns = assign(assigns, :hook, assigns.id && "SutraUI.TreeView.TreeView")

    ~H"""
    <div
      id={@id}
      class={["tree-view", @class]}
      role="tree"
      aria-label={@label}
      data-select-event={@select_event}
      phx-hook={@hook}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>

    <script :type={ColocatedHook} name=".TreeView" runtime>
      {
        mounted() {
          this.initTree();
        },

        updated() {
          this.initTree();
        },

        destroyed() {
          this.el.querySelectorAll('[data-tree-select]').forEach(btn => {
            if (btn._treeSelectHandler) {
              btn.removeEventListener('click', btn._treeSelectHandler);
              delete btn._treeSelectHandler;
              delete btn._treeSelectBound;
            }
          });

          this.el.querySelectorAll('[data-tree-trigger]').forEach(trigger => {
            if (trigger._treeKeydownHandler) {
              trigger.removeEventListener('keydown', trigger._treeKeydownHandler);
              delete trigger._treeKeydownHandler;
              delete trigger._treeKeydownBound;
            }
          });

          this.el.querySelectorAll('details.tree-item').forEach(item => {
            if (item._treeToggleHandler) {
              item.removeEventListener('toggle', item._treeToggleHandler);
              delete item._treeToggleHandler;
              delete item._treeToggleBound;
            }
          });
        },

        initTree() {
          this.items = Array.from(this.el.querySelectorAll('.tree-item'))
            .filter(item => item.getAttribute('aria-disabled') !== 'true');
          if (!this.items.length) return;
          this.selectEvent = this.el.dataset.selectEvent;

          // Wire up leaf node selection
          if (this.selectEvent) {
            this.el.querySelectorAll('[data-tree-select]').forEach(btn => {
              if (btn._treeSelectBound) return;
              btn._treeSelectBound = true;
              btn._treeSelectHandler = () => {
                const item = btn.closest('.tree-item');
                const value = item?.dataset.value;
                this.pushEvent(this.selectEvent, { node: value });
              };
              btn.addEventListener('click', btn._treeSelectHandler);
            });
          }

          // Find initially selected item for roving tabindex
          const selected = this.el.querySelector('.tree-item[aria-selected="true"]');
          this.focusableItem = selected || this.items[0];

          // Set up roving tabindex
          this.items.forEach(item => {
            const trigger = item.querySelector(':scope > .tree-item-trigger, :scope > summary > .tree-item-trigger, :scope > [data-tree-trigger]');
            if (item === this.focusableItem) {
              if (trigger) trigger.setAttribute('tabindex', '0');
            } else {
              if (trigger) trigger.setAttribute('tabindex', '-1');
            }
          });

          // Attach keydown to each trigger
          this.items.forEach(item => {
            const trigger = item.querySelector(':scope > .tree-item-trigger, :scope > summary > .tree-item-trigger, :scope > [data-tree-trigger]');
            if (trigger && !trigger._treeKeydownBound) {
              trigger._treeKeydownBound = true;
              trigger._treeKeydownHandler = (e) => this.handleKeydown(e, item);
              trigger.addEventListener('keydown', trigger._treeKeydownHandler);
            }

            if (item.tagName === 'DETAILS' && !item._treeToggleBound) {
              item._treeToggleBound = true;
              item._treeToggleHandler = () => {
                item.setAttribute('aria-expanded', item.open ? 'true' : 'false');
              };
              item.addEventListener('toggle', item._treeToggleHandler);
            }
          });
        },

        visibleItems() {
          return this.items.filter(item => {
            let parent = item.parentElement;
            while (parent && parent !== this.el) {
              if (parent.tagName === 'DETAILS' && !parent.open) return false;
              parent = parent.parentElement;
            }
            return true;
          });
        },

        getTrigger(item) {
          return item.querySelector(':scope > .tree-item-trigger, :scope > summary > .tree-item-trigger, :scope > [data-tree-trigger]');
        },

        setFocus(item) {
          const trigger = this.getTrigger(item);
          if (!trigger) return;
          this.items.forEach(i => {
            const t = this.getTrigger(i);
            if (t) t.setAttribute('tabindex', '-1');
          });
          trigger.setAttribute('tabindex', '0');
          trigger.focus();
          this.focusableItem = item;
        },

        handleKeydown(e, item) {
          const visible = this.visibleItems();
          const idx = visible.indexOf(item);
          const details = item.tagName === 'DETAILS' ? item : item.querySelector(':scope > details');

          switch (e.key) {
            case 'ArrowDown':
              e.preventDefault();
              if (idx < visible.length - 1) this.setFocus(visible[idx + 1]);
              break;
            case 'ArrowUp':
              e.preventDefault();
              if (idx > 0) this.setFocus(visible[idx - 1]);
              break;
            case 'ArrowRight':
              e.preventDefault();
              if (details && !details.open) {
                details.open = true;
              } else if (details && details.open) {
                const firstChild = visible.find(i => i.parentElement.closest('.tree-item, [role="treeitem"]') === item);
                if (firstChild) this.setFocus(firstChild);
              }
              break;
            case 'ArrowLeft':
              e.preventDefault();
              if (details && details.open) {
                details.open = false;
              } else {
                const parent = item.parentElement.closest('.tree-item, [role="treeitem"]');
                if (parent && visible.includes(parent)) this.setFocus(parent);
              }
              break;
            case 'Home':
              e.preventDefault();
              this.setFocus(visible[0]);
              break;
            case 'End':
              e.preventDefault();
              this.setFocus(visible[visible.length - 1]);
              break;
            case 'Enter':
            case ' ':
              // Let native click handle links; for non-link items, trigger click
              const trigger = this.getTrigger(item);
              if (trigger && trigger.tagName !== 'A') {
                e.preventDefault();
                trigger.click();
              }
              break;
          }
        }
      }
    </script>
    """
  end

  attr(:label, :string, default: nil, doc: "Node label")
  attr(:expanded, :boolean, default: false, doc: "Expand child nodes by default")
  attr(:selected, :boolean, default: false, doc: "Mark node selected")
  attr(:disabled, :boolean, default: false, doc: "Mark node disabled")
  attr(:href, :string, default: nil, doc: "Optional href for leaf nodes")
  attr(:icon, :string, default: nil, doc: "Custom text/emoji icon for the node")
  attr(:value, :string, default: nil, doc: "Node value emitted with select_event")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, doc: "Custom trigger content (overrides label/icon)")
  slot(:inner_block, doc: "Child tree items")

  def tree_item(assigns) do
    children = Phoenix.Component.__render_slot__(%{}, assigns.inner_block, nil)
    assigns = assign(assigns, :has_children, rendered_children?(children))

    ~H"""
    <%= if @has_children do %>
      <details
        class={["tree-item", @class]}
        open={@expanded}
        role="treeitem"
        aria-selected={@selected && "true"}
        aria-expanded={to_string(@expanded)}
        aria-disabled={@disabled && "true"}
        data-value={@value}
        {@rest}
      >
        <summary class="tree-item-trigger" data-tree-trigger tabindex={@disabled && "-1"}>
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
    <% else %>
      <div
        class={["tree-item tree-item-leaf", @class]}
        role="treeitem"
        aria-selected={@selected && "true"}
        aria-disabled={@disabled && "true"}
        data-value={@value}
        {@rest}
      >
        <a
          :if={@href}
          href={if @disabled, do: nil, else: @href}
          class="tree-item-trigger"
          data-tree-trigger
          tabindex={@disabled && "-1"}
        >
          <span class="tree-item-spacer" aria-hidden="true"></span>
          <%= if @trigger != [] do %>
            {render_slot(@trigger)}
          <% else %>
            <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
            <span class="tree-item-label">{@label}</span>
          <% end %>
        </a>
        <button
          :if={!@href}
          type="button"
          class="tree-item-trigger"
          data-tree-trigger
          data-tree-select
          disabled={@disabled}
        >
          <span class="tree-item-spacer" aria-hidden="true"></span>
          <%= if @trigger != [] do %>
            {render_slot(@trigger)}
          <% else %>
            <span :if={@icon} class="tree-item-icon" aria-hidden="true">{@icon}</span>
            <span class="tree-item-label">{@label}</span>
          <% end %>
        </button>
      </div>
    <% end %>
    """
  end

  defp rendered_children?(nil), do: false

  defp rendered_children?(rendered) do
    html =
      rendered
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> String.replace(~r/<!--.*?-->/s, "")
      |> String.trim()

    html != ""
  end
end
