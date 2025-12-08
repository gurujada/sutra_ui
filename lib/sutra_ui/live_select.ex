defmodule SutraUI.LiveSelect do
  @moduledoc """
  A dynamic searchable selection component with single, tags, and quick_tags modes.

  LiveSelect provides a text input that triggers server-side search as the user types.
  Results are displayed in a dropdown, and selections are stored in hidden form inputs.

  ## Modes

  - `:single` - Select one option. Clears input on selection.
  - `:tags` - Multi-select with removable tags. Dropdown closes on selection.
  - `:quick_tags` - Multi-select with dropdown staying open for rapid selection/deselection.

  ## Basic Usage

      <.live_component
        module={PhxUI.LiveSelect}
        id="city-select"
        field={@form[:city]}
      />

  ## Handling Search Events

  When the user types, LiveSelect emits a `live_select_change` event:

      def handle_event("live_select_change", %{"text" => text, "id" => id}, socket) do
        options = MyApp.search_cities(text)
        send_update(PhxUI.LiveSelect, id: id, options: options)
        {:noreply, socket}
      end

  ## Handling Selection

  When a selection is made, LiveSelect sends a message to the parent process:

      def handle_info({:live_select_selected, %{id: "city-select"} = payload}, socket) do
        # For single mode: payload has :value and :label
        {:noreply, assign(socket, :selected_city, payload[:value])}
      end

      def handle_info({:live_select_selected, %{id: "tags-select"} = payload}, socket) do
        # For tags modes: payload has :selection (list of maps with :value, :label, :tag_label)
        {:noreply, assign(socket, :selected_tags, payload[:selection])}
      end

  Selections also trigger standard form change events via hidden inputs:

      def handle_event("change", %{"form" => %{"city" => city_value}}, socket) do
        # city_value is JSON-encoded if complex, use PhxUI.LiveSelect.decode/1
        {:noreply, socket}
      end

  ## Options Format

  Options can be provided in several formats:

      # Simple strings/atoms (label = value)
      ["New York", "Los Angeles", "Chicago"]

      # Tuples {label, value}
      [{"New York", "nyc"}, {"Los Angeles", "la"}]

      # Maps with label and value
      [%{label: "New York", value: "nyc"}, %{label: "Los Angeles", value: "la"}]

      # With additional options
      [%{label: "New York", value: "nyc", tag_label: "NY", disabled: false, sticky: false}]

  ## Programmatic Control

  Update selection programmatically:

      send_update(PhxUI.LiveSelect, id: "city-select", value: "nyc")
      send_update(PhxUI.LiveSelect, id: "city-select", value: ["nyc", "la"])  # tags mode
      send_update(PhxUI.LiveSelect, id: "city-select", value: nil)  # clear

  ## Slots

      <.live_component module={PhxUI.LiveSelect} id="city-select" field={@form[:city]} mode={:tags}>
        <:option :let={option}>
          <span class="font-bold"><%= option.label %></span>
        </:option>
        <:tag :let={option}>
          <span class="bg-blue-100"><%= option.tag_label || option.label %></span>
        </:tag>
        <:clear_button>
          <.icon name="hero-x-mark" />
        </:clear_button>
      </.live_component>
  """

  use Phoenix.LiveComponent

  alias Phoenix.LiveView.ColocatedHook

  import SutraUI.Icon, only: [icon: 1]

  @default_debounce 100
  @default_update_min_len 1

  @doc """
  Decodes JSON-encoded selection values from form params.

  Use this when your option values are complex (maps, lists) rather than simple strings.

  ## Examples

      iex> PhxUI.LiveSelect.decode(nil)
      []

      iex> PhxUI.LiveSelect.decode("")
      nil

      iex> PhxUI.LiveSelect.decode("{\\"name\\":\\"Berlin\\"}")
      %{"name" => "Berlin"}

      iex> PhxUI.LiveSelect.decode(["{\\"id\\":1}", "{\\"id\\":2}"])
      [%{"id" => 1}, %{"id" => 2}]
  """
  def decode(nil), do: []
  def decode(""), do: nil
  def decode(value) when is_binary(value), do: Jason.decode!(value)
  def decode(values) when is_list(values), do: Enum.map(values, &decode/1)

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:text, "")
     |> assign(:selection, [])
     |> assign(:active_index, -1)
     |> assign(:dropdown_open, false)
     |> assign(:options, [])
     |> assign(:available_options, [])}
  end

  @impl true
  def update(assigns, socket) do
    # Handle field assign - only set if provided (initial mount)
    socket =
      if Map.has_key?(assigns, :field) do
        assign(socket, :field, assigns.field)
      else
        socket
      end

    # Set defaults for optional assigns - only on initial mount when field is provided
    socket =
      if Map.has_key?(assigns, :field) do
        socket
        |> assign_new(:id, fn -> assigns[:id] || default_id(assigns.field) end)
        |> assign_new(:mode, fn -> assigns[:mode] || :single end)
        |> assign_new(:placeholder, fn -> assigns[:placeholder] || "Search..." end)
        |> assign_new(:debounce, fn -> assigns[:debounce] || @default_debounce end)
        |> assign_new(:update_min_len, fn ->
          assigns[:update_min_len] || @default_update_min_len
        end)
        |> assign_new(:max_selectable, fn -> assigns[:max_selectable] || 0 end)
        |> assign_new(:allow_clear, fn -> assigns[:allow_clear] || false end)
        |> assign_new(:user_defined_options, fn -> assigns[:user_defined_options] || false end)
        |> assign_new(:disabled, fn -> assigns[:disabled] || false end)
        |> assign_new(:keep_options_on_select, fn -> assigns[:keep_options_on_select] || false end)
        |> assign_new(:target, fn -> assigns[:"phx-target"] end)
        |> assign_new(:blur_event, fn -> assigns[:"phx-blur"] end)
        |> assign_new(:focus_event, fn -> assigns[:"phx-focus"] end)
        |> assign_new(:value_mapper, fn -> assigns[:value_mapper] end)
        |> assign_new(:class, fn -> assigns[:class] end)
        |> assign_new(:option_slot, fn -> assigns[:option] || [] end)
        |> assign_new(:tag_slot, fn -> assigns[:tag] || [] end)
        |> assign_new(:clear_button_slot, fn -> assigns[:clear_button] || [] end)
      else
        socket
      end

    # Handle options update via send_update
    socket =
      if Map.has_key?(assigns, :options) do
        normalized = normalize_options(assigns.options)

        socket
        |> assign(:options, normalized)
        |> assign(:available_options, normalized)
        |> assign(:dropdown_open, length(normalized) > 0)
      else
        socket
      end

    # Handle programmatic value update via send_update
    socket =
      if Map.has_key?(assigns, :value) do
        set_selection(socket, assigns.value)
      else
        # Initialize selection from form field value only on initial mount
        if Map.has_key?(assigns, :field) do
          maybe_init_selection_from_field(socket)
        else
          socket
        end
      end

    {:ok, socket}
  end

  defp default_id(%{form: form, field: field}) do
    "#{form.name}_#{field}_live_select"
  end

  defp default_id(_), do: "live_select_#{System.unique_integer([:positive])}"

  defp maybe_init_selection_from_field(socket) do
    if socket.assigns[:selection] == [] do
      field = socket.assigns.field
      value = field.value

      # Skip empty/nil values and empty JSON array strings
      if value && value != "" && value != [] && value != "[]" do
        set_selection(socket, value)
      else
        socket
      end
    else
      socket
    end
  end

  defp set_selection(socket, nil) do
    assign(socket, :selection, [])
  end

  defp set_selection(socket, value) when is_list(value) do
    # Tags mode - list of values
    selection =
      Enum.map(value, fn v ->
        find_option_by_value(socket.assigns.options, v) ||
          normalize_option(v)
      end)

    assign(socket, :selection, selection)
  end

  defp set_selection(socket, value) do
    # Single mode - single value
    option =
      find_option_by_value(socket.assigns.options, value) ||
        normalize_option(value)

    assign(socket, :selection, [option])
  end

  defp find_option_by_value(options, value) do
    Enum.find(options, fn opt -> opt.value == value end)
  end

  # Option normalization - convert various formats to internal structure
  defp normalize_options(options) when is_list(options) do
    Enum.map(options, &normalize_option/1)
  end

  defp normalize_options(options) when is_map(options) do
    # Handle keyword-like maps: %{Red: 1, Yellow: 2}
    Enum.map(options, fn {label, value} ->
      %{
        label: to_string(label),
        value: value,
        tag_label: nil,
        disabled: false,
        sticky: false
      }
    end)
  end

  defp normalize_option(opt) when is_binary(opt) or is_atom(opt) or is_number(opt) do
    %{
      label: to_string(opt),
      value: opt,
      tag_label: nil,
      disabled: false,
      sticky: false
    }
  end

  defp normalize_option({label, value}) do
    %{
      label: to_string(label),
      value: value,
      tag_label: nil,
      disabled: false,
      sticky: false
    }
  end

  defp normalize_option({label, value, disabled}) when is_boolean(disabled) do
    %{
      label: to_string(label),
      value: value,
      tag_label: nil,
      disabled: disabled,
      sticky: false
    }
  end

  defp normalize_option(opt) when is_map(opt) do
    %{
      label: to_string(opt[:label] || opt["label"] || opt[:value] || opt["value"]),
      value: opt[:value] || opt["value"],
      tag_label: opt[:tag_label] || opt["tag_label"],
      disabled: opt[:disabled] || opt["disabled"] || false,
      sticky: opt[:sticky] || opt["sticky"] || false
    }
  end

  defp normalize_option(opt) when is_list(opt) do
    # Keyword list
    %{
      label: to_string(Keyword.get(opt, :label, Keyword.get(opt, :value))),
      value: Keyword.get(opt, :value),
      tag_label: Keyword.get(opt, :tag_label),
      disabled: Keyword.get(opt, :disabled, false),
      sticky: Keyword.get(opt, :sticky, false)
    }
  end

  # Event handlers
  @impl true
  def handle_event("text_input", %{"text" => text}, socket) do
    socket = assign(socket, :text, text)

    # Reset active index when text changes
    socket = assign(socket, :active_index, -1)

    {:noreply, socket}
  end

  def handle_event("select_option", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    options = socket.assigns.available_options

    if index >= 0 && index < length(options) do
      option = Enum.at(options, index)
      {:noreply, select_option(socket, option)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_active", _params, socket) do
    index = socket.assigns.active_index
    options = socket.assigns.available_options

    cond do
      # If an option is highlighted, select it
      index >= 0 && index < length(options) ->
        option = Enum.at(options, index)

        if option.disabled do
          {:noreply, socket}
        else
          {:noreply, select_option(socket, option)}
        end

      # If no option highlighted but options exist, select the first non-disabled one
      length(options) > 0 ->
        first_enabled = Enum.find(options, fn opt -> !opt.disabled end)

        if first_enabled do
          {:noreply, select_option(socket, first_enabled)}
        else
          {:noreply, socket}
        end

      # If no options but user_defined_options is enabled, create from text
      socket.assigns.user_defined_options && socket.assigns.text != "" ->
        option = normalize_option(socket.assigns.text)
        {:noreply, select_option(socket, option)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("remove_tag", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    selection = socket.assigns.selection

    if index >= 0 && index < length(selection) do
      option = Enum.at(selection, index)

      if option.sticky do
        {:noreply, socket}
      else
        new_selection = List.delete_at(selection, index)
        socket = assign(socket, :selection, new_selection)
        {:noreply, push_change_event(socket)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear", _params, socket) do
    socket =
      socket
      |> assign(:selection, [])
      |> assign(:text, "")

    {:noreply, push_change_event(socket)}
  end

  def handle_event("set_active", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    {:noreply, assign(socket, :active_index, index)}
  end

  def handle_event("navigate", %{"direction" => direction}, socket) do
    options = socket.assigns.available_options
    current = socket.assigns.active_index
    max_index = length(options) - 1

    new_index =
      case direction do
        "down" ->
          if current >= max_index, do: 0, else: current + 1

        "up" ->
          if current <= 0, do: max_index, else: current - 1
      end

    {:noreply, assign(socket, :active_index, new_index)}
  end

  def handle_event("open_dropdown", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, true)}
  end

  def handle_event("close_dropdown", _params, socket) do
    socket =
      socket
      |> assign(:dropdown_open, false)
      |> assign(:active_index, -1)

    {:noreply, socket}
  end

  def handle_event("toggle_option", %{"index" => index_str}, socket) do
    # For quick_tags mode - toggle selection
    index = String.to_integer(index_str)
    options = socket.assigns.available_options

    if index >= 0 && index < length(options) do
      option = Enum.at(options, index)

      if option.disabled do
        {:noreply, socket}
      else
        {:noreply, toggle_option(socket, option)}
      end
    else
      {:noreply, socket}
    end
  end

  # Catch-all for any unexpected events (e.g., from phx-keydown)
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp select_option(socket, option) do
    if option.disabled do
      socket
    else
      mode = socket.assigns.mode

      socket =
        case mode do
          :single ->
            socket
            |> assign(:selection, [option])
            |> assign(:text, option.label)
            |> maybe_close_dropdown()

          :tags ->
            add_to_selection(socket, option)
            |> assign(:text, "")
            |> maybe_close_dropdown()

          :quick_tags ->
            toggle_option(socket, option)
        end

      socket
      |> maybe_clear_options()
      |> push_change_event()
    end
  end

  defp toggle_option(socket, option) do
    selection = socket.assigns.selection
    existing = Enum.find_index(selection, fn s -> s.value == option.value end)

    if existing do
      # Already selected - remove it (unless sticky)
      opt = Enum.at(selection, existing)

      if opt.sticky do
        socket
      else
        new_selection = List.delete_at(selection, existing)
        assign(socket, :selection, new_selection)
      end
    else
      # Not selected - add it
      add_to_selection(socket, option)
    end
  end

  defp add_to_selection(socket, option) do
    selection = socket.assigns.selection
    max = socket.assigns.max_selectable

    # Check if already at max
    if max > 0 && length(selection) >= max do
      socket
    else
      # Check if already selected
      if Enum.any?(selection, fn s -> s.value == option.value end) do
        socket
      else
        assign(socket, :selection, selection ++ [option])
      end
    end
  end

  defp maybe_close_dropdown(socket) do
    if socket.assigns.keep_options_on_select do
      socket
    else
      assign(socket, :dropdown_open, false)
    end
  end

  defp maybe_clear_options(socket) do
    if socket.assigns.keep_options_on_select do
      socket
    else
      socket
      |> assign(:available_options, [])
      |> assign(:active_index, -1)
    end
  end

  defp push_change_event(socket) do
    # Push event to trigger form change (client-side)
    socket = push_event(socket, "live_select:change", %{id: socket.assigns.id})

    # Notify parent LiveView of selection change
    notify_parent(socket)

    socket
  end

  defp notify_parent(socket) do
    selection = socket.assigns.selection
    mode = socket.assigns.mode
    id = socket.assigns.id

    event_payload =
      case mode do
        :single ->
          case selection do
            [opt | _] -> %{id: id, value: opt.value, label: opt.label}
            _ -> %{id: id, value: nil, label: nil}
          end

        _ ->
          # Tags modes
          %{
            id: id,
            selection: Enum.map(selection, &Map.take(&1, [:value, :label, :tag_label]))
          }
      end

    # Send message to parent LiveView process
    send(self(), {:live_select_selected, event_payload})
  end

  # Helpers for rendering
  defp selected_value(selection, mode) do
    case mode do
      :single ->
        case selection do
          [opt | _] -> encode_value(opt.value)
          _ -> ""
        end

      _ ->
        # Tags modes return list
        Enum.map(selection, fn opt -> encode_value(opt.value) end)
    end
  end

  defp encode_value(value) when is_binary(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value) when is_number(value), do: to_string(value)
  defp encode_value(value), do: Jason.encode!(value)

  defp is_option_selected?(option, selection) do
    Enum.any?(selection, fn s -> s.value == option.value end)
  end

  defp input_name(%{form: form, field: field}), do: "#{form.name}[#{field}]"
  defp input_name(_), do: "live_select"

  defp text_input_name(field), do: "#{input_name(field)}_text_input"

  defp field_id(%{id: id}), do: id
  defp field_id(_), do: "live_select"

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
      data-field={input_name(@field)}
      data-target={@target}
      data-blur-event={@blur_event}
      data-focus-event={@focus_event}
      data-user-defined={@user_defined_options}
      data-allow-clear={@allow_clear}
      data-disabled={@disabled}
    >
      <%!-- Tags (for tags and quick_tags modes) --%>
      <div :if={@mode in [:tags, :quick_tags] && @selection != []} class="live-select-tags">
        <%= for {option, index} <- Enum.with_index(@selection) do %>
          <span class={["live-select-tag", option.sticky && "live-select-tag-sticky"]}>
            <%= if @tag_slot != [] do %>
              {render_slot(@tag_slot, option)}
            <% else %>
              <span class="live-select-tag-label">
                {option.tag_label || option.label}
              </span>
            <% end %>
            <button
              :if={!option.sticky}
              type="button"
              class="live-select-tag-remove"
              phx-click="remove_tag"
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
          class="live-select-input"
          value={@text}
          placeholder={@placeholder}
          autocomplete="off"
          disabled={@disabled}
          name={text_input_name(@field)}
          id={"#{@id}_text_input"}
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={to_string(@dropdown_open)}
          aria-controls={"#{@id}_dropdown"}
          aria-activedescendant={if @active_index >= 0, do: "#{@id}_option_#{@active_index}"}
          aria-autocomplete="list"
          aria-label={@placeholder}
        />

        <%!-- Clear button (single mode with allow_clear) --%>
        <button
          :if={@mode == :single && @allow_clear && @selection != []}
          type="button"
          class="live-select-clear"
          phx-click="clear"
          phx-target={@myself}
          aria-label="Clear selection"
        >
          <%= if @clear_button_slot != [] do %>
            {render_slot(@clear_button_slot)}
          <% else %>
            <.icon name="hero-x-mark" class="size-4" />
          <% end %>
        </button>
      </div>

      <%!-- Dropdown --%>
      <ul
        :if={@dropdown_open && @available_options != []}
        id={"#{@id}_dropdown"}
        class="live-select-dropdown"
        role="listbox"
        aria-label="Options"
        aria-multiselectable={to_string(@mode in [:tags, :quick_tags])}
      >
        <%= for {option, index} <- Enum.with_index(@available_options) do %>
          <li
            id={"#{@id}_option_#{index}"}
            class={[
              "live-select-option",
              @active_index == index && "live-select-option-active",
              option.disabled && "live-select-option-disabled",
              is_option_selected?(option, @selection) && "live-select-option-selected"
            ]}
            role="option"
            aria-selected={is_option_selected?(option, @selection)}
            aria-disabled={option.disabled}
            phx-click={if @mode == :quick_tags, do: "toggle_option", else: "select_option"}
            phx-value-index={index}
            phx-target={@myself}
          >
            <%= if @option_slot != [] do %>
              {render_slot(
                @option_slot,
                Map.put(option, :selected, is_option_selected?(option, @selection))
              )}
            <% else %>
              {option.label}
            <% end %>
          </li>
        <% end %>
      </ul>

      <%!-- Empty state --%>
      <div
        :if={@dropdown_open && @available_options == [] && @text != ""}
        class="live-select-empty"
        role="status"
        aria-live="polite"
      >
        No results found
      </div>

      <%!-- Hidden inputs for form submission --%>
      <%= if @mode == :single do %>
        <input
          type="hidden"
          name={input_name(@field)}
          value={selected_value(@selection, @mode)}
          id={field_id(@field)}
        />
      <% else %>
        <%!-- For tags modes, use array notation --%>
        <%= if @selection == [] do %>
          <input type="hidden" name={"#{input_name(@field)}[]"} value="" />
        <% else %>
          <%= for value <- selected_value(@selection, @mode) do %>
            <input type="hidden" name={"#{input_name(@field)}[]"} value={value} />
          <% end %>
        <% end %>
      <% end %>

      <script :type={ColocatedHook} name=".LiveSelect">
        export default {
          mounted() {
            this.mode = this.el.dataset.mode;
            this.debounce = parseInt(this.el.dataset.debounce) || 100;
            this.updateMinLen = parseInt(this.el.dataset.updateMinLen) || 1;
            this.target = this.el.dataset.target;
            this.blurEvent = this.el.dataset.blurEvent;
            this.focusEvent = this.el.dataset.focusEvent;
            this.userDefined = this.el.dataset.userDefined === 'true';
            this.allowClear = this.el.dataset.allowClear === 'true';
            this.disabled = this.el.dataset.disabled === 'true';
            this.fieldName = this.el.dataset.field;

            this.debounceTimer = null;
            this.input = this.el.querySelector('.live-select-input');
            this.lastText = this.input?.value || '';

            this.setupEventListeners();
          },

          updated() {
            // Re-cache input in case DOM changed
            this.input = this.el.querySelector('.live-select-input');
          },

          destroyed() {
            if (this.debounceTimer) {
              clearTimeout(this.debounceTimer);
            }
            document.removeEventListener('click', this.onClickOutside);
          },

          setupEventListeners() {
            if (!this.input || this.disabled) return;

            // Input events
            this.input.addEventListener('input', this.onInput.bind(this));
            this.input.addEventListener('keydown', this.onKeyDown.bind(this));
            this.input.addEventListener('focus', this.onFocus.bind(this));
            this.input.addEventListener('blur', this.onBlur.bind(this));

            // Click outside to close
            this.onClickOutside = (e) => {
              if (!this.el.contains(e.target)) {
                this.pushEventTo(this.el, 'close_dropdown', {});
              }
            };
            document.addEventListener('click', this.onClickOutside);

            // Listen for change events from server
            this.handleEvent('live_select:change', ({id}) => {
              if (id === this.el.id) {
                this.triggerFormChange();
              }
            });
          },

          onInput(e) {
            const text = e.target.value;
            this.lastText = text;

            // Update server with current text
            this.pushEventTo(this.el, 'text_input', { text });

            // Debounced search trigger
            if (this.debounceTimer) {
              clearTimeout(this.debounceTimer);
            }

            if (text.length >= this.updateMinLen) {
              this.debounceTimer = setTimeout(() => {
                this.triggerSearch(text);
              }, this.debounce);
            } else {
              // Close dropdown if text is too short
              this.pushEventTo(this.el, 'close_dropdown', {});
            }
          },

          onKeyDown(e) {
            switch (e.key) {
              case 'ArrowDown':
                e.preventDefault();
                this.pushEventTo(this.el, 'navigate', { direction: 'down' });
                this.pushEventTo(this.el, 'open_dropdown', {});
                break;

              case 'ArrowUp':
                e.preventDefault();
                this.pushEventTo(this.el, 'navigate', { direction: 'up' });
                break;

              case 'Enter':
                e.preventDefault();
                this.pushEventTo(this.el, 'select_active', {});
                break;

              case 'Escape':
                e.preventDefault();
                this.pushEventTo(this.el, 'close_dropdown', {});
                this.input.blur();
                break;

              case 'Backspace':
                // In tags mode, remove last tag if input is empty
                if (this.mode !== 'single' && this.input.value === '') {
                  const tags = this.el.querySelectorAll('.live-select-tag-remove');
                  if (tags.length > 0) {
                    tags[tags.length - 1].click();
                  }
                }
                break;

              case 'Tab':
                // Close dropdown on tab
                this.pushEventTo(this.el, 'close_dropdown', {});
                break;
            }
          },

          onFocus(e) {
            if (this.focusEvent) {
              this.pushEvent(this.focusEvent, { id: this.el.id });
            }
            // Open dropdown if we have options
            this.pushEventTo(this.el, 'open_dropdown', {});
          },

          onBlur(e) {
            // Small delay to allow click events on options to fire
            setTimeout(() => {
              if (this.blurEvent) {
                this.pushEvent(this.blurEvent, { id: this.el.id });
              }
              // Don't close on blur for quick_tags mode
              if (this.mode !== 'quick_tags') {
                // this.pushEventTo(this.el, 'close_dropdown', {});
              }
            }, 150);
          },

          triggerSearch(text) {
            // Send search event to parent LiveView
            const eventTarget = this.target ? 
              document.querySelector(`[phx-target="${this.target}"]`) || this.el :
              this.el;

            this.pushEvent('live_select_change', {
              text: text,
              id: this.el.id,
              field: this.fieldName
            });
          },

          triggerFormChange() {
            // Trigger input event on hidden field to notify form of change
            const hiddenInput = this.el.querySelector('input[type="hidden"]');
            if (hiddenInput) {
              hiddenInput.dispatchEvent(new Event('input', { bubbles: true }));
            }
          }
        }
      </script>
    </div>
    """
  end
end
