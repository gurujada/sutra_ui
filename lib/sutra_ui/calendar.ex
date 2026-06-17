defmodule SutraUI.Calendar do
  @moduledoc """
  A token-styled monthly calendar grid.

  Calendar is inspired by shadcn/ui's DayPicker-backed calendar, adapted as a
  dependency-free Phoenix component. It renders a single month and can emit a
  LiveView event when a day is selected.
  """

  use Phoenix.Component

  @month_names ~w(January February March April May June July August September October November December)
  @weekday_names ~w(Sun Mon Tue Wed Thu Fri Sat)

  attr(:year, :integer, default: nil, doc: "Displayed year. Defaults to today")
  attr(:month, :integer, default: nil, doc: "Displayed month number. Defaults to today")
  attr(:selected, :any, default: nil, doc: "Selected Date or ISO date string")
  attr(:today, :any, default: nil, doc: "Today Date or ISO date string")

  attr(:week_start, :integer,
    default: 0,
    values: [0, 1],
    doc: "Week start: 0 for Sunday, 1 for Monday"
  )

  attr(:select_event, :string, default: nil, doc: "Optional phx-click event for date buttons")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  def calendar(assigns) do
    today = normalize_date(assigns.today) || Date.utc_today()
    year = assigns.year || today.year
    month = assigns.month || today.month
    selected = normalize_date(assigns.selected)
    current = Date.new!(year, month, 1)

    assigns =
      assigns
      |> assign(:display_date, current)
      |> assign(:selected_date, selected)
      |> assign(:today_date, today)
      |> assign(:weeks, calendar_weeks(current, assigns.week_start))
      |> assign(:month_label, Enum.at(@month_names, month - 1))
      |> assign(:weekdays, weekday_labels(assigns.week_start))

    ~H"""
    <div class={["calendar", @class]} {@rest}>
      <div class="calendar-header">
        <h2>{@month_label} {@display_date.year}</h2>
      </div>
      <div class="calendar-grid" role="grid" aria-label={"#{@month_label} #{@display_date.year}"}>
        <div class="calendar-weekdays" role="row">
          <span :for={day <- @weekdays} role="columnheader">{day}</span>
        </div>
        <div :for={week <- @weeks} class="calendar-week" role="row">
          <button
            :for={day <- week}
            type="button"
            class="calendar-day"
            data-outside={bool_string(day.month != @display_date.month)}
            data-today={bool_string(same_date?(day, @today_date))}
            data-selected={bool_string(same_date?(day, @selected_date))}
            aria-selected={bool_string(same_date?(day, @selected_date))}
            aria-current={same_date?(day, @today_date) && "date"}
            disabled={day.month != @display_date.month}
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
  defp normalize_date(%Date{} = date), do: date

  defp normalize_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp calendar_weeks(%Date{} = first_day, week_start) do
    week_start_day = if week_start == 0, do: 7, else: 1
    start_offset = rem(Date.day_of_week(first_day) - week_start_day + 7, 7)
    grid_start = Date.add(first_day, -start_offset)

    for week <- 0..5 do
      for day <- 0..6 do
        Date.add(grid_start, week * 7 + day)
      end
    end
  end

  defp weekday_labels(0), do: @weekday_names
  defp weekday_labels(1), do: tl(@weekday_names) ++ [hd(@weekday_names)]

  defp same_date?(_date, nil), do: false
  defp same_date?(%Date{} = left, %Date{} = right), do: Date.compare(left, right) == :eq

  defp bool_string(true), do: "true"
  defp bool_string(false), do: "false"
end
