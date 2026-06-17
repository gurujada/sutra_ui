defmodule SutraUI.Stepper do
  @moduledoc """
  A progress indicator for multi-step workflows.

  Stepper is inspired by Preline's static and linear stepper patterns, adapted
  to Sutra UI's slot API and design tokens. It renders semantic list markup and
  leaves navigation or form progression state in the parent LiveView.

  ## Examples

      <.stepper current={2}>
        <:step title="Profile" description="Tell us about yourself" />
        <:step title="Workspace" description="Configure defaults" />
        <:step title="Invite" description="Bring in teammates" />
      </.stepper>

      <.stepper orientation="vertical" current={3}>
        <:step title="Created" state="complete" />
        <:step title="Reviewed" state="complete" />
        <:step title="Published" state="current" />
      </.stepper>
  """

  use Phoenix.Component

  attr(:current, :integer, default: 1, doc: "One-based active step index")

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "Stepper orientation"
  )

  attr(:variant, :string,
    default: "default",
    values: ~w(default solid),
    doc: "Visual variant"
  )

  attr(:linear, :boolean, default: false, doc: "Place labels inline with indicators")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  slot :step, required: true do
    attr(:title, :string, required: true, doc: "Step title")
    attr(:description, :string, doc: "Optional supporting text")
    attr(:state, :string, values: ~w(complete current pending error), doc: "Explicit state")
    attr(:icon, :string, doc: "Optional text or icon glyph for the indicator")
  end

  def stepper(assigns) do
    ~H"""
    <ol
      class={[
        "stepper",
        "stepper-#{@orientation}",
        @variant == "solid" && "stepper-solid",
        @linear && "stepper-linear",
        @class
      ]}
      data-orientation={@orientation}
      {@rest}
    >
      <%= for {step, index} <- Enum.with_index(@step, 1) do %>
        <.stepper_item step={step} index={index} state={step_state(step, index, @current)} />
      <% end %>
    </ol>
    """
  end

  attr(:step, :map, required: true)
  attr(:index, :integer, required: true)
  attr(:state, :string, required: true)

  defp stepper_item(assigns) do
    ~H"""
    <li class="stepper-item" data-state={@state} aria-current={@state == "current" && "step"}>
      <div class="stepper-marker-row">
        <span class="stepper-marker">
          <%= cond do %>
            <% @state == "complete" -> %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
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
                aria-hidden="true"
              >
                <path d="M12 8v4" />
                <path d="M12 16h.01" />
              </svg>
            <% @step[:icon] -> %>
              {@step.icon}
            <% true -> %>
              {@index}
          <% end %>
        </span>
        <span class="stepper-connector" aria-hidden="true"></span>
      </div>
      <div class="stepper-content">
        <span class="stepper-title">{@step.title}</span>
        <span :if={@step[:description]} class="stepper-description">{@step.description}</span>
      </div>
    </li>
    """
  end

  defp step_state(step, index, current) do
    step[:state] ||
      cond do
        index < current -> "complete"
        index == current -> "current"
        true -> "pending"
      end
  end
end
