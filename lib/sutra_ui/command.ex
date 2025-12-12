defmodule SutraUI.Command do
  @moduledoc """
  A command palette component for fast keyboard-driven navigation and actions.

  Command palettes provide a searchable, keyboard-navigable list of commands
  or options. They can be used inline or as a modal dialog.

  ## Examples

      # Inline command menu
      <.command id="actions" placeholder="Search actions...">
        <.command_group heading="Actions">
          <.command_item id="new-file" phx-click="new_file">New File</.command_item>
          <.command_item id="open-file" phx-click="open_file">Open File</.command_item>
        </.command_group>
        <.command_separator />
        <.command_group heading="Settings">
          <.command_item id="preferences">Preferences</.command_item>
        </.command_group>
      </.command>

      # Modal command palette (Cmd+K style)
      <.command_dialog id="cmd-palette">
        <.command_group heading="Navigation">
          <.command_item id="home" keywords={["index", "main"]}>Home</.command_item>
          <.command_item id="settings" keywords={["preferences", "config"]}>Settings</.command_item>
        </.command_group>
      </.command_dialog>

  ## Accessibility

  - Full keyboard navigation (Arrow keys, Home, End, Enter, Escape)
  - Search/filter functionality with live updates
  - Proper ARIA roles and attributes
  - Focus management
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @doc """
  Renders an inline command menu.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the command")

  attr(:placeholder, :string,
    default: "Type a command or search...",
    doc: "Search input placeholder"
  )

  attr(:empty_text, :string,
    default: "No results found.",
    doc: "Text shown when no results match"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Command items and groups")

  def command(assigns) do
    ~H"""
    <div
      id={@id}
      class={["command", @class]}
      data-command
      data-command-initialized="true"
      phx-hook=".Command"
      {@rest}
    >
      <header>
        <.icon name="lucide-search" />
        <input
          type="text"
          placeholder={@placeholder}
          autocomplete="off"
          autocorrect="off"
          spellcheck="false"
          aria-autocomplete="list"
          role="combobox"
          aria-expanded="true"
          aria-controls={"#{@id}-menu"}
          phx-debounce="100"
        />
      </header>
      <div id={"#{@id}-menu"} role="menu" aria-label="Commands" data-empty={@empty_text}>
        {render_slot(@inner_block)}
      </div>
    </div>

    <script :type={ColocatedHook} name=".Command">
      export default {
        mounted() {
          this.input = this.el.querySelector('input');
          this.menu = this.el.querySelector('[role="menu"]');
          this.items = [];
          this.activeIndex = -1;
          
          this.refreshItems();
          
          // Search/filter
          this.input.addEventListener('input', (e) => this.handleSearch(e.target.value));
          
          // Keyboard navigation
          this.input.addEventListener('keydown', (e) => this.handleKeydown(e));
          
          // Item click
          this.menu.addEventListener('click', (e) => {
            const item = e.target.closest('[role="menuitem"]');
            if (item && !item.hasAttribute('aria-disabled')) {
              this.selectItem(item);
            }
          });
        },
        
        refreshItems() {
          this.items = Array.from(this.el.querySelectorAll('[role="menuitem"]'));
        },
        
        handleSearch(query) {
          const normalizedQuery = query.toLowerCase().trim();
          
          this.items.forEach(item => {
            const text = item.textContent.toLowerCase();
            const keywords = (item.dataset.keywords || '').toLowerCase();
            const matches = !normalizedQuery || 
                           text.includes(normalizedQuery) || 
                           keywords.includes(normalizedQuery);
            
            item.setAttribute('aria-hidden', !matches);
          });
          
          // Reset active item
          this.setActiveItem(-1);
          
          // Auto-select first visible item
          const visibleItems = this.getVisibleItems();
          if (visibleItems.length > 0) {
            this.setActiveItem(0);
          }
        },
        
        getVisibleItems() {
          return this.items.filter(item => item.getAttribute('aria-hidden') !== 'true');
        },
        
        handleKeydown(e) {
          const visibleItems = this.getVisibleItems();
          if (visibleItems.length === 0) return;
          
          switch(e.key) {
            case 'ArrowDown':
              e.preventDefault();
              this.moveActive(1, visibleItems);
              break;
            case 'ArrowUp':
              e.preventDefault();
              this.moveActive(-1, visibleItems);
              break;
            case 'Home':
              e.preventDefault();
              this.setActiveItem(0, visibleItems);
              break;
            case 'End':
              e.preventDefault();
              this.setActiveItem(visibleItems.length - 1, visibleItems);
              break;
            case 'Enter':
              e.preventDefault();
              if (this.activeIndex >= 0 && visibleItems[this.activeIndex]) {
                this.selectItem(visibleItems[this.activeIndex]);
              }
              break;
            case 'Escape':
              // Let it bubble for dialog close
              break;
          }
        },
        
        moveActive(delta, visibleItems) {
          const newIndex = Math.max(0, Math.min(visibleItems.length - 1, this.activeIndex + delta));
          this.setActiveItem(newIndex, visibleItems);
        },
        
        setActiveItem(index, visibleItems = this.getVisibleItems()) {
          // Remove active class from all
          this.items.forEach(item => item.classList.remove('active'));
          
          this.activeIndex = index;
          
          if (index >= 0 && visibleItems[index]) {
            visibleItems[index].classList.add('active');
            visibleItems[index].scrollIntoView({ block: 'nearest' });
          }
        },
        
        selectItem(item) {
          if (item.hasAttribute('aria-disabled') && item.getAttribute('aria-disabled') === 'true') {
            return;
          }
          
          // Trigger click event for phx-click handlers
          item.click();
        }
      }
    </script>
    """
  end

  @doc """
  Renders a modal command dialog (Cmd+K style).
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the command dialog")

  attr(:placeholder, :string,
    default: "Type a command or search...",
    doc: "Search input placeholder"
  )

  attr(:empty_text, :string,
    default: "No results found.",
    doc: "Text shown when no results match"
  )

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Command items and groups")

  def command_dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      class="command-dialog"
      aria-label="Command palette"
      {@rest}
    >
      <div class={@class}>
        <.command
          id={"#{@id}-command"}
          placeholder={@placeholder}
          empty_text={@empty_text}
        >
          {render_slot(@inner_block)}
        </.command>
      </div>
    </dialog>
    """
  end

  @doc """
  Renders a command item.
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the item")
  attr(:keywords, :list, default: [], doc: "Additional search keywords")
  attr(:disabled, :boolean, default: false, doc: "Whether the item is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(phx-click phx-value-id),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, required: true, doc: "The item content")

  def command_item(assigns) do
    keywords = Enum.join(assigns.keywords, " ")
    assigns = assign(assigns, :keywords_str, keywords)

    ~H"""
    <button
      id={@id}
      type="button"
      class={@class}
      role="menuitem"
      data-keywords={@keywords_str}
      aria-disabled={to_string(@disabled)}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a command group with an optional heading.
  """
  attr(:heading, :string, default: nil, doc: "Group heading text")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "Command items in this group")

  def command_group(assigns) do
    ~H"""
    <div class={@class} role="group" aria-label={@heading} {@rest}>
      <div :if={@heading} role="heading" aria-hidden="true">
        {@heading}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a separator between command items or groups.
  """
  def command_separator(assigns) do
    ~H"""
    <hr role="separator" />
    """
  end

  @doc """
  Shows a command dialog by ID.

  ## Examples

      <button phx-click={PhxUI.Command.show_command_dialog("cmd-palette")}>Open</button>
  """
  def show_command_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:show-dialog", to: "##{id}")
  end

  @doc """
  Hides a command dialog by ID.

  ## Examples

      <button phx-click={PhxUI.Command.hide_command_dialog("cmd-palette")}>Close</button>
  """
  def hide_command_dialog(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.dispatch("phx:hide-dialog", to: "##{id}")
  end
end
