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

  - Uses semantic `<nav>` landmark navigation
  - Active route links use `aria-current="page"`
  - Arrow keys move focus between links as a convenience enhancement
  - All links remain in the normal tab order
  """
  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a visual tab navigation bar.

  ## Attributes

  - `id` (required) - Unique identifier for the tab navigation (required for keyboard nav)
  - `class` - Optional additional CSS classes for the container
  - `label` - Accessible label for the navigation landmark (default: "Tab navigation")

  ## Slots

  - `tab` (required) - Tab definitions with patch URL and active state
    - `patch` (required) - LiveView route to navigate to
    - `active` (required) - Boolean indicating if this tab is currently active
    - Inner block can contain icons and text
  """
  attr(:id, :string, required: true, doc: "Unique identifier (required for keyboard navigation)")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")
  attr(:label, :string, default: "Tab navigation", doc: "Accessible label for the navigation")

  slot :tab, required: true, doc: "Tab definitions" do
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
    attr(:active, :boolean, required: true, doc: "Whether this tab is active")
  end

  def tab_nav(assigns) do
    ~H"""
    <nav
      id={@id}
      class={["tab-nav", @class]}
      aria-label={@label}
      phx-hook=".TabNav"
    >
      <%= for {tab, index} <- Enum.with_index(@tab) do %>
        <.link
          id={"#{@id}-tab-#{index}"}
          patch={tab.patch}
          aria-current={tab.active && "page"}
          class={["tab-nav-item", tab.active && "tab-nav-item-active"]}
          data-index={index}
        >
          {render_slot(tab)}
        </.link>
      <% end %>
    </nav>

    <script :type={ColocatedHook} name=".TabNav" runtime>
      {
        mounted() {
          this.keydownHandler = (e) => this.handleKeydown(e);
          this.el.addEventListener('keydown', this.keydownHandler);
        },

        destroyed() {
          this.el.removeEventListener('keydown', this.keydownHandler);
        },

        handleKeydown(e) {
          const tabs = Array.from(this.el.querySelectorAll('.tab-nav-item'));
          if (tabs.length === 0) return;

          const focusedIndex = tabs.indexOf(document.activeElement);
          const activeIndex = tabs.findIndex(tab => tab.getAttribute('aria-current') === 'page');
          const currentIndex = focusedIndex >= 0 ? focusedIndex : Math.max(activeIndex, 0);

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
            case 'Enter':
            case ' ':
              e.preventDefault();
              e.target.closest('.tab-nav-item')?.click();
              return;
            default:
              return;
          }

          tabs[newIndex].focus();
        }
      }
    </script>
    """
  end
end
