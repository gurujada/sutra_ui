defmodule SutraUI.TabsLive.Live do
  @moduledoc false
  # Tabs as routes of one LiveView: `mount` runs once, `handle_params` on every switch.
  use Phoenix.LiveView
  import SutraUI.Tabs

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, mounts: 1, params_calls: 0, visited: [], draft: "", tab: nil, keep: false)}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || "overview"
    keep? = params["keep"] == "1"

    {:noreply,
     assign(socket,
       tab: tab,
       keep: keep?,
       params_calls: socket.assigns.params_calls + 1,
       visited: SutraUI.Tabs.visit(socket.assigns.visited, tab)
     )}
  end

  def handle_event("draft", %{"draft" => draft}, socket),
    do: {:noreply, assign(socket, draft: draft)}

  def render(assigns) do
    ~H"""
    <p id="counters">mounts={@mounts} params={@params_calls}</p>
    <p id="pid">{inspect(self())}</p>
    <.tabs id="t" value={@tab} label="Sections" keep={if @keep, do: @visited, else: false}>
      <:tab value="overview" patch={"/tabs/overview" <> if(@keep, do: "?keep=1", else: "")}>
        Overview
      </:tab>
      <:tab value="notes" patch={"/tabs/notes" <> if(@keep, do: "?keep=1", else: "")}>Notes</:tab>
      <:panel value="overview">
        <p>Overview content</p>
      </:panel>
      <:panel value="notes">
        <form id="draft-form" phx-change="draft">
          <input type="text" name="draft" value={@draft} />
        </form>
      </:panel>
    </.tabs>
    """
  end
end

defmodule SutraUI.TabsLive.NavLive do
  @moduledoc false
  use Phoenix.LiveView
  import SutraUI.Tabs

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <.tabs id="n" value={@live_action |> to_string()} label="Account">
      <:tab value="profile" navigate="/account/profile">Profile</:tab>
      <:tab value="billing" navigate="/account/billing">Billing</:tab>
    </.tabs>
    <p id="page">{@live_action}</p>
    """
  end
end

defmodule SutraUI.TabsLive.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)

    live_session :tabs do
      live("/tabs", SutraUI.TabsLive.Live, :index)
      live("/tabs/:tab", SutraUI.TabsLive.Live, :show)
      live("/account/profile", SutraUI.TabsLive.NavLive, :profile)
      live("/account/billing", SutraUI.TabsLive.NavLive, :billing)
    end
  end
end

defmodule SutraUI.TabsLive.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :sutra_ui

  @session [store: :cookie, key: "_tabs_test", signing_salt: "tabssalt"]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session]])

  plug(Plug.Session, @session)
  plug(SutraUI.TabsLive.Router)
end
