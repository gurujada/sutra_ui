defmodule SutraUI.Test.Dates do
  @moduledoc """
  Pick dates and times in `Phoenix.LiveViewTest`, the way the picker posts them.

      import SutraUI.Test.Dates

      test "due date", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/tasks/new")

        html = pick(view, "task[due]", ~D[2027-03-15], form: "#task-form")
        assert html =~ "must be on or after"

        pick(view, "task[period]", {~D[2027-03-01], ~D[2027-03-07]}, form: "#task-form")
        pick(view, "task[period]", {:preset, :last_7_days}, form: "#task-form")
        pick(view, "task[starts_at]", ~U[2027-03-15 03:30:00Z], form: "#task-form", zone: "Asia/Kolkata")
      end

  The picker's real inputs are in the DOM, so this is `form/3` plus `render_change/1` with
  the posted value: `YYYY-MM-DD` for a day, `HH:MM` for a time, `name[start]` and `name[end]`
  for a range, `name[preset]` for a preset key, and an ISO 8601 string with the zone's
  offset for a `DateTime`.
  """

  import Phoenix.LiveViewTest

  @doc """
  The params a picker posts for `value` under `name`, as the nested map `form/3` takes.

      params("task[due]", ~D[2027-03-15])
      #=> %{"task" => %{"due" => "2027-03-15"}}
  """
  @spec params(String.t(), term(), keyword()) :: map()
  def params(name, value, opts \\ []) do
    name
    |> pairs(value, opts)
    |> URI.encode_query()
    |> Plug.Conn.Query.decode()
  end

  defp pairs(name, %Date{} = d, _), do: [{name, Date.to_iso8601(d)}]
  defp pairs(name, %Time{hour: h, minute: m}, _), do: [{name, "#{pad(h)}:#{pad(m)}"}]
  defp pairs(name, "" = empty, _), do: [{name, empty}]
  defp pairs(name, value, _) when is_binary(value), do: [{name, value}]

  defp pairs(name, %DateTime{} = dt, opts) do
    zone = Keyword.get(opts, :zone) || dt.time_zone
    [{name, dt |> SutraUI.Time.to_zone(zone) |> DateTime.to_iso8601()}]
  end

  defp pairs(name, %NaiveDateTime{} = n, opts) do
    zone = Keyword.fetch!(opts, :zone)

    case SutraUI.Time.from_wall(n, zone) do
      {:ok, dt} -> [{name, DateTime.to_iso8601(dt)}]
      # a clock change is never guessed: post the wall time, as the browser would
      _ -> [{name, Calendar.strftime(n, "%Y-%m-%dT%H:%M")}]
    end
  end

  defp pairs(name, {:preset, key}, opts) do
    start_key = Keyword.get(opts, :start_key, "start")
    end_key = Keyword.get(opts, :end_key, "end")
    {from, to} = SutraUI.Test.Dates.preset_range(key, opts)

    [
      {"#{name}[#{start_key}]", Date.to_iso8601(from)},
      {"#{name}[#{end_key}]", Date.to_iso8601(to)},
      {"#{name}[preset]", to_string(key)}
    ]
  end

  defp pairs(name, {%Date{} = from, %Date{} = to}, opts) do
    start_key = Keyword.get(opts, :start_key, "start")
    end_key = Keyword.get(opts, :end_key, "end")

    [
      {"#{name}[#{start_key}]", Date.to_iso8601(from)},
      {"#{name}[#{end_key}]", Date.to_iso8601(to)}
    ]
  end

  defp pairs(name, %{start: from, end: to}, opts), do: pairs(name, {from, to}, opts)

  @doc false
  def preset_range(key, opts) do
    today = Keyword.get_lazy(opts, :today, fn -> SutraUI.DateRules.today(opts[:zone]) end)

    case to_string(key) do
      "last_7_days" ->
        {Date.add(today, -6), today}

      "last_30_days" ->
        {Date.add(today, -29), today}

      "this_month" ->
        {Date.beginning_of_month(today), Date.end_of_month(today)}

      "this_week" ->
        {Date.beginning_of_week(today), Date.end_of_week(today)}

      "last_month" ->
        last = Date.add(Date.beginning_of_month(today), -1)
        {Date.beginning_of_month(last), last}

      other ->
        raise ArgumentError, "unknown range preset #{inspect(other)}"
    end
  end

  @doc """
  Picks `value` in the picker whose input is named `name` and returns the rendered HTML.

  ## Options

    * `:form` - selector of the form (default `"form"`)
    * `:zone` - for a `DateTime` or `NaiveDateTime`, the picker's zone
    * `:event` - `:change` (default) or `:submit`
    * `:today` - for a preset, override today
    * `:start_key`, `:end_key` - a range picker's key names
  """
  @spec pick(Phoenix.LiveViewTest.View.t(), String.t(), term(), keyword()) :: String.t()
  def pick(view, name, value, opts \\ []) do
    selector = Keyword.get(opts, :form, "form")
    params = params(name, value, opts)

    case {value, Keyword.get(opts, :event, :change)} do
      # The preset key is a hidden input the hook fills; LiveViewTest cannot set hidden inputs
      # through form/3, so the params go to the form element as they would from the hook.
      {{:preset, _}, :change} -> view |> element(selector) |> render_change(params)
      {{:preset, _}, :submit} -> view |> element(selector) |> render_submit(params)
      {_, :change} -> view |> form(selector, params) |> render_change()
      {_, :submit} -> view |> form(selector, params) |> render_submit()
    end
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")
end
