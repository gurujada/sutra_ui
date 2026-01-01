defmodule SutraUI.Input do
  @moduledoc """
  Renders form input elements with label and error handling.

  A drop-in replacement for Phoenix's generated input component, providing
  full parity with Phoenix generators while using Sutra UI styling.

  ## Examples

      # Basic text input
      <.input type="text" name="username" placeholder="Username" />

      # With form field (auto-extracts id, name, value, errors)
      <.input field={@form[:email]} type="email" label="Email" />

      # Password input with label
      <.input type="password" name="password" label="Password" required />

      # Select with options
      <.input
        type="select"
        name="country"
        label="Country"
        prompt="Select a country"
        options={[{"United States", "us"}, {"Canada", "ca"}]}
      />

      # Checkbox
      <.input type="checkbox" name="terms" label="I agree to the terms" />

      # Switch (toggle)
      <.input type="switch" name="notifications" label="Enable notifications" />

      # Textarea
      <.input type="textarea" name="bio" label="Bio" rows={4} />

      # Range slider
      <.input type="range" name="volume" label="Volume" min={0} max={100} />

  ## Types

  This component accepts all HTML input types, with special handling for:

    * `type="checkbox"` - Renders a checkbox with hidden false value
    * `type="switch"` - Renders a toggle switch (styled checkbox with role="switch")
    * `type="select"` - Renders a native `<select>` element
    * `type="textarea"` - Renders a `<textarea>` element
    * `type="range"` - Renders a styled range slider with visual fill
    * `type="hidden"` - Renders just the input, no wrapper or label

  For live file uploads, see `Phoenix.Component.live_file_input/1`.

  ## Select Types

  This component provides two ways to render select inputs:

  ### Native Select (via `<.input type="select">`)

  For standard form selects that work with Phoenix generators:

      <.input
        field={@form[:country]}
        type="select"
        label="Country"
        prompt="Select a country"
        options={[{"United States", "us"}, {"Canada", "ca"}]}
      />

  ### Custom Select (via `SutraUI.Select`)

  For advanced features like search/filter, keyboard navigation, and custom styling,
  use the dedicated `SutraUI.Select` component directly:

      <.select id="country" name="country" value={@country} searchable>
        <.select_option value="us" label="United States" />
        <.select_option value="ca" label="Canada" />
      </.select>

  See `SutraUI.Select` for more details.

  ## Accessibility

  - Labels are properly associated with inputs via wrapping
  - `aria-invalid` is automatically set when errors are present
  - Error messages are displayed below inputs
  - Switch inputs include `role="switch"` and `aria-checked`
  - Range inputs include `aria-valuemin`, `aria-valuemax`, `aria-valuenow`
  - Supports standard ARIA attributes via `:rest`
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """

  attr(:id, :any, default: nil, doc: "The id attribute for the input")
  attr(:name, :any, default: nil, doc: "The name attribute for the input")
  attr(:label, :string, default: nil, doc: "Label text - renders label before input")
  attr(:value, :any, default: nil, doc: "The value of the input")

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range search select switch tel text textarea time url week)
  )

  attr(:field, FormField,
    doc: "A form field struct retrieved from the form, for example: @form[:email]"
  )

  attr(:errors, :list, default: [], doc: "List of error messages to display")
  attr(:checked, :boolean, doc: "The checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "The prompt for select inputs")
  attr(:options, :list, doc: "The options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "The multiple flag for select inputs")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step phx-debounce
                phx-mounted aria-label aria-describedby aria-invalid aria-required)
  )

  # FormField handler - extracts field data and recurses
  def input(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign(
      :name,
      assigns.name || if(assigns.multiple, do: field.name <> "[]", else: field.name)
    )
    |> assign(:value, assigns.value || field.value)
    |> input()
  end

  # Hidden input - no wrapper, no label, no errors
  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  # Checkbox input
  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={["input", @class]}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        />
        <span :if={@label} class="label">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Select input - native HTML select
  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={["select w-full", @class]}
          multiple={@multiple}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Textarea input
  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={["textarea w-full", @class]}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Switch input - uses SutraUI.Switch component
  def input(%{type: "switch"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label class="flex items-center gap-3 cursor-pointer">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          role="switch"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          aria-checked={to_string(@checked)}
          class={["switch", @class]}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        />
        <span :if={@label} class="label">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Range input - uses SutraUI.Slider styling
  def input(%{type: "range"} = assigns) do
    # Generate a unique ID if not provided
    assigns =
      assign_new(assigns, :id, fn ->
        "range-#{System.unique_integer([:positive])}"
      end)

    # Get min/max/step from rest or use defaults
    min = assigns.rest[:min] || 0
    max = assigns.rest[:max] || 100
    step = assigns.rest[:step] || 1
    value = assigns.value || 50

    # Convert to floats for calculation
    min_f = to_float(min)
    max_f = to_float(max)
    value_f = to_float(value)

    # Calculate percentage for CSS custom property
    percent = if max_f == min_f, do: 0.0, else: (value_f - min_f) / (max_f - min_f) * 100

    assigns =
      assigns
      |> assign(:percent, "#{percent}%")
      |> assign(:min, min)
      |> assign(:max, max)
      |> assign(:step, step)
      |> assign(:slider_value, value)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type="range"
          id={@id}
          name={@name}
          value={@slider_value}
          min={@min}
          max={@max}
          step={@step}
          class={["slider w-full", @class]}
          aria-invalid={@errors != [] && "true"}
          aria-valuemin={@min}
          aria-valuemax={@max}
          aria-valuenow={@slider_value}
          style={"--slider-value: #{@percent}"}
          oninput="this.style.setProperty('--slider-value', ((this.value - this.min) / (this.max - this.min) * 100) + '%')"
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Convert any numeric type to float (for range percentage calculation)
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(value) when is_float(value), do: value

  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp to_float(_), do: 0.0

  # All other inputs: text, email, password, number, date, etc.
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={["input w-full", @class]}
          multiple={@multiple}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Renders an error message with icon.
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-destructive">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="currentColor"
        class="size-5 shrink-0"
        aria-hidden="true"
      >
        <path
          fill-rule="evenodd"
          d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zM12 8.25a.75.75 0 01.75.75v3.75a.75.75 0 01-1.5 0V9a.75.75 0 01.75-.75zm0 8.25a.75.75 0 100-1.5.75.75 0 000 1.5z"
          clip-rule="evenodd"
        />
      </svg>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # You can make use of gettext to translate error messages by
    # uncommenting and adjusting the following code:

    # if count = opts[:count] do
    #   Gettext.dngettext(MyAppWeb.Gettext, "errors", msg, msg, count, opts)
    # else
    #   Gettext.dgettext(MyAppWeb.Gettext, "errors", msg, opts)
    # end

    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
