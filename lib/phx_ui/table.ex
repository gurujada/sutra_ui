defmodule PhxUI.Table do
  @moduledoc """
  A responsive table component for displaying structured data.

  Provides both a simple wrapper for manual table markup and a data-driven
  approach for generating tables from lists.

  ## Examples

      # Simple wrapper
      <.table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>John</td>
            <td>john@example.com</td>
          </tr>
        </tbody>
      </.table>

      # Data-driven
      <.data_table rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
      </.data_table>
  """

  use Phoenix.Component

  @doc """
  Renders a table wrapper that applies table styles.

  ## Examples

      <.table>
        <thead>
          <tr><th>Invoice</th><th>Amount</th></tr>
        </thead>
        <tbody>
          <tr><td>INV001</td><td>$250.00</td></tr>
        </tbody>
      </.table>
  """
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true, doc: "The table content (thead, tbody, tfoot, caption)")

  def table(assigns) do
    ~H"""
    <table class={["table", @class]} {@rest}>
      {render_slot(@inner_block)}
    </table>
    """
  end

  @doc """
  Renders a data-driven table component.

  Useful when you have a list of data and want to define columns declaratively.

  ## Examples

      <.data_table rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
        <:action :let={user}>
          <.link href={~p"/users/\#{user.id}"}>View</.link>
        </:action>
      </.data_table>
  """
  attr(:rows, :list, required: true, doc: "The list of data to display")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot(:caption, doc: "Optional table caption")

  slot :col, required: true, doc: "Columns to display" do
    attr(:label, :string, required: true, doc: "Column header label")
    attr(:class, :string, doc: "Additional CSS classes for cells in this column")
  end

  slot :action, doc: "Optional action column" do
    attr(:label, :string, doc: "Action column header label")
  end

  slot(:footer, doc: "Optional table footer content")

  def data_table(assigns) do
    ~H"""
    <table class={["table", @class]} {@rest}>
      <%= if @caption != [] do %>
        <caption>{render_slot(@caption)}</caption>
      <% end %>

      <thead>
        <tr>
          <th :for={col <- @col} class={col[:class]}>{col.label}</th>
          <th :if={@action != []}>
            {if @action != [] && hd(@action)[:label], do: hd(@action).label, else: ""}
          </th>
        </tr>
      </thead>

      <tbody>
        <tr :for={row <- @rows}>
          <td :for={col <- @col} class={col[:class]}>
            {render_slot(col, row)}
          </td>
          <td :if={@action != []}>
            {render_slot(@action, row)}
          </td>
        </tr>
      </tbody>

      <%= if @footer != [] do %>
        <tfoot>
          <tr>
            {render_slot(@footer)}
          </tr>
        </tfoot>
      <% end %>
    </table>
    """
  end
end
