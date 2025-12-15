defmodule SutraUI.Tabs do
  @moduledoc """
  A tabbed interface component for organizing content into separate views.

  Tabs allow users to switch between different views where only one panel
  is visible at a time. Useful for settings pages, dashboards, or any UI
  that needs to organize related content without navigation.

  ## Examples

      # Basic tabs
      <.tabs id="settings-tabs" default_value="account">
        <:tab value="account">Account</:tab>
        <:tab value="password">Password</:tab>
        <:tab value="notifications">Notifications</:tab>
        <:panel value="account">
          <h3>Account Settings</h3>
          <p>Manage your account details here.</p>
        </:panel>
        <:panel value="password">
          <h3>Change Password</h3>
          <.input type="password" name="current" label="Current Password" />
        </:panel>
        <:panel value="notifications">
          <h3>Notification Preferences</h3>
          <.switch name="email_notifications" label="Email notifications" />
        </:panel>
      </.tabs>

      # With disabled tab
      <.tabs id="feature-tabs" default_value="overview">
        <:tab value="overview">Overview</:tab>
        <:tab value="analytics">Analytics</:tab>
        <:tab value="reports" disabled>Reports (Coming Soon)</:tab>
        <:panel value="overview">Overview content...</:panel>
        <:panel value="analytics">Analytics content...</:panel>
        <:panel value="reports">Reports content...</:panel>
      </.tabs>

      # With icons in tabs
      <.tabs id="nav-tabs" default_value="home">
        <:tab value="home">
          <.icon name="lucide-house" class="size-4 mr-2" /> Home
        </:tab>
        <:tab value="settings">
          <.icon name="lucide-settings" class="size-4 mr-2" /> Settings
        </:tab>
        <:panel value="home">Home content</:panel>
        <:panel value="settings">Settings content</:panel>
      </.tabs>

  ## Slots

  | Slot | Required | Description |
  |------|----------|-------------|
  | `tab` | Yes | Tab trigger buttons |
  | `panel` | Yes | Content panels (matched by `value`) |

  ### Tab Slot Attributes

  | Attribute | Type | Description |
  |-----------|------|-------------|
  | `value` | string | **Required.** Unique identifier, matches panel |
  | `disabled` | boolean | Prevents tab from being selected |

  ### Panel Slot Attributes

  | Attribute | Type | Description |
  |-----------|------|-------------|
  | `value` | string | **Required.** Matches corresponding tab |

  ## Keyboard Navigation

  | Key | Action |
  |-----|--------|
  | `ArrowLeft` | Move to previous tab |
  | `ArrowRight` | Move to next tab |
  | `Home` | Move to first tab |
  | `End` | Move to last tab |

  ## How It Works

  Tab switching is handled entirely client-side using `Phoenix.LiveView.JS`:
  - No server round-trip for tab changes
  - Instant panel switching
  - Keyboard navigation via colocated hook

  The `default_value` determines which tab is active on initial render.
  Subsequent tab changes update the DOM directly without re-rendering.

  ## Colocated Hook

  The `.Tabs` hook provides keyboard navigation. Tab click handling
  uses `phx-click` with `JS` commands for immediate feedback.

  See [JavaScript Hooks](colocated-hooks.md) for more details.

  ## Accessibility

  - Uses `role="tablist"` for the tab container
  - Uses `role="tab"` for each tab trigger
  - Uses `role="tabpanel"` for each content panel
  - `aria-selected` indicates active tab
  - `aria-controls` links tab to its panel
  - `aria-labelledby` links panel to its tab
  - `tabindex` management for roving focus
  - Disabled tabs use `disabled` attribute

  > #### Panel Focus {: .tip}
  >
  > Tab panels have `tabindex="0"` allowing keyboard users to tab into
  > panel content after selecting a tab.

  ## Related

  - `SutraUI.Accordion` - For collapsible sections (multiple can be open)
  - `SutraUI.TabNav` - For page navigation that looks like tabs
  - `SutraUI.NavPills` - For pill-style navigation
  - [Accessibility Guide](accessibility.md) - ARIA patterns
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a tabs component.
  """
  attr(:default_value, :string, required: true, doc: "The value of the initially active tab")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:id, :string, required: true, doc: "Unique identifier for the tabs component")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :tab, required: true, doc: "Tab triggers" do
    attr(:value, :string, required: true, doc: "Unique identifier for the tab")
    attr(:disabled, :boolean, doc: "Whether the tab is disabled")
  end

  slot :panel, required: true, doc: "Tab panels" do
    attr(:value, :string, required: true, doc: "Value matching the corresponding tab")
  end

  def tabs(assigns) do
    ~H"""
    <div
      id={@id}
      class={["tabs", @class]}
      phx-hook=".Tabs"
      data-default-value={@default_value}
      {@rest}
    >
      <div class="tabs-list" role="tablist" aria-orientation="horizontal">
        <%= for tab <- @tab do %>
          <button
            type="button"
            role="tab"
            class={["tabs-trigger", tab.value == @default_value && "tabs-trigger-active"]}
            id={"#{@id}-tab-#{tab.value}"}
            aria-selected={to_string(tab.value == @default_value)}
            aria-controls={"#{@id}-panel-#{tab.value}"}
            tabindex={if tab.value == @default_value, do: "0", else: "-1"}
            disabled={tab[:disabled]}
            data-value={tab.value}
            phx-click={switch_tab(@id, tab.value, @tab)}
          >
            {render_slot([tab])}
          </button>
        <% end %>
      </div>
      <%= for panel <- @panel do %>
        <div
          role="tabpanel"
          class="tabs-panel"
          id={"#{@id}-panel-#{panel.value}"}
          aria-labelledby={"#{@id}-tab-#{panel.value}"}
          tabindex="0"
          hidden={panel.value != @default_value}
          data-value={panel.value}
        >
          {render_slot([panel])}
        </div>
      <% end %>
    </div>

    <script :type={ColocatedHook} name=".Tabs" runtime>
      {
        mounted() {
          this.el.addEventListener('keydown', (e) => this.handleKeydown(e));
        },
        handleKeydown(e) {
          const tabs = Array.from(this.el.querySelectorAll('[role="tab"]:not([disabled])'));
          const currentIndex = tabs.findIndex(tab => tab.getAttribute('aria-selected') === 'true');
          
          let newIndex;
          switch(e.key) {
            case 'ArrowLeft':
              newIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1;
              break;
            case 'ArrowRight':
              newIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0;
              break;
            case 'Home':
              newIndex = 0;
              break;
            case 'End':
              newIndex = tabs.length - 1;
              break;
            default:
              return;
          }
          
          e.preventDefault();
          tabs[newIndex].click();
          tabs[newIndex].focus();
        }
      }
    </script>
    """
  end

  defp switch_tab(tabs_id, value, all_tabs) do
    # Hide all other panels, show the selected one
    all_tabs
    |> Enum.reject(&(&1.value == value))
    |> Enum.reduce(
      JS.remove_class("tabs-trigger-active", to: "##{tabs_id} .tabs-trigger")
      |> JS.add_class("tabs-trigger-active", to: "##{tabs_id}-tab-#{value}")
      |> JS.set_attribute({"aria-selected", "false"}, to: "##{tabs_id} [role='tab']")
      |> JS.set_attribute({"aria-selected", "true"}, to: "##{tabs_id}-tab-#{value}")
      |> JS.set_attribute({"tabindex", "-1"}, to: "##{tabs_id} [role='tab']")
      |> JS.set_attribute({"tabindex", "0"}, to: "##{tabs_id}-tab-#{value}"),
      fn tab, js ->
        JS.hide(js, to: "##{tabs_id}-panel-#{tab.value}")
        |> JS.set_attribute({"hidden", "hidden"}, to: "##{tabs_id}-panel-#{tab.value}")
      end
    )
    |> JS.show(to: "##{tabs_id}-panel-#{value}")
    |> JS.remove_attribute("hidden", to: "##{tabs_id}-panel-#{value}")
  end
end
