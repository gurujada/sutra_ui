defmodule SutraUI.TabNav do
  @moduledoc """
  Routed tab-style navigation with responsive mobile collapse.

  Unlike the full `tabs` component which manages content panels client-side,
  this component only renders navigation links. Each tab links to a different
  LiveView route, allowing heavy content (analytics, tables, etc.) to load only
  when active.

  ## Features

  - Visual-only route navigation (no content panel management)
  - Server-side routing via LiveView patches
  - Collapses to a mobile dropdown by default
  - Desktop keyboard navigation (arrow keys, Home, End)
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

      # Keep tabs visible on small screens
      <.tab_nav id="settings-tabs" collapse="never">
        <:tab patch={~p"/settings"} active={@active_tab == :profile}>
          Profile
        </:tab>
        <:tab patch={~p"/settings/billing"} active={@active_tab == :billing}>
          Billing
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
  - The mobile trigger controls a collapsed list of the same route links
  - Arrow keys move focus between desktop links as a convenience enhancement
  - All links remain in the normal tab order

  ## Migrating from NavPills

  `SutraUI.NavPills` was removed in favor of this component. Use `tab_nav/1`
  for routed tab or pill navigation; it includes the responsive dropdown
  behavior by default.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a visual tab navigation bar.

  ## Attributes

  - `id` (required) - Unique identifier for the tab navigation (required for keyboard nav)
  - `class` - Optional additional CSS classes for the container
  - `label` - Accessible label for the navigation landmark (default: "Tab navigation")
  - `collapse` - Responsive behavior. Defaults to `dropdown`; use `never` to keep tabs visible on small screens.

  ## Slots

  - `tab` (required) - Tab definitions with patch URL and active state
    - `patch` (required) - LiveView route to navigate to
    - `active` (required) - Boolean indicating if this tab is currently active
    - Inner block can contain icons and text
  """
  attr(:id, :string, required: true, doc: "Unique identifier (required for keyboard navigation)")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")
  attr(:label, :string, default: "Tab navigation", doc: "Accessible label for the navigation")

  attr(:collapse, :string,
    default: "dropdown",
    values: ~w(dropdown never),
    doc: "Responsive behavior: `dropdown` on small screens or `never`"
  )

  attr(:rest, :global, doc: "Additional HTML attributes for the container")

  slot :tab, required: true, doc: "Tab definitions" do
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
    attr(:active, :boolean, required: true, doc: "Whether this tab is active")
  end

  def tab_nav(assigns) do
    active_tab = Enum.find(assigns.tab, & &1.active) || List.first(assigns.tab)
    assigns = assign(assigns, :active_tab, active_tab)

    ~H"""
    <div
      id={@id}
      class={["tab-nav", @class]}
      phx-hook=".TabNav"
      data-collapse={@collapse}
      {@rest}
    >
      <nav class="tab-nav-list" aria-label={@label}>
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

      <div class="tab-nav-mobile">
        <button
          type="button"
          id={"#{@id}-mobile-trigger"}
          class="tab-nav-mobile-trigger"
          aria-expanded="false"
          aria-controls={"#{@id}-mobile-menu"}
        >
          <span class="tab-nav-mobile-label">
            {render_slot(@active_tab)}
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="tab-nav-mobile-chevron"
            aria-hidden="true"
          >
            <path d="m6 9 6 6 6-6" />
          </svg>
        </button>

        <nav
          id={"#{@id}-mobile-menu"}
          class="tab-nav-mobile-menu"
          aria-hidden="true"
          aria-labelledby={"#{@id}-mobile-trigger"}
        >
          <%= for {tab, index} <- Enum.with_index(@tab) do %>
            <.link
              patch={tab.patch}
              class={["tab-nav-mobile-item", tab.active && "tab-nav-mobile-item-active"]}
              aria-current={tab.active && "page"}
              data-index={index}
            >
              {render_slot(tab)}
            </.link>
          <% end %>
        </nav>
      </div>
    </div>

    <script :type={ColocatedHook} name=".TabNav" runtime>
      {
        mounted() {
          this.trigger = this.el.querySelector('.tab-nav-mobile-trigger');
          this.menu = this.el.querySelector('.tab-nav-mobile-menu');
          this.keydownHandler = (e) => this.handleKeydown(e);
          this.el.addEventListener('keydown', this.keydownHandler);

          if (this.trigger && this.menu) {
            this.triggerClickHandler = () => this.toggleMenu();
            this.menuClickHandler = (e) => {
              if (e.target.closest('.tab-nav-mobile-item')) this.closeMenu();
            };
            this.outsideClickHandler = (e) => {
              if (!this.el.contains(e.target) && this.isMenuOpen()) this.closeMenu();
            };

            this.trigger.addEventListener('click', this.triggerClickHandler);
            this.menu.addEventListener('click', this.menuClickHandler);
            document.addEventListener('click', this.outsideClickHandler);
          }
        },

        destroyed() {
          this.el.removeEventListener('keydown', this.keydownHandler);
          this.trigger?.removeEventListener('click', this.triggerClickHandler);
          this.menu?.removeEventListener('click', this.menuClickHandler);
          document.removeEventListener('click', this.outsideClickHandler);
        },

        handleKeydown(e) {
          const tabs = Array.from(this.el.querySelectorAll('.tab-nav-list .tab-nav-item'));
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
        },

        isMenuOpen() {
          return this.trigger?.getAttribute('aria-expanded') === 'true';
        },

        toggleMenu() {
          this.isMenuOpen() ? this.closeMenu() : this.openMenu();
        },

        openMenu() {
          this.trigger?.setAttribute('aria-expanded', 'true');
          this.menu?.setAttribute('aria-hidden', 'false');
        },

        closeMenu() {
          this.trigger?.setAttribute('aria-expanded', 'false');
          this.menu?.setAttribute('aria-hidden', 'true');
        }
      }
    </script>
    """
  end
end
