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
  - Icon support via inner block
  - Consistent styling across pages
  - Permission-aware rendering (slots can be conditionally rendered)

  ## Examples

      <.tab_nav>
        <:tab patch={~p"/orgs/\#{@org.id}"} active={@active_tab == :show}>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tab-nav-icon"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
          About
        </:tab>
        <:tab patch={~p"/orgs/\#{@org.id}/members"} active={@active_tab == :members}>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tab-nav-icon"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
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

  @doc """
  Renders a visual tab navigation bar.

  ## Attributes

  - `class` - Optional additional CSS classes for the container

  ## Slots

  - `tab` (required) - Tab definitions with patch URL and active state
    - `patch` (required) - LiveView route to navigate to
    - `active` (required) - Boolean indicating if this tab is currently active
    - Inner block can contain icons and text
  """
  attr(:class, :string, default: nil, doc: "Additional CSS classes for the container")

  slot :tab, required: true, doc: "Tab definitions" do
    attr(:patch, :string, required: true, doc: "LiveView patch URL")
    attr(:active, :boolean, required: true, doc: "Whether this tab is active")
  end

  def tab_nav(assigns) do
    ~H"""
    <div class={["tab-nav", @class]}>
      <%= for tab <- @tab do %>
        <.link
          patch={tab.patch}
          class={["tab-nav-item", tab.active && "tab-nav-item-active"]}
        >
          {render_slot(tab)}
        </.link>
      <% end %>
    </div>
    """
  end
end
