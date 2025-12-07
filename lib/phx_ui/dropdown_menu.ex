defmodule PhxUI.DropdownMenu do
  @moduledoc """
  Displays a menu to the user with a list of actions or options.

  Dropdown menus are triggered by a button and display a list of
  options or actions that the user can select.

  ## Examples

      <.dropdown_menu>
        <:trigger>
          <button class="btn">Options</button>
        </:trigger>
        <:item icon="hero-user">Profile</:item>
        <:item icon="hero-cog-6-tooth" shortcut="⌘S">Settings</:item>
        <:separator />
        <:item variant="destructive" icon="hero-arrow-right-on-rectangle">Logout</:item>
      </.dropdown_menu>

  ## With keyboard shortcuts

      <.dropdown_menu>
        <:trigger>
          <button class="btn">Edit</button>
        </:trigger>
        <:item icon="hero-scissors" shortcut="⌘X">Cut</:item>
        <:item icon="hero-document-duplicate" shortcut="⌘C">Copy</:item>
        <:item icon="hero-clipboard" shortcut="⌘V">Paste</:item>
      </.dropdown_menu>

  ## Accessibility

  - Uses proper ARIA menu roles
  - Keyboard navigation with arrow keys
  - Escape to close
  - Focus management
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  import PhxUI.Icon, only: [icon: 1]

  @doc """
  Renders a dropdown menu component.
  """
  attr(:id, :string, default: nil, doc: "Unique identifier for the dropdown")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:align, :string,
    default: "start",
    values: ~w(start center end),
    doc: "Alignment of the dropdown relative to the trigger"
  )

  attr(:side, :string,
    default: "bottom",
    values: ~w(top bottom left right),
    doc: "Which side the dropdown opens on"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:trigger, required: true, doc: "The element that triggers the dropdown")

  slot :item, doc: "Menu items" do
    attr(:variant, :string, doc: "Visual variant (default or destructive)")
    attr(:disabled, :boolean, doc: "Whether the item is disabled")
    attr(:on_click, :string, doc: "Event to send when clicked")
    attr(:icon, :string, doc: "Icon name to display on the left (e.g., 'hero-user')")
    attr(:shortcut, :string, doc: "Keyboard shortcut to display on the right (e.g., '⌘K')")
  end

  slot(:separator, doc: "Visual separator between items")
  slot(:label, doc: "Non-interactive label/header for a group")

  def dropdown_menu(assigns) do
    assigns =
      assign(assigns, :id, assigns[:id] || "dropdown-#{System.unique_integer([:positive])}")

    ~H"""
    <div
      id={@id}
      class={["dropdown", @class]}
      phx-hook=".DropdownMenu"
      data-align={@align}
      data-side={@side}
      {@rest}
    >
      <div class="dropdown-trigger" phx-click={toggle_dropdown(@id)}>
        {render_slot(@trigger)}
      </div>
      <div
        id={"#{@id}-content"}
        class={["dropdown-content", "dropdown-#{@side}", "dropdown-align-#{@align}"]}
        role="menu"
        aria-orientation="vertical"
        style="display: none;"
      >
        <%= for slot <- build_menu_items(assigns) do %>
          <%= case slot.type do %>
            <% :label -> %>
              <div class="dropdown-label" role="presentation">
                {render_slot([slot.item])}
              </div>
            <% :separator -> %>
              <div class="dropdown-separator" role="separator"></div>
            <% :item -> %>
              <button
                type="button"
                role="menuitem"
                class={[
                  "dropdown-item",
                  slot.item[:variant] == "destructive" && "dropdown-item-destructive",
                  slot.item[:disabled] && "dropdown-item-disabled"
                ]}
                disabled={slot.item[:disabled]}
                phx-click={
                  JS.push(slot.item[:on_click] || "dropdown_item_click")
                  |> close_dropdown(@id)
                }
              >
                <span :if={slot.item[:icon]} class="dropdown-item-icon">
                  <.icon name={slot.item[:icon]} />
                </span>
                <span class="dropdown-item-label">{render_slot([slot.item])}</span>
                <span :if={slot.item[:shortcut]} class="dropdown-item-shortcut">
                  {slot.item[:shortcut]}
                </span>
              </button>
          <% end %>
        <% end %>
      </div>
    </div>

    <script :type={ColocatedHook} name=".DropdownMenu">
      export default {
        mounted() {
          this.content = this.el.querySelector('[role="menu"]');
          this.items = [];
          this.currentIndex = -1;
          
          // Close on click outside
          this.outsideClickHandler = (e) => {
            if (!this.el.contains(e.target) && this.isOpen()) {
              this.close();
            }
          };
          document.addEventListener('click', this.outsideClickHandler);
          
          // Keyboard navigation
          this.el.addEventListener('keydown', (e) => this.handleKeydown(e));
        },
        destroyed() {
          document.removeEventListener('click', this.outsideClickHandler);
        },
        isOpen() {
          return this.content.style.display !== 'none';
        },
        handleKeydown(e) {
          if (!this.isOpen()) return;
          
          this.items = Array.from(this.content.querySelectorAll('[role="menuitem"]:not([disabled])'));
          
          switch(e.key) {
            case 'Escape':
              e.preventDefault();
              this.close();
              this.el.querySelector('.dropdown-trigger button, .dropdown-trigger [role="button"]')?.focus();
              break;
            case 'ArrowDown':
              e.preventDefault();
              this.currentIndex = Math.min(this.currentIndex + 1, this.items.length - 1);
              this.items[this.currentIndex]?.focus();
              break;
            case 'ArrowUp':
              e.preventDefault();
              this.currentIndex = Math.max(this.currentIndex - 1, 0);
              this.items[this.currentIndex]?.focus();
              break;
            case 'Home':
              e.preventDefault();
              this.currentIndex = 0;
              this.items[0]?.focus();
              break;
            case 'End':
              e.preventDefault();
              this.currentIndex = this.items.length - 1;
              this.items[this.currentIndex]?.focus();
              break;
          }
        },
        close() {
          this.content.style.display = 'none';
          this.el.classList.remove('dropdown-open');
          this.currentIndex = -1;
        }
      }
    </script>
    """
  end

  defp build_menu_items(assigns) do
    items = Enum.map(assigns.item, &%{type: :item, item: &1})
    separators = Enum.map(assigns.separator, &%{type: :separator, item: &1})
    labels = Enum.map(assigns.label, &%{type: :label, item: &1})

    # Simple concatenation - in real usage you might want to interleave based on position
    (labels ++ items ++ separators)
    |> Enum.sort_by(&(&1.item[:__slot__] || 0))
  end

  defp toggle_dropdown(id) do
    JS.toggle(to: "##{id}-content")
    |> JS.toggle_class("dropdown-open", to: "##{id}")
    |> JS.focus_first(to: "##{id}-content [role='menuitem']:not([disabled])")
  end

  defp close_dropdown(js, id) do
    JS.hide(js, to: "##{id}-content")
    |> JS.remove_class("dropdown-open", to: "##{id}")
  end
end
