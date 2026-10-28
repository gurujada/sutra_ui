defmodule SutraUI.CommandsApp.Commands do
  @moduledoc false
  use SutraUI.Commands

  alias SutraUI.Commands.Action

  @workbooks [
    %{id: 1, title: "Physics 1"},
    %{id: 2, title: "Physics 2"},
    %{id: 3, title: "Chemistry"}
  ]

  @impl true
  def actions(_socket) do
    [
      Action.new(id: "home", title: "Go home", section: "Go to", shortcut: "g h", navigate: "/"),
      Action.new(
        id: "settings",
        title: "Settings",
        section: "Go to",
        keywords: ["preferences"],
        patch: "/?tab=settings"
      ),
      Action.new(
        id: "theme",
        title: "Change theme",
        section: "Settings",
        args: [%{name: :theme, label: "Theme", type: :choice, choices: ["light", "dark"]}],
        run: fn socket, %{theme: theme} ->
          {:ok, Phoenix.Component.assign(socket, :theme, theme)}
        end
      ),
      Action.new(
        id: "note",
        title: "Add a note",
        section: "Settings",
        args: [%{name: :note, label: "Note", type: :text, max_length: 10}],
        run: fn socket, %{note: note} -> Phoenix.Component.assign(socket, :note, note) end
      ),
      Action.new(
        id: "open",
        title: "Open a workbook",
        section: "Settings",
        args: [%{name: :workbook, label: "Which workbook?", type: :search, source: :workbooks}],
        run: fn socket, %{workbook: workbook} ->
          Phoenix.Component.assign(socket, :opened, workbook)
        end
      ),
      Action.new(
        id: "delete",
        title: "Delete everything",
        section: "Danger",
        tone: :danger,
        confirm: "Delete everything?",
        run: fn socket, _args -> Phoenix.Component.assign(socket, :deleted, true) end
      ),
      Action.new(
        id: "publish",
        title: "Publish",
        section: "Danger",
        disabled: "Add a title first",
        run: fn socket, _args -> socket end
      ),
      Action.new(
        id: "admin",
        title: "Admin only",
        section: "Danger",
        allow: fn socket -> socket.assigns[:admin] == true end,
        run: fn socket, _args -> Phoenix.Component.assign(socket, :did_admin, true) end
      ),
      Action.new(
        id: "fail",
        title: "Always fails",
        run: fn socket, _args -> {:error, "It did not work", socket} end
      ),
      Action.new(id: "ping", title: "Ping", event: "ping", payload: %{"from" => "palette"}),
      Action.new(
        id: "more",
        title: "More",
        children: [
          Action.new(id: "more.copy", title: "Copy link", copy: "https://example.test/x")
        ]
      )
    ]
  end

  @impl true
  def sources, do: [workbooks: "Workbooks"]

  @impl true
  def search(:workbooks, "boom", _socket), do: raise("search failed")

  def search(:workbooks, "slow" <> _ = query, _socket) do
    Process.sleep(200)
    [Action.new(id: "slow:#{query}", title: "Slow #{query}", navigate: "/")]
  end

  def search(:workbooks, query, _socket) do
    for %{id: id, title: title} <- @workbooks,
        query == "" or SutraUI.Commands.Match.score(query, title) != nil do
      Action.new(
        id: "workbook:#{id}",
        title: title,
        value: id,
        navigate: "/w/#{id}",
        children: [
          Action.new(id: "workbook:#{id}:open", title: "Open", navigate: "/w/#{id}"),
          Action.new(
            id: "workbook:#{id}:archive",
            title: "Archive",
            tone: :danger,
            run: fn socket, _ -> socket end
          )
        ]
      )
    end
  end
end

defmodule SutraUI.CommandsApp.Live do
  @moduledoc false
  use Phoenix.LiveView

  alias SutraUI.Commands.Action

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(admin: session["admin"] == true, theme: "light", pings: [])
      |> SutraUI.Commands.put_page_actions([
        Action.new(
          id: "page.rename",
          title: "Rename this page",
          section: "This page",
          event: "rename"
        )
      ])

    {:ok, socket}
  end

  def handle_params(%{"page" => "b"}, _uri, socket) do
    {:noreply,
     SutraUI.Commands.put_page_actions(socket, [
       Action.new(id: "page.b", title: "Page B action", section: "This page", event: "rename")
     ])}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("ping", params, socket),
    do: {:noreply, assign(socket, :pings, [params | socket.assigns.pings])}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <main>
      <SutraUI.Commands.Palette.command_palette id="palette" commands={@sutra_commands} />
      <p id="theme">{@theme}</p>
      <p id="pings">{inspect(@pings)}</p>
    </main>
    """
  end
end

defmodule SutraUI.CommandsApp.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)

    live_session :app, on_mount: [{SutraUI.Commands.Live, SutraUI.CommandsApp.Commands}] do
      live("/", SutraUI.CommandsApp.Live)
    end
  end
end

defmodule SutraUI.CommandsApp.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :sutra_ui

  @session_options [store: :cookie, key: "_commands_test", signing_salt: "commands-salt"]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Session, @session_options)
  plug(SutraUI.CommandsApp.Router)
end
