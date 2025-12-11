defmodule SutraUI.DropdownMenu do
  @moduledoc """
  Displays a menu to the user with a list of actions or options.

  Dropdown menus are triggered by a button and display a list of
  options or actions that the user can select.

  ## Examples

      <.dropdown_menu>
        <:trigger>
          <span>Options</span>
        </:trigger>
        <:item icon="hero-user">Profile</:item>
        <:item icon="hero-cog-6-tooth" shortcut="Ctrl+S">Settings</:item>
        <:separator />
        <:item variant="destructive" icon="hero-arrow-right-on-rectangle">Logout</:item>
      </.dropdown_menu>

  ## With keyboard shortcuts

      <.dropdown_menu>
        <:trigger>
          <span>Edit</span>
        </:trigger>
        <:item icon="hero-scissors" shortcut="Ctrl+X">Cut</:item>
        <:item icon="hero-document-duplicate" shortcut="Ctrl+C">Copy</:item>
        <:item icon="hero-clipboard" shortcut="Ctrl+V">Paste</:item>
      </.dropdown_menu>

  ## Accessibility

  - Uses proper ARIA menu roles
  - Keyboard navigation with arrow keys
  - Escape to close
  - Focus management
  - Shortcuts trigger actions when pressed
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders a dropdown menu component.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the dropdown")
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
    attr(:shortcut, :string, doc: "Keyboard shortcut to display on the right (e.g., 'Ctrl+K')")
  end

  slot(:separator, doc: "Visual separator between items")
  slot(:label, doc: "Non-interactive label/header for a group")

  def dropdown_menu(assigns) do
    # Collect shortcuts for keyboard handling
    shortcuts =
      assigns.item
      |> Enum.filter(&(&1[:shortcut] && &1[:on_click]))
      |> Enum.map(&%{shortcut: &1[:shortcut], event: &1[:on_click]})

    assigns = assign(assigns, :shortcuts, Jason.encode!(shortcuts))

    ~H"""
    <div
      id={@id}
      class={["dropdown", @class]}
      phx-hook=".DropdownMenu"
      data-align={@align}
      data-side={@side}
      data-shortcuts={@shortcuts}
      {@rest}
    >
      <button type="button" class="dropdown-trigger" aria-haspopup="true" aria-expanded="false">
        {render_slot(@trigger)}
        <.icon name="hero-chevron-down" class="dropdown-chevron size-4" />
      </button>
      <div
        id={"#{@id}-content"}
        class={["dropdown-content", "dropdown-#{@side}", "dropdown-align-#{@align}"]}
        role="menu"
        aria-orientation="vertical"
        aria-hidden="true"
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
                phx-click={slot.item[:on_click] && JS.push(slot.item[:on_click])}
                data-shortcut={slot.item[:shortcut]}
              >
                <span :if={slot.item[:icon]} class="dropdown-item-icon">
                  <.icon name={slot.item[:icon]} />
                </span>
                <span :if={!slot.item[:icon]} class="dropdown-item-icon-placeholder"></span>
                <span class="dropdown-item-label">{render_slot([slot.item])}</span>
                <kbd :if={slot.item[:shortcut]} class="dropdown-item-shortcut">
                  {slot.item[:shortcut]}
                </kbd>
              </button>
          <% end %>
        <% end %>
      </div>
    </div>

    <script :type={ColocatedHook} name=".DropdownMenu">
      export default {
        mounted() {
          this.trigger = this.el.querySelector('.dropdown-trigger');
          this.content = this.el.querySelector('[role="menu"]');
          this.items = [];
          this.currentIndex = -1;
          
          // Parse shortcuts
          try {
            this.shortcuts = JSON.parse(this.el.dataset.shortcuts || '[]');
          } catch(e) {
            this.shortcuts = [];
          }
          
          // Toggle on trigger click
          this.trigger.addEventListener('click', () => this.toggle());
          
          // Close on click outside
          this.outsideClickHandler = (e) => {
            if (!this.el.contains(e.target) && this.isOpen()) {
              this.close();
            }
          };
          document.addEventListener('click', this.outsideClickHandler);
          
          // Keyboard navigation and shortcuts
          this.keydownHandler = (e) => this.handleKeydown(e);
          document.addEventListener('keydown', this.keydownHandler);
          
          // Close dropdown when item is clicked
          this.content.addEventListener('click', (e) => {
            if (e.target.closest('[role="menuitem"]')) {
              this.close();
            }
          });
        },
        
        destroyed() {
          document.removeEventListener('click', this.outsideClickHandler);
          document.removeEventListener('keydown', this.keydownHandler);
        },
        
        isOpen() {
          return this.trigger.getAttribute('aria-expanded') === 'true';
        },
        
        toggle() {
          if (this.isOpen()) {
            this.close();
          } else {
            this.open();
          }
        },
        
        open() {
          this.trigger.setAttribute('aria-expanded', 'true');
          this.content.setAttribute('aria-hidden', 'false');
          this.el.classList.add('dropdown-open');
          this.items = Array.from(this.content.querySelectorAll('[role="menuitem"]:not([disabled])'));
          this.currentIndex = -1;
        },
        
        close() {
          this.trigger.setAttribute('aria-expanded', 'false');
          this.content.setAttribute('aria-hidden', 'true');
          this.el.classList.remove('dropdown-open');
          this.currentIndex = -1;
        },
        
        handleKeydown(e) {
          // Check for shortcuts (Ctrl+Key combinations)
          if (e.ctrlKey || e.metaKey) {
            const key = e.key.toUpperCase();
            const shortcutStr = `Ctrl+${key}`;
            
            const item = this.content.querySelector(`[data-shortcut="${shortcutStr}"]`);
            if (item && !item.disabled) {
              e.preventDefault();
              item.click();
              return;
            }
          }
          
          if (!this.isOpen()) return;
          
          this.items = Array.from(this.content.querySelectorAll('[role="menuitem"]:not([disabled])'));
          
          switch(e.key) {
            case 'Escape':
              e.preventDefault();
              this.close();
              this.trigger.focus();
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
            case 'Enter':
            case ' ':
              if (document.activeElement?.getAttribute('role') === 'menuitem') {
                e.preventDefault();
                document.activeElement.click();
              }
              break;
          }
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
end
