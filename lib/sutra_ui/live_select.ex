defmodule SutraUI.LiveSelect do
  @moduledoc """
  A searchable selection component with single, tags, and quick_tags modes.

  ## Basic Usage

      <.live_component
        module={SutraUI.LiveSelect}
        id="city-select"
        field={@form[:city]}
      />

  ## Handling Search Events

  When the user types, the JS hook sends a `live_select_change` event directly to the parent
  (or the target specified by `phx-target`):

      def handle_event("live_select_change", %{"text" => text, "id" => id, "field" => field}, socket) do
        options = MyApp.search_cities(text)
        send_update(SutraUI.LiveSelect, id: id, options: options)
        {:noreply, socket}
      end

  > If your form is in a LiveComponent, add `phx-target={@myself}` to LiveSelect.

  ## Handling Selection Changes

  Selection changes are communicated via the form's standard `phx-change` event.
  The hidden input contains JSON-encoded `{label, value}` pairs:

      def handle_event("form_change", params, socket) do
        # Single mode: params["city"] is a JSON string like "{\"label\":\"NYC\",\"value\":\"nyc\"}"
        city = SutraUI.LiveSelect.decode(params["city"])
        # => %{"label" => "NYC", "value" => "nyc"}

        # Tags mode: params["tags"] is a list of JSON strings
        tags = SutraUI.LiveSelect.decode(params["tags"])
        # => [%{"label" => "Tag1", "value" => "t1"}, ...]

        {:noreply, assign(socket, city: city, tags: tags)}
      end

  ## Attributes

  | Attribute | Type | Default | Description |
  |-----------|------|---------|-------------|
  | `id` | `string` | required | Unique identifier for the component |
  | `field` | `Phoenix.HTML.FormField.t()` | required | Form field for the hidden input |
  | `mode` | `:single \| :tags \| :quick_tags` | `:single` | Selection mode |
  | `placeholder` | `string` | `nil` | Placeholder text for the input |
  | `disabled` | `boolean` | `false` | Disable the input |
  | `allow_clear` | `boolean` | `false` | Show clear button (single mode) |
  | `debounce` | `integer` | `100` | Debounce time in ms for search |
  | `update_min_len` | `integer` | `1` | Minimum characters before search |
  | `user_defined_options` | `boolean` | `false` | Allow creating tags by typing (tags modes) |
  | `max_selectable` | `integer` | `0` | Max tags allowed (0 = unlimited) |
  | `phx-target` | `string` | `nil` | Target for search events (for LiveComponents) |
  | `class` | `string` | `nil` | Additional CSS classes |

  ## Options Format

  Options can be provided in many formats:

      # Simple strings/atoms/numbers (label = value)
      ["New York", "Los Angeles", "Chicago"]

      # Tuples {label, value}
      [{"New York", "nyc"}, {"Los Angeles", %{lat: 34.05, lng: -118.24}}]

      # Tuples with disabled flag {label, value, disabled}
      [{"New York", "nyc", false}, {"Coming Soon", "tbd", true}]

      # Maps with :label and :value
      [%{label: "New York", value: "nyc"}]

      # Maps with :key (alias for :label) and :value
      [%{key: "New York", value: "nyc"}]

      # Maps with :value only (value becomes label)
      [%{value: "nyc"}]

      # Keywords
      [[label: "New York", value: "nyc"]]

      # Map as options (sorted, keys become labels)
      %{NYC: "nyc", LA: "la"}

  ### Optional Fields

      %{
        label: "New York",       # Required
        value: "nyc",            # Required
        disabled: true,          # Cannot be selected
        sticky: true,            # Cannot be removed (tags mode)
        tag_label: "NY"          # Alternative label for tag display
      }

  ## Modes

  - `:single` - Select one option, input shows selected label
  - `:tags` - Multi-select with removable tags, dropdown closes on select
  - `:quick_tags` - Multi-select, dropdown stays open for rapid selection

  ## Slots

      <.live_component module={SutraUI.LiveSelect} id="city-select" field={@form[:city]}>
        <:option :let={option}>
          <span class="font-bold"><%= option.label %></span>
        </:option>
        <:tag :let={option}>
          <span><%= option.tag_label || option.label %></span>
        </:tag>
      </.live_component>

  ## Complete Examples

  ### Single Select with Search

      # In your LiveView
      def mount(_params, _session, socket) do
        {:ok, assign(socket, form: to_form(%{"city" => nil}))}
      end

      def handle_event("live_select_change", %{"text" => text, "id" => id}, socket) do
        options = Repo.all(from c in City, where: ilike(c.name, ^"%\#{text}%"), limit: 10)
        send_update(SutraUI.LiveSelect, id: id, options: Enum.map(options, &{&1.name, &1.id}))
        {:noreply, socket}
      end

      # In your template
      <form phx-change="form_change">
        <.live_component
          module={SutraUI.LiveSelect}
          id="city-select"
          field={@form[:city]}
          placeholder="Search cities..."
          allow_clear
        />
      </form>

  ### Tags Mode with Max Selection

      <.live_component
        module={SutraUI.LiveSelect}
        id="tags-select"
        field={@form[:tags]}
        mode={:tags}
        placeholder="Add tags..."
        max_selectable={5}
      />

  ### User-Defined Tags (Quick Tags)

      <.live_component
        module={SutraUI.LiveSelect}
        id="custom-tags"
        field={@form[:custom_tags]}
        mode={:quick_tags}
        placeholder="Type and press Enter..."
        user_defined_options
      />

  ## Keyboard Navigation

  - `ArrowDown` / `ArrowUp` - Navigate options
  - `Enter` - Select highlighted option (or create tag if `user_defined_options`)
  - `Escape` - Close dropdown
  - `Backspace` - Remove last tag (when input is empty, tags mode)

  ## Decoding Complex Values

  When using maps or complex values, decode form params with `decode/1`:

      def handle_event("save", %{"form" => params}, socket) do
        params = update_in(params, ["city"], &SutraUI.LiveSelect.decode/1)
        # ...
      end

  ## Programmatic Value Setting

  Set selection programmatically via `send_update/2`:

      send_update(SutraUI.LiveSelect, id: "city-select", value: %{label: "NYC", value: "nyc"})

      # For tags mode, pass a list
      send_update(SutraUI.LiveSelect, id: "tags-select", value: [
        %{label: "Tag1", value: "t1"},
        %{label: "Tag2", value: "t2"}
      ])
  """

  use Phoenix.LiveComponent

  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Decodes JSON-encoded selection values from form params.

  Uses `Phoenix.json_library()` for flexibility. Handles decode errors gracefully
  by returning the original value if not valid JSON.

  ## Examples

      iex> SutraUI.LiveSelect.decode(nil)
      []

      iex> SutraUI.LiveSelect.decode("")
      nil

      iex> SutraUI.LiveSelect.decode("nyc")
      "nyc"

      iex> SutraUI.LiveSelect.decode("42")
      42

      iex> SutraUI.LiveSelect.decode(~s({"name":"Berlin"}))
      %{"name" => "Berlin"}

      iex> SutraUI.LiveSelect.decode([~s({"id":1}), ~s({"id":2})])
      [%{"id" => 1}, %{"id" => 2}]
  """
  def decode(nil), do: []
  def decode(""), do: nil

  def decode(values) when is_list(values) do
    Enum.map(values, &json_decode/1)
  end

  def decode(value) when is_binary(value) do
    json_decode(value)
  end

  defp json_decode(value) do
    json = Phoenix.json_library()

    case json.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _} -> value
    end
  end

  @doc """
  Normalizes a list of options into a consistent format.

  This is useful for pre-processing options before passing them to
  `send_update/2`. Each option is normalized to a map with `:label`,
  `:value`, `:disabled`, `:sticky`, and `:tag_label` keys.

  ## Examples

      iex> SutraUI.LiveSelect.normalize_options(["NYC", "LA"])
      [%{label: "NYC", value: "NYC", disabled: false},
       %{label: "LA", value: "LA", disabled: false}]

      iex> SutraUI.LiveSelect.normalize_options([{"New York", "nyc"}])
      [%{label: "New York", value: "nyc", disabled: false}]
  """
  def normalize_options(options), do: do_normalize_options(options)

  # ============================================================================
  # LiveComponent Callbacks
  # ============================================================================

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       options: [],
       selection: [],
       value_mapper: & &1
     )}
  end

  @impl true
  def update(assigns, socket) do
    # Always update id
    socket = assign(socket, :id, assigns[:id])

    # Handle phx-target for routing events
    socket =
      if Map.has_key?(assigns, :"phx-target") do
        assign(socket, :"phx-target", assigns[:"phx-target"])
      else
        assign_new(socket, :"phx-target", fn -> nil end)
      end

    # Assign defaults (only on first render)
    socket =
      socket
      |> assign_new(:mode, fn -> assigns[:mode] || :single end)
      |> assign_new(:field, fn -> assigns[:field] end)
      |> assign_new(:placeholder, fn -> assigns[:placeholder] end)
      |> assign_new(:disabled, fn -> assigns[:disabled] || false end)
      |> assign_new(:allow_clear, fn -> assigns[:allow_clear] || false end)
      |> assign_new(:debounce, fn -> assigns[:debounce] || 100 end)
      |> assign_new(:update_min_len, fn -> assigns[:update_min_len] || 1 end)
      |> assign_new(:class, fn -> assigns[:class] end)
      |> assign_new(:option, fn -> assigns[:option] || [] end)
      |> assign_new(:tag, fn -> assigns[:tag] || [] end)
      |> assign_new(:user_defined_options, fn -> assigns[:user_defined_options] || false end)
      |> assign_new(:max_selectable, fn -> assigns[:max_selectable] || 0 end)
      |> assign_new(:value_mapper, fn -> assigns[:value_mapper] || (& &1) end)

    # Handle send_update with options
    socket =
      if Map.has_key?(assigns, :options) do
        assign(socket, :options, do_normalize_options(assigns.options))
      else
        socket
      end

    # Handle send_update with value (programmatic selection)
    socket =
      if Map.has_key?(assigns, :value) do
        socket
        |> set_selection(assigns.value)
        |> push_selected()
      else
        socket
      end

    {:ok, socket}
  end

  # ============================================================================
  # Server Events (4 total: select, remove, clear, recover)
  # ============================================================================

  @impl true
  def handle_event("select", %{"index" => index}, socket) do
    index = to_integer(index)

    case Enum.at(socket.assigns.options, index) do
      nil ->
        {:noreply, socket}

      %{disabled: true} ->
        {:noreply, socket}

      option ->
        socket = add_to_selection(socket, option)
        {:noreply, push_selected(socket)}
    end
  end

  # User-defined option: create from typed text
  def handle_event("select", %{"text" => text}, socket) do
    text = String.trim(text)

    if socket.assigns.user_defined_options && text != "" do
      option = %{label: text, value: text, disabled: false}

      if already_selected?(option, socket.assigns.selection) do
        {:noreply, socket}
      else
        socket = add_to_selection(socket, option)
        {:noreply, push_selected(socket)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove", %{"index" => index}, socket) do
    index = to_integer(index)

    # Check if tag is sticky
    case Enum.at(socket.assigns.selection, index) do
      %{sticky: true} ->
        {:noreply, socket}

      _ ->
        socket = update(socket, :selection, &List.delete_at(&1, index))
        {:noreply, push_selected(socket)}
    end
  end

  def handle_event("clear", _params, socket) do
    # Keep sticky tags when clearing
    sticky_tags = Enum.filter(socket.assigns.selection, &(&1[:sticky] == true))
    socket = assign(socket, :selection, sticky_tags)
    {:noreply, push_selected(socket)}
  end

  # Crash recovery: JS pushes cached selection back after reconnect
  def handle_event("recover", %{"selection" => selection}, socket) do
    selection =
      selection
      |> Enum.map(&normalize_recovered_option/1)
      |> Enum.reject(&is_nil/1)

    socket = assign(socket, :selection, selection)
    {:noreply, socket}
  end

  # Catch-all for unknown events
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # ============================================================================
  # Selection Logic
  # ============================================================================

  defp add_to_selection(socket, option) do
    case socket.assigns.mode do
      :single ->
        assign(socket, :selection, [option])

      mode when mode in [:tags, :quick_tags] ->
        if already_selected?(option, socket.assigns.selection) do
          # In quick_tags mode, toggle off (unless sticky)
          if mode == :quick_tags && option[:sticky] != true do
            idx = Enum.find_index(socket.assigns.selection, &(&1.value == option.value))
            update(socket, :selection, &List.delete_at(&1, idx))
          else
            socket
          end
        else
          # Check max_selectable limit (0 = unlimited)
          max = socket.assigns.max_selectable
          current_count = length(socket.assigns.selection)

          if max == 0 || current_count < max do
            update(socket, :selection, &(&1 ++ [option]))
          else
            socket
          end
        end
    end
  end

  defp already_selected?(option, selection) do
    Enum.any?(selection, &(&1.value == option.value))
  end

  defp set_selection(socket, nil), do: assign(socket, :selection, [])

  defp set_selection(socket, values) when is_list(values) do
    selection =
      values
      |> Enum.map(&normalize_selection_value(&1, socket.assigns))
      |> Enum.reject(&is_nil/1)

    assign(socket, :selection, selection)
  end

  defp set_selection(socket, value) do
    case normalize_selection_value(value, socket.assigns) do
      nil -> assign(socket, :selection, [])
      option -> assign(socket, :selection, [option])
    end
  end

  defp normalize_selection_value(value, assigns) do
    # Apply value_mapper
    mapped = assigns.value_mapper.(value)

    # Try to find in current options
    if option = Enum.find(assigns.options, &(&1.value == mapped)) do
      option
    else
      # Normalize the mapped value as an option
      case normalize_option(mapped) do
        {:ok, option} -> option
        :error -> %{label: to_string(value), value: value, disabled: false}
      end
    end
  end

  defp push_selected(socket) do
    push_event(socket, "live_select:selected", %{
      id: socket.assigns.id,
      selection: socket.assigns.selection,
      mode: socket.assigns.mode
    })
  end

  # ============================================================================
  # Option Normalization
  # ============================================================================

  defp do_normalize_options(options) when is_map(options) and not is_struct(options) do
    options
    |> Enum.sort()
    |> Enum.map(fn {label, value} -> %{label: label, value: value, disabled: false} end)
  end

  defp do_normalize_options(options) when is_list(options) do
    options
    |> Enum.map(&normalize_option/1)
    |> Enum.map(fn
      {:ok, opt} -> opt
      :error -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp do_normalize_options(_), do: []

  defp normalize_option(opt) when is_list(opt) do
    if Keyword.keyword?(opt) do
      opt |> Map.new() |> normalize_option()
    else
      :error
    end
  end

  defp normalize_option(%{key: key} = opt) do
    opt
    |> Map.delete(:key)
    |> Map.put(:label, key)
    |> normalize_option()
  end

  defp normalize_option(%{label: label, value: value} = opt) do
    {:ok,
     %{
       label: label,
       value: value,
       disabled: Map.get(opt, :disabled, false),
       sticky: Map.get(opt, :sticky, false),
       tag_label: Map.get(opt, :tag_label)
     }}
  end

  defp normalize_option(%{value: value} = opt) do
    opt
    |> Map.put(:label, value)
    |> normalize_option()
  end

  defp normalize_option({label, value}) do
    {:ok, %{label: label, value: value, disabled: false}}
  end

  defp normalize_option({label, value, disabled}) do
    {:ok, %{label: label, value: value, disabled: disabled}}
  end

  defp normalize_option(nil), do: :error

  defp normalize_option(value) when is_binary(value) or is_atom(value) or is_number(value) do
    {:ok, %{label: value, value: value, disabled: false}}
  end

  defp normalize_option(_), do: :error

  # For crash recovery - JS sends maps with string keys
  defp normalize_recovered_option(%{"label" => label, "value" => value} = opt) do
    %{
      label: label,
      value: value,
      disabled: Map.get(opt, "disabled", false),
      sticky: Map.get(opt, "sticky", false),
      tag_label: Map.get(opt, "tag_label")
    }
  end

  defp normalize_recovered_option(_), do: nil

  # ============================================================================
  # Helpers
  # ============================================================================

  defp to_integer(val) when is_integer(val), do: val
  defp to_integer(val) when is_binary(val), do: String.to_integer(val)

  defp field_name(%{field: %{field: field}}), do: field
  defp field_name(%{field: %{name: name}}), do: name
  defp field_name(%{id: id}), do: id

  defp input_name(%{field: %{form: %{name: nil}, field: field}}), do: to_string(field)
  defp input_name(%{field: %{form: form, field: field}}), do: "#{form.name}[#{field}]"
  defp input_name(%{field: %{name: name}}), do: name
  defp input_name(_), do: "live_select"

  # Encode selection with both label and value for form submission
  defp encode_selection(%{label: label, value: value}) when is_binary(value) do
    Phoenix.json_library().encode!(%{label: label, value: value})
  end

  defp encode_selection(%{label: label, value: value}) when is_atom(value) do
    Phoenix.json_library().encode!(%{label: label, value: Atom.to_string(value)})
  end

  defp encode_selection(%{label: label, value: value}) when is_number(value) do
    Phoenix.json_library().encode!(%{label: label, value: value})
  end

  defp encode_selection(%{label: label, value: value}) do
    Phoenix.json_library().encode!(%{label: label, value: value})
  end

  defp tag_label(option) do
    option[:tag_label] || option.label
  end

  defp is_selected?(option, selection) do
    Enum.any?(selection, &(&1.value == option.value))
  end

  # ============================================================================
  # Render
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={["live-select", @disabled && "live-select-disabled", @class]}
      phx-hook=".LiveSelect"
      data-mode={@mode}
      data-debounce={@debounce}
      data-update-min-len={@update_min_len}
      data-user-defined={@user_defined_options}
      data-max-selectable={@max_selectable}
      data-field={field_name(assigns)}
      data-phx-target={assigns[:"phx-target"]}
    >
      <%!-- Tags (tags/quick_tags modes) --%>
      <div :if={@mode in [:tags, :quick_tags] && @selection != []} class="live-select-tags">
        <%= for {option, index} <- Enum.with_index(@selection) do %>
          <span
            class={["live-select-tag", option[:sticky] && "live-select-tag-sticky"]}
            data-tag-index={index}
            data-sticky={option[:sticky]}
          >
            <%= if @tag != [] do %>
              {render_slot(@tag, option)}
            <% else %>
              <span class="live-select-tag-label">{tag_label(option)}</span>
            <% end %>
            <button
              :if={!option[:sticky]}
              type="button"
              class="live-select-tag-remove"
              phx-click="remove"
              phx-value-index={index}
              phx-target={@myself}
              aria-label="Remove"
            >
              <.icon name="hero-x-mark" class="size-3" />
            </button>
          </span>
        <% end %>
      </div>

      <%!-- Input container --%>
      <div class="live-select-input-container">
        <input
          type="text"
          data-input
          class="live-select-input"
          placeholder={@placeholder}
          autocomplete="off"
          disabled={@disabled}
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={"#{@id}-dropdown"}
          aria-activedescendant=""
        />

        <%!-- Clear button (single mode) --%>
        <button
          :if={@mode == :single && @allow_clear && @selection != []}
          type="button"
          class="live-select-clear"
          phx-click="clear"
          phx-target={@myself}
          aria-label="Clear selection"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>

      <%!-- Dropdown --%>
      <ul
        id={"#{@id}-dropdown"}
        data-dropdown
        class="live-select-dropdown"
        role="listbox"
        hidden
      >
        <%= for {option, index} <- Enum.with_index(@options) do %>
          <li
            id={"#{@id}-option-#{index}"}
            data-index={index}
            data-disabled={option[:disabled]}
            data-selected={is_selected?(option, @selection)}
            class={[
              "live-select-option",
              option[:disabled] && "live-select-option-disabled",
              is_selected?(option, @selection) && "live-select-option-selected"
            ]}
            role="option"
            aria-selected={to_string(is_selected?(option, @selection))}
            aria-disabled={to_string(option[:disabled] || false)}
          >
            <%= if @option != [] do %>
              {render_slot(@option, Map.put(option, :selected, is_selected?(option, @selection)))}
            <% else %>
              {option.label}
            <% end %>
          </li>
        <% end %>
        <%!-- Empty state when no options --%>
        <li :if={@options == []} class="live-select-empty-item">
          No results found
        </li>
      </ul>

      <%!-- Hidden inputs for form integration --%>
      <%= if @mode == :single do %>
        <input
          type="hidden"
          name={input_name(assigns)}
          value={if @selection != [], do: encode_selection(hd(@selection)), else: ""}
          data-live-select-input
        />
      <% else %>
        <%= if @selection == [] do %>
          <input type="hidden" name={"#{input_name(assigns)}[]"} value="" data-live-select-input />
        <% else %>
          <%= for option <- @selection do %>
            <input
              type="hidden"
              name={"#{input_name(assigns)}[]"}
              value={encode_selection(option)}
              data-live-select-input
            />
          <% end %>
        <% end %>
      <% end %>

      <script :type={ColocatedHook} name=".LiveSelect">
        // LiveSelect Hook - Client-side state management
        // Navigation (activeIndex, dropdownOpen) is entirely client-side
        // Only select/remove/clear/recover events go to server

        export default {
          mounted() {
            this.activeIndex = -1;
            this.dropdownOpen = false;
            this.selection = [];
            this.debounceTimer = null;
            this.pendingSearch = false; // Track if we're waiting for search results

            this.input = this.el.querySelector('[data-input]');
            this.dropdown = this.el.querySelector('[data-dropdown]');

            this.setupEventListeners();
            this.listenToServer();

            // Set initial input value for single mode
            if (this.mode() === 'single') {
              const hidden = this.el.querySelector('[data-live-select-input]');
              if (hidden && hidden.value) {
                // Find label from existing selection
                const selected = this.el.querySelector('[data-selected="true"]');
                if (selected) {
                  this.input.value = selected.textContent.trim();
                }
              }
            }
          },

          setupEventListeners() {
            // Use event delegation on container for all events
            // This survives DOM updates from LiveView
            
            // Input events
            this.el.addEventListener('input', (e) => {
              if (!e.target.matches('[data-input]')) return;
              clearTimeout(this.debounceTimer);
              const text = e.target.value.trim();

              if (text.length >= this.updateMinLen()) {
                this.pendingSearch = true;
                this.debounceTimer = setTimeout(() => {
                  this.pushSearchEvent(text);
                }, this.debounce());
              } else {
                this.pendingSearch = false;
              }
            });

            this.el.addEventListener('focus', (e) => {
              if (!e.target.matches('[data-input]')) return;
              if (this.hasOptions()) {
                this.openDropdown();
              }
            }, true); // Use capture for focus

            this.el.addEventListener('blur', (e) => {
              if (!e.target.matches('[data-input]')) return;
              // Delay to allow click events on dropdown options
              setTimeout(() => {
                this.closeDropdown();
                // Restore input value in single mode
                if (this.mode() === 'single' && this.selection.length > 0) {
                  this.input.value = this.selection[0].label;
                }
              }, 150);
            }, true); // Use capture for blur

            // Keyboard events
            this.el.addEventListener('keydown', (e) => {
              if (!e.target.matches('[data-input]')) return;
              
              switch (e.key) {
                case 'ArrowDown':
                  e.preventDefault();
                  if (!this.dropdownOpen && this.hasOptions()) {
                    this.openDropdown();
                  }
                  this.activeIndex = this.nextSelectable(this.activeIndex);
                  this.updateActiveOption();
                  this.scrollToActive();
                  break;

                case 'ArrowUp':
                  e.preventDefault();
                  this.activeIndex = this.prevSelectable(this.activeIndex);
                  this.updateActiveOption();
                  this.scrollToActive();
                  break;

                case 'Enter':
                  e.preventDefault();
                  e.stopPropagation();
                  const inputText = e.target.value.trim();
                  // User-defined tags: if user typed something, create a tag (regardless of dropdown state)
                  if (this.userDefined() && inputText) {
                    this.pushEventTo(this.el, 'select', { text: inputText });
                  } else if (this.activeIndex >= 0 && this.dropdownOpen) {
                    // Otherwise select from dropdown if open and has active option
                    this.pushEventTo(this.el, 'select', { index: this.activeIndex });
                  }
                  return false; // Extra protection against form submit

                case 'Escape':
                  e.preventDefault();
                  this.closeDropdown();
                  this.input.blur();
                  break;

                case 'Backspace':
                  // Remove last tag when input is empty (tags/quick_tags mode)
                  if (e.target.value === '' && this.mode() !== 'single') {
                    const tags = this.el.querySelectorAll('[data-tag-index]:not([data-sticky="true"])');
                    if (tags.length > 0) {
                      const lastTag = tags[tags.length - 1];
                      const index = parseInt(lastTag.dataset.tagIndex);
                      this.pushEventTo(this.el, 'remove', { index });
                    }
                  }
                  break;
              }
            });

            // Dropdown click - event delegation
            this.el.addEventListener('mousedown', (e) => {
              const option = e.target.closest('[data-index]');
              if (option && option.dataset.disabled !== 'true') {
                e.preventDefault();
                const index = parseInt(option.dataset.index);
                this.pushEventTo(this.el, 'select', { index });
              }
            });

            // Dropdown hover
            this.el.addEventListener('mousemove', (e) => {
              const option = e.target.closest('[data-index]');
              if (option && option.dataset.disabled !== 'true') {
                this.activeIndex = parseInt(option.dataset.index);
                this.updateActiveOption();
              }
            });
          },

          listenToServer() {
            this.handleEvent('live_select:selected', ({ id, selection, mode }) => {
              if (id !== this.el.id) return;

              this.selection = selection;
              this.pendingSearch = false; // Selection done

              if (mode === 'single') {
                this.input.value = selection.length > 0 ? selection[0].label : '';
                this.closeDropdown();
              } else if (mode === 'tags') {
                this.input.value = '';
                this.closeDropdown();
              } else {
                // quick_tags - keep dropdown open
                this.input.value = '';
              }

              this.activeIndex = -1;
              this.updateActiveOption();
              this.dispatchFormChange();
            });
          },

          updated() {
            this.dropdown = this.el.querySelector('[data-dropdown]');
            this.input = this.el.querySelector('[data-input]');
            
            // Reset active index on update
            this.activeIndex = -1;
            this.updateActiveOption();

            // Open dropdown if we have options and either input is focused or we have a pending search
            if (this.hasOptions() && (document.activeElement === this.input || this.pendingSearch)) {
              this.openDropdown();
              this.pendingSearch = false;
            }
          },

          reconnected() {
            if (this.selection && this.selection.length > 0) {
              this.pushEventTo(this.el, 'recover', { selection: this.selection });
            }
          },

          // Navigation helpers
          nextSelectable(current) {
            const options = this.getOptions();
            for (let i = current + 1; i < options.length; i++) {
              if (this.isSelectable(options[i])) return i;
            }
            return current === -1 && options.length > 0 ? this.nextSelectable(-1) : current;
          },

          prevSelectable(current) {
            const options = this.getOptions();
            const start = current === -1 ? options.length : current;
            for (let i = start - 1; i >= 0; i--) {
              if (this.isSelectable(options[i])) return i;
            }
            return current;
          },

          isSelectable(option) {
            if (option.dataset.disabled === 'true') return false;
            // In tags mode (not quick_tags), skip already-selected
            if (this.mode() === 'tags' && option.dataset.selected === 'true') return false;
            return true;
          },

          // Dropdown helpers
          openDropdown() {
            this.dropdownOpen = true;
            this.dropdown?.removeAttribute('hidden');
            this.input.setAttribute('aria-expanded', 'true');
          },

          closeDropdown() {
            this.dropdownOpen = false;
            this.dropdown?.setAttribute('hidden', '');
            this.input.setAttribute('aria-expanded', 'false');
            this.activeIndex = -1;
            this.updateActiveOption();
          },

          updateActiveOption() {
            this.getOptions().forEach((opt, i) => {
              opt.dataset.active = (i === this.activeIndex).toString();
            });
            const activeId = this.activeIndex >= 0
              ? `${this.el.id}-option-${this.activeIndex}`
              : '';
            this.input.setAttribute('aria-activedescendant', activeId);
          },

          scrollToActive() {
            const active = this.dropdown?.querySelector('[data-active="true"]');
            active?.scrollIntoView({ block: 'nearest' });
          },

          getOptions() {
            return Array.from(this.dropdown?.querySelectorAll('[data-index]') || []);
          },

          hasOptions() {
            return this.getOptions().length > 0;
          },

          dispatchFormChange() {
            const hidden = this.el.querySelector('[data-live-select-input]');
            if (hidden) {
              // Dispatch both input and change events to ensure Phoenix picks up the change
              hidden.dispatchEvent(new Event('input', { bubbles: true }));
              hidden.dispatchEvent(new Event('change', { bubbles: true }));
            }
          },

          pushSearchEvent(text) {
            const target = this.el.dataset.phxTarget;
            const field = this.el.dataset.field;
            const payload = { id: this.el.id, text, field };

            if (target) {
              this.pushEventTo(target, 'live_select_change', payload);
            } else {
              this.pushEvent('live_select_change', payload);
            }
          },

          // Config from data attributes
          debounce() { return parseInt(this.el.dataset.debounce) || 100; },
          updateMinLen() { return parseInt(this.el.dataset.updateMinLen) || 1; },
          mode() { return this.el.dataset.mode || 'single'; },
          userDefined() { 
            const val = this.el.dataset.userDefined;
            return val === 'true' || val === true || val === '';
          },
          maxSelectable() { return parseInt(this.el.dataset.maxSelectable) || 0; }
        }
      </script>
    </div>
    """
  end
end
