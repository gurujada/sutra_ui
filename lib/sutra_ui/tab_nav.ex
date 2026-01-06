defmodule SutraUI.TabNav do
  @moduledoc """
  Visual tab navigation component for server-side routed tabs.

  Unlike the full `tabs` component which manages content panels client-side,
  this component only provides the visual tab navigation. Each tab links to
  a different LiveView route, allowing heavy content (analytics, tables, etc.)
  to load only when active.

  ## Features

  - Visual-only tab navigation (no content panel management)
  - Server-side routing via LiveView patches
  - Full keyboard navigation (arrow keys, Home, End)
  - Icon support via inner block
  - Consistent styling across pages
  - Permission-aware rendering (slots can be conditionally rendered)

  ## Examples

      <.tab_nav id="org-tabs">
        <:tab patch={~p"/orgs/\#{@org.id}"} active={@active_tab == :show}>
          About
        </:tab>
        <:tab patch={~p"/orgs/\#{@org.id}/members"} active={@active_tab == :members}>
          Members
        </:tab>
      </.tab_nav>

  ## Permission-aware usage

      <.tab_nav id="batch-tabs">
        <:tab patch={~p"/batches/\#{@batch.id}"} active={@active_tab == :overview}>
          Overview
        </:tab>
        <%= if @can_manage do %>
          <:tab patch={~p"/batches/\#{@batch.id}/settings"} active={@active_tab == :settings}>
            Settings
          </:tab>
        <% end %>
      </.tab_nav>

  ## Keyboard Navigation

  | Key | Action |
  |-----|--------|
  | `ArrowLeft` | Move to previous tab |
  | `ArrowRight` | Move to next tab |
  | `Home` | Move to first tab |
  | `End` | Move to last tab |
  | `Enter` / `Space` | Navigate to focused tab |

  ## Accessibility

  - Uses `role="tablist"` for the container
  - Uses `role="tab"` for each tab trigger
  - `aria-selected` indicates active tab
  - `tabindex` management for roving focus
  - Active tab marked with `aria-selected="true"`
  """
  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a visual tab navigation bar.

  ## Attributes

  - `id` (required) - Unique identifier for the tab navigation (required for keyboard nav)
  - `class` - Optional additional CSS classes for the container
  - `label` - Accessible label for the tablist (default: "Tab navigation")

  ## Slots

  - `tab` (required) - Tab definitions with patch URL and active state
    - `patch` (required) - LiveView route to navigate to
    - `active` (required) - Boolean indicating if this tab is currently active
    - Inner block can contain icons and text
  """
  attr(:id, :string, required: true, doc: "Unique identifier (required for keyboard navigation)")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")
  attr(:label, :string, default: "Tab navigation", doc: "Accessible label for the tablist")

  slot :tab, required: true, doc: "Tab definitions" do
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
    attr(:active, :boolean, required: true, doc: "Whether this tab is active")
  end

  def tab_nav(assigns) do
    ~H"""
    <div
      id={@id}
      class={["tab-nav", @class]}
      role="tablist"
      aria-label={@label}
      aria-orientation="horizontal"
      phx-hook=".TabNav"
    >
      <%= for {tab, index} <- Enum.with_index(@tab) do %>
        <.link
          id={"#{@id}-tab-#{index}"}
          patch={tab.patch}
          role="tab"
          aria-selected={to_string(tab.active)}
          tabindex={if tab.active, do: "0", else: "-1"}
          class={["tab-nav-item", tab.active && "tab-nav-item-active"]}
          data-index={index}
        >
          {render_slot(tab)}
        </.link>
      <% end %>
    </div>

    <script :type={ColocatedHook} name=".TabNav" runtime>
      {
        mounted() {
          this.el.addEventListener('keydown', (e) => this.handleKeydown(e));
        },

        handleKeydown(e) {
          const tabs = Array.from(this.el.querySelectorAll('[role="tab"]'));
          const currentIndex = tabs.findIndex(tab => tab.getAttribute('aria-selected') === 'true');

          let newIndex;
          switch(e.key) {
            case 'ArrowLeft':
              e.preventDefault();
              newIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1;
              break;
            case 'ArrowRight':
              e.preventDefault();
              newIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0;
              break;
            case 'Home':
              e.preventDefault();
              newIndex = 0;
              break;
            case 'End':
              e.preventDefault();
              newIndex = tabs.length - 1;
              break;
            default:
              return;
          }

          // Update tabindex for roving focus
          tabs.forEach((tab, i) => {
            tab.setAttribute('tabindex', i === newIndex ? '0' : '-1');
          });

          tabs[newIndex].focus();
        }
      }
    </script>
    """
  end
end
