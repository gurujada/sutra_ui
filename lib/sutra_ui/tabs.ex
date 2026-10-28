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
          <div class="flex items-center gap-2">
            <.switch id="email-notifications" name="email_notifications" />
            <.label for="email-notifications">Email notifications</.label>
          </div>
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
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4 mr-2"><path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg> Home
        </:tab>
        <:tab value="settings">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4 mr-2"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg> Settings
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

  ## Segmented control and filter tabs

  Two more shapes share the tabs look but have no panels: they choose, and your LiveView
  decides what to show.

  `segmented/1` is a single choice out of two to six (a view mode, a unit, a plan): a real
  radio group, so arrow keys move the choice and it works in a form.

      <.segmented id="view" label="View" name="view" value={@view} click="set_view">
        <:option value="list" label="List" />
        <:option value="grid" label="Grid" />
      </.segmented>

  `filter_tabs/1` is the "All · Mine · Waiting" row with counts: each choice is a link
  (`patch` or `navigate`, marked `aria-current`) or a button (`click`, marked `aria-pressed`).

      <.filter_tabs id="inbox-filter" label="Filter inbox">
        <:item label="All" count={42} active={@filter == :all} click="filter" value="all" />
        <:item label="Mine" count={3} active={@filter == :mine} patch={~p"/inbox?filter=mine"} />
      </.filter_tabs>

  ## Related

  - `SutraUI.Accordion` - For collapsible sections (multiple can be open)
  - `SutraUI.TabNav` - For responsive routed navigation that looks like tabs
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

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script")

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

    <script :type={ColocatedHook} name=".Tabs" runtime nonce={@nonce}>
      {
        mounted() {
          this.keydownHandler = (e) => this.handleKeydown(e);
          this.el.addEventListener('keydown', this.keydownHandler);
        },

        destroyed() {
          this.el.removeEventListener('keydown', this.keydownHandler);
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

  @doc """
  A single choice out of two to six, as a row of chips: an accessible radio group of real
  radio inputs.

  In a form, give `field` (or `name`): the form's `phx-change` receives the value.
  Standalone, give `click` (an event name or a `%JS{}`): it is sent with `%{"value" => value}`.

  An option with an icon only (its content in the slot) is named by its `title`, which is also
  its tooltip.
  """
  attr(:id, :string, required: true, doc: "Unique identifier")
  attr(:label, :string, required: true, doc: "Accessible name of the group")
  attr(:field, Phoenix.HTML.FormField, default: nil, doc: "A form field; sets name and value")
  attr(:name, :string, default: nil, doc: "The input name without a `field`")
  attr(:value, :any, default: nil, doc: "The chosen value without a `field`")
  attr(:click, :any, default: nil, doc: "Standalone: event name or `%JS{}` sent with the value")
  attr(:target, :any, default: nil, doc: "`phx-target` of `click`")
  attr(:disabled, :boolean, default: false, doc: "Disables every option")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :option, required: true, doc: "The choices; the slot content (an icon) leads the label" do
    attr(:value, :string, required: true, doc: "The value this option sends")
    attr(:label, :string, doc: "Visible words")
    attr(:title, :string, doc: "Tooltip, and the accessible name when there is no `label`")
    attr(:disabled, :boolean, doc: "Disables this option")
  end

  def segmented(assigns) do
    assigns =
      assign(assigns,
        input_name: (assigns.field && assigns.field.name) || assigns.name || assigns.id,
        chosen: to_string((assigns.field && assigns.field.value) || assigns.value || "")
      )

    ~H"""
    <div
      id={@id}
      role="radiogroup"
      aria-label={@label}
      class={["segmented", @class]}
      data-style="segmented"
      {@rest}
    >
      <label
        :for={option <- @option}
        class="segmented-option"
        data-state={if to_string(option.value) == @chosen, do: "active", else: "idle"}
        data-value={option.value}
        title={option[:title]}
      >
        <input
          type="radio"
          id={"#{@id}-#{option.value}"}
          name={@input_name}
          value={option.value}
          checked={to_string(option.value) == @chosen}
          disabled={@disabled || option[:disabled] == true}
          phx-click={@click}
          phx-value-value={@click && option.value}
          phx-target={@click && @target}
          class="sr-only"
        />
        {option.inner_block && render_slot([option])}
        <span class={!option[:label] && "sr-only"}>{option[:label] || option[:title]}</span>
      </label>
    </div>
    """
  end

  @doc """
  A filter row ("All · Mine · Waiting") with optional counts. Each item is a link (`patch` or
  `navigate`, marked `aria-current="page"`) or a button (`click` with a `value`, marked
  `aria-pressed`). The active item has `data-state="active"`.
  """
  attr(:id, :string, required: true, doc: "Unique identifier")
  attr(:label, :string, required: true, doc: "Accessible name of the group")
  attr(:target, :any, default: nil, doc: "`phx-target` for click items")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :item, required: true, doc: "The choices; the slot content (an icon) leads the label" do
    attr(:label, :string, required: true, doc: "Visible words")
    attr(:active, :boolean, doc: "Whether this is the current filter")
    attr(:count, :integer, doc: "A count shown after the label")
    attr(:patch, :string, doc: "A LiveView patch path (renders a link)")
    attr(:navigate, :string, doc: "A navigate path (renders a link)")
    attr(:click, :any, doc: "An event name or `%JS{}` (renders a button)")
    attr(:value, :string, doc: "Sent as `phx-value-filter` with `click`")
    attr(:id, :string, doc: "DOM id of the item")
  end

  def filter_tabs(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      class={["filter-tabs", @class]}
      data-style="filter"
      {@rest}
    >
      <%= for item <- @item do %>
        <.link
          :if={item[:patch] || item[:navigate]}
          id={item[:id]}
          patch={item[:patch]}
          navigate={item[:navigate]}
          aria-current={item[:active] && "page"}
          data-state={if item[:active], do: "active", else: "idle"}
          class="filter-tab"
        >
          {item.inner_block && render_slot([item])}{item.label}<span
            :if={item[:count]}
            class="filter-tab-count"
          >{item.count}</span>
        </.link>
        <button
          :if={!(item[:patch] || item[:navigate])}
          id={item[:id]}
          type="button"
          phx-click={item[:click]}
          phx-value-filter={item[:value]}
          phx-target={@target}
          aria-pressed={to_string(!!item[:active])}
          data-state={if item[:active], do: "active", else: "idle"}
          class="filter-tab"
        >
          {item.inner_block && render_slot([item])}{item.label}<span
            :if={item[:count]}
            class="filter-tab-count"
          >{item.count}</span>
        </button>
      <% end %>
    </div>
    """
  end
end
