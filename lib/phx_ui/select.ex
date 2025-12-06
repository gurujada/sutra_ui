defmodule PhxUI.Select do
  @moduledoc """
  A custom select component with search/filter capabilities (combobox).

  This component provides a custom dropdown select with:
  - Keyboard navigation (Arrow keys, Home, End, Enter, Escape)
  - Search/filter functionality (when `searchable: true`)
  - Focus management and ARIA attributes
  - Custom styling via CSS

  The component requires a unique `id` attribute for the JavaScript hook to function.

  ## Components

  - `select/1` - The main select container
  - `select_option/1` - Individual selectable options
  - `select_group/1` - Groups of related options
  - `select_separator/1` - Visual separator between options/groups

  ## Colocated Hook

  This component includes a colocated JavaScript hook (`.Select`) that handles:
  - Opening/closing the dropdown
  - Keyboard navigation
  - Search filtering
  - Value selection and form integration

  The hook is automatically available when you import colocated hooks in your app.js.
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
      class={select_class(@class)}
      data-select-value={@value}
      phx-hook=".Select"
      {@rest}
    >
      <button
        type="button"
        class={trigger_class(@trigger_class)}
        id={"#{@id}-trigger"}
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        disabled={@disabled}
      >
        <span class="truncate" data-selected-label>
          <%= if @trigger != [] do %>
            {render_slot(@trigger)}
          <% else %>
            Select...
          <% end %>
        </span>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="ml-2 shrink-0 opacity-50"
          aria-hidden="true"
        >
          <%= if @searchable do %>
            <path d="m7 15 5 5 5-5" /><path d="m7 9 5-5 5 5" />
          <% else %>
            <path d="m6 9 6 6 6-6" />
          <% end %>
        </svg>
      </button>
      <div id={"#{@id}-popover"} class={popover_class()} data-popover aria-hidden="true">
        <%= if @searchable do %>
          <div class="flex items-center border-b px-3">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="mr-2 shrink-0 opacity-50"
              aria-hidden="true"
            >
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />
            </svg>
            <input
              type="text"
              value=""
              placeholder={@search_placeholder}
              class="flex h-10 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50"
              autocomplete="off"
              autocorrect="off"
              spellcheck="false"
              aria-autocomplete="list"
              role="combobox"
              aria-expanded="false"
              aria-controls={"#{@id}-listbox"}
              aria-labelledby={"#{@id}-trigger"}
            />
          </div>
        <% end %>
        <div
          role="listbox"
          id={"#{@id}-listbox"}
          class="max-h-[300px] overflow-y-auto p-1"
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

      <script :type={ColocatedHook} name=".Select">
        export default {
          mounted() {
            this.initSelect();
          },

          updated() {
            const newValue = this.el.dataset.selectValue;
            if (newValue !== this.input.value) {
              this.selectByValue(newValue, false);
            }
          },

          destroyed() {
            document.removeEventListener('click', this.handleOutsideClick);
          },

          initSelect() {
            this.trigger = this.el.querySelector(':scope > button');
            this.selectedLabel = this.trigger.querySelector('[data-selected-label]');
            this.popover = this.el.querySelector('[data-popover]');
            this.listbox = this.popover.querySelector('[role="listbox"]');
            this.input = this.el.querySelector('[data-select-input]');
            this.filter = this.el.querySelector('input[type="text"]');

            if (!this.trigger || !this.popover || !this.listbox || !this.input) {
              console.error('PhxUI.Select: Missing required elements');
              return;
            }

            this.allOptions = Array.from(this.listbox.querySelectorAll('[role="option"]'));
            this.options = this.allOptions.filter(opt => opt.getAttribute('aria-disabled') !== 'true');
            this.visibleOptions = [...this.options];
            this.activeIndex = -1;

            this.trigger.addEventListener('click', () => this.togglePopover());
            this.trigger.addEventListener('keydown', (e) => this.handleKeyNavigation(e));
            this.listbox.addEventListener('click', (e) => this.handleOptionClick(e));
            this.listbox.addEventListener('mousemove', (e) => this.handleMouseMove(e));
            this.listbox.addEventListener('mouseleave', () => this.handleMouseLeave());

            if (this.filter) {
              this.filter.addEventListener('input', () => this.filterOptions());
              this.filter.addEventListener('keydown', (e) => this.handleKeyNavigation(e));
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

            if (this.activeIndex > -1) {
              const activeOption = this.options[this.activeIndex];
              activeOption.classList.add('bg-accent');
              if (activeOption.id) {
                this.trigger.setAttribute('aria-activedescendant', activeOption.id);
              } else {
                this.trigger.removeAttribute('aria-activedescendant');
              }
            } else {
              this.trigger.removeAttribute('aria-activedescendant');
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
            this.setActiveOption(-1);
          },

          openPopover() {
            this.popover.setAttribute('aria-hidden', 'false');
            this.trigger.setAttribute('aria-expanded', 'true');

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

            // Handle letter navigation when popover is open
            if (isPopoverOpen && event.key.length === 1 && /[a-zA-Z]/.test(event.key)) {
              this.jumpToLetter(event.key.toLowerCase());
              return;
            }

            if (!['ArrowDown', 'ArrowUp', 'Enter', 'Home', 'End', 'Escape'].includes(event.key)) {
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

            if (event.key === 'Enter') {
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
      class={option_class(@class, @disabled)}
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
    <div role="group" class={@class} {@rest}>
      <div role="presentation" class="px-2 py-1.5 text-xs font-medium text-muted-foreground">
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
    <div role="separator" class="-mx-1 my-1 h-px bg-muted" {@rest} />
    """
  end

  defp select_class(extra_class) do
    base = "relative inline-block w-full"

    if extra_class do
      "#{base} #{extra_class}"
    else
      base
    end
  end

  defp trigger_class(extra_class) do
    base =
      "flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"

    if extra_class do
      "#{base} #{extra_class}"
    else
      base
    end
  end

  defp popover_class do
    "absolute z-50 mt-1 w-full rounded-md border bg-popover text-popover-foreground shadow-md outline-none data-[aria-hidden=true]:hidden"
  end

  defp option_class(extra_class, disabled) do
    base =
      "relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground"

    disabled_class = if disabled, do: "cursor-not-allowed opacity-50", else: ""

    [base, disabled_class, extra_class]
    |> Enum.filter(&(&1 && &1 != ""))
    |> Enum.join(" ")
  end
end
