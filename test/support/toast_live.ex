defmodule SutraUI.ToastLive.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_live_flash)
  end

  scope "/" do
    pipe_through(:browser)
    live("/toast", SutraUI.ToastLive.Page)
  end
end

defmodule SutraUI.ToastLive.ErrorHTML do
  @moduledoc false
  # Shows the real error instead of a missing error template.
  def render(_template, %{reason: reason, stack: stack}) do
    raise "page crashed: " <> Exception.format(:error, reason, stack)
  end
end

defmodule SutraUI.ToastLive.Endpoint do
  use Phoenix.Endpoint, otp_app: :sutra_ui

  @session [store: :cookie, key: "_toast_test", signing_salt: "toastsalt"]

  socket("/live", Phoenix.LiveView.Socket)
  plug(Plug.Session, @session)
  plug(SutraUI.ToastLive.Router)
end

defmodule SutraUI.ToastLive.Sender do
  @moduledoc false
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <button id="from-component" phx-click="go" phx-target={@myself}>send</button>
    """
  end

  def handle_event("go", _params, socket) do
    SutraUI.Toast.send(:success, "Sent by a component", id: "from-component-toast")
    {:noreply, socket}
  end
end

defmodule SutraUI.ToastLive.Page do
  @moduledoc false
  use Phoenix.LiveView
  use SutraUI

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <.toast_group flash={@flash} live />
    <.live_component module={SutraUI.ToastLive.Sender} id="sender" />
    <.confirm_host />
    <.confirm_dialog
      id="retire"
      title="Retire this course?"
      consequence="Nobody can start it again."
      confirm="Retire"
      event="retire"
      values={%{"id" => "7"}}
    />
    <button id="plain" data-confirm="Sure?" phx-click="plain">plain</button>
    """
  end

  def handle_event("send", %{"kind" => kind, "body" => body} = params, socket) do
    opts =
      [
        id: params["id"],
        title: params["title"],
        duration: params["duration"],
        action: params["action"] && %{label: "Undo", event: "undo", values: %{"n" => 1}}
      ]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    SutraUI.Toast.send(String.to_existing_atom(kind), body, opts)
    {:noreply, socket}
  end

  def handle_event("update", %{"id" => id} = params, socket) do
    SutraUI.Toast.update(
      id,
      Enum.map(Map.take(params, ["kind", "body"]), fn
        {"kind", k} -> {:kind, String.to_existing_atom(k)}
        {"body", b} -> {:body, b}
      end)
    )

    {:noreply, socket}
  end

  def handle_event("dismiss", %{"id" => id}, socket) do
    SutraUI.Toast.dismiss(id)
    {:noreply, socket}
  end

  def handle_event("flash", %{"kind" => kind, "body" => body}, socket) do
    {:noreply, put_flash(socket, String.to_existing_atom(kind), body)}
  end

  def handle_event("put_toast", %{"kind" => kind, "body" => body}, socket) do
    {:noreply, SutraUI.Toast.put_toast(socket, String.to_existing_atom(kind), body)}
  end

  def handle_event("retire", params, socket) do
    {:noreply, put_flash(socket, :info, "Retired #{params["id"]}")}
  end

  def handle_event("plain", _params, socket) do
    {:noreply, put_flash(socket, :info, "Plain done")}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def handle_info(_msg, socket), do: {:noreply, socket}
end
