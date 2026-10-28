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

  ## URL tabs

  Give each `tab` a `patch` or a `navigate` and every tab has its own URL: it feels instant,
  and a reload or a direct link lands on the right tab.

  **`patch`: tabs as routes (or params) of one LiveView.** The app sets `value` from the URL in
  `handle_params`. A click first switches on the client, in the same tick as the patch starts:
  the tab turns active (`aria-selected`, `data-state`) and its panel shows at once, or, when the
  server has not rendered that panel yet, a loading state; then the URL patches and the server
  renders the active tab. The server's render is the same state, so nothing flickers back.

      def handle_params(params, _uri, socket) do
        tab = params["tab"] || "overview"
        {:noreply, assign(socket, tab: tab, visited: SutraUI.Tabs.visit(socket.assigns.visited, tab))}
      end

      <.tabs id="course" value={@tab} label="Course" keep={@visited}>
        <:tab value="overview" patch={~p"/courses/\#{@id}/overview"}>Overview</:tab>
        <:tab value="notes" patch={~p"/courses/\#{@id}/notes"}>Notes</:tab>
        <:panel value="overview">...</:panel>
        <:panel value="notes">...</:panel>
      </.tabs>

  Only the active panel is rendered by default (the others are empty containers, so a panel's
  slot content is not even evaluated). `keep` leaves visited panels on the page, hidden, so
  returning is instant and what the user typed in them stays: pass `true` to render every given
  panel, or the list of visited values (`visit/2` keeps it) to render those. With `keep`, the hook
  also carries a typed value of a plain field over server patches (LiveView would reset it to the
  server's value); fields in a form with `phx-change` or `phx-submit` are the server's own state
  and are left alone.

  **`navigate`: tabs that are separate LiveViews** of one `live_session`. The tab bar is a
  navigation landmark of links with `aria-current="page"` on the active one; there are no panels.

  **Neither: client-only tabs**, as before (`default_value`, no URL).

  ### Why the roles differ

  Patch tabs control panels on the same page, so they follow the ARIA tabs pattern: `tablist`,
  `tab` (on the links, so open-in-new-tab and copy-link still work), `tabpanel`, a roving
  `tabindex`, arrow keys and Home/End move focus, Enter or Space activates (manual activation, so
  arrowing past a tab does not patch). Navigate tabs lead to other pages, which is navigation:
  a `nav` with links and `aria-current`, not `tab` roles, since there is no panel on the page
  for the tab to control.

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

  Each `tab` takes `patch`, `navigate`, or neither; see "URL tabs" in the module doc.
  """
  attr(:default_value, :string,
    default: nil,
    doc: "The initially active tab of client-only tabs (use `value` for URL tabs)"
  )

  attr(:value, :string,
    default: nil,
    doc: "The active tab, from the server (the app's assign, set from the URL)"
  )

  attr(:keep, :any,
    default: false,
    doc:
      "Patch tabs: `true` renders every given panel (hidden when inactive); a list of values " <>
        "(see `visit/2`) renders those panels as well as the active one. Default: only the active panel"
  )

  attr(:label, :string, default: nil, doc: "Accessible name of the tab list")

  attr(:loading_label, :string,
    default: "Loading",
    doc: "Screen-reader word of the loading state"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")
  attr(:id, :string, required: true, doc: "Unique identifier for the tabs component")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot :tab, required: true, doc: "Tab triggers" do
    attr(:value, :string, required: true, doc: "Unique identifier for the tab")
    attr(:disabled, :boolean, doc: "Whether the tab is disabled")
    attr(:patch, :string, doc: "A LiveView patch path: the tab switches at once, then patches")
    attr(:navigate, :string, doc: "A path of another LiveView: the tab is a link")
  end

  slot :panel, doc: "Tab panels (none for `navigate` tabs)" do
    attr(:value, :string, required: true, doc: "Value matching the corresponding tab")
  end

  attr(:nonce, :string, default: nil, doc: "CSP nonce for the inline hook script")

  def tabs(assigns) do
    assigns = assign(assigns, :mode, mode(assigns.tab))
    assigns = assign(assigns, :active, assigns.value || assigns.default_value)

    if assigns.mode != :client and is_nil(assigns.value) do
      raise ArgumentError,
            "tabs #{inspect(assigns.id)} has patch or navigate tabs and needs `value`, " <>
              "the active tab from the app's assign"
    end

    if assigns.mode == :client and is_nil(assigns.active) do
      raise ArgumentError, "tabs #{inspect(assigns.id)} needs `default_value` (or `value`)"
    end

    render_tabs(assigns)
  end

  # navigate: a navigation bar of links (separate LiveViews), `aria-current` on the active one.
  defp render_tabs(%{mode: :navigate} = assigns) do
    ~H"""
    <nav id={@id} class={["tabs", @class]} data-mode="navigate" aria-label={@label} {@rest}>
      <div class="tabs-list">
        <.choice
          :for={tab <- @tab}
          id={"#{@id}-tab-#{tab.value}"}
          patch={tab[:patch]}
          navigate={tab[:navigate]}
          class="tabs-trigger"
          aria-current={tab.value == @active && "page"}
          data-state={if tab.value == @active, do: "active", else: "inactive"}
          data-value={tab.value}
        >
          {render_slot([tab])}
        </.choice>
      </div>
    </nav>
    """
  end

  # client: today's behaviour; patch: the same with links that also patch the URL.
  defp render_tabs(assigns) do
    patch? = assigns.mode == :patch

    assigns =
      assign(assigns,
        patch?: patch?,
        panels: panels(assigns, patch?)
      )

    ~H"""
    <div
      id={@id}
      class={["tabs", @class]}
      phx-hook=".Tabs"
      data-mode={@mode}
      data-default-value={@active}
      data-activation={if @patch?, do: "manual", else: "automatic"}
      data-keep={@patch? && @keep != false && "true"}
      {@rest}
    >
      <div
        class="tabs-list"
        role="tablist"
        aria-orientation="horizontal"
        aria-label={@label}
      >
        <.choice
          :for={tab <- @tab}
          id={"#{@id}-tab-#{tab.value}"}
          patch={tab[:patch]}
          click={switch_tab(@id, tab.value, @tab, @patch?)}
          class={["tabs-trigger", tab.value == @active && "tabs-trigger-active"]}
          role="tab"
          aria-selected={to_string(tab.value == @active)}
          aria-controls={"#{@id}-panel-#{tab.value}"}
          tabindex={if tab.value == @active, do: "0", else: "-1"}
          disabled={tab[:disabled]}
          data-state={if tab.value == @active, do: "active", else: "inactive"}
          data-value={tab.value}
        >
          {render_slot([tab])}
        </.choice>
      </div>
      <div
        :for={panel <- @panels}
        role="tabpanel"
        class="tabs-panel"
        id={"#{@id}-panel-#{panel.value}"}
        aria-labelledby={"#{@id}-tab-#{panel.value}"}
        tabindex="0"
        hidden={panel.value != @active}
        data-state={if panel.value == @active, do: "active", else: "inactive"}
        data-empty={panel.slot == nil}
        data-value={panel.value}
      >
        <%= if panel.slot do %>
          {render_slot([panel.slot])}
        <% else %>
          <div class="tabs-loading" role="status">
            <span class="sr-only">{@loading_label}</span>
            <span class="tabs-loading-bar" aria-hidden="true"></span>
            <span class="tabs-loading-bar" aria-hidden="true"></span>
            <span class="tabs-loading-bar" aria-hidden="true"></span>
          </div>
        <% end %>
      </div>
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

        // With `keep`, a server patch must not wipe what the user typed in a kept panel: LiveView
        // sets a plain field back to the server's value. Fields in forms with phx-change or
        // phx-submit are the server's own state and are left alone, as is a field whose
        // server-rendered value changed.
        beforeUpdate() {
          if (this.el.dataset.keep !== 'true') return;
          this.typed = [];
          this.el.querySelectorAll('[role="tabpanel"]:not([data-empty]) :is(input, textarea, select)[name]').forEach((field) => {
            if (field.type === 'file' || field.type === 'password' || field === document.activeElement) return;
            if (field.closest('form[phx-change], form[phx-submit]')) return;
            this.typed.push({
              field,
              value: field.value,
              checked: field.checked,
              defaultValue: field.defaultValue,
              defaultChecked: field.defaultChecked
            });
          });
        },

        updated() {
          (this.typed || []).forEach(({ field, value, checked, defaultValue, defaultChecked }) => {
            if (!field.isConnected) return;
            if (field.defaultValue === defaultValue && field.value !== value) field.value = value;
            if (field.defaultChecked === defaultChecked && field.checked !== checked) field.checked = checked;
          });
          this.typed = [];
        },

        handleKeydown(e) {
          const tabs = Array.from(this.el.querySelectorAll('[role="tab"]:not([disabled])'));
          if (!tabs.includes(document.activeElement) && e.target.closest('[role="tabpanel"]')) return;
          const manual = this.el.dataset.activation === 'manual';
          // Manual activation (URL tabs): arrows move focus, Enter or Space activates.
          const currentIndex = manual
            ? tabs.indexOf(document.activeElement)
            : tabs.findIndex(tab => tab.getAttribute('aria-selected') === 'true');

          if (manual && (e.key === ' ' || e.key === 'Spacebar') && currentIndex > -1) {
            e.preventDefault();
            tabs[currentIndex].click();
            return;
          }

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
          if (manual) {
            tabs.forEach(tab => tab.setAttribute('tabindex', tab === tabs[newIndex] ? '0' : '-1'));
          } else {
            tabs[newIndex].click();
          }
          tabs[newIndex].focus();
        }
      }
    </script>
    """
  end

  defp mode(tabs) do
    cond do
      Enum.any?(tabs, & &1[:navigate]) -> :navigate
      Enum.any?(tabs, & &1[:patch]) -> :patch
      true -> :client
    end
  end

  # One entry per tab: the given panel slot, or none (rendered empty, with a loading state the
  # click shows until the server sends the panel). Patch tabs render a panel's content only when
  # it is active or kept; client-only tabs render every panel as before.
  defp panels(assigns, patch?) do
    Enum.map(assigns.tab, fn tab ->
      slot = Enum.find(assigns.panel, &(&1.value == tab.value))

      keep? =
        not patch? or tab.value == assigns.active or assigns.keep == true or
          (is_list(assigns.keep) and tab.value in assigns.keep) or
          (is_struct(assigns.keep, MapSet) and MapSet.member?(assigns.keep, tab.value))

      %{value: tab.value, slot: if(keep?, do: slot)}
    end)
  end

  @doc """
  Adds `value` to the list of visited tabs, for `keep`.

      def handle_params(params, _uri, socket) do
        tab = params["tab"] || "overview"
        {:noreply, assign(socket, tab: tab, visited: SutraUI.Tabs.visit(socket.assigns.visited, tab))}
      end
  """
  @spec visit([String.t()], String.t()) :: [String.t()]
  def visit(visited, value) when is_list(visited), do: Enum.uniq(visited ++ [value])

  # The tab link or button: a link for `patch` or `navigate`, else a button. `click` is the
  # phx-click (on a link it runs after the navigation starts, in the same tick).
  attr(:patch, :string, default: nil)
  attr(:navigate, :string, default: nil)
  attr(:click, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(role aria-selected aria-current aria-pressed aria-controls tabindex disabled phx-value-filter phx-target)
  )

  slot(:inner_block, required: true)

  defp choice(%{patch: patch} = assigns) when is_binary(patch) do
    ~H"""
    <.link patch={@patch} phx-click={@click} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  defp choice(%{navigate: navigate} = assigns) when is_binary(navigate) do
    ~H"""
    <.link navigate={@navigate} phx-click={@click} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  defp choice(assigns) do
    ~H"""
    <button type="button" phx-click={@click} {@rest}>{render_slot(@inner_block)}</button>
    """
  end

  # The client's side of a click: the active tab and its panel switch at once. Patch tabs only
  # set attributes (so the server's render of the same state changes nothing); client-only tabs
  # also show and hide as before.
  defp switch_tab(tabs_id, value, all_tabs, patch?) do
    tab = "##{tabs_id}-tab-#{value}"
    panel = "##{tabs_id}-panel-#{value}"

    base =
      JS.remove_class("tabs-trigger-active", to: "##{tabs_id} .tabs-trigger")
      |> JS.add_class("tabs-trigger-active", to: tab)
      |> JS.set_attribute({"aria-selected", "false"}, to: "##{tabs_id} [role='tab']")
      |> JS.set_attribute({"aria-selected", "true"}, to: tab)
      |> JS.set_attribute({"data-state", "inactive"}, to: "##{tabs_id} [role='tab']")
      |> JS.set_attribute({"data-state", "active"}, to: tab)
      |> JS.set_attribute({"tabindex", "-1"}, to: "##{tabs_id} [role='tab']")
      |> JS.set_attribute({"tabindex", "0"}, to: tab)

    others = Enum.reject(all_tabs, &(&1.value == value))

    base =
      Enum.reduce(others, base, fn other, js ->
        other_panel = "##{tabs_id}-panel-#{other.value}"

        js
        |> JS.set_attribute({"hidden", "hidden"}, to: other_panel)
        |> JS.set_attribute({"data-state", "inactive"}, to: other_panel)
      end)

    base = JS.set_attribute(base, {"data-state", "active"}, to: panel)

    if patch? do
      JS.remove_attribute(base, "hidden", to: panel)
    else
      Enum.reduce(others, base, fn other, js ->
        JS.hide(js, to: "##{tabs_id}-panel-#{other.value}")
      end)
      |> JS.show(to: panel)
      |> JS.remove_attribute("hidden", to: panel)
    end
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
      <.choice
        :for={item <- @item}
        id={item[:id]}
        patch={item[:patch]}
        navigate={item[:navigate]}
        click={item[:click]}
        phx-value-filter={item[:value]}
        phx-target={@target}
        aria-current={(item[:patch] || item[:navigate]) && item[:active] && "page"}
        aria-pressed={!(item[:patch] || item[:navigate]) && to_string(!!item[:active])}
        data-state={if item[:active], do: "active", else: "idle"}
        class="filter-tab"
      >
        {item.inner_block && render_slot([item])}{item.label}<span
          :if={item[:count]}
          class="filter-tab-count"
        >{item.count}</span>
      </.choice>
    </div>
    """
  end
end
