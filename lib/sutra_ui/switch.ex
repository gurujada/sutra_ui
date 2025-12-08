defmodule SutraUI.Switch do
  @moduledoc """
  A toggle control that allows the user to switch between checked and not checked.

  ## Examples

      # Basic switch
      <.switch name="airplane_mode" />

      # Switch with initial checked state
      <.switch name="notifications" checked />

      # Disabled switch
      <.switch name="marketing_emails" disabled />

      # Switch with phx-click for LiveView interactivity
      <.switch name="dark_mode" phx-click="toggle_dark_mode" checked={@dark_mode} />

      # Switch with phx-change inside a form
      <.switch name="auto_save" phx-change="toggle_auto_save" checked={@auto_save} />

      # Switch with accessibility attributes
      <.switch
        name="email_notifications"
        id="email-notifications"
        aria-label="Enable email notifications"
        aria-describedby="email-help"
      />

  ## Accessibility

  - Uses `<input type="checkbox">` with `role="switch"`
  - Supports `aria-label` or `aria-labelledby` for labeling
  - Supports `aria-describedby` for helper text
  - Keyboard accessible (Space to toggle, Enter to submit forms)
  - Communicates checked state via `aria-checked`
  """

  use Phoenix.Component

  @doc """
  Renders a switch component.

  ## Examples

      <.switch name="airplane_mode" />
      <.switch name="notifications" checked />
      <.switch name="marketing_emails" disabled />
  """

  attr(:id, :string, default: nil, doc: "The id of the switch input")
  attr(:name, :string, required: true, doc: "The name of the switch input")
  attr(:value, :string, default: "true", doc: "The value to submit when checked")
  attr(:checked, :boolean, default: false, doc: "Whether the switch is checked")
  attr(:disabled, :boolean, default: false, doc: "Whether the switch is disabled")
  attr(:class, :string, default: nil, doc: "Additional CSS classes")

  attr(:rest, :global,
    include:
      ~w(form required aria-label aria-labelledby aria-describedby aria-required phx-click phx-change),
    doc: "Additional HTML attributes including ARIA"
  )

  def switch(assigns) do
    ~H"""
    <input
      type="checkbox"
      role="switch"
      id={@id}
      name={@name}
      value={@value}
      checked={@checked}
      disabled={@disabled}
      aria-checked={to_string(@checked)}
      class={["switch", @class]}
      {@rest}
    />
    """
  end
end
