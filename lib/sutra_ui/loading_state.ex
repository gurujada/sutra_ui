defmodule SutraUI.LoadingState do
  @moduledoc """
  A reusable loading state component for displaying loading indicators.

  Provides a centered loading state with spinner and optional message,
  commonly used in LiveViews while data is being fetched.

  ## Examples

      # Basic loading state
      <.loading_state />

      # Loading with custom message
      <.loading_state message="Loading batch data..." />

      # Loading without card wrapper (just spinner)
      <.loading_state wrap_card={false} />

      # With custom spinner size
      <.loading_state spinner_size="xl" message="Processing..." />

      # Inline loading (smaller, no card)
      <.loading_state wrap_card={false} spinner_size="sm" message="Saving..." />
  """

  use Phoenix.Component

  import SutraUI.Card
  import SutraUI.Spinner

  @doc """
  Renders a loading state with spinner and message.

  ## Attributes

  * `message` - Loading message text. Defaults to `"Loading..."`.
  * `wrap_card` - Whether to wrap in a card component. Defaults to `true`.
  * `spinner_size` - Size of the spinner: `sm`, `default`, `lg`, `xl`. Defaults to `"lg"`.
  * `class` - Additional CSS classes.
  """
  attr(:message, :string,
    default: "Loading...",
    doc: "Loading message text"
  )

  attr(:wrap_card, :boolean,
    default: true,
    doc: "Whether to wrap in a card"
  )

  attr(:spinner_size, :string,
    default: "lg",
    values: ~w(sm default lg xl),
    doc: "Size of the spinner"
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional CSS classes"
  )

  def loading_state(assigns) do
    ~H"""
    <%= if @wrap_card do %>
      <.card class={@class}>
        <:content>
          <div class="loading-state">
            <.spinner size={@spinner_size} />
            <span class="loading-state-message">{@message}</span>
          </div>
        </:content>
      </.card>
    <% else %>
      <div class={["loading-state", @class]}>
        <.spinner size={@spinner_size} />
        <span class="loading-state-message">{@message}</span>
      </div>
    <% end %>
    """
  end
end
