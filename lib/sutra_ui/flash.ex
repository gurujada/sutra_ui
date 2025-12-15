defmodule SutraUI.Flash do
  @moduledoc """
  Flash notification component for displaying temporary messages.

  Flash messages are used to provide feedback to users after actions,
  such as form submissions, errors, or successful operations.

  ## Examples

      # Basic flash messages
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} title="Error!" />

      # With custom content via inner_block
      <.flash kind={:info}>
        Custom message with <strong>formatting</strong>
      </.flash>

  ## Flash Kinds

  | Kind | Usage | Icon |
  |------|-------|------|
  | `:info` | Success messages, confirmations, general information | info icon |
  | `:error` | Error messages, validation failures, warnings | circle-alert icon |

  ## Setting Flash Messages

  In LiveView, use `put_flash/3`:

      def handle_event("save", params, socket) do
        case save_data(params) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Changes saved successfully")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to save changes")}
        end
      end

  In controllers, use `put_flash/3` from `Phoenix.Controller`:

      def create(conn, params) do
        case create_resource(params) do
          {:ok, resource} ->
            conn
            |> put_flash(:info, "Created successfully")
            |> redirect(to: ~p"/resources/\#{resource}")
          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to create")
            |> render(:new)
        end
      end

  ## Accessibility

  The flash component follows WAI-ARIA alert pattern guidelines:

  | Feature | Implementation |
  |---------|----------------|
  | Role | `role="alert"` announces content to screen readers immediately |
  | Close button | `type="button"` with `aria-label="close"` |
  | Icons | Decorative icons hidden from screen readers via `aria-hidden` |
  | Dismissal | Click anywhere on flash or close button to dismiss |

  ## JS Helpers

  The module exports `show/2` and `hide/2` functions for animated visibility:

      # Show with animation
      SutraUI.Flash.show("#my-element")

      # Hide with animation  
      SutraUI.Flash.hide("#my-element")

      # Chain with other JS commands
      JS.push("event") |> SutraUI.Flash.hide("#flash")

  ## Related

  - `SutraUI.Toast` - For non-blocking, auto-dismissing notifications
  - `SutraUI.Alert` - For persistent, inline alert messages
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Renders a flash message.

  Flash messages automatically hide when clicked or when the close button
  is pressed. They also clear the flash from the socket.

  ## Attributes

  | Attribute | Type | Default | Description |
  |-----------|------|---------|-------------|
  | `id` | `string` | `"flash-{kind}"` | Unique identifier for the flash element |
  | `flash` | `map` | `%{}` | The flash map from socket assigns |
  | `title` | `string` | `nil` | Optional title displayed above the message |
  | `kind` | `atom` | required | `:info` or `:error` - determines styling and icon |

  ## Slots

  | Slot | Description |
  |------|-------------|
  | `inner_block` | Optional custom content (overrides flash message lookup) |

  ## Examples

      # Basic usage - reads message from flash map
      <.flash kind={:info} flash={@flash} />

      # With title
      <.flash kind={:error} flash={@flash} title="Validation Error" />

      # With custom content (ignores flash map)
      <.flash kind={:info}>
        Your file <strong>report.pdf</strong> has been uploaded.
      </.flash>

      # Standalone error (no flash map needed when using inner_block)
      <.flash kind={:error} title="Connection Lost">
        Please check your internet connection.
      </.flash>
  """
  attr(:id, :string, default: nil, doc: "The id of the flash container")
  attr(:flash, :map, default: %{}, doc: "The flash map from the socket")
  attr(:title, :string, default: nil, doc: "Optional title for the flash")

  attr(:kind, :atom,
    values: [:info, :error],
    required: true,
    doc: "Used for styling and flash lookup"
  )

  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:inner_block, doc: "The optional inner block that renders the flash message")

  def flash(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || "flash-#{assigns.kind}")
      |> assign(:has_inner_block, assigns.inner_block != [])
      |> assign(:flash_message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H"""
    <div
      :if={@has_inner_block || @flash_message}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={["flash", flash_kind_class(@kind)]}
      {@rest}
    >
      <div class="flash-icon" aria-hidden="true">
        <svg
          :if={@kind == :info}
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-5"
        >
          <circle cx="12" cy="12" r="10" /><path d="M12 16v-4" /><path d="M12 8h.01" />
        </svg>
        <svg
          :if={@kind == :error}
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-5"
        >
          <circle cx="12" cy="12" r="10" /><line x1="12" x2="12" y1="8" y2="12" /><line
            x1="12"
            x2="12.01"
            y1="16"
            y2="16"
          />
        </svg>
      </div>
      <div class="flash-content">
        <p :if={@title} class="flash-title">{@title}</p>
        <p class="flash-description">
          <%= if @has_inner_block do %>
            {render_slot(@inner_block)}
          <% else %>
            {@flash_message}
          <% end %>
        </p>
      </div>
      <button type="button" class="flash-close" aria-label="close">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="size-5"
        >
          <path d="M18 6 6 18" /><path d="m6 6 12 12" />
        </svg>
      </button>
    </div>
    """
  end

  defp flash_kind_class(:info), do: "flash-info"
  defp flash_kind_class(:error), do: "flash-error"

  ## JS Commands

  @doc """
  Shows an element with a fade and scale animation.

  ## Parameters

  | Parameter | Type | Description |
  |-----------|------|-------------|
  | `js` | `Phoenix.LiveView.JS` | Optional JS struct to chain commands |
  | `selector` | `string` | CSS selector for the element to show |

  ## Examples

      # Basic usage
      show("#my-modal")

      # Chain with other commands
      JS.push("open") |> show("#modal")

  ## Animation

  - Duration: 300ms ease-out
  - From: `opacity-0 translate-y-4 scale-95`
  - To: `opacity-100 translate-y-0 scale-100`
  """
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @doc """
  Hides an element with a fade and scale animation.

  ## Parameters

  | Parameter | Type | Description |
  |-----------|------|-------------|
  | `js` | `Phoenix.LiveView.JS` | Optional JS struct to chain commands |
  | `selector` | `string` | CSS selector for the element to hide |

  ## Examples

      # Basic usage
      hide("#my-modal")

      # Chain with other commands
      JS.push("close") |> hide("#modal")

  ## Animation

  - Duration: 200ms ease-in
  - From: `opacity-100 translate-y-0 scale-100`
  - To: `opacity-0 translate-y-4 scale-95`
  """
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
