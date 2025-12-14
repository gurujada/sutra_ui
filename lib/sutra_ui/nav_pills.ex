defmodule SutraUI.NavPills do
  @moduledoc """
  A responsive navigation pills component that displays pills on desktop and converts to a dropdown on mobile.

  This component provides a flexible navigation pattern that adapts to screen size:
  - **Desktop**: Shows all navigation items as pill-style buttons in a horizontal row
  - **Mobile**: Converts to a compact dropdown menu showing the active item

  ## Features

  - Responsive design (pills on desktop, dropdown on mobile)
  - Active state management
  - ARIA labels for accessibility
  - Flexible item slots
  - Support for icons in navigation items

  ## Examples

      # Basic navigation pills
      <.nav_pills id="content-nav" active_label="Overview">
        <:item label="Overview" patch={~p"/content"} />
        <:item label="Students" patch={~p"/content/students"} />
        <:item label="Settings" patch={~p"/content/settings"} />
      </.nav_pills>

      # With icons
      <.nav_pills id="batch-nav" active_label="Content">
        <:item label="Content" patch={~p"/batches/123"}>
          <.icon name="lucide-book-open" class="size-4" />
        </:item>
        <:item label="Students" patch={~p"/batches/123/students"}>
          <.icon name="lucide-users" class="size-4" />
        </:item>
        <:item label="Settings" patch={~p"/batches/123/settings"}>
          <.icon name="lucide-settings" class="size-4" />
        </:item>
      </.nav_pills>

      # Custom styling
      <.nav_pills id="org-nav" active_label="About" class="mb-6">
        <:item label="About" patch={~p"/orgs/456"} />
        <:item label="Members" patch={~p"/orgs/456/members"} />
      </.nav_pills>

  ## Accessibility

  - Desktop pills use `role="navigation"` with `aria-label`
  - Mobile dropdown uses proper ARIA attributes
  - Active item is clearly indicated visually and semantically
  """

  use Phoenix.Component

  import SutraUI.Icon, only: [icon: 1]

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders responsive navigation pills.

  ## Attributes

  - `id` (required) - Unique identifier for the navigation component
  - `active_label` (required) - Label of the currently active item
  - `class` - Additional CSS classes for the container
  - `aria_label` - Accessible label for the navigation (default: "Navigation")

  ## Slots

  - `item` (required, multiple) - Navigation items
    - `label` (required) - Text label for the item
    - `patch` (required) - Phoenix LiveView patch URL for navigation
    - Inner block (optional) - Icon or additional content before label
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the navigation")
  attr(:active_label, :string, required: true, doc: "Label of the currently active item")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")
  attr(:aria_label, :string, default: "Navigation", doc: "Accessible label for the navigation")

  attr(:rest, :global, doc: "Additional HTML attributes for the container")

  slot :item, required: true, doc: "Navigation items" do
    attr(:label, :string, required: true, doc: "Item label")
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
  end

  def nav_pills(assigns) do
    ~H"""
    <div id={@id} class={["nav-pills", @class]} phx-hook=".NavPills" {@rest}>
      <%!-- Desktop: Pills layout (hidden on mobile) --%>
      <nav role="navigation" aria-label={@aria_label} class="nav-pills-desktop">
        <%= for item <- @item do %>
          <.link
            patch={item.patch}
            class={["nav-pills-item", item.label == @active_label && "nav-pills-item-active"]}
          >
            {if item.inner_block, do: render_slot(item)}
            {item.label}
          </.link>
        <% end %>
      </nav>

      <%!-- Mobile: Dropdown menu (hidden on desktop) --%>
      <div class="nav-pills-mobile">
        <button
          type="button"
          class="nav-pills-mobile-trigger"
          aria-haspopup="true"
          aria-expanded="false"
        >
          {@active_label}
          <.icon name="lucide-chevron-down" class="nav-pills-mobile-chevron" />
        </button>
        <div class="nav-pills-mobile-menu" role="menu" aria-hidden="true">
          <%= for item <- @item do %>
            <.link
              patch={item.patch}
              role="menuitem"
              class={[
                "nav-pills-mobile-item",
                item.label == @active_label && "nav-pills-mobile-item-active"
              ]}
            >
              {if item.inner_block, do: render_slot(item)}
              {item.label}
            </.link>
          <% end %>
        </div>
      </div>
    </div>

    <script :type={ColocatedHook} name=".NavPills" runtime>
      {
        mounted() {
          this.trigger = this.el.querySelector('.nav-pills-mobile-trigger');
          this.menu = this.el.querySelector('.nav-pills-mobile-menu');
          
          if (this.trigger && this.menu) {
            this.trigger.addEventListener('click', () => this.toggle());
            
            this.outsideClickHandler = (e) => {
              if (!this.el.contains(e.target) && this.isOpen()) {
                this.close();
              }
            };
            document.addEventListener('click', this.outsideClickHandler);
            
            // Close on item click
            this.menu.addEventListener('click', (e) => {
              if (e.target.closest('[role="menuitem"]')) {
                this.close();
              }
            });
          }
        },
        
        destroyed() {
          if (this.outsideClickHandler) {
            document.removeEventListener('click', this.outsideClickHandler);
          }
        },
        
        isOpen() {
          return this.trigger?.getAttribute('aria-expanded') === 'true';
        },
        
        toggle() {
          if (this.isOpen()) {
            this.close();
          } else {
            this.open();
          }
        },
        
        open() {
          this.trigger.setAttribute('aria-expanded', 'true');
          this.menu.setAttribute('aria-hidden', 'false');
        },
        
        close() {
          this.trigger.setAttribute('aria-expanded', 'false');
          this.menu.setAttribute('aria-hidden', 'true');
        }
      }
    </script>
    """
  end
end
