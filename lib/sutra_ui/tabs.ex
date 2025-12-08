defmodule SutraUI.Tabs do
  @moduledoc """
  A set of layered sections of content, known as tab panels.

  Tabs organize content into separate views where only one view is
  visible at a time.

  ## Examples

      <.tabs id="settings-tabs" default_value="tab1">
        <:tab value="tab1">Account</:tab>
        <:tab value="tab2">Password</:tab>
        <:panel value="tab1">Account settings content</:panel>
        <:panel value="tab2">Password settings content</:panel>
      </.tabs>

  ## Accessibility

  - Uses proper ARIA tablist/tab/tabpanel roles
  - Keyboard navigation with arrow keys
  - `aria-selected` indicates active tab
  - `aria-controls` links tabs to panels
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

    <script :type={ColocatedHook} name=".Tabs">
      export default {
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
