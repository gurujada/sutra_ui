defmodule SutraUI.Commands do
  @moduledoc """
  The command palette's server side: what a person may do, read per socket, and the searches
  they can run from the palette.

  The browser half is `SutraUI.Commands.Palette` (`<.command_palette>`), built on the
  div-based `SutraUI.Dialog` and the look of `SutraUI.Command`. This module is the behaviour
  you implement once per app.

      defmodule MyAppWeb.Commands do
        use SutraUI.Commands
        alias SutraUI.Commands.Action

        @impl true
        def actions(socket) do
          [
            Action.new(id: "home", title: "Go home", section: "Go to", shortcut: "g h", navigate: "/"),
            Action.new(
              id: "theme",
              title: "Change theme",
              section: "Settings",
              args: [%{name: :theme, label: "Theme", type: :choice, choices: ["light", "dark"]}],
              run: fn socket, %{theme: theme} -> {:ok, MyApp.set_theme(socket, theme)} end
            )
          ]
        end

        @impl true
        def sources, do: [workbooks: "Workbooks"]

        @impl true
        def search(:workbooks, query, socket) do
          for w <- MyApp.search_workbooks(socket.assigns.current_scope, query) do
            Action.new(
              id: "workbook:\#{w.id}",
              title: w.title,
              navigate: ~p"/w/\#{w.slug}",
              children: [
                Action.new(id: "workbook:\#{w.id}:open", title: "Open", navigate: ~p"/w/\#{w.slug}"),
                Action.new(id: "workbook:\#{w.id}:copy", title: "Copy link", copy: url(w))
              ]
            )
          end
        end
      end

      # router: every LiveView in the session has the palette's events and actions
      live_session :app, on_mount: [{SutraUI.Commands.Live, MyAppWeb.Commands}] do
        ...
      end

      # layout
      <.command_palette id="command-palette" commands={@sutra_commands} />
      <.button phx-click={SutraUI.Commands.Palette.show_palette("command-palette")}>Search</.button>

      # one page's own actions; they leave with the page
      socket = SutraUI.Commands.put_page_actions(socket, [Action.new(...)])

  ## Callbacks

    * `actions/1` is called when the LiveView mounts, on every `handle_params`, and by
      `refresh/1`. Return only what this person may do now.
    * `sources/0` names the server searches: atoms, or `{atom, "Heading"}` pairs.
    * `search/3` runs in its own process per search; only the newest search of a source
      is answered. Return actions (each may carry `children`, its own actions).

  ## Server actions

  A `run:` action is looked up again by its id when the browser asks to run it, `allow` is
  checked again, and its arguments are validated before the function runs. Nothing the
  browser sends is trusted but the id and the argument values.

  ## Telemetry

    * `[:sutra_ui, :commands, :search]` with `%{duration: native_time, count: results}`
      and metadata `%{source: atom, query_length: integer, ok: boolean}`
    * `[:sutra_ui, :commands, :run]` with `%{count: 1}` and metadata
      `%{id: String.t(), kind: :server | :client, ok: boolean}`

  Test with `SutraUI.Commands.Test`.
  """

  alias SutraUI.Commands.Action

  @type source :: atom() | {atom(), String.t()}

  @callback actions(socket :: Phoenix.LiveView.Socket.t()) :: [Action.t()]
  @callback sources() :: [source()]
  @callback search(source :: atom(), query :: String.t(), socket :: Phoenix.LiveView.Socket.t()) ::
              [Action.t()]
  @optional_callbacks search: 3

  defmacro __using__(_opts) do
    quote do
      @behaviour SutraUI.Commands

      @impl SutraUI.Commands
      def sources, do: []

      defoverridable sources: 0
    end
  end

  @doc """
  Sets the actions of the current page: they come first in the palette and live as long as
  the LiveView (a patch keeps them; navigating to another LiveView leaves them behind).
  Calling it again replaces them, so a page with per-tab actions calls it in `handle_params/3`.
  """
  @spec put_page_actions(Phoenix.LiveView.Socket.t(), [Action.t() | keyword() | map()]) ::
          Phoenix.LiveView.Socket.t()
  def put_page_actions(socket, actions) do
    commands = fetch!(socket)
    page = Enum.map(actions, &Action.new/1)
    Phoenix.Component.assign(socket, :sutra_commands, %{commands | page_actions: page})
  end

  @doc "Reads `actions/1` again (after your assigns changed what this person may do)."
  @spec refresh(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def refresh(socket) do
    commands = fetch!(socket)
    runtime = socket.assigns.sutra_commands_runtime
    actions = Enum.map(runtime.module.actions(socket), &Action.new/1)
    Phoenix.Component.assign(socket, :sutra_commands, %{commands | actions: actions})
  end

  @doc "The actions the palette lists now: the page's first, then the app's, an id only once."
  @spec visible(map()) :: [Action.t()]
  def visible(%{actions: actions, page_actions: page_actions}) do
    Enum.uniq_by(page_actions ++ actions, & &1.id)
  end

  @doc false
  def normalize_sources(sources) do
    Enum.map(sources, fn
      {id, title} when is_atom(id) ->
        {id, title}

      id when is_atom(id) ->
        {id, id |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()}
    end)
  end

  @doc false
  def flatten(actions) do
    Enum.flat_map(actions, fn action -> [action | flatten(action.children)] end)
  end

  defp fetch!(socket) do
    case socket.assigns do
      %{sutra_commands: commands} ->
        commands

      _ ->
        raise ArgumentError,
              "the command palette is not set up on this LiveView: add " <>
                "`on_mount: [{SutraUI.Commands.Live, MyAppWeb.Commands}]` to its live_session"
    end
  end
end
