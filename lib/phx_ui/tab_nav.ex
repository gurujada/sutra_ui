defmodule PhxUI.TabNav do
  @moduledoc """
  Visual tab navigation component for server-side routed tabs.

  Unlike the full `tabs` component which manages content panels client-side,
  this component only provides the visual tab navigation. Each tab links to
  a different LiveView route, allowing heavy content (analytics, tables, etc.)
  to load only when active.

  ## Features

  - Visual-only tab navigation (no content panel management)
  - Server-side routing via LiveView patches
  - Icon support for tabs
  - Consistent styling across pages
  - Permission-aware rendering (slots can be conditionally rendered)

  ## Examples

      <.tab_nav>
        <:tab patch={~p"/orgs/\#{@org.id}"} active={@active_tab == :show} icon="lucide-info">
          About
        </:tab>
        <:tab patch={~p"/orgs/\#{@org.id}/members"} active={@active_tab == :members} icon="lucide-users">
          Members
        </:tab>
      </.tab_nav>

  ## Permission-aware usage

      <.tab_nav>
        <:tab patch={~p"/batches/\#{@batch.id}"} active={@active_tab == :overview}>
          Overview
        </:tab>
        <%= if @can_manage do %>
          <:tab patch={~p"/batches/\#{@batch.id}/settings"} active={@active_tab == :settings}>
            Settings
          </:tab>
        <% end %>
      </.tab_nav>

  ## With custom class

      <.tab_nav class="mb-6">
        <:tab patch={~p"/dashboard"} active={true}>Dashboard</:tab>
        <:tab patch={~p"/analytics"} active={false}>Analytics</:tab>
      </.tab_nav>
  """
  use Phoenix.Component

  import PhxUI.Icon, only: [icon: 1]

  @doc """
  Renders a visual tab navigation bar.

  ## Attributes

  - `class` - Optional additional CSS classes for the container

  ## Slots

  - `tab` (required) - Tab definitions with patch URL and active state
    - `patch` (required) - LiveView route to navigate to
    - `active` (required) - Boolean indicating if this tab is currently active
    - `icon` - Optional icon name to display before the label
  """
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")

  slot :tab, required: true, doc: "Tab definitions" do
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
    attr(:active, :boolean, required: true, doc: "Whether this tab is active")
    attr(:icon, :string, doc: "Optional icon name")
  end

  def tab_nav(assigns) do
    ~H"""
    <div class={["tab-nav", @class]}>
      <%= for tab <- @tab do %>
        <.link
          patch={tab.patch}
          class={["tab-nav-item", tab.active && "tab-nav-item-active"]}
        >
          <.icon :if={tab[:icon]} name={tab.icon} class="tab-nav-icon" />
          {render_slot(tab)}
        </.link>
      <% end %>
    </div>
    """
  end
end
