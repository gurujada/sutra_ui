defmodule SutraUI.Toast.Group do
  @moduledoc """
  The stack behind `SutraUI.Toast.toast_group/1` when it is `live`.

  A LiveComponent that holds the toasts: Phoenix flashes (it shows each new flash message
  once), toasts sent with `SutraUI.Toast.send/3`, and toasts asked for by the browser. The
  `ToastGroup` hook times and animates them and tells this component when one is dismissed
  (`dismiss`, which marks it closing) and when its exit animation ended (`remove`).
  """

  use Phoenix.LiveComponent

  alias SutraUI.Toast

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket, toasts: [], seen_flash: %{}, seen_queued: MapSet.new(), max: 3, render: nil)}
  end

  @impl true
  def update(%{op: op} = assigns, socket) do
    {:ok, socket |> assign(Map.delete(assigns, :op)) |> apply_op(op)}
  end

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> sync_flash()}
  end

  ## Operations (from Toast.send/3, update/3, dismiss/2)

  defp apply_op(socket, {:put, toast}), do: put(socket, toast)

  defp apply_op(socket, {:update, id, changes}) do
    change(socket, id, fn toast ->
      toast
      |> Map.merge(changes)
      |> Map.put(:closing, false)
      |> Map.update(:version, 1, &(&1 + 1))
      |> then(fn t ->
        if Map.has_key?(changes, :duration),
          do: t,
          else: Map.put(t, :duration, Toast.default_duration(t.kind, t[:action]))
      end)
    end)
  end

  defp apply_op(socket, {:dismiss, id}), do: change(socket, id, &Map.put(&1, :closing, true))

  defp put(socket, toast) do
    toasts =
      case Enum.find_index(socket.assigns.toasts, &(&1.id == toast.id)) do
        nil -> socket.assigns.toasts ++ [toast]
        i -> List.update_at(socket.assigns.toasts, i, &Map.put(toast, :version, &1.version + 1))
      end

    assign(socket, :toasts, toasts)
  end

  defp change(socket, id, fun) do
    assign(
      socket,
      :toasts,
      Enum.map(socket.assigns.toasts, &if(&1.id == id, do: fun.(&1), else: &1))
    )
  end

  ## Flash

  # Each flash message becomes a toast once; the message leaving the flash (cleared by the
  # hook on dismissal) makes the same message show again next time.
  defp sync_flash(socket) do
    # `:flash` is reserved in a LiveComponent, so the layout's flash arrives as `toast_flash`.
    flash = Map.get(socket.assigns, :toast_flash) || %{}
    {kinds, queued} = flash |> Toast.flash_toasts() |> Enum.split_with(&(&1.id =~ ~r/^flash-/))

    seen =
      Map.new(kinds, fn t -> {t.flash_key, t.body} end)

    socket =
      Enum.reduce(kinds, socket, fn toast, socket ->
        if socket.assigns.seen_flash[toast.flash_key] == toast.body,
          do: socket,
          else: put(socket, toast)
      end)

    queued_ids = MapSet.new(queued, & &1.id)

    socket =
      queued
      |> Enum.reject(&MapSet.member?(socket.assigns.seen_queued, &1.id))
      |> Enum.reduce(socket, &put(&2, &1))

    assign(socket, seen_flash: seen, seen_queued: queued_ids)
  end

  ## Events from the hook

  @impl true
  def handle_event("dismiss", %{"id" => id}, socket) do
    {:noreply, change(socket, id, &Map.put(&1, :closing, true))}
  end

  def handle_event("remove", %{"id" => id}, socket) do
    {:noreply, assign(socket, :toasts, Enum.reject(socket.assigns.toasts, &(&1.id == id)))}
  end

  # From the browser (`toast("success", "Copied")`) and the 0.4 push event.
  def handle_event("toast", params, socket) do
    kind = params["kind"] || legacy_kind(params["variant"])
    body = params["body"] || params["description"]
    title = params["title"]

    opts =
      [title: title, duration: duration(params["duration"]), id: params["id"]]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    kind =
      if kind in ["info", "success", "warning", "error"], do: kind, else: "info"

    {:noreply, put(socket, Toast.build(kind, body, opts))}
  end

  defp legacy_kind("success"), do: "success"
  defp legacy_kind("destructive"), do: "error"
  defp legacy_kind(_), do: "info"

  defp duration(ms) when is_integer(ms) and ms >= 0, do: ms
  defp duration(_), do: nil

  ## Render

  @impl true
  def render(assigns) do
    toasts = assigns.toasts
    folded = max(length(toasts) - assigns.max, 0)

    assigns =
      assign(assigns,
        indexed: Enum.with_index(toasts),
        fold_until: folded,
        folded_count: Enum.count(Enum.take(toasts, folded), &(not &1.closing)),
        more: String.replace(assigns.labels.more, "%{count}", to_string(folded))
      )

    ~H"""
    <div class="toast-stack" data-toast-stack>
      <p :if={@folded_count > 0} class="toast-more" data-toast-more>{@more}</p>
      <Toast.toast_item
        :for={{toast, index} <- @indexed}
        toast={toast}
        labels={@labels}
        render={@render}
        folded={index < @fold_until}
        myself={@myself}
      />
    </div>
    """
  end
end
