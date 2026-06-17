defmodule SutraUI.Calendar do
  @moduledoc """
  A monthly calendar grid for date selection.

  Renders a single month with prev/next navigation. Designed to be composed
  into date pickers or used standalone. Pure server-rendered — all date logic
  in Elixir, no JavaScript.

  ## Examples

      <.calendar />

      <.calendar selected={~D[2026-06-15]} />

      <.calendar year={2025} month={3} select_event="calendar_select" />

      <.calendar mode="range" selected={~D[2026-06-10]} range_end={~D[2026-06-20]} />
  """

  use Phoenix.Component

  @month_names ~w(January February March April May June July August September October November December)

  attr(:year, :integer, default: nil, doc: "Displayed year. Defaults to current year")
  attr(:month, :integer, default: nil, doc: "Displayed month (1-12). Defaults to current month")
  attr(:selected, :any, default: nil, doc: "Selected Date struct or ISO string")
  attr(:range_end, :any, default: nil, doc: "Range end Date struct or ISO string")
  attr(:mode, :string, default: "single", values: ~w(single range), doc: "Selection mode")
  attr(:disabled_dates, :list, default: [], doc: "List of disabled Date structs or ISO strings")
  attr(:week_start, :integer, default: 0, values: [0, 1], doc: "0 = Sunday, 1 = Monday")

  attr(:select_event, :string, default: nil, doc: "LiveView event to emit on date click")
  attr(:class, :any, default: nil, doc: "Additional CSS classes")
  attr(:rest, :global, include: ~w(id aria-label), doc: "Additional HTML attributes")

  def calendar(assigns) do
    today = Date.utc_today()
    year = assigns.year || today.year
    month = assigns.month || today.month
    current = Date.new!(year, month, 1)
    selected = normalize_date(assigns.selected)
    range_end = normalize_date(assigns.range_end)
    disabled = Enum.map(assigns.disabled_dates, &normalize_date/1) |> Enum.reject(&is_nil/1)

    weeks = calendar_weeks(current, assigns.week_start)
    weekdays = weekday_labels(assigns.week_start)

    prev = Date.add(current, -1) |> then(fn d -> %{year: d.year, month: d.month} end)

    next =
      Date.add(Date.new!(year, month, Date.days_in_month(current)), 1)
      |> then(fn d -> %{year: d.year, month: d.month} end)

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
      |> assign(:disabled_set, MapSet.new(disabled, fn d -> Date.to_iso8601(d) end))

    ~H"""
    <div class={["calendar", @class]} {@rest}>
      <div class="calendar-header">
        <button
          type="button"
          class="calendar-nav-btn"
          aria-label="Previous month"
          phx-click={@select_event}
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
          phx-click={@select_event}
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
            class={
              calendar_day_class(
                day,
                @display_date,
                @selected_date,
                @range_end_date,
                @today_date,
                @mode,
                @disabled_set
              )
            }
            data-outside={to_attr(day.month != @display_date.month)}
            data-today={to_attr(same_date?(day, @today_date))}
            data-selected={to_attr(same_date?(day, @selected_date))}
            data-in-range={to_attr(in_range?(day, @selected_date, @range_end_date, @mode))}
            aria-selected={to_attr(same_date?(day, @selected_date))}
            aria-current={same_date?(day, @today_date) && "date"}
            disabled={day_disabled?(day, @display_date, @disabled_set)}
            phx-click={@select_event}
            phx-value-date={Date.to_iso8601(day)}
            role="gridcell"
            tabindex={same_date?(day, @selected_date) && 0}
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
        |> then(fn d -> if week_start == 0, do: rem(d + 6, 7), else: d - 1 end),
        7
      )

    start = Date.add(first_day, -offset)
    for w <- 0..5, do: for(d <- 0..6, do: Date.add(start, w * 7 + d))
  end

  defp weekday_labels(0), do: ~w(Sun Mon Tue Wed Thu Fri Sat)
  defp weekday_labels(1), do: ~w(Mon Tue Wed Thu Fri Sat Sun)

  defp same_date?(_, nil), do: false
  defp same_date?(%Date{} = a, %Date{} = b), do: Date.compare(a, b) == :eq

  defp in_range?(_, nil, _, _), do: false
  defp in_range?(_, _, nil, _), do: false
  defp in_range?(d, s, e, "range"), do: Date.compare(d, s) != :lt && Date.compare(d, e) != :gt

  defp day_disabled?(day, current, disabled) do
    day.month != current.month || MapSet.member?(disabled, Date.to_iso8601(day))
  end

  defp calendar_day_class(day, current, selected, range_end, today, mode, disabled) do
    outside = day.month != current.month
    sel = selected && same_date?(day, selected)
    range = in_range?(day, selected, range_end, mode)
    today_class = same_date?(day, today)
    disabled_class = day_disabled?(day, current, disabled)

    [
      "calendar-day",
      outside && "calendar-day-outside",
      sel && "calendar-day-selected",
      range && !sel && "calendar-day-in-range",
      today_class && "calendar-day-today",
      disabled_class && "calendar-day-disabled"
    ]
  end

  defp to_attr(true), do: "true"
  defp to_attr(false), do: nil
end
