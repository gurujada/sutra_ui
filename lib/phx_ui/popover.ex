defmodule PhxUI.Popover do
  @moduledoc """
  A floating content panel that appears on click or keyboard interaction.

  Popovers are used to display rich content in a floating panel that is
  positioned relative to a trigger element. Unlike tooltips, popovers
  are interactive and can contain buttons, forms, and other elements.

  ## Examples

      <.popover id="user-popover">
        <:trigger>
          <button class="btn">User Info</button>
        </:trigger>
        <div class="p-4">
          <p>User details go here</p>
          <button class="btn btn-primary">View Profile</button>
        </div>
      </.popover>

      <.popover id="settings-popover" side="right" align="start">
        <:trigger>
          <button class="btn">Settings</button>
        </:trigger>
        Settings content...
      </.popover>

  ## Accessibility

  - Trigger has `aria-expanded` and `aria-controls` attributes
  - Popover content is hidden from screen readers when closed
  - Escape key closes the popover
  - Click outside closes the popover
  - Focus is managed appropriately
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders a popover component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the popover")

  attr(:side, :string,
    default: "bottom",
    values: ~w(top bottom left right),
    doc: "Which side the popover opens on"
  )

  attr(:align, :string,
    default: "start",
    values: ~w(start center end),
    doc: "Alignment of the popover relative to the trigger"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes for the popover content")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "The element that triggers the popover")
  slot(:inner_block, required: true, doc: "The popover content")

  def popover(assigns) do
    ~H"""
    <div id={@id} class="popover" {@rest}>
      <button
        type="button"
        class="popover-trigger"
        aria-expanded="false"
        aria-controls={"#{@id}-content"}
        phx-click={toggle_popover(@id)}
      >
        {render_slot(@trigger)}
      </button>
      <div
        id={"#{@id}-content"}
        class={@class}
        data-popover
        data-side={@side}
        data-align={@align}
        role="dialog"
        aria-hidden="true"
        phx-click-away={hide_popover(@id)}
        phx-window-keydown={hide_popover(@id)}
        phx-key="escape"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Shows a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.show_popover("my-popover")}>Open</button>
  """
  def show_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "false"}, to: "##{id}-content")
  end

  @doc """
  Hides a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.hide_popover("my-popover")}>Close</button>
  """
  def hide_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id} .popover-trigger")
    |> JS.set_attribute({"aria-hidden", "true"}, to: "##{id}-content")
  end

  @doc """
  Toggles a popover by ID.

  ## Examples

      <button phx-click={PhxUI.Popover.toggle_popover("my-popover")}>Toggle</button>
  """
  def toggle_popover(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id} .popover-trigger")
    |> JS.toggle_attribute({"aria-hidden", "false", "true"}, to: "##{id}-content")
  end
end
