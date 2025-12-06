defmodule PhxUI.RadioGroup do
  @moduledoc """
  A set of checkable buttons—known as radio buttons—where no more than one
  of the buttons can be checked at a time.

  Provides two components:
  - `radio_group/1` - A complete group with label, radios, and error handling
  - `radio/1` - A single radio button for custom layouts

  ## Accessibility

  - Uses semantic `<fieldset>` and `role="radiogroup"` for proper grouping
  - Individual radio buttons use `<input type="radio">`
  - Supports `aria-invalid` for error states
  - Supports `aria-describedby` for error messages
  - Proper label associations via `for` and `id` attributes
  - Keyboard accessible (Arrow keys to navigate, Space to select)
  """

  use Phoenix.Component

  @doc """
  Renders a radio group with label and multiple radio options.

  ## Examples

      # Basic radio group
      <.radio_group name="theme" label="Choose your theme">
        <:radio value="light" label="Light" />
        <:radio value="dark" label="Dark" checked />
        <:radio value="auto" label="Auto" />
      </.radio_group>

      # Required radio group
      <.radio_group name="size" label="Select size" required>
        <:radio value="small" label="Small" />
        <:radio value="medium" label="Medium" />
        <:radio value="large" label="Large" />
      </.radio_group>

      # With errors
      <.radio_group name="plan" label="Select plan" errors={["Please select a plan"]}>
        <:radio value="free" label="Free" />
        <:radio value="pro" label="Pro" />
      </.radio_group>

      # Disabled group
      <.radio_group name="option" label="Choose option" disabled>
        <:radio value="a" label="Option A" />
        <:radio value="b" label="Option B" />
      </.radio_group>

      # Radio with description
      <.radio_group name="notify" label="Notifications">
        <:radio value="all" label="All">Receive all notifications</:radio>
        <:radio value="important" label="Important only">Only critical alerts</:radio>
      </.radio_group>
  """

  attr(:name, :string,
    required: true,
    doc: "The name attribute for all radio inputs in the group"
  )

  attr(:label, :string, default: nil, doc: "The label for the radio group")
  attr(:id, :string, default: nil, doc: "The ID for the fieldset element")
  attr(:errors, :list, default: [], doc: "List of error messages")
  attr(:required, :boolean, default: false, doc: "Whether the radio group is required")
  attr(:disabled, :boolean, default: false, doc: "Whether all radio inputs are disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(aria-describedby),
    doc: "Additional HTML attributes for the fieldset"
  )

  slot :radio, required: true, doc: "Radio button items" do
    attr(:value, :string, required: true, doc: "The value of the radio input")
    attr(:label, :string, required: true, doc: "The label text for the radio button")
    attr(:checked, :boolean, doc: "Whether this radio is checked")
    attr(:disabled, :boolean, doc: "Whether this specific radio is disabled")
    attr(:id, :string, doc: "Custom ID for this radio input")
  end

  def radio_group(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "radio-group-#{assigns.name}" end)
      |> assign(:label_id, "#{assigns[:id] || "radio-group-#{assigns.name}"}-label")
      |> assign(:error_id, "#{assigns[:id] || "radio-group-#{assigns.name}"}-error")

    ~H"""
    <div class={["flex flex-col gap-3", @class]}>
      <label
        :if={@label}
        id={@label_id}
        class={[
          "label",
          @required && "after:content-['*'] after:text-destructive after:ml-0.5"
        ]}
      >
        {@label}
      </label>

      <fieldset
        id={@id}
        role="radiogroup"
        class="grid gap-3"
        aria-labelledby={@label && @label_id}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={@errors != [] && @error_id}
        aria-required={@required && "true"}
        {@rest}
      >
        <label
          :for={radio <- @radio}
          class={[
            "flex cursor-pointer items-center gap-2 text-sm font-normal",
            (radio[:disabled] || @disabled) && "cursor-not-allowed opacity-50"
          ]}
        >
          <input
            type="radio"
            name={@name}
            value={radio.value}
            id={radio[:id] || "#{@id}-#{radio.value}"}
            checked={radio[:checked]}
            disabled={radio[:disabled] || @disabled}
            required={@required}
            class="input"
            aria-invalid={@errors != [] && "true"}
          />
          <div class="flex flex-col gap-0.5">
            <span class="text-sm font-medium">{radio.label}</span>
            <%= if radio[:inner_block] do %>
              <span class="text-muted-foreground text-sm">{render_slot(radio)}</span>
            <% end %>
          </div>
        </label>
      </fieldset>

      <div :if={@errors != []} id={@error_id} class="flex flex-col gap-1">
        <p :for={error <- @errors} class="text-destructive text-sm">
          {error}
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a single radio input for custom layouts.

  Use this when you need more control over the layout of radio buttons.

  ## Examples

      # Basic radio
      <.radio name="agree" value="yes" label="I agree to the terms" />

      # Checked radio
      <.radio name="remember" value="true" label="Remember me" checked />

      # Disabled radio
      <.radio name="option" value="1" label="Option 1" disabled />

      # With description
      <.radio name="notify" value="email" label="Email notifications">
        Receive daily digest emails
      </.radio>

      # With errors
      <.radio name="plan" value="pro" label="Pro Plan" errors={["Required"]}>
        $29/month
      </.radio>
  """

  attr(:name, :string, required: true, doc: "The name attribute for the radio input")
  attr(:value, :string, required: true, doc: "The value of the radio input")
  attr(:label, :string, required: true, doc: "The label text for the radio button")
  attr(:id, :string, default: nil, doc: "The ID for the input element")
  attr(:checked, :boolean, default: false, doc: "Whether the radio is checked")
  attr(:disabled, :boolean, default: false, doc: "Whether the radio is disabled")
  attr(:errors, :list, default: [], doc: "List of error messages")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(required form aria-describedby),
    doc: "Additional HTML attributes"
  )

  slot(:inner_block, doc: "Optional description content")

  def radio(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "radio-#{assigns.name}-#{assigns.value}" end)
      |> assign(:error_id, "#{assigns[:id] || "radio-#{assigns.name}-#{assigns.value}"}-error")

    ~H"""
    <div class={["flex flex-col gap-1", @class]}>
      <label class={[
        "flex cursor-pointer items-center gap-2 text-sm font-normal",
        @disabled && "cursor-not-allowed opacity-50"
      ]}>
        <input
          type="radio"
          name={@name}
          value={@value}
          id={@id}
          checked={@checked}
          disabled={@disabled}
          class="input"
          aria-invalid={@errors != [] && "true"}
          aria-describedby={@errors != [] && @error_id}
          {@rest}
        />
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-medium">{@label}</span>
          <%= if @inner_block != [] do %>
            <span class="text-muted-foreground text-sm">{render_slot(@inner_block)}</span>
          <% end %>
        </div>
      </label>

      <div :if={@errors != []} id={@error_id} class="ml-6 flex flex-col gap-1">
        <p :for={error <- @errors} class="text-destructive text-sm">
          {error}
        </p>
      </div>
    </div>
    """
  end

  # Removed radio_input_class as we now use "input" class
end
