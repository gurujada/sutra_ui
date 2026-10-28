defmodule SutraUI.Commands.Action do
  @moduledoc """
  One thing a person can do from the command palette.

  Build one with `new/1`:

      Action.new(
        id: "workbook.new",
        title: "New workbook",
        section: "Create",
        keywords: ["add", "course"],
        icon: "icon-[lucide--plus]",
        shortcut: "g n",
        navigate: ~p"/workbooks/new"
      )

  ## Fields

  | Field | Meaning |
  |-------|---------|
  | `id` | Unique across everything the palette can show (required). Server actions are looked up again by it |
  | `title` | What the person reads and searches (required) |
  | `section` | Heading to group under |
  | `keywords` | Extra words that find it |
  | `icon` | CSS classes for a decorative icon (for example `icon-[lucide--plus]`) |
  | `shortcut` | `"mod+k"` (a chord) or `"g h"` (a sequence); never typed into text fields |
  | `badge` | Short text at the right (a count, "New") |
  | `tone` | `:danger` for a destructive action |
  | `disabled` | `true`, or the reason as a string, shown under the title |
  | `confirm` | `true` or a question; the palette asks before running, with a button and Cancel |
  | `confirm_label` | Text of the confirm button (default: the title) |
  | `children` | Actions of a next page, opened instead of running |
  | `args` | Values asked in turn before running (see below) |
  | `allow` | `fn socket -> boolean end`, checked again before a server action runs |
  | `value` | What a `:search` argument receives when this result is picked (default: `id`) |

  ## One kind

  An action does one of these when chosen (an action with `children` and no kind only opens
  its page):

  | Option | Does |
  |--------|------|
  | `navigate: path` | `live_redirect` to the path |
  | `patch: path` | `live_patch` to the path |
  | `href: url` | Browser navigation (`http`, `https` or `mailto` only) |
  | `event: name`, `payload: map` | Pushes the event to your LiveView (`handle_event/3`) |
  | `js: %Phoenix.LiveView.JS{}` | Runs the JS command |
  | `copy: text` | Copies the text |
  | `run: fun` | On the server: `fun.(socket, args)` returns the socket, `{:ok, socket}` or `{:error, message, socket}` |

  ## Arguments

  `args` are asked in turn, then passed to the `run` function (or merged into the `event`
  payload), keyed by `name`:

      args: [
        %{name: :workbook, label: "Which workbook?", type: :search, source: :workbooks},
        %{name: :role, label: "Role", type: :choice, choices: [{"learner", "Learner"}, {"teacher", "Teacher"}]},
        %{name: :note, label: "Note", type: :text, required: false, max_length: 200}
      ]

  The server checks every argument again: a choice must be one of `choices`, a search value
  must be a result of that source, and text must fit `max_length` (default 500).
  """

  @kinds [:navigate, :patch, :href, :event, :js, :copy, :run]
  @arg_types [:choice, :search, :text]

  defstruct id: nil,
            title: nil,
            section: nil,
            keywords: [],
            icon: nil,
            shortcut: nil,
            badge: nil,
            tone: nil,
            disabled: nil,
            confirm: nil,
            confirm_label: nil,
            children: [],
            args: [],
            allow: nil,
            value: nil,
            navigate: nil,
            patch: nil,
            href: nil,
            event: nil,
            payload: %{},
            js: nil,
            copy: nil,
            run: nil

  @type t :: %__MODULE__{}

  @doc "Builds an action from keyword options or a map; raises `ArgumentError` when it is malformed."
  @spec new(keyword() | map() | t()) :: t()
  def new(%__MODULE__{} = action), do: validate!(action)

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    known = Map.keys(%__MODULE__{}) -- [:__struct__]

    case Map.keys(attrs) -- known do
      [] -> :ok
      unknown -> raise ArgumentError, "unknown action options #{inspect(unknown)}"
    end

    __MODULE__
    |> struct(attrs)
    |> Map.update!(:children, &Enum.map(&1, fn child -> new(child) end))
    |> Map.update!(:args, &Enum.map(&1, fn arg -> normalize_arg!(arg) end))
    |> validate!()
  end

  defp validate!(%__MODULE__{id: id, title: title} = action) do
    unless is_binary(id) and id != "", do: raise(ArgumentError, "an action needs an id")

    unless is_binary(title) and title != "",
      do: raise(ArgumentError, "action #{id} needs a title")

    set = kinds(action)

    if length(set) > 1 do
      raise ArgumentError, "action #{id} has several kinds (#{inspect(set)}); give it one"
    end

    if set == [] and action.children == [] do
      raise ArgumentError, "action #{id} needs a kind (#{inspect(@kinds)}) or children"
    end

    if action.args != [] and (set == [] or hd(set) not in [:run, :event]) do
      raise ArgumentError, "action #{id}: args need `run` or `event`"
    end

    if action.tone not in [nil, :danger] do
      raise ArgumentError, "action #{id}: tone must be :danger"
    end

    action
  end

  defp kinds(action) do
    Enum.filter(@kinds, &(Map.get(action, &1) not in [nil, false]))
  end

  @doc "The kind of an action (`nil` for one that only opens its children)."
  @spec kind(t()) :: atom() | nil
  def kind(action), do: action |> kinds() |> List.first()

  defp normalize_arg!(arg) do
    arg = Map.new(arg)
    type = Map.get(arg, :type, :text)

    unless type in @arg_types,
      do: raise(ArgumentError, "argument type must be one of #{inspect(@arg_types)}")

    unless Map.has_key?(arg, :name), do: raise(ArgumentError, "an argument needs a name")

    if type == :search and not Map.has_key?(arg, :source) do
      raise ArgumentError, "a :search argument needs a source"
    end

    arg
    |> Map.put(:type, type)
    |> Map.put_new(:label, nil)
    |> Map.put_new(:required, true)
    |> Map.update(:choices, [], fn choices -> Enum.map(choices, &normalize_choice/1) end)
  end

  defp normalize_choice({value, label}), do: {to_string(value), label}
  defp normalize_choice(value) when is_binary(value), do: {value, value}
  defp normalize_choice(value) when is_atom(value), do: {to_string(value), to_string(value)}

  @doc "Whether a server action may run now: not disabled, and `allow` says yes."
  @spec allowed?(t(), term()) :: boolean()
  def allowed?(%__MODULE__{disabled: disabled}, _socket) when disabled not in [nil, false],
    do: false

  def allowed?(%__MODULE__{allow: nil}, _socket), do: true
  def allowed?(%__MODULE__{allow: allow}, socket), do: allow.(socket) == true

  @doc """
  The JSON-ready map the palette's browser module reads. Functions never leave the server.
  """
  @spec to_wire(t()) :: map()
  def to_wire(%__MODULE__{} = action) do
    {kind, target} = wire_kind(action)

    %{
      id: action.id,
      title: action.title,
      section: action.section,
      keywords: action.keywords,
      icon: action.icon,
      shortcut: action.shortcut,
      badge: action.badge && to_string(action.badge),
      tone: action.tone && to_string(action.tone),
      disabled: wire_disabled(action.disabled),
      confirm: wire_confirm(action.confirm),
      confirm_label: action.confirm_label,
      kind: kind,
      target: target,
      children: Enum.map(action.children, &to_wire/1),
      args: Enum.map(action.args, &wire_arg/1)
    }
  end

  defp wire_kind(%{run: run}) when not is_nil(run), do: {"server", nil}
  defp wire_kind(%{navigate: path}) when not is_nil(path), do: {"navigate", path}
  defp wire_kind(%{patch: path}) when not is_nil(path), do: {"patch", path}
  defp wire_kind(%{href: url}) when not is_nil(url), do: {"href", url}

  defp wire_kind(%{event: event, payload: payload}) when not is_nil(event),
    do: {"event", %{event: event, payload: payload}}

  defp wire_kind(%{js: js}) when not is_nil(js), do: {"js", Phoenix.json_library().encode!(js)}
  defp wire_kind(%{copy: text}) when not is_nil(text), do: {"copy", text}
  defp wire_kind(_), do: {nil, nil}

  defp wire_disabled(nil), do: nil
  defp wire_disabled(false), do: nil
  defp wire_disabled(true), do: true
  defp wire_disabled(reason), do: to_string(reason)

  defp wire_confirm(nil), do: nil
  defp wire_confirm(false), do: nil
  defp wire_confirm(true), do: true
  defp wire_confirm(question), do: to_string(question)

  defp wire_arg(arg) do
    %{
      name: to_string(arg.name),
      label: arg[:label],
      type: to_string(arg.type),
      source: arg[:source] && to_string(arg.source),
      placeholder: arg[:placeholder],
      required: arg.required,
      choices: Enum.map(arg.choices, fn {value, label} -> %{value: value, label: label} end)
    }
  end
end
