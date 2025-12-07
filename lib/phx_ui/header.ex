defmodule PhxUI.Header do
  @moduledoc """
  A header component for page titles and actions.

  Provides a consistent way to display page headers with titles,
  subtitles, and action buttons across your application.

  ## Examples

      <.header>
        Dashboard
      </.header>

      <.header>
        Settings
        <:subtitle>Manage your account preferences</:subtitle>
      </.header>

      <.header>
        Users
        <:actions>
          <.button navigate={~p"/users/new"}>New User</.button>
        </:actions>
      </.header>
  """

  use Phoenix.Component

  @doc """
  Renders a page header with optional subtitle and actions.

  ## Slots

  - `inner_block` (required) - The main title text
  - `subtitle` - Optional subtitle text displayed below the title
  - `actions` - Optional action buttons displayed on the right side
  """
  slot(:inner_block, required: true, doc: "The main title content")
  slot(:subtitle, doc: "Optional subtitle text")
  slot(:actions, doc: "Optional action buttons")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  def header(assigns) do
    ~H"""
    <header class={["header", @actions != [] && "header-with-actions", @class]}>
      <div>
        <h1 class="header-title">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="header-subtitle">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="header-actions">{render_slot(@actions)}</div>
    </header>
    """
  end
end
