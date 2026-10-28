defmodule SutraUI.Commands.Live do
  @moduledoc """
  `on_mount` hook that gives every LiveView of a `live_session` the palette's actions and
  events.

      live_session :app, on_mount: [{SutraUI.Commands.Live, MyAppWeb.Commands}] do
        live "/", HomeLive
      end

  It assigns `:sutra_commands` (render it with `<.command_palette commands={@sutra_commands} />`)
  and handles the palette's events before your LiveView sees them:

    * `"sutra-ui:command-search"`: runs a source's `search/3` in its own process and pushes
      `"sutra-ui:command-results"` back; only the newest search of a source is answered
    * `"sutra-ui:command-run"`: runs a server action after looking it up again, checking
      `allow` and validating its arguments; replies `%{ok: true}` or `%{error: message}`
    * `"sutra-ui:command-ran"`: telemetry for actions the browser ran itself
  """

  require Logger

  import Phoenix.LiveView, only: [attach_hook: 4, push_event: 3]
  import Phoenix.Component, only: [assign: 3]

  alias SutraUI.Commands
  alias SutraUI.Commands.Action

  @max_query 200
  @max_text 500

  @doc false
  def on_mount(module, _params, _session, socket) when is_atom(module) do
    sources = Commands.normalize_sources(module.sources())

    socket =
      socket
      |> assign(:sutra_commands_runtime, %{
        module: module,
        results: %{},
        searches: %{},
        patched?: false
      })
      |> assign(:sutra_commands, %{actions: [], page_actions: [], sources: sources})
      |> Commands.refresh()
      |> attach_hook(:sutra_commands_events, :handle_event, &handle_event/3)
      |> attach_hook(:sutra_commands_info, :handle_info, &handle_info/2)
      |> attach_hook(:sutra_commands_params, :handle_params, &handle_params/3)

    {:cont, socket}
  end

  # The first `handle_params` follows `mount`, which may have set page actions; every later one
  # is a patch, and a patched page sets its own again.
  defp handle_params(_params, _uri, socket) do
    runtime = socket.assigns.sutra_commands_runtime

    if runtime.patched? do
      socket =
        assign(socket, :sutra_commands, %{socket.assigns.sutra_commands | page_actions: []})

      {:cont, Commands.refresh(socket)}
    else
      {:cont, assign(socket, :sutra_commands_runtime, %{runtime | patched?: true})}
    end
  end

  defp handle_event("sutra-ui:command-search", params, socket) do
    {:halt, %{}, search(params, socket)}
  end

  defp handle_event("sutra-ui:command-run", params, socket) do
    {reply, socket} = run(params, socket)
    {:halt, reply, socket}
  end

  defp handle_event("sutra-ui:command-ran", %{"id" => id}, socket) when is_binary(id) do
    :telemetry.execute([:sutra_ui, :commands, :run], %{count: 1}, %{
      id: id,
      kind: :client,
      ok: true
    })

    {:halt, %{}, socket}
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}

  defp handle_info({:sutra_commands_results, source, ref, meta, outcome}, socket) do
    runtime = socket.assigns.sutra_commands_runtime

    case runtime.searches[source] do
      {^ref, _pid} ->
        {payload, results} =
          case outcome do
            {:ok, actions} ->
              {%{
                 source: to_string(source),
                 ref: ref,
                 items: Enum.map(actions, &Action.to_wire/1)
               }, Map.put(runtime.results, source, actions)}

            :error ->
              {%{source: to_string(source), ref: ref, items: [], error: "Search failed"},
               Map.put(runtime.results, source, [])}
          end

        count = length(payload.items)
        duration = System.monotonic_time() - meta.started

        :telemetry.execute(
          [:sutra_ui, :commands, :search],
          %{duration: duration, count: count},
          %{
            source: source,
            query_length: meta.query_length,
            ok: outcome != :error
          }
        )

        runtime = %{runtime | results: results, searches: Map.delete(runtime.searches, source)}

        socket =
          socket
          |> assign(:sutra_commands_runtime, runtime)
          |> push_event("sutra-ui:command-results", payload)

        {:halt, socket}

      _older ->
        {:halt, socket}
    end
  end

  defp handle_info(_message, socket), do: {:cont, socket}

  # ---- search ----------------------------------------------------------------------------

  defp search(%{"source" => name, "query" => query, "ref" => ref}, socket)
       when is_binary(name) and is_binary(query) and is_integer(ref) do
    runtime = socket.assigns.sutra_commands_runtime

    source =
      Enum.find_value(socket.assigns.sutra_commands.sources, fn {id, _} ->
        to_string(id) == name && id
      end)

    if source && function_exported?(runtime.module, :search, 3) do
      with {_ref, pid} <- runtime.searches[source], do: Process.exit(pid, :kill)

      parent = self()
      query = String.slice(query, 0, @max_query)
      meta = %{started: System.monotonic_time(), query_length: String.length(query)}
      module = runtime.module

      {:ok, pid} =
        Task.start(fn ->
          outcome =
            try do
              {:ok, module |> apply(:search, [source, query, socket]) |> Enum.map(&Action.new/1)}
            rescue
              error ->
                Logger.error(Exception.format(:error, error, __STACKTRACE__))
                :error
            end

          send(parent, {:sutra_commands_results, source, ref, meta, outcome})
        end)

      runtime = %{runtime | searches: Map.put(runtime.searches, source, {ref, pid})}
      assign(socket, :sutra_commands_runtime, runtime)
    else
      socket
    end
  end

  defp search(_params, socket), do: socket

  # ---- running a server action -----------------------------------------------------------

  defp run(%{"id" => id} = params, socket) when is_binary(id) do
    runtime = socket.assigns.sutra_commands_runtime

    known =
      Commands.flatten(
        Commands.visible(socket.assigns.sutra_commands) ++
          Enum.concat(Map.values(runtime.results))
      )

    given = if is_map(params["args"]), do: params["args"], else: %{}

    with %Action{run: run} = action when is_function(run, 2) <- Enum.find(known, &(&1.id == id)),
         :ok <- check_allowed(action, socket),
         {:ok, args} <- validate_args(action, given, runtime) do
      outcome = run.(socket, args)
      {reply, socket} = finish(outcome, socket)

      :telemetry.execute([:sutra_ui, :commands, :run], %{count: 1}, %{
        id: id,
        kind: :server,
        ok: reply == %{ok: true}
      })

      {reply, socket}
    else
      {:error, message} ->
        {%{error: message}, socket}

      _missing ->
        {%{error: "That is no longer available"}, socket}
    end
  end

  defp run(_params, socket), do: {%{error: "That is no longer available"}, socket}

  defp finish(%Phoenix.LiveView.Socket{} = socket, _), do: {%{ok: true}, socket}
  defp finish({:ok, %Phoenix.LiveView.Socket{} = socket}, _), do: {%{ok: true}, socket}

  defp finish({:error, message, %Phoenix.LiveView.Socket{} = socket}, _),
    do: {%{error: to_string(message)}, socket}

  defp check_allowed(%Action{disabled: disabled} = action, socket) do
    cond do
      disabled not in [nil, false] ->
        {:error, if(is_binary(disabled), do: disabled, else: "Not available")}

      not Action.allowed?(action, socket) ->
        {:error, "You are not allowed to do that"}

      true ->
        :ok
    end
  end

  defp validate_args(%Action{args: specs}, given, runtime) do
    Enum.reduce_while(specs, {:ok, %{}}, fn spec, {:ok, acc} ->
      case validate_arg(spec, Map.get(given, to_string(spec.name)), runtime) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, spec.name, value)}}
        {:error, message} -> {:halt, {:error, message}}
      end
    end)
  end

  defp validate_arg(%{type: :choice} = spec, value, _runtime) do
    if is_binary(value) and List.keymember?(spec.choices, value, 0),
      do: {:ok, value},
      else: {:error, "Pick one of the choices"}
  end

  defp validate_arg(%{type: :search} = spec, value, runtime) do
    found =
      Enum.find(Map.get(runtime.results, spec.source, []), &(is_binary(value) and &1.id == value))

    case found do
      nil -> {:error, "Pick one of the results"}
      %Action{value: nil, id: id} -> {:ok, id}
      %Action{value: picked} -> {:ok, picked}
    end
  end

  defp validate_arg(%{type: :text} = spec, value, _runtime) do
    max = Map.get(spec, :max_length, @max_text)
    text = if is_binary(value), do: String.trim(value), else: ""

    cond do
      text == "" and spec.required -> {:error, "Type a value first"}
      String.length(text) > max -> {:error, "Use at most #{max} characters"}
      true -> {:ok, text}
    end
  end
end
