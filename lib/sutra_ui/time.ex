defmodule SutraUI.Time do
  @moduledoc """
  Times shown to people: `relative_time/1`, `local_time/1` and the wording they share,
  `format/3`.

  ## One shown zone

  Every absolute time shows in the place's zone (an organization's, a Workbook's, an
  event's), on screens, in emails and in PDFs, so everyone sees and says the same time.
  Relative times ("3 hours ago", "in 2 days") need no zone. When the browser's zone shows a
  different wall time, the hook adds the viewer's own time as a hint
  ("Mon 5 Oct, 14:30 IST · Sun 23:30 your time"); nothing is converted silently.

  The server renders the final English words inside `<time datetime title>`, so tests,
  emails and the first paint are correct without JavaScript. The hook only improves them:
  relative words refresh from one shared page timer (every 30 seconds while any is under an
  hour, then every five minutes, and it stops when none is left) in the page's language
  (`<html lang>`, then the browser's) with `Intl.RelativeTimeFormat`, and the viewer hint
  is added with `Intl.DateTimeFormat`.

  The clock is 24-hour: "Mon 5 Oct, 14:30 IST".

  ## Examples

      <.relative_time at={@post.inserted_at} />                    <%!-- "3 hours ago" --%>
      <.relative_time at={@due} style={:short} />                  <%!-- "in 2d" --%>
      <.local_time at={@due} format={:day_time} zone={@workbook.time_zone} />
      <%!-- "Mon 5 Oct, 14:30 IST", plus "· Sun 23:30 your time" from the hook abroad --%>

      SutraUI.Time.format(~U[2026-10-05 09:00:00Z], :day_time, "Asia/Kolkata")
      #=> "Mon 5 Oct, 14:30 IST"

  ## Setup

  Converting to a named zone needs a time zone database, which your app configures (Sutra UI
  does not depend on one). With [`tz`](https://hex.pm/packages/tz):

      # mix.exs
      {:tz, "~> 0.28"}

      # config/config.exs
      config :elixir, :time_zone_database, Tz.TimeZoneDatabase

  Without it, `format/3` and the components raise an `ArgumentError` naming that setting
  for any zone but `"Etc/UTC"`.

  The refreshing and the hint come from a hook that imports `sutra_ui/time`. Merge the
  generated `phoenix-colocated/sutra_ui` hooks into your LiveSocket, as for `SutraUI.Dialog`;
  your esbuild finds the module through `deps` in `NODE_PATH`, like `phoenix` does. Without
  the hooks the words stay as the server rendered them.

  ## Formats

  | Format | Example |
  |--------|---------|
  | `:date` | `5 Oct 2026` |
  | `:short` | `5 Oct` |
  | `:long` | `5 October 2026` |
  | `:day` | `Mon 5 Oct` |
  | `:time` | `14:30` |
  | `:date_time` | `5 Oct, 14:30` |
  | `:day_time` | `Mon 5 Oct, 14:30 IST` |
  | `:full` | `5 Oct 2026, 14:30 IST` |
  | `:month` | `October 2026` |

  A `Date` given a time format reads as its day (`:date`); a `NaiveDateTime` is a wall time
  with no zone, so its zone words are left out.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.ColocatedHook

  @patterns %{
    date: "%-d %b %Y",
    short: "%-d %b",
    long: "%-d %B %Y",
    day: "%a %-d %b",
    date_time: "%-d %b, %H:%M",
    day_time: "%a %-d %b, %H:%M",
    time: "%H:%M",
    full: "%-d %b %Y, %H:%M",
    month: "%B %Y"
  }

  @zoned ~w(day_time full)a
  @timed ~w(date_time day_time time full)a
  @formats Map.keys(@patterns)

  @type format :: :date | :short | :long | :day | :time | :date_time | :day_time | :full | :month

  @week 7 * 86_400

  # ── Wording ──────────────────────────────────────────────────────────────

  @doc """
  The words for a `Date`, `DateTime` or `NaiveDateTime` in `format` (see the module doc).

  An instant (`DateTime`) needs `zone`, the place's IANA name ("Asia/Kolkata", or
  "Etc/UTC"). The zone abbreviation shows with `:day_time` and `:full`.

  ## Options

    * `:time_zone_database` - the database to convert with; defaults to the one configured
      for Elixir (`config :elixir, :time_zone_database, ...`).
  """
  @spec format(
          Date.t() | DateTime.t() | NaiveDateTime.t() | nil,
          format(),
          String.t() | nil,
          keyword()
        ) ::
          String.t()
  def format(value, format, zone, opts \\ [])

  def format(nil, _format, _zone, _opts), do: ""

  def format(%DateTime{} = at, format, zone, opts) when format in @formats do
    local = to_zone(at, zone, opts)
    words = Calendar.strftime(local, Map.fetch!(@patterns, format))
    if format in @zoned, do: words <> " " <> local.zone_abbr, else: words
  end

  def format(%NaiveDateTime{} = at, format, _zone, _opts) when format in @formats,
    do: Calendar.strftime(at, Map.fetch!(@patterns, format))

  def format(%Date{} = date, format, _zone, _opts) when format in @formats do
    pattern = if format in @timed, do: @patterns.date, else: Map.fetch!(@patterns, format)
    Calendar.strftime(date, pattern)
  end

  def format(_value, format, _zone, _opts),
    do:
      raise(
        ArgumentError,
        "unknown time format #{inspect(format)}; expected one of #{inspect(@formats)}"
      )

  @doc """
  An instant in `zone`.

  Raises an `ArgumentError` when `zone` is nil, when it is unknown, or when no time zone
  database is configured and `zone` is not "Etc/UTC".
  """
  @spec to_zone(DateTime.t(), String.t() | nil, keyword()) :: DateTime.t()
  def to_zone(at, zone, opts \\ [])

  def to_zone(%DateTime{}, nil, _opts),
    do:
      raise(
        ArgumentError,
        ~s|an instant needs the place's zone: pass its IANA name ("Asia/Kolkata", or "Etc/UTC" where there is none)|
      )

  def to_zone(%DateTime{time_zone: zone} = at, zone, _opts), do: at

  def to_zone(%DateTime{} = at, zone, opts) do
    db = Keyword.get_lazy(opts, :time_zone_database, &Calendar.get_time_zone_database/0)

    case DateTime.shift_zone(at, zone, db) do
      {:ok, local} ->
        local

      {:error, :utc_only_time_zone_database} ->
        raise ArgumentError,
              "showing a time in #{inspect(zone)} needs a time zone database, and none is " <>
                "configured. Add {:tz, \"~> 0.28\"} to your deps and " <>
                "`config :elixir, :time_zone_database, Tz.TimeZoneDatabase` to your config " <>
                "(SutraUI.Time does not depend on one)."

      {:error, :time_zone_not_found} ->
        raise ArgumentError, "unknown time zone #{inspect(zone)}"

      {:error, reason} ->
        raise ArgumentError, "cannot show a time in #{inspect(zone)}: #{inspect(reason)}"
    end
  end

  @doc """
  How long ago `at` was, in words, as of `now` (negative: in the future).

  `:long` gives "now", "5 minutes ago", "3 hours ago", "2 days ago", "in 2 days"; `:short`
  gives "now", "5m", "3h", "2d", "in 2d". Minutes for the first hour, then hours, then days.
  """
  @spec relative_words(integer(), :long | :short) :: String.t()
  def relative_words(seconds, style)
      when seconds > -60 and seconds < 60 and style in [:long, :short],
      do: "now"

  def relative_words(seconds, style) when style in [:long, :short] do
    {value, unit} = amount(abs(seconds))
    words = unit_words(value, unit, style)

    cond do
      style == :short and seconds < 0 -> "in " <> words
      style == :short -> words
      seconds < 0 -> "in " <> words
      true -> words <> " ago"
    end
  end

  defp amount(abs) when abs < 3_600, do: {div(abs, 60), :minute}
  defp amount(abs) when abs < 86_400, do: {div(abs, 3_600), :hour}
  defp amount(abs), do: {div(abs, 86_400), :day}

  defp unit_words(value, :minute, :short), do: "#{value}m"
  defp unit_words(value, :hour, :short), do: "#{value}h"
  defp unit_words(value, :day, :short), do: "#{value}d"
  defp unit_words(1, unit, :long), do: "1 #{unit}"
  defp unit_words(value, unit, :long), do: "#{value} #{unit}s"

  # ── Components ───────────────────────────────────────────────────────────

  @doc """
  A time relative to now ("3 hours ago", "in 2 days") inside a `<time>` element whose title
  is the full date and time in `zone`.

  Past `until` seconds (either direction) it shows the date in `zone`: the same year as `now`
  gets the short form ("5 Oct"), an older one keeps its year. The hook refreshes the words;
  see the module doc for the setup.

  An `id` is generated from the values; pass one when the same instant shows twice on a page.
  """
  attr(:at, DateTime, required: true, doc: "the instant")

  attr(:style, :atom,
    default: :long,
    values: [:long, :short],
    doc: "`:long` \"3 hours ago\", `:short` \"3h\""
  )

  attr(:until, :integer,
    default: @week,
    doc: "seconds (either direction) after which the date shows instead; default 7 days"
  )

  attr(:zone, :string,
    default: "Etc/UTC",
    doc: "the place's zone, for the title and the date shown past `until`"
  )

  attr(:now, DateTime, default: nil, doc: "the reference time; defaults to now (for tests)")
  attr(:id, :string, default: nil, doc: "DOM id; generated when omitted")
  attr(:class, :any, default: nil, doc: "additional CSS classes")
  attr(:rest, :global, doc: "additional HTML attributes")

  def relative_time(assigns) do
    now = assigns.now || DateTime.utc_now()
    seconds = DateTime.diff(now, assigns.at)

    words =
      if abs(seconds) >= assigns.until,
        do: date_near(assigns.at, now, assigns.zone),
        else: relative_words(seconds, assigns.style)

    assigns =
      assign(assigns,
        words: words,
        iso: DateTime.to_iso8601(assigns.at),
        full: format(assigns.at, :full, assigns.zone),
        dom_id: assigns.id || generated_id(:relative, [assigns.at, assigns.style, assigns.zone])
      )

    ~H"""
    <time
      id={@dom_id}
      phx-hook=".RelativeTime"
      data-sutra-time="relative"
      data-style={@style}
      data-until={@until}
      datetime={@iso}
      title={@full}
      class={@class}
      {@rest}
    >{@words}</time>
    <script :type={ColocatedHook} name=".RelativeTime">
      import {RelativeTime} from "sutra_ui/time"
      export default RelativeTime
    </script>
    """
  end

  @doc """
  A date or instant in the shared wording (`format/3`) inside a `<time>` element, always in
  `zone`. The title carries the full date and time.

  When the browser's zone shows a different wall time, the hook adds the viewer's time
  ("· Sun 23:30 your time") after the words; set `hint={false}` in dense lists, where the
  title still carries it. A `Date` or a format without a time has no hint.
  """
  attr(:at, :any, required: true, doc: "a `Date`, `DateTime` or `NaiveDateTime`")

  attr(:format, :atom,
    default: :date,
    values: @formats,
    doc: "a named format; see `SutraUI.Time`"
  )

  attr(:zone, :string,
    required: true,
    doc: ~s|the place's IANA zone ("Etc/UTC" where there is none)|
  )

  attr(:hint, :boolean,
    default: true,
    doc: "add the viewer's time when the browser's zone differs"
  )

  attr(:hint_label, :string, default: "your time", doc: "the words after the viewer's time")
  attr(:id, :string, default: nil, doc: "DOM id; generated when omitted")
  attr(:class, :any, default: nil, doc: "additional CSS classes")
  attr(:rest, :global, doc: "additional HTML attributes")

  def local_time(%{zone: nil}),
    do: raise(ArgumentError, "local_time needs a zone: pass the place's IANA name or \"Etc/UTC\"")

  def local_time(%{at: %DateTime{}, format: format} = assigns) do
    assigns =
      assign(assigns,
        words: format(assigns.at, format, assigns.zone),
        iso: DateTime.to_iso8601(assigns.at),
        full: format(assigns.at, :full, assigns.zone),
        hooked: format in @timed,
        dom_id: assigns.id || generated_id(:local, [assigns.at, format, assigns.zone])
      )

    ~H"""
    <time
      id={@dom_id}
      phx-hook={@hooked && "SutraUI.Time.LocalTime"}
      data-sutra-time={@hooked && "local"}
      data-zone={@hooked && @zone}
      data-hint={@hooked && to_string(@hint)}
      data-hint-label={@hooked && @hint_label}
      datetime={@iso}
      title={@full}
      class={@class}
      {@rest}
    >{@words}</time>
    <script :type={ColocatedHook} name=".LocalTime">
      import {LocalTime} from "sutra_ui/time"
      export default LocalTime
    </script>
    """
  end

  def local_time(assigns) do
    assigns =
      assign(assigns,
        words: format(assigns.at, assigns.format, assigns.zone),
        iso: iso(assigns.at)
      )

    ~H"""
    <time datetime={@iso} class={@class} {@rest}>{@words}</time>
    """
  end

  defp iso(%Date{} = date), do: Date.to_iso8601(date)
  defp iso(%NaiveDateTime{} = at), do: NaiveDateTime.to_iso8601(at)

  # The same year as `now` (in `zone`) gets the short form; older ones keep the year.
  defp date_near(at, now, zone) do
    if to_zone(at, zone).year == to_zone(now, zone).year,
      do: format(at, :short, zone),
      else: format(at, :date, zone)
  end

  defp generated_id(kind, parts),
    do: "sutra-#{kind}-time-" <> Integer.to_string(:erlang.phash2(parts), 36)
end
