defmodule SutraUI.DateRules do
  @moduledoc """
  What dates, times and ranges a picker allows: one struct that both the picker (it disables
  the days, and marks a typed value it refuses) and the server (`validate/4`) read, so what the
  calendar refuses is what the changeset refuses.

      rules = %SutraUI.DateRules{
        min: :today,                       # no past days, in the picker's zone
        max: {:today, 90},                 # at most 90 days ahead
        disabled_weekdays: [6, 7],         # no Saturdays or Sundays (ISO: Monday is 1)
        disabled_dates: [~D[2026-12-25]],
        min_length: 2,                     # ranges: at least 2 days, end day included
        max_length: 14,
        step: 15                           # times: on the quarter hour
      }

      <.date_picker field={@form[:due]} label="Due" rules={rules} zone="Asia/Kolkata" />

      changeset
      |> SutraUI.DateRules.validate(:due, rules, zone: "Asia/Kolkata")

  `min` and `max` are a `Date`, `:today` or `{:today, days}` (days from today, negative for
  the past). "Today" is the day it is in the zone you pass, so a rule such as "not in the
  past" means the place's today, wherever the viewer is.

  A rule that is nil or empty does not apply. `check_date/3`, `check_range/4`, `check_time/2`
  and `errors/3` are pure and need no Ecto; `validate/4` and `validate_range/5` add the
  errors to a changeset (they call `Ecto.Changeset`, so your app needs Ecto, which Phoenix
  apps have).
  """

  alias SutraUI.Time, as: SutraTime

  defstruct min: nil,
            max: nil,
            disabled_dates: [],
            disabled_weekdays: [],
            min_length: nil,
            max_length: nil,
            step: nil

  @type bound :: Date.t() | :today | {:today, integer()} | nil
  @type t :: %__MODULE__{
          min: bound(),
          max: bound(),
          disabled_dates: [Date.t()],
          disabled_weekdays: [1..7],
          min_length: pos_integer() | nil,
          max_length: pos_integer() | nil,
          step: pos_integer() | nil
        }

  @type reason ::
          :before_min
          | :after_max
          | :disabled_date
          | :disabled_weekday
          | :reversed
          | :too_short
          | :too_long
          | :step

  @weekdays ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  @doc "Rules from a struct, keyword list or map; nil is no rules."
  @spec new(t() | keyword() | map() | nil) :: t()
  def new(nil), do: %__MODULE__{}
  def new(%__MODULE__{} = rules), do: rules
  def new(attrs) when is_list(attrs) or is_map(attrs), do: struct!(__MODULE__, attrs)

  @doc """
  The day it is in `zone`. `"Etc/UTC"` needs no time zone database; any other zone does (see
  `SutraUI.Time`).
  """
  @spec today(String.t() | nil) :: Date.t()
  def today(zone \\ nil)
  def today(zone) when zone in [nil, "Etc/UTC", "UTC"], do: Date.utc_today()

  def today(zone),
    do: DateTime.utc_now() |> SutraTime.to_zone(zone) |> DateTime.to_date()

  @doc "A bound as a date, `today` being the day it is now."
  @spec resolve(bound(), Date.t()) :: Date.t() | nil
  def resolve(nil, _today), do: nil
  def resolve(%Date{} = date, _today), do: date
  def resolve(:today, today), do: today
  def resolve({:today, days}, today) when is_integer(days), do: Date.add(today, days)

  @doc """
  The rules as the picker's hook reads them: ISO strings, relative bounds resolved against
  `today`.
  """
  @spec to_map(t(), Date.t()) :: map()
  def to_map(%__MODULE__{} = r, %Date{} = today) do
    %{
      "today" => Date.to_iso8601(today),
      "min" => iso(resolve(r.min, today)),
      "max" => iso(resolve(r.max, today)),
      "disabledDates" => Enum.map(r.disabled_dates, &Date.to_iso8601/1),
      "disabledWeekdays" => r.disabled_weekdays,
      "minLength" => r.min_length,
      "maxLength" => r.max_length,
      "step" => r.step
    }
  end

  defp iso(nil), do: nil
  defp iso(date), do: Date.to_iso8601(date)

  @doc "Whether `rules` allow a day: `:ok` or `{:error, reason}`."
  @spec check_date(t(), Date.t(), Date.t()) :: :ok | {:error, reason()}
  def check_date(%__MODULE__{} = r, %Date{} = date, %Date{} = today) do
    min = resolve(r.min, today)
    max = resolve(r.max, today)

    cond do
      min && Date.compare(date, min) == :lt -> {:error, :before_min}
      max && Date.compare(date, max) == :gt -> {:error, :after_max}
      date in r.disabled_dates -> {:error, :disabled_date}
      Date.day_of_week(date) in r.disabled_weekdays -> {:error, :disabled_weekday}
      true -> :ok
    end
  end

  @doc """
  Whether `rules` allow a range: both days, the order, and the length (days, both ends
  counted).
  """
  @spec check_range(t(), Date.t(), Date.t(), Date.t()) :: :ok | {:error, reason()}
  def check_range(%__MODULE__{} = r, %Date{} = from, %Date{} = to, %Date{} = today) do
    length = Date.diff(to, from) + 1

    with :ok <- check_date(r, from, today),
         :ok <- check_date(r, to, today) do
      cond do
        length < 1 -> {:error, :reversed}
        r.min_length && length < r.min_length -> {:error, :too_short}
        r.max_length && length > r.max_length -> {:error, :too_long}
        true -> :ok
      end
    end
  end

  @doc "Whether the time is on the rules' minute `step`."
  @spec check_time(t(), Time.t()) :: :ok | {:error, :step}
  def check_time(%__MODULE__{step: step}, %Time{} = time) when is_integer(step) and step > 1 do
    if rem(time.hour * 60 + time.minute, step) == 0 and time.second == 0,
      do: :ok,
      else: {:error, :step}
  end

  def check_time(%__MODULE__{}, %Time{}), do: :ok

  @doc """
  The errors for a value, as `{message, opts}` pairs ready for a changeset. The value is a
  `Date`, `Time`, `DateTime` (checked as its day in `opts[:zone]` and its time), a
  `NaiveDateTime`, `nil` (no errors), or an ISO string.

  ## Options

    * `:zone` - the picker's zone (default `"Etc/UTC"`); decides today and the day of a
      `DateTime`
    * `:today` - override today, for tests
  """
  @spec errors(t() | keyword() | map() | nil, term(), keyword()) :: [{String.t(), keyword()}]
  def errors(rules, value, opts \\ []) do
    rules = new(rules)
    zone = Keyword.get(opts, :zone)
    today = Keyword.get_lazy(opts, :today, fn -> today(zone) end)

    case normalize(value, zone) do
      nil -> []
      %Date{} = date -> to_errors(check_date(rules, date, today), rules, today)
      %Time{} = time -> to_errors(check_time(rules, time), rules, today)
      {%Date{} = date, %Time{} = time} -> datetime_errors(rules, date, time, today)
    end
  end

  defp datetime_errors(rules, date, time, today) do
    to_errors(check_date(rules, date, today), rules, today) ++
      to_errors(check_time(rules, time), rules, today)
  end

  @doc """
  Adds the errors for a range given as two dates to `changeset` (on `end_field`; a reversed
  range on `end_field` too). Options as `errors/3`, plus `:changeset` (the module to call,
  `Ecto.Changeset`).
  """
  @spec validate_range(term(), atom(), atom(), t() | keyword() | map() | nil, keyword()) ::
          term()
  def validate_range(changeset, start_field, end_field, rules, opts \\ []) do
    mod = Keyword.get(opts, :changeset, Ecto.Changeset)
    rules = new(rules)
    today = Keyword.get_lazy(opts, :today, fn -> today(opts[:zone]) end)
    from = normalize(apply(mod, :get_field, [changeset, start_field]), opts[:zone])
    to = normalize(apply(mod, :get_field, [changeset, end_field]), opts[:zone])

    case {from, to} do
      {%Date{} = from, %Date{} = to} ->
        case check_range(rules, from, to, today) do
          :ok ->
            changeset

          {:error, reason}
          when reason in [:before_min, :after_max, :disabled_date, :disabled_weekday] ->
            field = if check_date(rules, from, today) == :ok, do: end_field, else: start_field
            add_errors(mod, changeset, field, to_errors({:error, reason}, rules, today))

          {:error, reason} ->
            add_errors(mod, changeset, end_field, to_errors({:error, reason}, rules, today))
        end

      _ ->
        changeset
    end
  end

  @doc """
  Adds the picker's errors for `field` to `changeset`: the same checks the calendar makes,
  so the server refuses what the picker refused. See `errors/3` for the options.

      changeset |> SutraUI.DateRules.validate(:starts_at, rules, zone: "Asia/Kolkata")
  """
  @spec validate(term(), atom(), t() | keyword() | map() | nil, keyword()) :: term()
  def validate(changeset, field, rules, opts \\ []) do
    mod = Keyword.get(opts, :changeset, Ecto.Changeset)
    value = apply(mod, :get_field, [changeset, field])
    add_errors(mod, changeset, field, errors(rules, value, opts))
  end

  defp add_errors(mod, changeset, field, errors) do
    Enum.reduce(errors, changeset, fn {message, opts}, acc ->
      apply(mod, :add_error, [acc, field, message, opts])
    end)
  end

  defp to_errors(:ok, _rules, _today), do: []

  defp to_errors({:error, reason}, rules, today),
    do: [
      {message(reason), [validation: :date_rules, reason: reason] ++ words(reason, rules, today)}
    ]

  defp message(:before_min), do: "must be on or after %{date}"
  defp message(:after_max), do: "must be on or before %{date}"
  defp message(:disabled_date), do: "is not available"
  defp message(:disabled_weekday), do: "is not available on a %{weekday}"
  defp message(:reversed), do: "must not be before the start"
  defp message(:too_short), do: "must be at least %{count} days"
  defp message(:too_long), do: "must be at most %{count} days"
  defp message(:step), do: "must be a multiple of %{step} minutes"

  defp words(:before_min, r, today),
    do: [date: SutraTime.format(resolve(r.min, today), :date, nil)]

  defp words(:after_max, r, today),
    do: [date: SutraTime.format(resolve(r.max, today), :date, nil)]

  defp words(:too_short, r, _), do: [count: r.min_length]
  defp words(:too_long, r, _), do: [count: r.max_length]
  defp words(:step, r, _), do: [step: r.step]
  defp words(:disabled_weekday, _r, _), do: [weekday: "weekday"]
  defp words(_, _, _), do: []

  @doc "The English name of an ISO weekday (Monday is 1)."
  @spec weekday_name(1..7) :: String.t()
  def weekday_name(n), do: Enum.at(@weekdays, n - 1)

  # ── values ────────────────────────────────────────────────────────────────

  defp normalize(nil, _), do: nil
  defp normalize("", _), do: nil
  defp normalize(%Date{} = d, _), do: d
  defp normalize(%Time{} = t, _), do: t

  defp normalize(%NaiveDateTime{} = n, _),
    do: {NaiveDateTime.to_date(n), NaiveDateTime.to_time(n)}

  defp normalize(%DateTime{} = dt, zone) do
    local = SutraTime.to_zone(dt, zone || dt.time_zone)
    {DateTime.to_date(local), DateTime.to_time(local)}
  end

  defp normalize(string, zone) when is_binary(string) do
    cond do
      match?({:ok, _}, Date.from_iso8601(string)) ->
        elem(Date.from_iso8601(string), 1)

      match?({:ok, _, _}, DateTime.from_iso8601(string)) ->
        {:ok, dt, _} = DateTime.from_iso8601(string)
        normalize(dt, zone)

      match?({:ok, _}, NaiveDateTime.from_iso8601(string)) ->
        normalize(elem(NaiveDateTime.from_iso8601(string), 1), zone)

      match?({:ok, _}, Time.from_iso8601(string <> ":00")) ->
        elem(Time.from_iso8601(string <> ":00"), 1)

      true ->
        nil
    end
  end

  defp normalize(_other, _), do: nil
end
