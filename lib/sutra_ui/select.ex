defmodule SutraUI.Select do
  @moduledoc """
  A select for forms: a real `<select>` underneath, SutraUI's own list on top.

  Every form that chooses from a list uses this component (`<.input type="select">` renders
  it). The server renders a real `<select>` with the options, so the form posts, `phx-change`
  fires, `to_form`/`field`, validation errors and first paint work with no JavaScript. The
  `.Select` hook then hides the `<select>` and shows a trigger and a list that the page
  draws as ordinary markup, so the open list also appears in a screen share (the browser's
  own option popup does not). Choosing an option sets the `<select>` and fires its `input`
  and `change` events.

  ## Examples

      # From a form field (id, name, value come from the field)
      <.select field={@form[:role]} label="Role" options={[{"Admin", "admin"}, {"Member", "member"}]} />

      # Standalone, with a prompt
      <.select id="country" name="country" label="Country" prompt="Choose a country"
               value={@country} options={@countries} />

      # Option groups and disabled options
      <.select
        id="stack"
        name="stack"
        label="Stack"
        options={[
          {"Backend", [{"Phoenix", "phoenix"}, {"Rails", "rails", disabled: true}]},
          {"Frontend", [{"React", "react"}, {"Vue", "vue"}]}
        ]}
      />

      # Several values, shown as chips in the trigger
      <.select field={@form[:tags]} label="Tags" options={@tags} multiple />

      # Through the input component, with label, description and errors
      <.input field={@form[:role]} type="select" label="Role" options={@roles} prompt="Choose" />

  ## Options

  `options` takes what `Phoenix.HTML.Form.options_for_select/2` takes: a list of strings,
  `{label, value}` pairs, `{label, value, disabled: true}` triples, and `{group_label, options}`
  for an option group. The value can be anything with a string form.

  ## Attributes

  | Attribute | Meaning |
  |-----------|---------|
  | `field` | a `Phoenix.HTML.FormField`; supplies `id`, `name` and `value` |
  | `label` | the accessible name, and the title of the bottom sheet on phones |
  | `prompt` | the empty choice ("Choose…"); also offered in the list so a choice can be cleared |
  | `multiple` | several values; the trigger shows chips and the list stays open while choosing |
  | `searchable` | a search box in the list. `nil` (default): from 10 options on; `true` or `false` force it |
  | `native` | only the browser's own `<select>` (for a page that must work without JavaScript) |
  | `disabled` | the field cannot be changed |
  | `class`, `trigger_class` | extra classes on the wrapper and on the trigger |

  Attributes such as `required`, `form`, `phx-change`, `aria-invalid` and `aria-describedby`
  go to the real `<select>` (and, for the last three, to the trigger).

  A multiple select with nothing chosen posts nothing for its field (the browser's rule), so
  give the field a default in the handler.

  ## Phones

  Below 640 px the list opens as a bottom sheet (a backdrop, the label as title, a Close
  button and finger-sized rows). A search box in it takes focus only when tapped, so the
  keyboard does not cover the list.

  ## On screen

  On larger screens the list hangs under the field; near the bottom or the right edge it
  flips above or shifts back in, and it never grows taller than the room it has (the list
  scrolls inside).

  ## Keyboard

  | Key | Action |
  |-----|--------|
  | `Enter`, `Space`, `ArrowDown`, `ArrowUp` | Open the list (on the field) |
  | `ArrowDown`, `ArrowUp`, `Home`, `End`, `PageDown`, `PageUp` | Move the active option |
  | Letters | Type-ahead by first letters (a repeated letter cycles); in the search box they filter |
  | `Enter`, `Space` | Choose the active option (`Space` types in the search box) |
  | `Tab` | Take the active option and move on |
  | `Escape` | Close and return to the field |

  ## Custom option content

  For options that need markup (a badge, an icon) build the list yourself with
  `select_option/1`, `select_group/1` and `select_separator/1` inside `select/1`. That form
  keeps a hidden `<input>` for the value instead of a `<select>`:

      <.select id="status" name="status" value={@status}>
        <:trigger><.badge>{@status}</.badge></:trigger>
        <.select_option value="active" label="Active" />
        <.select_option value="pending" label="Pending" />
      </.select>

  Prefer `options` wherever the options are plain text.

  ## Hook

  The hook is an extracted colocated hook that imports `sutra_ui/select` (see
  [JavaScript Hooks](colocated-hooks.md)): merge the generated `phoenix-colocated/sutra_ui`
  hooks into your LiveSocket, as for `dialog`. Without it the page still works with the
  browser's own `<select>`.

  ## Accessibility

  - The trigger is the WAI-ARIA select-only combobox (`role="combobox"`, `aria-expanded`,
    `aria-controls`, `aria-activedescendant`); the list is a `role="listbox"` (with
    `aria-multiselectable` for `multiple`) of `role="option"` rows with `aria-selected`
  - With a search box it is the editable combobox: focus moves to the search box on larger
    screens
  - The trigger takes the label as its name and the field's `aria-invalid` and
    `aria-describedby`; a `<label for={id}>` focuses the trigger
  - The real `<select>` stays in the form but is out of the tab order and hidden from
    assistive technology while the hook is active

  ## Related

  - `SutraUI.LiveSelect` - For async/remote data loading
  - `SutraUI.RadioGroup` - For smaller option sets without dropdown
  - `SutraUI.DropdownMenu` - For action menus (not form selection)
  - [Forms Cheatsheet](forms.cheatmd) - Form patterns
  - [Accessibility Guide](accessibility.md) - ARIA patterns
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders a select.

  With `options` (or a `field` and `options`) it is a real `<select>` with SutraUI's list on
  top; with an inner block of `select_option/1` it is the custom-option form. See the module
  documentation.
  """

  attr(:id, :string, default: nil, doc: "Unique id; the `<select>`'s id (taken from `field`)")
  attr(:name, :string, default: nil, doc: "Form input name (taken from `field`)")
  attr(:value, :any, default: nil, doc: "Selected value, or a list of values for `multiple`")
  attr(:field, FormField, default: nil, doc: "A form field, for example `@form[:role]`")

  attr(:options, :list,
    default: nil,
    doc: "Strings, `{label, value}`, `{label, value, disabled: true}` and `{group, options}`"
  )

  attr(:label, :string, default: nil, doc: "Accessible name, and the title of the phone sheet")
  attr(:prompt, :string, default: nil, doc: "The empty choice, for example \"Choose…\"")
  attr(:multiple, :boolean, default: false, doc: "Choose several values; chips in the trigger")

  attr(:searchable, :any,
    default: nil,
    doc: "Search box in the list: `nil` from 10 options on, `true` or `false` to force"
  )

  attr(:native, :boolean, default: false, doc: "Only the browser's own `<select>`")

  attr(:selected_label, :string,
    default: nil,
    doc: "Custom-option form only: label for the current value (defaults to the value)"
  )

  attr(:search_placeholder, :string,
    default: "Search...",
    doc: "Placeholder text for the search input"
  )

  attr(:empty_message, :string,
    default: "No results found",
    doc: "Message when no results match search"
  )

  attr(:trigger_class, :string, default: nil, doc: "Additional CSS classes for trigger button")
  attr(:class, :string, default: nil, doc: "Additional CSS classes for main container")
  attr(:disabled, :boolean, default: false, doc: "Whether the select is disabled")

  attr(:rest, :global,
    include:
      ~w(form required autocomplete size phx-change phx-blur phx-focus phx-debounce aria-invalid aria-describedby aria-required),
    doc: "Additional HTML attributes, set on the `<select>`"
  )

  slot(:trigger, doc: "Custom-option form only: content for the trigger button")

  slot(:inner_block,
    doc: "Custom-option form: `select_option`, `select_group`, `select_separator`"
  )

  attr(:nonce, :string, default: nil, doc: "Unused; the hook is bundled by your app, not inline")

  def select(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(
      :name,
      assigns.name || if(assigns.multiple, do: field.name <> "[]", else: field.name)
    )
    |> assign(:value, if(is_nil(assigns.value), do: field.value, else: assigns.value))
    |> select()
  end

  def select(%{options: options, native: true} = assigns) when is_list(options) do
    assigns = assigns |> require_id() |> assign_items()

    ~H"""
    <select
      id={@id}
      name={@name}
      multiple={@multiple}
      disabled={@disabled}
      class={["select w-full", @class]}
      {@rest}
    >
      <.native_options prompt={@prompt} multiple={@multiple} items={@items} selected={@selected} />
    </select>
    """
  end

  def select(%{options: options} = assigns) when is_list(options) do
    assigns = assigns |> require_id() |> assign_items()

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class={["select", @class]}
      data-has-select
      data-state="closed"
      data-mode={if @multiple, do: "multiple", else: "single"}
      data-disabled={@disabled}
      data-prompt={@prompt}
      phx-hook=".Select"
    >
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        disabled={@disabled}
        class="select-native"
        {@rest}
      >
        <.native_options prompt={@prompt} multiple={@multiple} items={@items} selected={@selected} />
      </select>
      <button
        type="button"
        id={"#{@id}-trigger"}
        class={["select-trigger", @trigger_class]}
        role="combobox"
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        aria-label={@label}
        aria-invalid={@rest[:"aria-invalid"]}
        aria-describedby={@rest[:"aria-describedby"]}
        aria-required={@rest[:required] && "true"}
        disabled={@disabled}
      >
        <span
          class="select-value"
          data-selected-label
          data-placeholder={@selected in [[], [""]]}
        >{if @shown_chips == [], do: @shown}<span :for={chip <- @shown_chips} class="select-chip">{chip}</span></span>
        <.chevron />
      </button>
      <div class="select-backdrop" aria-hidden="true"></div>
      <div id={"#{@id}-popover"} class="select-popover" data-popover aria-hidden="true">
        <div class="select-sheet-head">
          <span class="select-sheet-title">{@label || @prompt}</span>
          <button type="button" class="select-sheet-close" data-select-close aria-label="Close">
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
              <path d="M18 6 6 18" /><path d="m6 6 12 12" />
            </svg>
          </button>
        </div>
        <header :if={@search}>
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
            aria-label={@search_placeholder}
            autocomplete="off"
            autocorrect="off"
            spellcheck="false"
            aria-autocomplete="list"
            role="combobox"
            aria-expanded="false"
            aria-controls={"#{@id}-listbox"}
          />
        </header>
        <div
          role="listbox"
          id={"#{@id}-listbox"}
          class="select-listbox"
          aria-orientation="vertical"
          aria-multiselectable={@multiple && "true"}
          aria-label={@label}
          data-empty={@empty_message}
        >
          <div
            :if={@prompt && !@multiple}
            role="option"
            id={"#{@id}-option-prompt"}
            class="select-option select-option-prompt"
            data-value=""
            data-label={@prompt}
            aria-selected={to_string(@selected == [""])}
            tabindex="-1"
          >
            {@prompt}
          </div>
          <%= for item <- @items do %>
            <div
              :if={item.type == :group}
              role="group"
              class="select-group"
              aria-labelledby={"#{@id}-group-#{item.index}"}
            >
              <div role="presentation" id={"#{@id}-group-#{item.index}"} class="select-group-label">
                {item.label}
              </div>
              <.list_option :for={opt <- item.options} id={@id} opt={opt} />
            </div>
            <.list_option :if={item.type == :option} id={@id} opt={item} />
          <% end %>
        </div>
      </div>
      <.select_hook />
    </div>
    """
  end

  def select(assigns), do: custom_select(assigns)

  # The id names the `<select>` and everything around it; without one it comes from the name.
  defp require_id(%{id: nil, name: name} = assigns) when is_binary(name) and name != "" do
    assign(assigns, :id, String.replace(name, ~r/[^A-Za-z0-9_-]+/, "_"))
  end

  defp require_id(%{id: nil}),
    do: raise(ArgumentError, "SutraUI.Select needs an `id`, a `name` or a `field`")

  defp require_id(assigns), do: assigns

  attr(:prompt, :string, default: nil)
  attr(:multiple, :boolean, default: false)
  attr(:items, :list, required: true)
  attr(:selected, :list, required: true)

  defp native_options(assigns) do
    ~H"""
    <option :if={@prompt && !@multiple} value="" selected={@selected == [""]}>{@prompt}</option>
    <%= for item <- @items do %>
      <optgroup :if={item.type == :group} label={item.label}>
        <option
          :for={opt <- item.options}
          value={opt.value}
          selected={opt.value in @selected}
          disabled={opt.disabled}
        >
          {opt.label}
        </option>
      </optgroup>
      <option
        :if={item.type == :option}
        value={item.value}
        selected={item.value in @selected}
        disabled={item.disabled}
      >
        {item.label}
      </option>
    <% end %>
    """
  end

  attr(:id, :string, required: true)
  attr(:opt, :map, required: true)

  defp list_option(assigns) do
    ~H"""
    <div
      role="option"
      id={"#{@id}-option-#{@opt.index}"}
      class={["select-option", @opt.disabled && "select-option-disabled"]}
      data-value={@opt.value}
      data-label={@opt.label}
      aria-selected={to_string(@opt.selected)}
      aria-disabled={to_string(@opt.disabled)}
      tabindex="-1"
    >
      {@opt.label}
    </div>
    """
  end

  defp chevron(assigns) do
    ~H"""
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
    """
  end

  defp select_hook(assigns) do
    ~H"""
    <script :type={ColocatedHook} name=".Select">
      import {Select} from "sutra_ui/select"
      export default Select
    </script>
    """
  end

  # The options as the template needs them: groups and options in order, each option with
  # its index (for ids), whether it is selected and disabled. For one value, a missing or
  # unknown value falls back to the prompt, else to the first enabled option (the browser's
  # own choice), so the trigger and the `<select>` agree.
  defp assign_items(assigns) do
    {items, count} = options_to_items(assigns.options)

    flat =
      Enum.flat_map(items, fn
        %{type: :group, options: o} -> o
        opt -> [opt]
      end)

    values = assigns.value |> List.wrap() |> Enum.map(&to_string/1)

    selected =
      cond do
        assigns.multiple ->
          values

        Enum.any?(flat, &(&1.value in values)) ->
          [Enum.find(flat, &(&1.value in values)).value]

        assigns.prompt ->
          [""]

        true ->
          flat |> Enum.reject(& &1.disabled) |> Enum.take(1) |> Enum.map(& &1.value)
      end

    items = mark_selected(items, selected)

    flat_selected =
      flat |> Enum.filter(&(&1.value in selected)) |> Enum.map(& &1.label)

    assigns
    |> assign(:items, items)
    |> assign(:selected, selected)
    |> assign(:count, count)
    |> assign(:search, search?(assigns.searchable, count))
    |> assign(
      :shown,
      if(assigns.multiple, do: "", else: shown_label(flat_selected, assigns.prompt))
    )
    |> assign(:shown_chips, if(assigns.multiple, do: flat_selected, else: []))
  end

  defp shown_label([label | _], _prompt), do: label
  defp shown_label([], prompt), do: prompt || ""

  defp search?(true, _), do: true
  defp search?(false, _), do: false
  defp search?(_, count), do: count >= 10

  defp mark_selected(items, selected) do
    Enum.map(items, fn
      %{type: :group, options: opts} = group ->
        %{group | options: Enum.map(opts, &Map.put(&1, :selected, &1.value in selected))}

      opt ->
        Map.put(opt, :selected, opt.value in selected)
    end)
  end

  defp options_to_items(options) do
    {items, count} =
      Enum.map_reduce(options, 0, fn entry, n ->
        case entry do
          {label, list} when is_list(list) ->
            {opts, n2} = Enum.map_reduce(list, n, &option_item(&1, &2))
            {%{type: :group, label: to_string(label), options: opts, index: n}, n2}

          other ->
            option_item(other, n)
        end
      end)

    {items, count}
  end

  defp option_item({label, value, opts}, n) when is_list(opts) do
    {item(label, value, Keyword.get(opts, :disabled, false), n), n + 1}
  end

  defp option_item({label, value}, n), do: {item(label, value, false, n), n + 1}
  defp option_item(value, n), do: {item(value, value, false, n), n + 1}

  defp item(label, value, disabled, n) do
    %{
      type: :option,
      label: to_string(label),
      value: to_string(value),
      disabled: disabled == true,
      index: n
    }
  end

  defp custom_select(assigns) do
    ~H"""
    <div
      id={@id}
      class={["select", @class]}
      data-select-value={@value}
      phx-hook=".Select"
      data-custom-trigger={@trigger != []}
      {@rest}
    >
      <button
        type="button"
        class={["select-trigger", @trigger_class]}
        id={"#{@id}-trigger"}
        role="combobox"
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

      <.select_hook />
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
