defmodule SutraUI.Select do
  @moduledoc """
  A custom select component with search/filter capabilities (combobox pattern).

  Provides a keyboard-accessible custom dropdown select with optional search
  filtering, option grouping, and form integration. Use this instead of native
  `<select>` when you need custom styling or searchable options.

  ## Examples

      # Basic select
      <.select id="country" name="country" value="us">
        <.select_option value="us" label="United States" />
        <.select_option value="ca" label="Canada" />
        <.select_option value="mx" label="Mexico" />
      </.select>

      # Searchable select
      <.select id="framework" name="framework" value="phoenix" searchable>
        <.select_option value="phoenix" label="Phoenix" />
        <.select_option value="rails" label="Rails" />
        <.select_option value="django" label="Django" />
        <.select_option value="laravel" label="Laravel" />
      </.select>

      # With option groups
      <.select id="stack" name="stack" value="phoenix" searchable>
        <.select_group label="Backend">
          <.select_option value="phoenix" label="Phoenix" />
          <.select_option value="rails" label="Rails" />
        </.select_group>
        <.select_separator />
        <.select_group label="Frontend">
          <.select_option value="react" label="React" />
          <.select_option value="vue" label="Vue" />
        </.select_group>
      </.select>

      # With custom trigger content
      <.select id="status" name="status" value={@status}>
        <:trigger>
          <.badge variant={status_variant(@status)}>{@status}</.badge>
        </:trigger>
        <.select_option value="active" label="Active" />
        <.select_option value="pending" label="Pending" />
        <.select_option value="inactive" label="Inactive" />
      </.select>

  ## Components

  | Component | Description |
  |-----------|-------------|
  | `select/1` | Main container with trigger and popover |
  | `select_option/1` | Individual selectable option |
  | `select_group/1` | Labeled group of options |
  | `select_separator/1` | Visual divider between options/groups |

  ## Keyboard Navigation

  | Key | Action |
  |-----|--------|
  | `Enter` / `Space` | Open dropdown or select focused option |
  | `Escape` | Close dropdown |
  | `ArrowDown` | Move to next option |
  | `ArrowUp` | Move to previous option |
  | `Home` | Jump to first option |
  | `End` | Jump to last option |
  | `A-Z` | Jump to first option starting with letter |

  ## Form Integration

  The select renders a hidden `<input>` with the selected value, making it
  compatible with Phoenix forms and `phx-change` events:

      <.form for={@form} class="form" phx-change="validate" phx-submit="save">
        <.select
          id="role-select"
          name={@form[:role].name}
          value={@form[:role].value}
        >
          <.select_option value="admin" label="Administrator" />
          <.select_option value="user" label="User" />
        </.select>
      </.form>

  ## Colocated Hook

  The `.Select` hook handles all interactive behavior:
  - Opening/closing the dropdown popover
  - Keyboard navigation and letter jumping
  - Search filtering (when `searchable`)
  - Value selection and form `change` event dispatch
  - Outside click detection

  See [JavaScript Hooks](colocated-hooks.md) for more details.

  ## Accessibility

  - Uses combobox/listbox-style ARIA roles and attributes
  - `role="listbox"` for the options container
  - `role="option"` for each selectable item
  - `aria-selected` indicates current selection
  - `aria-expanded` reflects dropdown state
  - `aria-controls` links trigger to listbox
  - `aria-disabled` for disabled options

  > #### Required ID {: .warning}
  >
  > The `id` attribute is **required** for the JavaScript hook to function.
  > Each select must have a unique ID on the page.

  ## Related

  - `SutraUI.LiveSelect` - For async/remote data loading
  - `SutraUI.RadioGroup` - For smaller option sets without dropdown
  - `SutraUI.DropdownMenu` - For action menus (not form selection)
  - [Forms Cheatsheet](forms.cheatmd) - Form patterns
  - [Accessibility Guide](accessibility.md) - ARIA patterns
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a custom select component.

  ## Examples

      <.select id="country-select" name="country" value="us">
        <.select_option value="us" label="United States" />
        <.select_option value="ca" label="Canada" />
        <.select_option value="mx" label="Mexico" />
      </.select>

      <.select id="framework-select" name="framework" value="phoenix" searchable>
        <.select_group label="Frontend">
          <.select_option value="react" label="React" />
          <.select_option value="vue" label="Vue" />
        </.select_group>
        <.select_separator />
        <.select_group label="Backend">
          <.select_option value="phoenix" label="Phoenix" />
          <.select_option value="rails" label="Rails" />
        </.select_group>
      </.select>

      <.select id="status-select" name="status" value="active" disabled>
        <.select_option value="active" label="Active" />
        <.select_option value="inactive" label="Inactive" />
      </.select>
  """

  attr(:id, :string, required: true, doc: "Unique identifier for the select (required for hook)")
  attr(:name, :string, default: nil, doc: "Form input name")
  attr(:value, :string, default: nil, doc: "Currently selected value")

  attr(:selected_label, :string,
    default: nil,
    doc: "Display label for the current value (defaults to value if not set)"
  )

  attr(:searchable, :boolean, default: false, doc: "Enable search/filter functionality")

  attr(:search_placeholder, :string,
    default: "Search entries...",
    doc: "Placeholder text for search input"
  )

  attr(:empty_message, :string,
    default: "No results found",
    doc: "Message when no results match search"
  )

  attr(:trigger_class, :string, default: nil, doc: "Additional CSS classes for trigger button")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for main container")
  attr(:disabled, :boolean, default: false, doc: "Whether the select is disabled")

  attr(:rest, :global,
    include: ~w(form phx-change phx-blur phx-focus),
    doc: "Additional HTML attributes"
  )

  slot(:trigger, doc: "Custom content for the trigger button (optional)")
  slot(:inner_block, required: true, doc: "The select options and groups")

  def select(assigns) do
    ~H"""
    <div
      id={@id}
      class={["select", @class]}
      data-select-value={@value}
      phx-hook=".Select"
      {@rest}
    >
      <button
        type="button"
        class={["select-trigger", @trigger_class]}
        id={"#{@id}-trigger"}
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        disabled={@disabled}
      >
        <span class="select-value" data-selected-label>
          <%= if @trigger != [] do %>
            {render_slot(@trigger)}
          <% else %>
            {@selected_label || @value || "Select..."}
          <% end %>
        </span>
        <%= if @searchable do %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="select-icon"
            aria-hidden="true"
          >
            <path d="m7 15 5 5 5-5" /><path d="m7 9 5-5 5 5" />
          </svg>
        <% else %>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="select-icon"
            aria-hidden="true"
          >
            <path d="m6 9 6 6 6-6" />
          </svg>
        <% end %>
      </button>
      <div
        id={"#{@id}-popover"}
        class="select-popover"
        data-popover
        aria-hidden="true"
      >
        <%= if @searchable do %>
          <header>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              aria-hidden="true"
            >
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />
            </svg>
            <input
              type="text"
              value=""
              placeholder={@search_placeholder}
              autocomplete="off"
              autocorrect="off"
              spellcheck="false"
              aria-autocomplete="list"
              role="combobox"
              aria-expanded="false"
              aria-controls={"#{@id}-listbox"}
              aria-labelledby={"#{@id}-trigger"}
            />
          </header>
        <% end %>
        <div
          role="listbox"
          id={"#{@id}-listbox"}
          class="select-listbox"
          aria-orientation="vertical"
          aria-labelledby={"#{@id}-trigger"}
          data-empty={@empty_message}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
      <input
        type="hidden"
        name={@name || "#{@id}-value"}
        value={@value || ""}
        data-select-input
      />

      <script :type={ColocatedHook} name=".Select" runtime>
        {
          mounted() {
            this.initSelect();
          },

          beforeUpdate() {
            // Save popover state BEFORE morphdom patches aria-hidden back to "true"
            this._wasOpen = this.popover && this.popover.getAttribute('aria-hidden') === 'false';
            this._filterValue = this.filter ? this.filter.value : '';
          },

          updated() {
            // Re-query ALL DOM refs (morphdom may have replaced inner elements)
            const oldTrigger = this.trigger;
            const oldListbox = this.listbox;
            const oldFilter = this.filter;
            this.trigger = this.el.querySelector(':scope > button');
            this.selectedLabel = this.trigger.querySelector('[data-selected-label]');
            this.popover = this.el.querySelector('[data-popover]');
            this.listbox = this.popover.querySelector('[role="listbox"]');
            this.input = this.el.querySelector('[data-select-input]');
            this.filter = this.el.querySelector('input[type="text"]');

            // Refresh option references
            this.allOptions = Array.from(this.listbox.querySelectorAll('[role="option"]'));
            this.options = this.allOptions.filter(opt => opt.getAttribute('aria-disabled') !== 'true');
            this.visibleOptions = [...this.options];

            if (this.trigger !== oldTrigger) {
              oldTrigger?.removeEventListener('click', this.handleTriggerClick);
              oldTrigger?.removeEventListener('keydown', this.handleTriggerKeydown);
              this.trigger.addEventListener('click', this.handleTriggerClick);
              this.trigger.addEventListener('keydown', this.handleTriggerKeydown);
            }

            if (this.listbox !== oldListbox) {
              oldListbox?.removeEventListener('click', this.handleListboxClick);
              oldListbox?.removeEventListener('mousemove', this.handleListboxMousemove);
              oldListbox?.removeEventListener('mouseleave', this.handleListboxMouseleave);
              this.listbox.addEventListener('click', this.handleListboxClick);
              this.listbox.addEventListener('mousemove', this.handleListboxMousemove);
              this.listbox.addEventListener('mouseleave', this.handleListboxMouseleave);
            }

            // Re-register filter listeners if the element was replaced by morphdom
            if (this.filter !== oldFilter) {
              this.removeFilterListeners(oldFilter);
              if (this.filter) {
                this.addFilterListeners(this.filter);
              }
            }

            // Sync value from server
            const newValue = this.el.dataset.selectValue;
            this.selectByValue(newValue || this.input.value, false);

            // Restore popover state saved in beforeUpdate
            if (this._wasOpen) {
              this.popover.setAttribute('aria-hidden', 'false');
              this.trigger.setAttribute('aria-expanded', 'true');
              this.filter?.setAttribute('aria-expanded', 'true');
              if (this.filter) {
                this.filter.value = this._filterValue;
                if (this._filterValue) {
                  this.filterOptions();
                }
                setTimeout(() => this.filter.focus(), 0);
              }
            }
          },

          destroyed() {
            document.removeEventListener('click', this.handleOutsideClick);
            this.trigger?.removeEventListener('click', this.handleTriggerClick);
            this.trigger?.removeEventListener('keydown', this.handleTriggerKeydown);
            this.listbox?.removeEventListener('click', this.handleListboxClick);
            this.listbox?.removeEventListener('mousemove', this.handleListboxMousemove);
            this.listbox?.removeEventListener('mouseleave', this.handleListboxMouseleave);
            this.removeFilterListeners(this.filter);
          },

          initSelect() {
            this.trigger = this.el.querySelector(':scope > button');
            this.selectedLabel = this.trigger.querySelector('[data-selected-label]');
            this.popover = this.el.querySelector('[data-popover]');
            this.listbox = this.popover.querySelector('[role="listbox"]');
            this.input = this.el.querySelector('[data-select-input]');
            this.filter = this.el.querySelector('input[type="text"]');

            if (!this.trigger || !this.popover || !this.listbox || !this.input) {
              console.error('SutraUI.Select: Missing required elements');
              return;
            }

            this.allOptions = Array.from(this.listbox.querySelectorAll('[role="option"]'));
            this.options = this.allOptions.filter(opt => opt.getAttribute('aria-disabled') !== 'true');
            this.visibleOptions = [...this.options];
            this.activeIndex = -1;

            this.handleTriggerClick = () => this.togglePopover();
            this.handleTriggerKeydown = (e) => this.handleKeyNavigation(e);
            this.handleListboxClick = (e) => this.handleOptionClick(e);
            this.handleListboxMousemove = (e) => this.handleMouseMove(e);
            this.handleListboxMouseleave = () => this.handleMouseLeave();
            this.handleFilterInput = (e) => {
              e.stopPropagation(); // Prevent bubbling to parent form's phx-change
              this.filterOptions();
            };
            this.handleFilterChange = (e) => e.stopPropagation();
            this.handleFilterKeydown = (e) => this.handleKeyNavigation(e);

            this.trigger.addEventListener('click', this.handleTriggerClick);
            this.trigger.addEventListener('keydown', this.handleTriggerKeydown);
            this.listbox.addEventListener('click', this.handleListboxClick);
            this.listbox.addEventListener('mousemove', this.handleListboxMousemove);
            this.listbox.addEventListener('mouseleave', this.handleListboxMouseleave);

            if (this.filter) {
              this.addFilterListeners(this.filter);
            }

            this.handleOutsideClick = (e) => {
              if (!this.el.contains(e.target)) {
                this.closePopover(false);
              }
            };
            document.addEventListener('click', this.handleOutsideClick);

            const initialValue = this.input.value || this.el.dataset.selectValue;
            if (initialValue) {
              this.selectByValue(initialValue, false);
            } else {
              const firstOption = this.options[0];
              if (firstOption) {
                this.updateValue(firstOption, false);
              }
            }
          },

          setActiveOption(index) {
            if (this.activeIndex > -1 && this.options[this.activeIndex]) {
              this.options[this.activeIndex].classList.remove('bg-accent');
            }

            this.activeIndex = index;
            const activeTargets = [this.trigger, this.filter].filter(Boolean);

            if (this.activeIndex > -1) {
              const activeOption = this.options[this.activeIndex];
              activeOption.classList.add('bg-accent');
              if (activeOption.id) {
                activeTargets.forEach((target) => target.setAttribute('aria-activedescendant', activeOption.id));
              } else {
                activeTargets.forEach((target) => target.removeAttribute('aria-activedescendant'));
              }
            } else {
              activeTargets.forEach((target) => target.removeAttribute('aria-activedescendant'));
            }
          },

          updateValue(option, triggerEvent = true) {
            if (option) {
              const label = option.dataset.label || option.textContent.trim();
              this.selectedLabel.textContent = label;
              this.input.value = option.dataset.value;
              this.el.dataset.selectValue = option.dataset.value;

              this.listbox.querySelector('[role="option"][aria-selected="true"]')?.removeAttribute('aria-selected');
              option.setAttribute('aria-selected', 'true');

              if (triggerEvent) {
                this.input.dispatchEvent(new Event('input', { bubbles: true }));
                this.input.dispatchEvent(new Event('change', { bubbles: true }));
              }
            }
          },

          closePopover(focusOnTrigger = true) {
            if (this.popover.getAttribute('aria-hidden') === 'true') return;

            if (this.filter) {
              this.filter.value = '';
              this.visibleOptions = [...this.options];
              this.allOptions.forEach(opt => opt.setAttribute('aria-hidden', 'false'));
            }

            if (focusOnTrigger) this.trigger.focus();
            this.popover.setAttribute('aria-hidden', 'true');
            this.trigger.setAttribute('aria-expanded', 'false');
            this.filter?.setAttribute('aria-expanded', 'false');
            this.setActiveOption(-1);
          },

          openPopover() {
            this.popover.setAttribute('aria-hidden', 'false');
            this.trigger.setAttribute('aria-expanded', 'true');
            this.filter?.setAttribute('aria-expanded', 'true');

            if (this.filter) {
              setTimeout(() => this.filter.focus(), 0);
            }

            const selectedOption = this.listbox.querySelector('[role="option"][aria-selected="true"]');
            if (selectedOption) {
              this.setActiveOption(this.options.indexOf(selectedOption));
              selectedOption.scrollIntoView({ block: 'nearest' });
            }
          },

          togglePopover() {
            const isExpanded = this.trigger.getAttribute('aria-expanded') === 'true';
            if (isExpanded) {
              this.closePopover();
            } else {
              this.openPopover();
            }
          },

          selectOption(option) {
            if (!option) return;

            const oldValue = this.input.value;
            const newValue = option.dataset.value;

            if (newValue != null && newValue !== oldValue) {
              this.updateValue(option);
            }

            this.closePopover();
          },

          selectByValue(value, triggerEvent = true) {
            const option = this.options.find(opt => opt.dataset.value === value);
            if (option) {
              this.updateValue(option, triggerEvent);
            }
          },

          filterOptions() {
            const searchTerm = this.filter.value.trim().toLowerCase();

            this.setActiveOption(-1);

            this.visibleOptions = [];
            this.allOptions.forEach(option => {
              const optionText = (option.dataset.label || option.textContent).trim().toLowerCase();
              const matches = optionText.includes(searchTerm);
              option.setAttribute('aria-hidden', String(!matches));
              option.style.display = matches ? '' : 'none';
              if (matches && this.options.includes(option)) {
                this.visibleOptions.push(option);
              }
            });
          },

          handleKeyNavigation(event) {
            const isPopoverOpen = this.popover.getAttribute('aria-hidden') === 'false';
            const isSpace = event.key === ' ' || event.key === 'Spacebar';

            if (event.target === this.filter && isSpace) {
              return;
            }

            // Handle letter navigation when popover is open (but NOT when typing in search)
            if (isPopoverOpen && event.key.length === 1 && /[a-zA-Z]/.test(event.key) && event.target !== this.filter) {
              this.jumpToLetter(event.key.toLowerCase());
              return;
            }

            if (!['ArrowDown', 'ArrowUp', 'Enter', 'Home', 'End', 'Escape'].includes(event.key) && !isSpace) {
              return;
            }

            if (!isPopoverOpen) {
              if (event.key !== 'Enter' && event.key !== 'Escape') {
                event.preventDefault();
                this.openPopover();
              }
              return;
            }

            event.preventDefault();

            if (event.key === 'Escape') {
              this.closePopover();
              return;
            }

            if (event.key === 'Enter' || isSpace) {
              if (this.activeIndex > -1) {
                this.selectOption(this.options[this.activeIndex]);
              }
              return;
            }

            if (this.visibleOptions.length === 0) return;

            const currentVisibleIndex = this.activeIndex > -1 ? this.visibleOptions.indexOf(this.options[this.activeIndex]) : -1;
            let nextVisibleIndex = currentVisibleIndex;

            switch (event.key) {
              case 'ArrowDown':
                nextVisibleIndex = currentVisibleIndex < this.visibleOptions.length - 1 ? currentVisibleIndex + 1 : currentVisibleIndex;
                break;
              case 'ArrowUp':
                nextVisibleIndex = currentVisibleIndex > 0 ? currentVisibleIndex - 1 : 0;
                break;
              case 'Home':
                nextVisibleIndex = 0;
                break;
              case 'End':
                nextVisibleIndex = this.visibleOptions.length - 1;
                break;
            }

            if (nextVisibleIndex !== currentVisibleIndex) {
              const newActiveOption = this.visibleOptions[nextVisibleIndex];
              this.setActiveOption(this.options.indexOf(newActiveOption));
              newActiveOption.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
            }
          },

          jumpToLetter(letter) {
            // Find first visible option starting with the letter
            const currentIndex = this.activeIndex > -1 ? this.visibleOptions.indexOf(this.options[this.activeIndex]) : -1;

            // Start searching from after current position, wrap around
            for (let i = 0; i < this.visibleOptions.length; i++) {
              const searchIndex = (currentIndex + 1 + i) % this.visibleOptions.length;
              const option = this.visibleOptions[searchIndex];
              const label = (option.dataset.label || option.textContent).trim().toLowerCase();

              if (label.startsWith(letter)) {
                this.setActiveOption(this.options.indexOf(option));
                option.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
                return;
              }
            }
          },

          handleMouseMove(event) {
            const option = event.target.closest('[role="option"]');
            if (option && this.visibleOptions.includes(option)) {
              const index = this.options.indexOf(option);
              if (index !== this.activeIndex) {
                this.setActiveOption(index);
              }
            }
          },

          handleMouseLeave() {
            const selectedOption = this.listbox.querySelector('[role="option"][aria-selected="true"]');
            if (selectedOption) {
              this.setActiveOption(this.options.indexOf(selectedOption));
            } else {
              this.setActiveOption(-1);
            }
          },

          handleOptionClick(event) {
            const clickedOption = event.target.closest('[role="option"]');
            if (clickedOption && clickedOption.getAttribute('aria-disabled') !== 'true') {
              this.selectOption(clickedOption);
            }
          },

          addFilterListeners(filter) {
            filter.addEventListener('input', this.handleFilterInput);
            filter.addEventListener('change', this.handleFilterChange);
            filter.addEventListener('keydown', this.handleFilterKeydown);
          },

          removeFilterListeners(filter) {
            if (!filter) return;
            filter.removeEventListener('input', this.handleFilterInput);
            filter.removeEventListener('change', this.handleFilterChange);
            filter.removeEventListener('keydown', this.handleFilterKeydown);
          }
        }
      </script>
    </div>
    """
  end

  @doc """
  Renders a select option.

  ## Examples

      <.select_option value="us" label="United States" />
      <.select_option value="ca">Canada</.select_option>
      <.select_option value="mx" label="Mexico" disabled />
  """

  attr(:value, :string, required: true, doc: "The value of this option")
  attr(:label, :string, default: nil, doc: "The display label (optional)")
  attr(:disabled, :boolean, default: false, doc: "Whether this option is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, doc: "The option content")

  def select_option(assigns) do
    ~H"""
    <div
      role="option"
      data-value={@value}
      data-label={@label}
      aria-disabled={to_string(@disabled)}
      class={["select-option", @disabled && "select-option-disabled", @class]}
      tabindex="-1"
      {@rest}
    >
      {if @inner_block != [], do: render_slot(@inner_block), else: @label || @value}
    </div>
    """
  end

  @doc """
  Renders a select option group.

  ## Examples

      <.select_group label="Frontend">
        <.select_option value="react" label="React" />
        <.select_option value="vue" label="Vue" />
      </.select_group>
  """

  attr(:label, :string, required: true, doc: "The group label")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, required: true, doc: "The group options")

  def select_group(assigns) do
    ~H"""
    <div role="group" class={["select-group", @class]} {@rest}>
      <div role="heading" class="select-group-label">
        {@label}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a separator between select options or groups.

  ## Examples

      <.select_separator />
  """

  attr(:rest, :global, doc: "Additional HTML attributes")

  def select_separator(assigns) do
    ~H"""
    <div role="separator" class="select-separator" {@rest} />
    """
  end
end
