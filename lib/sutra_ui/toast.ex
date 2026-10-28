defmodule SutraUI.Toast do
  @moduledoc """
  Toasts and flashes in one stack.

  One `toast_group/1` in the layout shows Phoenix flashes *and* toasts sent from the server.
  Several can be visible at once; each has an id the server can use to update it in place
  ("Uploading…" becomes "Uploaded") or dismiss it.

      # layout (Layouts.app)
      <.toast_group flash={@flash} live />

  `live` renders the stack as a LiveComponent (`SutraUI.Toast.Group`), which is what lets the
  server send, update and dismiss toasts. Without it (a page with no LiveView, or a layout
  shared with controllers that does not know) the group shows the flash only, rendered on the
  server, and the same hook times and closes them. Merge the generated
  `phoenix-colocated/sutra_ui` hooks into your LiveSocket, as for `dialog`.

  ## Sending toasts

      alias SutraUI.Toast

      # From a LiveView, a LiveComponent or any process
      Toast.send(:success, "Saved")
      Toast.send(:error, "Could not save", title: "Save failed")
      id = Toast.send(:info, "Uploading…", id: "upload-1", duration: 0)
      Toast.update("upload-1", kind: :success, body: "Uploaded", duration: 4000)
      Toast.dismiss("upload-1")

      # From a process that is not the LiveView
      Toast.send(:info, "Export ready", to: liveview_pid)

      # With an action; a duration adds a countdown line (Undo)
      Toast.send(:info, "Message deleted",
        action: %{label: "Undo", event: "undo_delete", values: %{"id" => 7}},
        duration: 8000)

      # Survives a redirect, as a flash does (conn or socket)
      conn |> Toast.put_toast(:success, "Course published") |> redirect(to: ~p"/courses")

  `send/3` returns the toast id and works in the process that calls it: it uses
  `Phoenix.LiveView.send_update/3`, so the result is delivered after the current callback.
  The group is found by its id (`"toast-group"`, or the `:group` option).

  | Option | Meaning |
  |--------|---------|
  | `:id` | Stable id, to update or dismiss it. Sending again with the same id replaces it |
  | `:title` | A heading above the body (default: the kind's word) |
  | `:duration` | Milliseconds before it leaves; `0` stays until dismissed. See below |
  | `:action` | `%{label: ..., event: ..., values: %{}, target: nil}`: a button pushing `event` |
  | `:metadata` | Any term, passed untouched to a custom `render` function |
  | `:to` | The LiveView pid, when not sending from it |
  | `:group` | The id of the `toast_group` (default `"toast-group"`) |

  ## Kinds, timing, words

  | Kind | Role | Default duration |
  |------|------|------------------|
  | `:info` | `status` | 5 s |
  | `:success` | `status` | 5 s |
  | `:warning` | `alert` | 8 s |
  | `:error` | `alert` | stays until dismissed |

  A toast with an `:action` also stays, unless you give a `:duration`. The timer pauses while
  the toast is hovered or has focus and resumes with the time left. At most 3 are shown; older
  ones fold into "+2 more". Every toast shows its kind as a word and an icon, never colour
  alone. Reduced motion turns the slide off.

  ## From the browser

  A hook (or any script) can ask for a toast; the server renders it, so it looks like every
  other one:

      import {toast} from "sutra_ui/toast"
      toast("success", "Copied")

  ## Connection notice

  With `live`, the group also holds "Can't reach the server": it appears only after a delay
  (3 s), so a short blip shows nothing, and goes away by itself on reconnect.

  ## Placement

  `corner` is one of `top-left`, `top-center`, `top-right`, `bottom-left`, `bottom-center` and
  `bottom-right` (default). On phones the group is always full width at the bottom. An app
  keeps toasts clear of its own bars with CSS variables:

      :root { --toast-offset-bottom: 4.5rem; --toast-offset-top: 0px; }

  ## Custom content

  `render` replaces the inside of every toast (the icon, text and action) while SutraUI keeps
  the shell: timers, animation, stacking and the close button.

      <.toast_group flash={@flash} live render={&MyAppWeb.Toasts.render/1} />

      def render(assigns) do
        ~H\"\"\"
        <strong>{@toast.title}</strong> {@toast.body} <.link href={@toast.metadata.url}>Open</.link>
        \"\"\"
      end

  ## Words

  Built-in texts are attributes (`labels`) so an app can translate them:

      <.toast_group flash={@flash} live labels={%{close: "Cerrar", error: "Error"}} />

  ## Testing

  `SutraUI.Toast.Test.assert_toast/3` finds a toast by kind and text in a LiveView test.

  ## Accessibility

  - `role="status"` (polite) for info and success, `role="alert"` (assertive) for warnings and errors
  - The region is named "Notifications"; the close button is named "Close"
  - Focus is never moved; hovering or focusing a toast pauses its timer
  - The connection notice is a `role="alert"`

  ## Migrating from 0.4

  `toast_container/1` is now a thin wrapper of `toast_group/1` (without `live`) and goes away
  in 0.6. The `toast` push event still works (`variant` `default`/`success`/`destructive`,
  `description`), but `Toast.send/3` is the way. The `.toaster` CSS block and the
  `toast-success` and `toast-destructive` classes are gone: toasts are styled by
  `data-kind`.

  ## Related

  - `SutraUI.Flash` - A single inline flash message
  - `SutraUI.Confirm` - Confirm what cannot be undone; offer Undo in a toast for the rest
  - `SutraUI.Alert` - Persistent inline alerts
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS

  @kinds [:info, :success, :warning, :error]
  @corners ~w(top-left top-center top-right bottom-left bottom-center bottom-right)
  @default_group "toast-group"
  @flash_list :sutra_toasts

  @default_labels %{
    region: "Notifications",
    close: "Close",
    more: "+%{count} more",
    connection: "Can't reach the server. Trying to reconnect…",
    info: "Info",
    success: "Success",
    warning: "Warning",
    error: "Error"
  }

  @typedoc "A toast as the group holds it"
  @type t :: %{
          required(:id) => String.t(),
          required(:kind) => :info | :success | :warning | :error,
          optional(:title) => String.t() | nil,
          optional(:body) => String.t() | nil,
          optional(:duration) => non_neg_integer(),
          optional(:action) => map() | nil,
          optional(:metadata) => term(),
          optional(:closing) => boolean(),
          optional(:version) => non_neg_integer(),
          optional(:flash_key) => String.t() | nil
        }

  @doc false
  def kinds, do: @kinds

  @doc false
  def default_labels, do: @default_labels

  @doc false
  def default_group, do: @default_group

  @doc """
  The default duration in milliseconds for a kind: `5000` for info and success, `8000` for
  warnings, `0` (stays) for errors and for any toast with an action.
  """
  def default_duration(kind, action \\ nil)
  def default_duration(_kind, action) when is_map(action), do: 0
  def default_duration(:error, _), do: 0
  def default_duration(:warning, _), do: 8000
  def default_duration(kind, _) when kind in [:info, :success], do: 5000

  ## Server API

  @doc """
  Sends a toast to the page's `toast_group` and returns its id.

  See the module documentation for the options. Works from a LiveView, a LiveComponent or
  (with `to: pid`) any process.
  """
  def send(kind, body, opts \\ []) do
    toast = build(kind, body, opts)
    deliver(opts, {:put, toast})
    toast.id
  end

  @doc """
  Updates a toast in place. `changes` may hold `:kind`, `:title`, `:body`, `:duration`,
  `:action` and `:metadata`; a changed toast restarts its timer.
  """
  def update(id, changes, opts \\ []) when is_binary(id) do
    changes =
      changes
      |> Map.new()
      |> Map.take([:kind, :title, :body, :duration, :action, :metadata])
      |> then(fn c -> if k = c[:kind], do: Map.put(c, :kind, check_kind!(k)), else: c end)

    deliver(opts, {:update, id, changes})
    :ok
  end

  @doc "Dismisses a toast; its exit animation plays first."
  def dismiss(id, opts \\ []) when is_binary(id) do
    deliver(opts, {:dismiss, id})
    :ok
  end

  @doc """
  Queues a toast on a `Plug.Conn` or a LiveView socket so that it survives a redirect, as a
  flash does. The `toast_group` shows it on the next page.
  """
  def put_toast(conn_or_socket, kind, body, opts \\ [])

  def put_toast(%Plug.Conn{} = conn, kind, body, opts) do
    toast = kind |> build(body, opts) |> flashable()

    existing =
      conn.assigns |> Map.get(:flash, %{}) |> Phoenix.Flash.get(@flash_list) |> List.wrap()

    Phoenix.Controller.put_flash(conn, @flash_list, existing ++ [toast])
  end

  def put_toast(%Phoenix.LiveView.Socket{} = socket, kind, body, opts) do
    toast = kind |> build(body, opts) |> flashable()
    existing = socket.assigns.flash |> Phoenix.Flash.get(@flash_list) |> List.wrap()
    Phoenix.LiveView.put_flash(socket, @flash_list, existing ++ [toast])
  end

  # The flash is stored in the session, so keep it to plain data.
  defp flashable(toast), do: Map.put(toast, :origin, :flash)

  @doc false
  def build(kind, body, opts) do
    kind = check_kind!(kind)
    action = normalize_action(opts[:action])

    %{
      id: to_string(opts[:id] || "t#{System.unique_integer([:positive, :monotonic])}"),
      kind: kind,
      title: opts[:title],
      body: body && to_string(body),
      duration: opts[:duration] || default_duration(kind, action),
      action: action,
      metadata: opts[:metadata],
      closing: false,
      version: 0,
      origin: :server,
      flash_key: nil
    }
  end

  @doc false
  def check_kind!(kind) when kind in @kinds, do: kind

  def check_kind!(kind) when is_binary(kind) do
    case Enum.find(@kinds, &(Atom.to_string(&1) == kind)) do
      nil ->
        raise ArgumentError,
              "unknown toast kind #{inspect(kind)}, expected one of #{inspect(@kinds)}"

      atom ->
        atom
    end
  end

  def check_kind!(kind),
    do:
      raise(
        ArgumentError,
        "unknown toast kind #{inspect(kind)}, expected one of #{inspect(@kinds)}"
      )

  defp normalize_action(nil), do: nil

  defp normalize_action(%{label: label, event: event} = action) do
    %{
      label: to_string(label),
      event: to_string(event),
      values: Map.get(action, :values, %{}),
      target: Map.get(action, :target)
    }
  end

  defp normalize_action(other),
    do: raise(ArgumentError, "toast :action needs :label and :event, got: #{inspect(other)}")

  defp deliver(opts, op) do
    Phoenix.LiveView.send_update(
      opts[:to] || self(),
      SutraUI.Toast.Group,
      id: opts[:group] || @default_group,
      op: op
    )
  end

  @doc false
  # The toasts a flash map holds: the four kinds, and the ones queued by `put_toast/4`.
  def flash_toasts(flash) do
    kinds =
      for kind <- @kinds, message = Phoenix.Flash.get(flash, kind), is_binary(message) do
        key = Atom.to_string(kind)

        kind
        |> build(message, id: "flash-#{key}")
        |> Map.merge(%{origin: :flash, flash_key: key})
      end

    queued =
      flash
      |> Phoenix.Flash.get(@flash_list)
      |> List.wrap()
      |> Enum.map(&Map.merge(&1, %{flash_key: Atom.to_string(@flash_list)}))

    kinds ++ queued
  end

  @doc false
  def flash_list_key, do: @flash_list

  ## Components

  @doc """
  The stack of toasts. Put one in the layout.

      <.toast_group flash={@flash} live />
  """
  attr(:id, :string, default: @default_group)
  attr(:flash, :map, default: %{}, doc: "The flash map from the socket or conn assigns")

  attr(:live, :boolean,
    default: false,
    doc: "Render the stack as a LiveComponent so the server can send, update and dismiss toasts"
  )

  attr(:corner, :string, default: "bottom-right", values: @corners)

  attr(:max, :integer,
    default: 3,
    doc: "How many toasts are visible; older ones fold into \"+n more\""
  )

  attr(:labels, :map,
    default: %{},
    doc: "Overrides of the built-in words; see the module documentation"
  )

  attr(:render, :any,
    default: nil,
    doc:
      "A function component rendering the inside of a toast; it receives `@toast` and `@labels`"
  )

  attr(:class, :string, default: nil)

  def toast_group(assigns) do
    assigns =
      assigns
      |> assign(:labels, Map.merge(@default_labels, assigns.labels))
      |> assign(:static, if(assigns.live, do: [], else: flash_toasts(assigns.flash)))

    ~H"""
    <section
      id={@id}
      phx-hook=".ToastGroup"
      class={["toast-group", @class]}
      data-corner={@corner}
      data-live={to_string(@live)}
      aria-label={@labels.region}
    >
      <.live_component
        :if={@live}
        module={SutraUI.Toast.Group}
        id={@id}
        toast_flash={@flash}
        labels={@labels}
        render={@render}
        max={@max}
      />
      <div :if={!@live} class="toast-stack" data-toast-stack>
        <.toast_item :for={toast <- @static} toast={toast} labels={@labels} render={@render} />
      </div>
      <div
        :if={@live}
        id={"#{@id}-notice"}
        class="toast"
        data-kind="error"
        data-toast-notice
        data-delay="3000"
        role="alert"
        hidden
        phx-disconnected={JS.dispatch("sutra:connection-lost")}
        phx-connected={JS.dispatch("sutra:connection-back")}
      >
        <span class="toast-icon" aria-hidden="true"><.kind_icon kind={:error} /></span>
        <div class="toast-content">
          <p class="toast-title">
            <span class="sr-only">{@labels.error}: </span>{@labels.connection}
          </p>
        </div>
      </div>
    </section>

    <script :type={ColocatedHook} name=".ToastGroup">
      import {ToastGroup} from "sutra_ui/toast"
      export default ToastGroup
    </script>
    """
  end

  @doc """
  Renders one toast. `toast_group/1` renders these for you; use this for a toast of your own
  that is not managed by a group.

      <.toast id="saved" kind="success">
        <:title>Saved</:title>
        <:description>Your changes are live.</:description>
      </.toast>

  Without a group the close button hides the toast (`JS.hide`); inside one, the group's hook
  handles it.
  """
  attr(:id, :string, required: true)
  attr(:kind, :string, default: nil, values: [nil | Enum.map(@kinds, &Atom.to_string/1)])

  attr(:variant, :string,
    default: nil,
    values: [nil, "default", "success", "destructive"],
    doc: "Deprecated, use `kind`: default is info, destructive is error"
  )

  attr(:close_label, :string, default: "Close")
  attr(:class, :string, default: nil)
  attr(:rest, :global, doc: "Additional HTML attributes")

  slot(:icon, doc: "Replaces the kind's icon")
  slot(:title, doc: "The heading")
  slot(:description, doc: "Detail text")
  slot(:action, doc: "An action button")

  slot(:inner_block, doc: "Replaces the whole inside (icon, text and action); the shell stays")

  def toast(assigns) do
    kind = toast_kind(assigns)
    # An inner block next to named slots is only the whitespace between them.
    custom? =
      assigns.inner_block != [] and assigns.title == [] and assigns.description == [] and
        assigns.action == [] and assigns.icon == []

    assigns = assign(assigns, kind: kind, custom?: custom?)

    ~H"""
    <.shell
      id={@id}
      kind={@kind}
      class={@class}
      close_label={@close_label}
      managed={false}
      {@rest}
    >
      <%= if @custom? do %>
        {render_slot(@inner_block)}
      <% else %>
        <span class="toast-icon" aria-hidden="true">
          <%= if @icon != [] do %>
            {render_slot(@icon)}
          <% else %>
            <.kind_icon kind={@kind} />
          <% end %>
        </span>
        <div class="toast-content">
          <p :if={@title != []} class="toast-title">{render_slot(@title)}</p>
          <p :if={@description != []} class="toast-description">{render_slot(@description)}</p>
        </div>
        <div :if={@action != []} class="toast-action">{render_slot(@action)}</div>
      <% end %>
    </.shell>
    """
  end

  defp toast_kind(%{kind: kind}) when is_binary(kind), do: String.to_existing_atom(kind)
  defp toast_kind(%{variant: "success"}), do: :success
  defp toast_kind(%{variant: "destructive"}), do: :error
  defp toast_kind(_), do: :info

  @doc false
  # One toast from a map, as the group and the static stack render it.
  attr(:toast, :map, required: true)
  attr(:labels, :map, required: true)
  attr(:render, :any, default: nil)
  attr(:folded, :boolean, default: false)
  attr(:myself, :any, default: nil, doc: "The LiveComponent to tell about a used action")

  def toast_item(assigns) do
    toast = assigns.toast

    assigns =
      assign(assigns,
        title: toast[:title] || assigns.labels[toast.kind],
        has_title: toast[:title] not in [nil, ""],
        countdown: toast[:action] != nil and toast.duration > 0
      )

    ~H"""
    <.shell
      id={"toast-#{@toast.id}"}
      toast_id={@toast.id}
      kind={@toast.kind}
      state={if @toast[:closing], do: "closing", else: "open"}
      duration={@toast.duration}
      version={@toast[:version] || 0}
      flash_key={@toast[:flash_key]}
      folded={@folded}
      countdown={@countdown}
      close_label={@labels.close}
      managed
    >
      <%= if @render do %>
        {@render.(%{toast: @toast, labels: @labels, __changed__: nil})}
      <% else %>
        <span class="toast-icon" aria-hidden="true"><.kind_icon kind={@toast.kind} /></span>
        <div class="toast-content">
          <p class="toast-title">
            <span :if={@has_title} class="sr-only">{@labels[@toast.kind]}: </span>{@title}
          </p>
          <p :if={@toast[:body] not in [nil, ""]} class="toast-description">{@toast.body}</p>
        </div>
        <div :if={@toast[:action]} class="toast-action">
          <button
            type="button"
            class="toast-action-button"
            phx-click={action_click(@toast.action, @toast.id, @myself)}
          >
            {@toast.action.label}
          </button>
        </div>
      <% end %>
    </.shell>
    """
  end

  defp action_click(action, id, myself) do
    js = JS.push(%JS{}, action.event, value: action.values, target: action.target)

    if myself,
      do: JS.push(js, "dismiss", value: %{id: id}, target: myself),
      else: js
  end

  # The shell: element, role, data attributes, close button and countdown line.
  attr(:id, :string, required: true)
  attr(:toast_id, :string, default: nil)
  attr(:kind, :atom, required: true)
  attr(:state, :string, default: "open")
  attr(:duration, :integer, default: nil)
  attr(:version, :integer, default: nil)
  attr(:flash_key, :string, default: nil)
  attr(:folded, :boolean, default: false)
  attr(:countdown, :boolean, default: false)
  attr(:close_label, :string, default: "Close")
  attr(:managed, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  defp shell(assigns) do
    alert? = assigns.kind in [:warning, :error]

    assigns =
      assign(assigns,
        role: if(alert?, do: "alert", else: "status"),
        live: if(alert?, do: "assertive", else: "polite")
      )

    ~H"""
    <div
      id={@id}
      class={["toast", @class]}
      role={@role}
      aria-live={@live}
      aria-atomic="true"
      data-toast={@managed && "true"}
      data-toast-id={@toast_id}
      data-kind={@kind}
      data-state={@state}
      data-duration={@duration}
      data-version={@version}
      data-flash={@flash_key}
      data-folded={@folded && "true"}
      data-countdown={@countdown && "true"}
      {@rest}
    >
      {render_slot(@inner_block)}
      <button
        type="button"
        class="toast-close"
        aria-label={@close_label}
        data-toast-close
        phx-click={!@managed && JS.hide(to: "##{@id}")}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="M18 6 6 18" /><path d="m6 6 12 12" />
        </svg>
      </button>
      <span :if={@countdown} class="toast-countdown" aria-hidden="true"></span>
    </div>
    """
  end

  attr(:kind, :atom, required: true)

  defp kind_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <%= case @kind do %>
        <% :info -> %>
          <circle cx="12" cy="12" r="10" /><path d="M12 16v-4" /><path d="M12 8h.01" />
        <% :success -> %>
          <circle cx="12" cy="12" r="10" /><path d="m9 12 2 2 4-4" />
        <% :warning -> %>
          <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" />
        <% :error -> %>
          <circle cx="12" cy="12" r="10" /><path d="m15 9-6 6" /><path d="m9 9 6 6" />
      <% end %>
    </svg>
    """
  end

  @doc """
  Deprecated: use `toast_group/1`. Shows the flash only, rendered on the server.

  Removed in 0.6.
  """
  attr(:flash, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:nonce, :string, default: nil, doc: "Unused, the hook is no longer inline")

  @deprecated "use toast_group/1"
  def toast_container(assigns) do
    ~H"""
    <.toast_group flash={@flash} class={@class} />
    """
  end
end
