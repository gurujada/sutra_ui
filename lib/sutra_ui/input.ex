defmodule SutraUI.Input do
  @moduledoc """
  Renders form input elements with label, description, and error handling.

  The unified form field component for Sutra UI. This is a drop-in replacement
  for Phoenix's generated `input` component, providing full parity with Phoenix
  generators while using Sutra UI styling.

  ## Basic Usage

      # Simple text input
      <.input type="text" name="username" placeholder="Username" />

      # With label
      <.input type="email" name="email" label="Email" placeholder="you@example.com" />

      # With label and description
      <.input
        type="text"
        name="username"
        label="Username"
        description="This will be your public display name."
        placeholder="johndoe"
      />

  ## Phoenix Form Integration

  Pass a `Phoenix.HTML.FormField` via the `field` attribute to automatically
  extract the input's `id`, `name`, `value`, and validation errors:

      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:password]} type="password" label="Password" />
        <.input
          field={@form[:bio]}
          type="textarea"
          label="Bio"
          description="Tell us about yourself."
        />
        <:actions>
          <.button type="submit">Save</.button>
        </:actions>
      </.simple_form>

  Errors are displayed automatically when the field has been interacted with
  (via `Phoenix.Component.used_input?/1`), so errors won't flash on first render.

  ## Error Handling

  Errors can come from two sources:

  1. **Automatic** - from a `Phoenix.HTML.FormField` (Ecto changeset errors):

          <.input field={@form[:email]} type="email" label="Email" />

  2. **Manual** - via the `errors` attribute:

          <.input name="email" errors={["can't be blank"]} />

  When errors are present, the input gets `aria-invalid="true"` and error
  messages render below the input with a destructive icon.

  ## Input Types

  This component handles all standard HTML input types, with special handling for:

    * `type="checkbox"` - Delegates to `SutraUI.Checkbox` with hidden false value
    * `type="switch"` - Delegates to `SutraUI.Switch` (toggle with role="switch")
    * `type="select"` - Renders a native `<select>` element
    * `type="textarea"` - Delegates to `SutraUI.Textarea`
    * `type="range"` - Delegates to `SutraUI.Slider` with colocated hook
    * `type="hidden"` - Renders just the input, no wrapper or label

  ### Type Examples

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

  ## Complete Form Example

  Here is a realistic registration form demonstrating labels, descriptions,
  error handling, and multiple input types working together:

      defmodule MyAppWeb.RegistrationLive do
        use MyAppWeb, :live_view

        def mount(_params, _session, socket) do
          changeset = Accounts.change_user(%User{})
          {:ok, assign(socket, form: to_form(changeset))}
        end

        def handle_event("validate", %{"user" => params}, socket) do
          changeset =
            %User{}
            |> Accounts.change_user(params)
            |> Map.put(:action, :validate)

          {:noreply, assign(socket, form: to_form(changeset))}
        end

        def handle_event("save", %{"user" => params}, socket) do
          case Accounts.create_user(params) do
            {:ok, _user} -> {:noreply, push_navigate(socket, to: ~p"/dashboard")}
            {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
          end
        end

        def render(assigns) do
          ~H\"\"\"
          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <.input
              field={@form[:name]}
              label="Full Name"
              placeholder="Jane Smith"
            />
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              description="We'll send a confirmation link to this address."
              placeholder="jane@example.com"
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              description="Must be at least 8 characters."
              placeholder="Create a password"
            />
            <.input
              field={@form[:role]}
              type="select"
              label="Role"
              prompt="Choose a role"
              options={[{"Developer", "dev"}, {"Designer", "design"}, {"Manager", "pm"}]}
            />
            <.input
              field={@form[:bio]}
              type="textarea"
              label="Bio"
              description="Brief description for your profile."
              rows={3}
            />
            <.input
              field={@form[:terms]}
              type="checkbox"
              label="I agree to the terms of service"
            />
            <.input
              field={@form[:newsletter]}
              type="switch"
              label="Subscribe to newsletter"
              description="Receive weekly updates about new features."
            />
            <:actions>
              <.button type="submit">Create Account</.button>
            </:actions>
          </.simple_form>
          \"\"\"
        end
      end

  ## Accessibility

  - Labels are properly associated with inputs via wrapping `<label>` elements
  - Description text is linked via `aria-describedby` on the input
  - `aria-invalid` is automatically set when errors are present
  - Error messages are displayed below inputs with destructive styling
  - Switch inputs include `role="switch"` and `aria-checked`
  - Range inputs include `aria-valuemin`, `aria-valuemax`, `aria-valuenow`
  - Supports standard ARIA attributes via `:rest`
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField

  @doc """
  Renders an input with label, description, and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" label="Email" />
      <.input name="my-input" errors={["oh no!"]} />
      <.input field={@form[:username]} label="Username" description="Pick something unique." />
  """

  attr(:id, :any, default: nil, doc: "The id attribute for the input")
  attr(:name, :any, default: nil, doc: "The name attribute for the input")
  attr(:label, :string, default: nil, doc: "Label text - renders label before input")

  attr(:description, :string,
    default: nil,
    doc: "Helper text rendered below the label, above the input"
  )

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

  # Checkbox input - delegates to SutraUI.Checkbox
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
        <SutraUI.Checkbox.checkbox
          name={@name}
          value="true"
          checked={@checked}
          class={@class}
          id={@id}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        />
        <span :if={@label} class="label">{@label}</span>
      </label>
      <p :if={@description} class="field-description mt-1">{@description}</p>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Select input - native HTML select
  def input(%{type: "select"} = assigns) do
    assigns = assign_description_id(assigns)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <p :if={@description} id={@description_id} class="field-description mb-1.5">
          {@description}
        </p>
        <select
          id={@id}
          name={@name}
          class={["select w-full", @class]}
          multiple={@multiple}
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@description_id}
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

  # Textarea input - delegates to SutraUI.Textarea
  def input(%{type: "textarea"} = assigns) do
    assigns =
      assigns
      |> assign(
        :textarea_value,
        Phoenix.HTML.Form.normalize_value("textarea", assigns.value)
      )
      |> assign_description_id()

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <p :if={@description} id={@description_id} class="field-description mb-1.5">
          {@description}
        </p>
        <SutraUI.Textarea.textarea
          id={@id}
          name={@name}
          value={@textarea_value}
          class={@class}
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@description_id}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Switch input - delegates to SutraUI.Switch
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
        <SutraUI.Switch.switch
          name={@name}
          value="true"
          checked={@checked}
          class={@class}
          id={@id}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        />
        <span :if={@label} class="label">{@label}</span>
      </label>
      <p :if={@description} class="field-description mt-1">{@description}</p>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Range input - delegates to SutraUI.Slider
  def input(%{type: "range"} = assigns) do
    # Generate a unique ID if not provided (required by Slider)
    assigns =
      assigns
      |> assign_new(:id, fn -> "range-#{System.unique_integer([:positive])}" end)
      |> assign(:slider_value, assigns.value || 50)

    ~H"""
    <div class="fieldset mb-2">
      <label :if={@label}>
        <span class="label mb-1">{@label}</span>
      </label>
      <p :if={@description} class="field-description mb-1.5">{@description}</p>
      <SutraUI.Slider.slider
        id={@id}
        name={@name}
        value={@slider_value}
        class={@class}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs: text, email, password, number, date, etc.
  def input(assigns) do
    assigns = assign_description_id(assigns)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <p :if={@description} id={@description_id} class="field-description mb-1.5">
          {@description}
        </p>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={["input w-full", @class]}
          multiple={@multiple}
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@description_id}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Assigns a description_id based on the input's id, or nil if no description.
  defp assign_description_id(%{description: nil} = assigns),
    do: assign(assigns, :description_id, nil)

  defp assign_description_id(%{description: _} = assigns) do
    desc_id = if assigns.id, do: "#{assigns.id}-description", else: nil
    assign(assigns, :description_id, desc_id)
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
