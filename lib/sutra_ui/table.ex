defmodule SutraUI.Table do
  @moduledoc """
  Responsive table components for displaying structured data.

  Provides both a simple wrapper for manual table markup and a data-driven
  approach for generating tables from lists. Use the wrapper for full control,
  or the data-driven version for rapid development.

  ## Examples

      # Simple wrapper - full control over markup
      <.table>
        <thead>
          <tr>
            <th>Invoice</th>
            <th>Status</th>
            <th class="text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={invoice <- @invoices}>
            <td>{invoice.number}</td>
            <td><.badge>{invoice.status}</.badge></td>
            <td class="text-right">{invoice.amount}</td>
          </tr>
        </tbody>
      </.table>

      # Data-driven table
      <.data_table rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
        <:col :let={user} label="Role">
          <.badge variant={role_variant(user.role)}>{user.role}</.badge>
        </:col>
        <:action :let={user}>
          <.button size="sm" variant="ghost" navigate={~p"/users/\#{user.id}"}>
            View
          </.button>
        </:action>
      </.data_table>

      # With caption and footer
      <.data_table rows={@transactions}>
        <:caption>Recent Transactions</:caption>
        <:col :let={t} label="Date">{format_date(t.date)}</:col>
        <:col :let={t} label="Description">{t.description}</:col>
        <:col :let={t} label="Amount" class="text-right">
          {format_currency(t.amount)}
        </:col>
        <:footer>
          <td colspan="2">Total</td>
          <td class="text-right">{format_currency(@total)}</td>
        </:footer>
      </.data_table>

  ## Components

  | Component | Description |
  |-----------|-------------|
  | `table/1` | Simple wrapper with table styling |
  | `data_table/1` | Data-driven table generator |

  ## Data Table Slots

  | Slot | Required | Description |
  |------|----------|-------------|
  | `col` | Yes | Column definitions with `:let` binding |
  | `action` | No | Row action buttons (right-aligned) |
  | `caption` | No | Table caption/title |
  | `footer` | No | Footer row content |

  ### Column Slot Attributes

  | Attribute | Type | Description |
  |-----------|------|-------------|
  | `label` | string | **Required.** Column header text |
  | `class` | string | CSS classes for header and cells |

  ### Action Slot Attributes

  | Attribute | Type | Description |
  |-----------|------|-------------|
  | `label` | string | Optional header text for actions column |

  ## When to Use Each

  | Component | Use When |
  |-----------|----------|
  | `table/1` | Complex layouts, colspan/rowspan, custom `<thead>`/`<tfoot>` |
  | `data_table/1` | Simple row iteration, consistent columns, quick prototyping |

  ## Styling

  Tables use CSS classes from `sutra_ui.css`:

  - `.table` - Base table styling
  - Column alignment via Tailwind (`text-right`, `text-center`)
  - Responsive overflow handled by wrapper

  > #### Large Data Sets {: .tip}
  >
  > For tables with many rows, consider using `SutraUI.Pagination` and
  > loading data in pages. For very large datasets, look into virtual
  > scrolling solutions.

  ## Accessibility

  - Uses semantic `<table>`, `<thead>`, `<tbody>`, `<tfoot>` elements
  - `<caption>` provides table description for screen readers
  - Column headers in `<th>` elements
  - Proper table structure for screen reader navigation

  ## Related

  - `SutraUI.Pagination` - For paging through table data
  - `SutraUI.Skeleton` - For loading states
  - `SutraUI.Empty` - For empty table states
  - `SutraUI.Badge` - For status indicators in cells
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
