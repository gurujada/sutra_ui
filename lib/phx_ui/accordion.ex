defmodule PhxUI.Accordion do
  @moduledoc """
  A vertically stacked set of interactive headings that reveal content.

  Accordions are useful for organizing content into collapsible sections,
  reducing visual clutter while keeping content accessible.

  ## Examples

      <.accordion>
        <:item title="Section 1" value="item-1">
          Content for section 1
        </:item>
        <:item title="Section 2" value="item-2">
          Content for section 2
        </:item>
      </.accordion>

      # Single mode (only one open at a time)
      <.accordion type="single">
        <:item title="FAQ 1" value="faq-1">Answer 1</:item>
        <:item title="FAQ 2" value="faq-2">Answer 2</:item>
      </.accordion>

  ## Accessibility

  - Uses proper ARIA attributes for accordion pattern
  - Keyboard navigation with Enter/Space to toggle
  - `aria-expanded` indicates open/closed state
  - `aria-controls` links trigger to content panel
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders an accordion component.
  """
  attr(:type, :string,
    default: "single",
    values: ~w(single multiple),
    doc: "Whether one or multiple items can be open"
  )

  attr(:default_value, :any,
    default: nil,
    doc: "The value(s) of items to open by default"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id),
    doc: "Additional HTML attributes"
  )

  slot :item, required: true, doc: "Accordion items" do
    attr(:value, :string, required: true, doc: "Unique identifier for the item")
    attr(:title, :string, required: true, doc: "The header text")
    attr(:disabled, :boolean, doc: "Whether the item is disabled")
  end

  def accordion(assigns) do
    default_value = assigns.default_value

    default_open =
      cond do
        is_list(default_value) -> default_value
        is_binary(default_value) -> [default_value]
        true -> []
      end

    assigns = assign(assigns, :default_open, default_open)

    ~H"""
    <div class={["accordion", @class]} data-type={@type} {@rest}>
      <%= for item <- @item do %>
        <div
          class={["accordion-item", item[:disabled] && "accordion-disabled"]}
          data-state={if item.value in @default_open, do: "open", else: "closed"}
          id={"accordion-item-#{item.value}"}
        >
          <h3 class="accordion-header">
            <button
              type="button"
              class="accordion-trigger"
              aria-expanded={if item.value in @default_open, do: "true", else: "false"}
              aria-controls={"accordion-content-#{item.value}"}
              disabled={item[:disabled]}
              phx-click={toggle_item(item.value, @type)}
            >
              <span>{item.title}</span>
              <svg
                class="accordion-chevron"
                xmlns="http://www.w3.org/2000/svg"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="m6 9 6 6 6-6" />
              </svg>
            </button>
          </h3>
          <div
            id={"accordion-content-#{item.value}"}
            class="accordion-content"
            role="region"
            aria-labelledby={"accordion-trigger-#{item.value}"}
            style={if item.value not in @default_open, do: "display: none;", else: nil}
          >
            <div class="accordion-content-inner">
              {render_slot([item])}
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp toggle_item(value, _type) do
    JS.toggle_attribute({"aria-expanded", "true", "false"},
      to: "#accordion-item-#{value} .accordion-trigger"
    )
    |> JS.toggle_attribute({"data-state", "open", "closed"},
      to: "#accordion-item-#{value}"
    )
    |> JS.toggle(to: "#accordion-content-#{value}")
  end
end
