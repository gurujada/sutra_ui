defmodule SutraUI.DatePicker do
  @moduledoc """
  Date, range, time and datetime pickers: a segmented field you type into, and a calendar.

  | Component | Posts |
  |---|---|
  | `date_picker/1` | `2027-03-15` |
  | `date_range_picker/1` | `name[start]` and `name[end]` (the key names are configurable) |
  | `time_picker/1` | `09:00`, on an optional minute step |
  | `datetime_picker/1` | `2027-03-15T09:00:00+05:30`, the wall time in its `zone` with that moment's offset |

      <.date_picker field={@form[:due]} label="Due" rules={@rules} zone="Asia/Kolkata" />
      <.date_range_picker field={@form[:period]} label="Period" />
      <.time_picker field={@form[:opens]} label="Opens" step={15} />
      <.datetime_picker field={@form[:starts_at]} label="Starts" zone="Asia/Kolkata" />

  ## How it works

  The server renders the browser's own `<input type="date">` (and `time`, `datetime-local`)
  inside the wrapper, so forms post and tests read the value with no JavaScript. The extracted
  `.DatePicker` hook (it imports `sutra_ui/dates`) hides that input and draws:

    * a **segmented field** in the locale's order ("15 / 03 / 2027" or "03 / 15 / 2027"):
      digits fill a segment and move on, the arrow keys step it, `Backspace` clears it,
      paste reads a whole value, and phones get the number keyboard
    * a **calendar** in a div-based popover (so it shows in a screen share): arrow keys, `Home`,
      `End`, `PageUp`/`PageDown` (with `Shift` for years), months and years to jump to, and
      `Escape`; below 640 px it opens as a bottom sheet
    * **presets** as buttons (below)
    * for a range, its **length as you draw it** ("7 days")

  The posted input gets its own `input` and `change` events, so `phx-change` and
  `used_input?` work as with any input. Merge the generated `phoenix-colocated/sutra_ui` hooks
  into your LiveSocket, as for `SutraUI.Dialog`.

  ## Rules

  A `%SutraUI.DateRules{}` (`rules` attribute) sets the earliest and latest day (absolute or
  relative to today), disabled days and weekdays, the shortest and longest range and the minute
  step. The calendar greys out what the rules refuse, a typed value they refuse is marked, and
  `SutraUI.DateRules.validate/4` refuses the same on the server.

  ## Presets

  `presets` is a list of keys, or `{key, label}` pairs, or maps with a `value` of your own:

      presets={[:today, :tomorrow, :next_monday]}
      presets={[:last_7_days, {:last_quarter, "Last quarter"}]}      # label only: the key must be known
      presets={[%{key: "term_start", label: "Start of term", value: ~D[2026-11-02]}]}

  Known keys: `:today`, `:tomorrow`, `:next_monday`, `:end_of_week`, `:end_of_month` for a day;
  `:last_7_days`, `:last_30_days`, `:this_week`, `:this_month`, `:last_month` for a range
  (a range picker also takes a day preset as a one-day range). Dates and ranges come from the
  browser's today in the picker's zone. Defaults: a day picker `today`, `tomorrow`,
  `next_monday`, `end_of_week`; a range picker `last_7_days`, `last_30_days`, `this_month`;
  `presets={[]}` for none.

  In a filter, a preset can post its **key** so a shared link stays relative: `preset_key`
  adds a `name[preset]` input holding `last_7_days` (cleared when the dates are typed or
  picked by hand). The dates are posted too; the filter reads the key first.

  ## Zones

  Pickers show and post in the place's zone (`zone`, required on `datetime_picker/1`). A
  datetime is read as wall-clock time there and posted with that moment's offset. A clock
  change is **shown, never guessed**: a time that does not exist (clocks jump forward) or
  happens twice (clocks go back) posts nothing and says so, and for a repeated hour the
  person picks the first or second. When the browser's zone shows a different wall time, the
  viewer's time is added as a hint ("Sun 23:30 your time"), as for `SutraUI.Time.local_time/1`.
  A non-UTC zone needs a time zone database (see `SutraUI.Time`).

  Read what a datetime picker posts with `SutraUI.Time.parse_datetime/3`.

  ## Without JavaScript

  The browser's controls stay in place and post `2027-03-15`, `09:00` and, for a datetime,
  the wall time `2027-03-15T09:00` (which `parse_datetime/3` reads in the zone).

  ## Related

  `SutraUI.Calendar` is a server-driven month grid for your own pages (events on click);
  the pickers do not use it. It accepts the same `rules`.
  """

  use Phoenix.Component

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.ColocatedHook
  alias SutraUI.DateRules
  alias SutraUI.Time, as: SutraTime

  @day_presets ~w(today tomorrow next_monday end_of_week)a
  @range_presets ~w(last_7_days last_30_days this_month)a
  @labels %{
    today: "Today",
    tomorrow: "Tomorrow",
    next_monday: "Next Monday",
    end_of_week: "End of week",
    end_of_month: "End of month",
    last_7_days: "Last 7 days",
    last_30_days: "Last 30 days",
    this_week: "This week",
    this_month: "This month",
    last_month: "Last month"
  }

  # ── date ─────────────────────────────────────────────────────────────────

  @doc """
  A date: posts `2027-03-15` (an empty string when cleared).
  """
  attr(:id, :string, default: nil, doc: "The input's id (taken from `field`)")
  attr(:name, :string, default: nil, doc: "Form input name (taken from `field`)")
  attr(:value, :any, default: nil, doc: "A `Date` or an ISO 8601 string")
  attr(:field, FormField, default: nil, doc: "A form field, for example `@form[:due]`")
  attr(:label, :string, default: nil, doc: "Accessible name, and the title of the phone sheet")
  attr(:rules, :any, default: nil, doc: "A `%SutraUI.DateRules{}` (or keyword list)")

  attr(:presets, :any,
    default: :default,
    doc: "Preset keys, `{key, label}` or maps; `[]` for none"
  )

  attr(:zone, :string, default: "Etc/UTC", doc: "The place's zone: decides what today is")
  attr(:week_start, :integer, default: 1, doc: "First weekday, 1 Monday to 7 Sunday")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Extra classes on the wrapper")
  attr(:rest, :global, include: ~w(required form phx-change aria-invalid aria-describedby))

  def date_picker(assigns) do
    assigns = common(assigns, :date)
    assigns = assign(assigns, :iso, date_value(assigns.value))

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class={["date-picker", @class]}
      {@wrapper}
      phx-hook=".DatePicker"
    >
      <input
        type="date"
        id={@id}
        name={@name}
        value={@iso}
        min={@min}
        max={@max}
        disabled={@disabled}
        class="dp-native"
        data-dp="main"
        {@rest}
      />
      <div id={"#{@id}-ui"} class="dp-ui" phx-update="ignore"></div>
      <.picker_hook />
    </div>
    """
  end

  # ── range ────────────────────────────────────────────────────────────────

  @doc """
  A range of days: posts `name[start]` and `name[end]` (an empty string for a missing end).
  Pick the first day, then the last; the length shows as it is drawn.
  """
  attr(:id, :string, default: nil, doc: "The start input's id (taken from `field`)")

  attr(:name, :string,
    default: nil,
    doc: "The base name; the inputs are `name[start]`, `name[end]`"
  )

  attr(:value, :any,
    default: nil,
    doc: "A map with `start` and `end` (atom or string keys), or `{from, to}`"
  )

  attr(:field, FormField, default: nil)
  attr(:label, :string, default: nil)
  attr(:rules, :any, default: nil, doc: "`min_length` and `max_length` apply here")
  attr(:presets, :any, default: :default)
  attr(:zone, :string, default: "Etc/UTC")
  attr(:week_start, :integer, default: 1)
  attr(:start_key, :string, default: "start", doc: "The posted key of the first day")
  attr(:end_key, :string, default: "end", doc: "The posted key of the last day")

  attr(:preset_key, :boolean,
    default: false,
    doc: "Also post `name[preset]` with the chosen preset's key, for filters that stay relative"
  )

  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(required form phx-change aria-invalid aria-describedby))

  def date_range_picker(assigns) do
    assigns = assigns |> common(:range)
    {from, to, preset} = range_value(assigns.value)

    assigns =
      assign(assigns,
        start_name: "#{assigns.name}[#{assigns.start_key}]",
        end_name: "#{assigns.name}[#{assigns.end_key}]",
        preset_name: "#{assigns.name}[preset]",
        from: from,
        to: to,
        preset: preset
      )

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class={["date-picker", @class]}
      {@wrapper}
      phx-hook=".DatePicker"
    >
      <input
        type="date"
        id={@id}
        name={@start_name}
        value={@from}
        min={@min}
        max={@max}
        disabled={@disabled}
        class="dp-native"
        data-dp="start"
        {@rest}
      />
      <input
        type="date"
        id={"#{@id}-end"}
        name={@end_name}
        value={@to}
        min={@min}
        max={@max}
        disabled={@disabled}
        class="dp-native"
        data-dp="end"
        {@rest}
      />
      <input
        :if={@preset_key}
        type="hidden"
        name={@preset_name}
        value={@preset}
        disabled={@disabled}
        data-dp="preset"
      />
      <div id={"#{@id}-ui"} class="dp-ui" phx-update="ignore"></div>
      <.picker_hook />
    </div>
    """
  end

  # ── time ─────────────────────────────────────────────────────────────────

  @doc """
  A time of day on a 24-hour clock: posts `09:00`. With a `step` of 5 minutes or more the
  popover lists the times.
  """
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "A `Time` or `\"HH:MM\"`")
  attr(:field, FormField, default: nil)
  attr(:label, :string, default: nil)
  attr(:rules, :any, default: nil, doc: "`step` applies here too; the `step` attribute wins")

  attr(:step, :integer,
    default: nil,
    doc: "Minute step (1, 5, 15, 30 ...); typing and arrow keys follow it"
  )

  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(required form phx-change aria-invalid aria-describedby))

  def time_picker(assigns) do
    rules = DateRules.new(assigns.rules)
    step = assigns.step || rules.step || 1
    assigns = assigns |> assign(:rules, %{rules | step: step}) |> common(:time)
    assigns = assign(assigns, step: step, time: time_value(assigns.value))

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class={["date-picker", @class]}
      {@wrapper}
      phx-hook=".DatePicker"
    >
      <input
        type="time"
        id={@id}
        name={@name}
        value={@time}
        step={@step * 60}
        disabled={@disabled}
        class="dp-native"
        data-dp="main"
        {@rest}
      />
      <div id={"#{@id}-ui"} class="dp-ui" phx-update="ignore"></div>
      <.picker_hook />
    </div>
    """
  end

  # ── datetime ─────────────────────────────────────────────────────────────

  @doc """
  A date and time in a zone: posts `2027-03-15T09:00:00+05:30`. `zone` is required: it is the
  zone the wall time is read in, and the one shown beside the field.
  """
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)

  attr(:value, :any,
    default: nil,
    doc: "A `DateTime`, `NaiveDateTime` (a wall time in `zone`) or an ISO 8601 string"
  )

  attr(:field, FormField, default: nil)
  attr(:label, :string, default: nil)

  attr(:zone, :string,
    required: true,
    doc: "The place's IANA zone (\"Etc/UTC\" where there is none)"
  )

  attr(:rules, :any, default: nil)
  attr(:presets, :any, default: :default)
  attr(:step, :integer, default: nil, doc: "Minute step of the time part")
  attr(:week_start, :integer, default: 1)
  attr(:hint_label, :string, default: "your time", doc: "The words after the viewer's time")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(required form phx-change aria-invalid aria-describedby))

  def datetime_picker(%{zone: nil}),
    do: raise(ArgumentError, "datetime_picker needs a zone: the place's IANA name or \"Etc/UTC\"")

  def datetime_picker(assigns) do
    rules = DateRules.new(assigns.rules)
    step = assigns.step || rules.step || 1
    assigns = assigns |> assign(:rules, %{rules | step: step}) |> common(:datetime)
    {wall, posted, resolution} = datetime_value(assigns.value, assigns.zone)

    assigns =
      assign(assigns,
        step: step,
        wall: wall,
        posted: posted,
        wrapper: Map.put(assigns.wrapper, :"data-resolution", resolution)
      )

    ~H"""
    <div
      id={"#{@id}-wrapper"}
      class={["date-picker", @class]}
      {@wrapper}
      phx-hook=".DatePicker"
    >
      <input
        type="datetime-local"
        id={@id}
        name={@name}
        value={@wall}
        min={@min && "#{@min}T00:00"}
        max={@max && "#{@max}T23:59"}
        step={@step * 60}
        disabled={@disabled}
        class="dp-native"
        data-dp="main"
        {@rest}
      />
      <input type="hidden" name={@name} value={@posted} disabled data-dp="posted" />
      <div id={"#{@id}-ui"} class="dp-ui" phx-update="ignore"></div>
      <.picker_hook />
    </div>
    """
  end

  defp picker_hook(assigns) do
    ~H"""
    <script :type={ColocatedHook} name=".DatePicker">
      import {DatePicker} from "sutra_ui/dates"
      export default DatePicker
    </script>
    """
  end

  # ── shared ───────────────────────────────────────────────────────────────

  # Id, name and value from the field; the rules resolved against today in the zone; the
  # wrapper's data attributes the hook reads.
  defp common(%{field: %FormField{} = field} = assigns, kind) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id, name: assigns.name || field.name)
    |> assign(:value, if(is_nil(assigns.value), do: field.value, else: assigns.value))
    |> common(kind)
  end

  defp common(assigns, kind) do
    id = assigns.id || derive_id(assigns.name)
    rules = DateRules.new(assigns.rules)
    zone = assigns[:zone] || "Etc/UTC"
    today = DateRules.today(zone)
    map = DateRules.to_map(rules, today)

    wrapper =
      %{
        :"data-has-picker" => true,
        :"data-kind" => to_string(kind),
        :"data-state" => "closed",
        :"data-disabled" => assigns.disabled,
        :"data-zone" => zone,
        :"data-rules" => encode(map),
        :"data-presets" => encode(presets(assigns[:presets] || :default, kind)),
        :"data-label" => assigns.label,
        :"data-week-start" => assigns[:week_start] || 1,
        :"data-step" => assigns[:step] || rules.step,
        :"data-hint-label" => assigns[:hint_label]
      }

    assign(assigns, id: id, wrapper: wrapper, min: map["min"], max: map["max"])
  end

  defp derive_id(nil),
    do: raise(ArgumentError, "a picker needs an `id`, a `name` or a `field`")

  defp derive_id(name), do: String.replace(name, ~r/[^A-Za-z0-9_-]+/, "_")

  defp encode(data), do: Phoenix.json_library().encode!(data)

  # ── presets ──

  defp presets(:default, kind) when kind in [:date, :datetime], do: presets(@day_presets, kind)
  defp presets(:default, :range), do: presets(@range_presets, :range)
  defp presets(:default, _), do: []
  defp presets(list, _kind) when is_list(list), do: Enum.map(list, &preset/1)

  defp preset(key) when is_atom(key) or is_binary(key),
    do: %{"key" => to_string(key), "label" => Map.get(@labels, to_atom(key), to_string(key))}

  defp preset({key, label}), do: %{"key" => to_string(key), "label" => label}

  defp preset(%{key: key} = map) do
    base = %{
      "key" => to_string(key),
      "label" => map[:label] || Map.get(@labels, to_atom(key), to_string(key))
    }

    if Map.has_key?(map, :value), do: Map.put(base, "value", preset_value(map.value)), else: base
  end

  defp preset_value(%Date{} = d), do: Date.to_iso8601(d)

  defp preset_value({%Date{} = a, %Date{} = b}),
    do: %{"start" => Date.to_iso8601(a), "end" => Date.to_iso8601(b)}

  defp preset_value(%{start: a, end: b}), do: preset_value({a, b})

  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key), do: Enum.find(Map.keys(@labels), &(Atom.to_string(&1) == key))

  # ── values ──

  defp date_value(%Date{} = date), do: Date.to_iso8601(date)

  defp date_value(string) when is_binary(string) do
    case Date.from_iso8601(string) do
      {:ok, date} -> Date.to_iso8601(date)
      _ -> ""
    end
  end

  defp date_value(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
  defp date_value(%NaiveDateTime{} = n), do: n |> NaiveDateTime.to_date() |> Date.to_iso8601()
  defp date_value(_), do: ""

  defp time_value(%Time{hour: h, minute: m}), do: pad(h) <> ":" <> pad(m)

  defp time_value(<<h::binary-size(2), ":", m::binary-size(2), _::binary>>), do: h <> ":" <> m
  defp time_value(_), do: ""

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp range_value({from, to}), do: {date_value(from), date_value(to), ""}

  defp range_value(%{} = map) do
    get = fn key -> Map.get(map, key) || Map.get(map, Atom.to_string(key)) end
    {date_value(get.(:start)), date_value(get.(:end)), get.(:preset) || ""}
  end

  defp range_value(_), do: {"", "", ""}

  # The wall time shown, the exact moment posted, and what the zone made of it.
  defp datetime_value(%DateTime{} = dt, zone) do
    local = SutraTime.to_zone(dt, zone)
    {wall_string(DateTime.to_naive(local)), DateTime.to_iso8601(local), "ok"}
  end

  defp datetime_value(%NaiveDateTime{} = naive, zone) do
    classify(SutraTime.from_wall(naive, zone), naive)
  end

  defp datetime_value(string, zone) when is_binary(string) and string != "" do
    case SutraTime.parse_datetime(string, zone) do
      {:error, :invalid} ->
        {"", "", "empty"}

      result ->
        naive =
          case result do
            {:ok, dt} -> DateTime.to_naive(dt)
            _ -> typed_wall(string)
          end

        classify(result, naive)
    end
  end

  defp datetime_value(_, _zone), do: {"", "", "empty"}

  # The wall time as typed, from a string without an offset.
  defp typed_wall(string) do
    with {:ok, naive} <-
           NaiveDateTime.from_iso8601(
             if(Regex.match?(~r/T\d\d:\d\d$/, string), do: string <> ":00", else: string)
           ) do
      naive
    else
      _ -> nil
    end
  end

  defp classify({:ok, dt}, _naive),
    do: {wall_string(DateTime.to_naive(dt)), DateTime.to_iso8601(dt), "ok"}

  defp classify({:ambiguous, first, _second}, _naive),
    do: {wall_string(DateTime.to_naive(first)), "", "ambiguous"}

  # A skipped wall time: keep what was typed, post nothing.
  defp classify({:gap, before, _after}, naive),
    do: {wall_string(naive || DateTime.to_naive(before)), "", "gap"}

  defp wall_string(%NaiveDateTime{} = n), do: Calendar.strftime(n, "%Y-%m-%dT%H:%M")
end
