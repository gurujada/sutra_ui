defmodule PhxUI.Field do
  @moduledoc """
  Combine labels, controls, and help text to compose accessible form fields.

  Provides two main components:
  - `field/1` - Individual field container (label, input, helper text, errors)
  - `fieldset/1` - Groups multiple related fields together

  ## Accessibility

  This component implements the WAI-ARIA field pattern:
  - Uses `role="group"` for field container
  - Generates unique IDs for helper text and errors
  - Helper text linked via `aria-describedby`
  - Error messages linked via `aria-describedby` and `aria-invalid`
  - Fieldsets use semantic `<fieldset>` and `<legend>` elements
  """

  use Phoenix.Component

  @doc """
  Renders a field container for form inputs.

  Fields automatically manage the layout of labels, inputs, helper text,
  and error messages. Use the slots to compose the field structure.

  ## Examples

      # Basic field with label and input
      <.field>
        <:label for="username">Username</:label>
        <:input>
          <input id="username" type="text" placeholder="evilrabbit" />
        </:input>
        <:description id="username-desc">Choose a unique username.</:description>
      </.field>

      # Horizontal orientation (checkbox/switch pattern)
      <.field orientation="horizontal">
        <:input>
          <input id="newsletter" type="checkbox" />
        </:input>
        <:label for="newsletter">Subscribe to newsletter</:label>
      </.field>

      # Field with error state
      <.field invalid>
        <:label for="password">Password</:label>
        <:input>
          <input id="password" type="password" aria-invalid="true" />
        </:input>
        <:error id="password-error">Password must be at least 8 characters</:error>
      </.field>

      # With section (complex horizontal layout)
      <.field orientation="horizontal">
        <:section>
          <:label for="mfa">Multi-factor authentication</:label>
          <:description>Enable MFA for enhanced security</:description>
        </:section>
        <:input>
          <input id="mfa" type="checkbox" role="switch" />
        </:input>
      </.field>
  """

  attr(:orientation, :string,
    default: "vertical",
    values: ~w(vertical horizontal),
    doc: "Layout orientation - vertical stacks label above input, horizontal aligns side-by-side"
  )

  attr(:invalid, :boolean, default: false, doc: "Mark field as invalid (applies error styling)")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id role),
    doc: "Additional HTML attributes"
  )

  slot :label, doc: "Label for the input (use 'for' attribute to associate with input)" do
    attr(:for, :string, doc: "Associates label with input")
    attr(:class, :string, doc: "Additional CSS classes")
  end

  slot :section,
    doc: "Wraps label and description when label sits beside input (for horizontal orientation)" do
    attr(:class, :string, doc: "Additional CSS classes for the section")
  end

  slot(:input, required: true, doc: "The form input control")

  slot :description,
    doc: "Helper text (use 'id' attribute and reference with aria-describedby on input)" do
    attr(:id, :string, doc: "ID for aria-describedby reference")
  end

  slot :error,
    doc:
      "Error message (use 'id' attribute, reference with aria-describedby, and set aria-invalid on input)" do
    attr(:id, :string, doc: "ID for aria-describedby reference")
  end

  def field(assigns) do
    field_class =
      case assigns.orientation do
        "horizontal" -> "field-horizontal"
        _ -> "field-vertical"
      end

    assigns = assign(assigns, :field_class, field_class)

    ~H"""
    <div
      class={[@field_class, @class]}
      role="group"
      data-orientation={@orientation != "vertical" && @orientation}
      data-invalid={@invalid || nil}
      {@rest}
    >
      <%= if @section != [] do %>
        <%= for section <- @section do %>
          <section class={Map.get(section, :class)}>
            {render_slot([section])}
          </section>
        <% end %>
      <% else %>
        {render_label_slot(@label)}
        {render_description_slot(@description)}
      <% end %>
      {render_slot(@input)}
      <%= if @error != [] do %>
        {render_error_slot(@error)}
      <% end %>
    </div>
    """
  end

  defp render_label_slot([]), do: nil

  defp render_label_slot(label_slot) do
    assigns = %{label: label_slot}

    ~H"""
    <%= for label <- @label do %>
      <label for={label[:for]} class={["field-label", label[:class]]}>
        {render_slot([label])}
      </label>
    <% end %>
    """
  end

  defp render_description_slot([]), do: nil

  defp render_description_slot(description_slot) do
    assigns = %{description: description_slot}

    ~H"""
    <%= for desc <- @description do %>
      <p id={desc[:id]} class="field-description">
        {render_slot([desc])}
      </p>
    <% end %>
    """
  end

  defp render_error_slot(error_slot) do
    assigns = %{error: error_slot}

    ~H"""
    <%= for err <- @error do %>
      <p id={err[:id]} class="field-error">
        {render_slot([err])}
      </p>
    <% end %>
    """
  end

  @doc """
  Renders a fieldset container for grouping related fields.

  Fieldsets use semantic HTML with `<fieldset>` and `<legend>` elements,
  providing proper accessibility for groups of related form controls.

  ## Examples

      # Basic fieldset with multiple fields
      <.fieldset>
        <:legend>Profile Information</:legend>
        <:description>This information will be displayed on your profile</:description>
        <:fields>
          <.field>
            <:label for="name">Full name</:label>
            <:input>
              <input id="name" type="text" placeholder="Evil Rabbit" />
            </:input>
          </.field>

          <.field>
            <:label for="email">Email</:label>
            <:input>
              <input id="email" type="email" placeholder="evil@rabbit.com" />
            </:input>
          </.field>
        </:fields>
      </.fieldset>

      # Disabled fieldset (disables all child inputs)
      <.fieldset disabled>
        <:legend>Locked Section</:legend>
        <:fields>
          <.field>
            <:label for="locked">This is disabled</:label>
            <:input>
              <input id="locked" type="text" />
            </:input>
          </.field>
        </:fields>
      </.fieldset>
  """

  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include: ~w(id disabled),
    doc: "Additional HTML attributes"
  )

  slot(:legend, required: true, doc: "Heading for the fieldset")
  slot(:description, doc: "Description text")
  slot(:fields, required: true, doc: "Individual field containers or form controls")

  def fieldset(assigns) do
    ~H"""
    <fieldset class={["fieldset-base", @class]} {@rest}>
      <legend class="fieldset-legend">{render_slot(@legend)}</legend>
      <%= if @description != [] do %>
        <p class="fieldset-description">{render_slot(@description)}</p>
      <% end %>
      <div class="fieldset-fields">
        {render_slot(@fields)}
      </div>
    </fieldset>
    """
  end
end
