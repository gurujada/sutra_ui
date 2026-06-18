defmodule SutraUI.Stepper do
  @moduledoc """
  A progress indicator for multi-step workflows.

  Stepper provides the chrome — numbered markers, connector lines, and state
  styling. You define what each step looks like inside the `:step` slot. Step
  states auto-compute from the `current` index, so you rarely set them by hand.

  ## Examples

      # Basic — states auto-compute from current
      <.stepper current={2}>
        <:step>
          <h4>Profile</h4>
          <p>Tell us about yourself</p>
        </:step>
        <:step>
          <h4>Workspace</h4>
          <p>Configure defaults</p>
        </:step>
        <:step>
          <h4>Invite</h4>
          <p>Bring in teammates</p>
        </:step>
      </.stepper>

      # Vertical orientation for side panels
      <.stepper current={3} orientation="vertical">
        <:step><h4>Account</h4></:step>
        <:step><h4>Team</h4></:step>
        <:step><h4>Billing</h4></:step>
        <:step><h4>Launch</h4></:step>
      </.stepper>

      # Clickable steps — emit an event when a marker is clicked
      <.stepper current={@current_step} select_event="jump_to_step">
        <:step value="profile"><h4>Profile</h4></:step>
        <:step value="workspace"><h4>Workspace</h4></:step>
        <:step value="invite"><h4>Invite</h4></:step>
      </.stepper>

      # Error state — pass an errors map keyed by step index
      <.stepper current={3} errors={%{3 => "Card declined"}}>
        <:step><h4>Select plan</h4></:step>
        <:step><h4>Payment</h4></:step>
        <:step><h4>Confirm</h4></:step>
      </.stepper>

  ## Step States

  States auto-compute from `current` (1-based):

  | Condition | State |
  |-----------|-------|
  | index < current | `complete` (checkmark) |
  | index == current | `current` (highlighted) |
  | index > current | `pending` (muted) |
  | errors[index] present | `error` (overrides auto-state) |

  Override any step's state explicitly with the `state` slot attr.

  ## Attributes

  * `current` - 1-based index of the active step. `0` means none active.
  * `errors` - Map of step index → error message. Auto-marks those steps as error.
  * `orientation` - `horizontal`, `vertical`, or `responsive` (vertical on mobile,
    horizontal on desktop). Defaults to `horizontal`.
  * `variant` - `default` (solid markers) or `outline` (bordered markers).
  * `select_event` - When set, markers become buttons that emit this event with
    `phx-value-step` set to the step's `value`.
  * `class` - Additional CSS classes.

  ## Slot Attributes

  The `:step` slot accepts:

  * `state` - Override the auto-computed state: `complete`, `current`, `pending`, `error`.
  * `icon` - Custom text/emoji for the marker — overrides the number and auto-state icons.
  * `value` - Step value, emitted as `phx-value-step` when `select_event` is set.

  ## Accessibility

  - Uses an ordered list (`<ol>`) to convey sequence.
  - The active step sets `aria-current="step"`.
  - When `select_event` is set, markers render as `<button>` elements; otherwise
    they're non-interactive spans.
  """

  use Phoenix.Component

  attr(:current, :integer,
    default: 0,
    doc: "One-based index of the active step. 0 means none active."
  )

  attr(:errors, :map,
    default: %{},
    doc: "Map of step index (1-based) → error message. Auto-marks those steps as error."
  )

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical responsive),
    doc: "Stepper orientation"
  )

  attr(:variant, :string,
    default: "default",
    values: ~w(default outline),
    doc: "Visual variant — `outline` gives bordered markers"
  )

  attr(:select_event, :string,
    default: nil,
    doc: "When set, markers become buttons that emit this event with phx-value-step"
  )

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :step, required: true do
    attr(:state, :string,
      values: ~w(complete current pending error),
      doc: "Step state. Defaults to auto-computed from current."
    )

    attr(:icon, :string,
      doc: "Custom text/emoji for the marker — overrides number and auto-state icons"
    )

    attr(:value, :string, doc: "Step value, emitted as phx-value-step when select_event is set")
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
          <%= if @select_event && step[:value] do %>
            <button
              type="button"
              class="stepper-marker stepper-marker-button"
              phx-click={@select_event}
              phx-value-step={step[:value]}
              aria-label={"Go to step #{index}"}
            >
              {render_marker(step, index, @current, @errors)}
            </button>
          <% else %>
            <span class="stepper-marker">
              {render_marker(step, index, @current, @errors)}
            </span>
          <% end %>
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

  defp render_marker(step, index, current, errors) do
    state = step_state(step, index, current, errors)
    assigns = %{step: step, index: index, state: state}

    ~H"""
    <%= cond do %>
      <% @step[:icon] -> %>
        {@step.icon}
      <% @state == "complete" -> %>
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
      <% @state == "error" -> %>
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
        {@index}
    <% end %>
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

  defp error_msg(_step, index, errors) when is_map(errors), do: errors[index]
  defp error_msg(_, _, _), do: nil
end
