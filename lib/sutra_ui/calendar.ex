defmodule SutraUI.Calendar do
  @moduledoc """
  A monthly calendar grid for date selection.

  Renders a single month with prev/next navigation. Designed to be composed
  into date pickers or used standalone. Date state stays in the parent
  LiveView; the component emits plain LiveView events.

  ## Examples

      # Static calendar (current month)
      <.calendar />

      # Interactive — emit events on date click and month navigation
      <.calendar
        year={@year}
        month={@month}
        selected={@selected}
        select_event="select_date"
        nav_event="nav_month"
      />

      # Range selection
      <.calendar
        mode="range"
        selected={@range_start}
        range_end={@range_end}
        select_event="select_range"
        nav_event="nav_month"
      />

      # Monday-start week, with disabled dates
      <.calendar
        week_start={1}
        disabled_dates={@holidays}
        selected={@selected}
        select_event="select_date"
      />

  ## Attributes

  * `year` - Displayed year. Defaults to the selected date's year, then current year.
  * `month` - Displayed month (1-12). Defaults to the selected date's month, then current month.
  * `selected` - Selected `Date` struct or ISO string.
  * `range_end` - Range end date (only used in `mode="range"`).
  * `mode` - Selection mode: `single` or `range`. Defaults to `single`.
  * `disabled_dates` - List of `Date` structs or ISO strings to disable.
  * `week_start` - First weekday, where `0` is Sunday and `6` is Saturday.
    Defaults to `0`.
  * `select_event` - LiveView event emitted on date click with `phx-value-date`.
  * `nav_event` - LiveView event emitted on prev/next with `phx-value-year` and
    `phx-value-month`.
  * `class` - Additional CSS classes.

  ## Event Handling

  The calendar emits two distinct events:

  ```elixir
  # Date selection — fires with the clicked date
  def handle_event("select_date", %{"date" => date}, socket) do
    d = Date.from_iso8601!(date)
    {:noreply, assign(socket, selected: d, year: d.year, month: d.month)}
  end

  # Month navigation — fires with the new year/month
  def handle_event("nav_month", %{"year" => year, "month" => month}, socket) do
    {:noreply, assign(socket, year: String.to_integer(year), month: String.to_integer(month))}
  end

  ```

  ## Accessibility

  - Uses `role="grid"` with `role="row"` and `role="gridcell"` for the calendar grid.
  - Each day is a `<button>` — natively keyboard-focusable and operable.
  - `aria-selected` marks the selected date.
  - `aria-current="date"` marks today.
  - Disabled dates use the native `disabled` attribute.
  - Navigation buttons have descriptive `aria-label`s.
  """

  use Phoenix.Component

  @month_names ~w(January February March April May June July August September October November December)

  attr(:year, :integer,
    default: nil,
    doc: "Displayed year. Defaults to selected year, then current year"
  )

  attr(:month, :integer,
    default: nil,
    doc: "Displayed month (1-12). Defaults to selected month, then current month"
  )

  attr(:selected, :any, default: nil, doc: "Selected Date struct or ISO string")
  attr(:range_end, :any, default: nil, doc: "Range end Date struct or ISO string")
  attr(:mode, :string, default: "single", values: ~w(single range), doc: "Selection mode")
  attr(:disabled_dates, :list, default: [], doc: "List of disabled Date structs or ISO strings")

  attr(:week_start, :integer,
    default: 0,
    values: [0, 1, 2, 3, 4, 5, 6],
    doc: "First weekday: 0 = Sunday, 1 = Monday, ... 6 = Saturday"
  )

  attr(:select_event, :string,
    default: nil,
    doc: "LiveView event emitted on date click with phx-value-date"
  )

  attr(:nav_event, :string,
    default: nil,
    doc:
      "LiveView event emitted on prev/next with phx-value-year and phx-value-month. Falls back to select_event."
  )

  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:id, :string, default: nil, doc: "DOM id for the calendar root")
  attr(:rest, :global, include: ~w(aria-label), doc: "Additional HTML attributes")

  def calendar(assigns) do
    today = Date.utc_today()
    selected = normalize_date(assigns.selected)
    range_end = normalize_date(assigns.range_end)
    year = assigns.year || (selected && selected.year) || today.year
    month = assigns.month || (selected && selected.month) || today.month
    current = Date.new!(year, month, 1)
    disabled = Enum.map(assigns.disabled_dates, &normalize_date/1) |> Enum.reject(&is_nil/1)

    weeks = calendar_weeks(current, assigns.week_start)
    weekdays = weekday_labels(assigns.week_start)

    prev = Date.add(current, -1) |> then(fn d -> %{year: d.year, month: d.month} end)

    next =
      Date.add(Date.new!(year, month, Date.days_in_month(current)), 1)
      |> then(fn d -> %{year: d.year, month: d.month} end)

    nav_event = assigns.nav_event || assigns.select_event

    assigns =
      assigns
      |> assign(:display_date, current)
      |> assign(:selected_date, selected)
      |> assign(:range_end_date, range_end)
      |> assign(:today_date, today)
      |> assign(:weeks, weeks)
      |> assign(:weekdays, weekdays)
      |> assign(:month_label, Enum.at(@month_names, month - 1))
      |> assign(:prev, prev)
      |> assign(:next, next)
      |> assign(:nav_event, nav_event)
      |> assign(:disabled_set, MapSet.new(disabled, fn d -> Date.to_iso8601(d) end))

    ~H"""
    <div
      id={@id}
      class={["calendar", @class]}
      {@rest}
    >
      <div class="calendar-header">
        <button
          type="button"
          class="calendar-nav-btn"
          aria-label="Previous month"
          disabled={is_nil(@nav_event)}
          phx-click={@nav_event}
          phx-value-year={@prev.year}
          phx-value-month={@prev.month}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="size-4"
            aria-hidden="true"
          >
            <path d="m15 18-6-6 6-6" />
          </svg>
        </button>
        <h2 class="calendar-title">{@month_label} {@display_date.year}</h2>
        <button
          type="button"
          class="calendar-nav-btn"
          aria-label="Next month"
          disabled={is_nil(@nav_event)}
          phx-click={@nav_event}
          phx-value-year={@next.year}
          phx-value-month={@next.month}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="size-4"
            aria-hidden="true"
          >
            <path d="m9 18 6-6-6-6" />
          </svg>
        </button>
      </div>
      <div class="calendar-grid" role="grid" aria-label={"#{@month_label} #{@display_date.year}"}>
        <div class="calendar-weekdays" role="row">
          <span :for={day <- @weekdays} class="calendar-weekday" role="columnheader">{day}</span>
        </div>
        <div :for={week <- @weeks} class="calendar-week" role="row">
          <button
            :for={day <- week}
            type="button"
            class={[
              calendar_day_class(
                day,
                @display_date,
                @selected_date,
                @range_end_date,
                @today_date,
                @mode,
                @disabled_set
              ),
              is_nil(@select_event) && "calendar-day-static"
            ]}
            data-outside={to_attr(day.month != @display_date.month)}
            data-today={to_attr(same_date?(day, @today_date))}
            data-selected={to_attr(selected_day?(day, @selected_date, @range_end_date, @mode))}
            data-in-range={to_attr(in_range?(day, @selected_date, @range_end_date, @mode))}
            data-range-start={to_attr(range_start_day?(day, @selected_date, @range_end_date, @mode))}
            data-range-end={to_attr(range_end_day?(day, @selected_date, @range_end_date, @mode))}
            aria-selected={to_attr(selected_day?(day, @selected_date, @range_end_date, @mode))}
            aria-current={same_date?(day, @today_date) && "date"}
            disabled={day_disabled?(day, @display_date, @disabled_set)}
            phx-click={@select_event}
            phx-value-date={Date.to_iso8601(day)}
            role="gridcell"
          >
            {day.day}
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp normalize_date(nil), do: nil
  defp normalize_date(%Date{} = d), do: d

  defp normalize_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp calendar_weeks(first_day, week_start) do
    offset =
      Integer.mod(
        first_day
        |> Date.day_of_week()
        |> then(fn d -> Integer.mod(d, 7) - week_start end),
        7
      )

    start = Date.add(first_day, -offset)
    for w <- 0..5, do: for(d <- 0..6, do: Date.add(start, w * 7 + d))
  end

  defp weekday_labels(week_start) do
    labels = ~w(Sun Mon Tue Wed Thu Fri Sat)
    {head, tail} = Enum.split(labels, week_start)
    tail ++ head
  end

  defp same_date?(_, nil), do: false
  defp same_date?(%Date{} = a, %Date{} = b), do: Date.compare(a, b) == :eq

  defp selected_day?(day, selected, range_end, "range"),
    do: same_date?(day, selected) or same_date?(day, range_end)

  defp selected_day?(day, selected, _range_end, _mode), do: same_date?(day, selected)

  defp in_range?(_, nil, _, _), do: false
  defp in_range?(_, _, nil, _), do: false

  defp in_range?(d, s, e, "range") do
    {start_date, end_date} = ordered_range(s, e)
    Date.compare(d, start_date) != :lt && Date.compare(d, end_date) != :gt
  end

  defp in_range?(_, _, _, _), do: false

  defp range_start_day?(_, nil, _, _), do: false
  defp range_start_day?(_, _, nil, _), do: false

  defp range_start_day?(day, start_date, end_date, "range") do
    {first_day, _last_day} = ordered_range(start_date, end_date)
    same_date?(day, first_day)
  end

  defp range_start_day?(_, _, _, _), do: false

  defp range_end_day?(_, nil, _, _), do: false
  defp range_end_day?(_, _, nil, _), do: false

  defp range_end_day?(day, start_date, end_date, "range") do
    {_first_day, last_day} = ordered_range(start_date, end_date)
    same_date?(day, last_day)
  end

  defp range_end_day?(_, _, _, _), do: false

  defp ordered_range(start_date, end_date) do
    case Date.compare(start_date, end_date) do
      :gt -> {end_date, start_date}
      _ -> {start_date, end_date}
    end
  end

  defp day_disabled?(day, current, disabled) do
    day.month != current.month || MapSet.member?(disabled, Date.to_iso8601(day))
  end

  defp calendar_day_class(day, current, selected, range_end, today, mode, disabled) do
    outside = day.month != current.month
    sel = selected_day?(day, selected, range_end, mode)
    range = in_range?(day, selected, range_end, mode)
    today_class = same_date?(day, today)
    disabled_class = day_disabled?(day, current, disabled)

    [
      "calendar-day",
      outside && "calendar-day-outside",
      sel && "calendar-day-selected",
      range && !sel && "calendar-day-in-range",
      range_start_day?(day, selected, range_end, mode) && "calendar-day-range-start",
      range_end_day?(day, selected, range_end, mode) && "calendar-day-range-end",
      today_class && "calendar-day-today",
      disabled_class && "calendar-day-disabled"
    ]
  end

  defp to_attr(true), do: "true"
  defp to_attr(false), do: nil
end
