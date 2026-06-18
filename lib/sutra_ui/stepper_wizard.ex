defmodule SutraUI.StepperWizard do
  @moduledoc """
  A composable wizard shell for multi-step forms and flows.

  Stepper Wizard composes `SutraUI.Stepper` for the progress navigation and
  renders only the active step body. The parent LiveView owns form state,
  validation, persistence, and step transitions.

  ## Examples

      <.form for={@form} phx-change="validate" phx-submit="submit_wizard">
        <.stepper_wizard id="checkout" current={@step} errors={@step_errors}>
          <:step id="shipping" label="Shipping">
            <.shipping_fields form={@form} />
          </:step>
          <:step id="payment" label="Payment">
            <.payment_fields form={@form} />
          </:step>
          <:step id="confirm" label="Confirm">
            <.order_review order={@order} />
          </:step>

          <:actions>
            <.button type="button" phx-click="previous_step">Back</.button>
            <.button type="submit">Continue</.button>
          </:actions>
        </.stepper_wizard>
      </.form>
  """

  use Phoenix.Component

  import SutraUI.Stepper

  attr(:id, :string, required: true, doc: "Unique DOM id for the wizard")

  attr(:current, :string,
    default: nil,
    doc: "ID of the active step. Defaults to the first step"
  )

  attr(:errors, :map,
    default: %{},
    doc: "Map of step id to error message. Error steps are reflected in the navigation"
  )

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical responsive),
    doc: "Stepper orientation"
  )

  attr(:variant, :string,
    default: "default",
    values: ~w(default outline),
    doc: "Stepper visual variant"
  )

  attr(:class, :any, default: nil, doc: "Additional classes for the wizard root")
  attr(:nav_class, :any, default: nil, doc: "Additional classes for the step navigation")
  attr(:panel_class, :any, default: nil, doc: "Additional classes for the active panel")
  attr(:actions_class, :any, default: nil, doc: "Additional classes for the actions wrapper")
  attr(:rest, :global, include: ~w(aria-label), doc: "Additional HTML attributes")

  slot :step, required: true do
    attr(:id, :string, required: true, doc: "Stable step id")
    attr(:label, :string, required: true, doc: "Navigation label")
    attr(:description, :string, doc: "Optional navigation description")
    attr(:icon, :string, doc: "Custom marker icon")
  end

  slot(:actions, doc: "Optional action row rendered below the active panel")

  def stepper_wizard(assigns) do
    assigns = assign(assigns, :steps, build_steps(assigns.step, assigns.current, assigns.errors))

    ~H"""
    <div id={@id} class={["stepper-wizard", @class]} data-stepper-wizard {@rest}>
      <.stepper
        current={@steps.current_index}
        errors={@steps.index_errors}
        orientation={@orientation}
        variant={@variant}
        class={["stepper-wizard-nav", @nav_class]}
        aria-label="Steps"
      >
        <:step :for={step <- @steps.items} state={step.state} icon={step.icon}>
          <span
            id={"#{@id}-step-#{step.id}"}
            class="stepper-wizard-trigger"
            aria-controls={"#{@id}-panel"}
            aria-current={step.current? && "step"}
            data-stepper-wizard-trigger
            data-step-id={step.id}
            data-step-index={step.index}
          >
            <span class="stepper-wizard-label">{step.label}</span>
            <span :if={step.description} class="stepper-wizard-description">
              {step.description}
            </span>
          </span>
        </:step>
      </.stepper>

      <section
        id={"#{@id}-panel"}
        class={["stepper-wizard-panel", @panel_class]}
        role="tabpanel"
        aria-labelledby={"#{@id}-step-#{@steps.current.id}"}
        tabindex="0"
      >
        {render_slot(@steps.current.slot)}
      </section>

      <div :if={@actions != []} class={["stepper-wizard-actions", @actions_class]}>
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  defp build_steps(steps, current, errors) do
    current = normalized_current(steps, current)
    active_index = current_index(steps, current)

    items =
      steps
      |> Enum.with_index(1)
      |> Enum.map(fn {step, index} ->
        step_id = step.id
        current? = step_id == current
        error = error_for(errors, step_id)
        completed? = index < active_index

        %{
          slot: step,
          id: step_id,
          index: index,
          label: step.label,
          description: step[:description],
          icon: step[:icon],
          current?: current?,
          completed?: completed?,
          state: step_state(current?, completed?, error),
          error: error
        }
      end)

    current_step = Enum.find(items, & &1.current?) || List.first(items)

    %{
      current: current_step,
      current_index: (current_step && current_step.index) || 0,
      index_errors: index_errors(items),
      items: items
    }
  end

  defp first_step_id([first | _]), do: first.id
  defp first_step_id(_), do: nil

  defp normalized_current(steps, nil), do: first_step_id(steps)

  defp normalized_current(steps, current) do
    if Enum.any?(steps, &(&1.id == current)), do: current, else: first_step_id(steps)
  end

  defp current_index(steps, current) do
    steps
    |> Enum.find_index(&(&1.id == current))
    |> case do
      nil -> 1
      index -> index + 1
    end
  end

  defp error_for(errors, step_id) when is_map(errors) do
    errors[step_id] || errors[to_string(step_id)] || errors[to_atom(step_id)]
  end

  defp error_for(_errors, _step_id), do: nil

  defp to_atom(value) when is_atom(value), do: value

  defp to_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end

  defp to_atom(_value), do: nil

  defp step_state(_current?, _completed?, error) when not is_nil(error), do: "error"
  defp step_state(true, _completed?, _error), do: "current"
  defp step_state(_current?, true, _error), do: "complete"
  defp step_state(_current?, _completed?, _error), do: "pending"

  defp index_errors(items) do
    items
    |> Enum.filter(& &1.error)
    |> Map.new(&{&1.index, &1.error})
  end
end
