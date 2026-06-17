defmodule SutraUI.Stepper do
  @moduledoc """
  A progress indicator for multi-step workflows.

  Stepper provides the chrome (numbered marker, connector lines, state styling).
  You define what each step looks like inside the inner_block. No brittle
  title/description attributes — maximum flexibility.

  ## Examples

      <.stepper current={2}>
        <:step state="complete">
          <h4>Profile</h4>
          <p>Tell us about yourself</p>
        </:step>
        <:step state="current">
          <h4>Workspace</h4>
          <p>Configure defaults</p>
        </:step>
        <:step>
          <h4>Invite</h4>
          <p>Bring in teammates</p>
        </:step>
      </.stepper>

      # Custom icons in markers
      <.stepper orientation="vertical" current={3}>
        <:step state="complete" icon="✓" />
        <:step state="complete" icon="✓" />
        <:step state="current" icon="3" />
      </.stepper>
  """

  use Phoenix.Component

  attr(:current, :integer,
    default: 0,
    doc: "One-based index of the active step. 0 means none active."
  )

  attr(:errors, :map,
    default: %{},
    doc: "Map of step index (1-based) to error message string. Auto-marks those steps as error."
  )

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical responsive),
    doc: "Stepper orientation"
  )

  attr(:variant, :string,
    default: "default",
    values: ~w(default white),
    doc: "Visual variant"
  )

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :step, required: true do
    attr(:state, :string,
      values: ~w(complete current pending error),
      doc: "Step state. Defaults to auto-computed from @current."
    )

    attr(:icon, :string,
      doc: "Custom text/emoji for the marker — overrides number and auto-state icons"
    )
  end

  def stepper(assigns) do
    ~H"""
    <ol
      class={[
        "stepper",
        "stepper-#{@orientation}",
        @variant != "default" && "stepper-#{@variant}",
        @class
      ]}
      {@rest}
    >
      <li
        :for={{step, index} <- Enum.with_index(@step, 1)}
        class="stepper-item"
        data-state={step_state(step, index, @current, @errors)}
        aria-current={index == @current && "step"}
      >
        <div class="stepper-marker-row">
          <span class="stepper-marker">
            <%= cond do %>
              <% step[:icon] -> %>
                {step.icon}
              <% step_state(step, index, @current, @errors) == "complete" -> %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="stepper-check"
                  aria-hidden="true"
                >
                  <path d="M20 6 9 17l-5-5" />
                </svg>
              <% step_state(step, index, @current, @errors) == "error" -> %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="stepper-error-icon"
                  aria-hidden="true"
                >
                  <path d="M18 6 6 18" /><path d="m6 6 12 12" />
                </svg>
              <% true -> %>
                {index}
            <% end %>
          </span>
          <span class="stepper-connector" aria-hidden="true"></span>
        </div>
        <div class="stepper-content">
          {render_slot(step)}
          <p :if={error_msg(step, index, @errors)} class="stepper-error-text">
            {error_msg(step, index, @errors)}
          </p>
        </div>
      </li>
    </ol>
    """
  end

  defp step_state(step, index, current, errors) when is_map(errors) do
    step[:state] ||
      if(errors[index], do: "error") ||
      cond do
        index < current -> "complete"
        index == current -> "current"
        true -> "pending"
      end
  end

  defp step_state(step, index, current, _errors), do: step_state(step, index, current, %{})

  defp error_msg(_step, index, errors) when is_map(errors) do
    errors[index]
  end

  defp error_msg(_, _, _), do: nil
end
