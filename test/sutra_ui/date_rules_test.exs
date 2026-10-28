defmodule SutraUI.DateRulesTest do
  use ExUnit.Case, async: true

  alias SutraUI.DateRules

  @today ~D[2026-10-28]

  defmodule Changeset do
    # A stand-in for Ecto.Changeset: the same calls, over a map.
    def get_field(%{changes: changes}, field), do: Map.get(changes, field)

    def add_error(%{errors: errors} = cs, field, message, opts),
      do: %{cs | errors: errors ++ [{field, {message, opts}}]}
  end

  defp changeset(changes), do: %{changes: changes, errors: []}

  describe "check_date/3" do
    test "min and max, absolute and relative to today" do
      rules = %DateRules{min: :today, max: {:today, 10}}

      assert DateRules.check_date(rules, ~D[2026-10-27], @today) == {:error, :before_min}
      assert DateRules.check_date(rules, ~D[2026-10-28], @today) == :ok
      assert DateRules.check_date(rules, ~D[2026-11-07], @today) == :ok
      assert DateRules.check_date(rules, ~D[2026-11-08], @today) == {:error, :after_max}

      absolute = %DateRules{min: ~D[2026-11-01], max: ~D[2026-11-30]}
      assert DateRules.check_date(absolute, ~D[2026-10-31], @today) == {:error, :before_min}
      assert DateRules.check_date(absolute, ~D[2026-12-01], @today) == {:error, :after_max}
    end

    test "disabled dates and weekdays (ISO: Monday is 1)" do
      rules = %DateRules{disabled_dates: [~D[2026-12-25]], disabled_weekdays: [6, 7]}

      assert DateRules.check_date(rules, ~D[2026-12-25], @today) == {:error, :disabled_date}
      # 31 Oct 2026 is a Saturday
      assert DateRules.check_date(rules, ~D[2026-10-31], @today) == {:error, :disabled_weekday}
      assert DateRules.check_date(rules, ~D[2026-10-30], @today) == :ok
    end

    test "no rules allow everything" do
      assert DateRules.check_date(%DateRules{}, ~D[1999-01-01], @today) == :ok
    end
  end

  describe "check_range/4" do
    test "length counts both ends" do
      rules = %DateRules{min_length: 2, max_length: 7}

      assert DateRules.check_range(rules, ~D[2026-11-01], ~D[2026-11-07], @today) == :ok

      assert DateRules.check_range(rules, ~D[2026-11-01], ~D[2026-11-08], @today) ==
               {:error, :too_long}

      assert DateRules.check_range(rules, ~D[2026-11-01], ~D[2026-11-01], @today) ==
               {:error, :too_short}

      assert DateRules.check_range(%DateRules{}, ~D[2026-11-02], ~D[2026-11-01], @today) ==
               {:error, :reversed}
    end

    test "each end obeys the day rules" do
      rules = %DateRules{min: :today}

      assert DateRules.check_range(rules, ~D[2026-10-01], ~D[2026-11-01], @today) ==
               {:error, :before_min}
    end
  end

  test "check_time/2 follows the minute step" do
    assert DateRules.check_time(%DateRules{step: 15}, ~T[09:30:00]) == :ok
    assert DateRules.check_time(%DateRules{step: 15}, ~T[09:20:00]) == {:error, :step}
    assert DateRules.check_time(%DateRules{step: 15}, ~T[09:30:30]) == {:error, :step}
    assert DateRules.check_time(%DateRules{}, ~T[09:20:00]) == :ok
  end

  test "to_map/2 resolves relative bounds for the hook" do
    rules = %DateRules{
      min: :today,
      max: {:today, 30},
      disabled_weekdays: [7],
      max_length: 14,
      step: 5
    }

    assert DateRules.to_map(rules, @today) == %{
             "today" => "2026-10-28",
             "min" => "2026-10-28",
             "max" => "2026-11-27",
             "disabledDates" => [],
             "disabledWeekdays" => [7],
             "minLength" => nil,
             "maxLength" => 14,
             "step" => 5
           }
  end

  describe "errors/3" do
    test "values of every kind; nil and empty are no errors" do
      rules = %DateRules{min: ~D[2026-11-01], step: 15}

      assert DateRules.errors(rules, nil, today: @today) == []
      assert DateRules.errors(rules, "", today: @today) == []

      assert [{"must be on or after %{date}", opts}] =
               DateRules.errors(rules, ~D[2026-10-01], today: @today)

      assert opts[:date] == "1 Nov 2026"
      assert opts[:reason] == :before_min

      assert [{"must be on or after %{date}", _}] =
               DateRules.errors(rules, "2026-10-01", today: @today)

      assert [{"must be a multiple of %{step} minutes", step: 15} | _] =
               Enum.map(DateRules.errors(rules, ~T[09:20:00], today: @today), fn {m, o} ->
                 {m, Keyword.take(o, [:step])}
               end)
    end

    test "a datetime is checked as its day and time in the zone" do
      rules = %DateRules{disabled_weekdays: [1]}
      # Sunday 14:00 UTC is Monday 00:00 in Auckland? use Kolkata: Sun 20:00Z -> Mon 01:30 IST
      instant = ~U[2026-11-01 20:00:00Z]

      assert [{"is not available on a %{weekday}", _}] =
               DateRules.errors(rules, instant, zone: "Asia/Kolkata", today: @today)

      assert [] = DateRules.errors(rules, instant, zone: "Etc/UTC", today: @today)
    end

    test "rules can be a keyword list or nil" do
      assert [_] = DateRules.errors([min: ~D[2027-01-01]], ~D[2026-01-01], today: @today)
      assert [] = DateRules.errors(nil, ~D[2026-01-01], today: @today)
    end
  end

  describe "validate/4 and validate_range/5" do
    test "adds the errors to the field" do
      rules = %DateRules{min: :today}

      cs =
        DateRules.validate(changeset(%{due: ~D[2026-10-01]}), :due, rules,
          today: @today,
          changeset: Changeset
        )

      assert [{:due, {"must be on or after %{date}", opts}}] = cs.errors
      assert opts[:validation] == :date_rules
    end

    test "a valid or missing value adds nothing" do
      rules = %DateRules{min: :today}

      ok =
        DateRules.validate(changeset(%{due: ~D[2026-11-01]}), :due, rules,
          today: @today,
          changeset: Changeset
        )

      none = DateRules.validate(changeset(%{}), :due, rules, today: @today, changeset: Changeset)
      assert ok.errors == [] and none.errors == []
    end

    test "a range: length errors go on the end, a refused day on the day" do
      rules = %DateRules{max_length: 3, min: :today}
      opts = [today: @today, changeset: Changeset]

      too_long =
        DateRules.validate_range(
          changeset(%{from: ~D[2026-11-01], to: ~D[2026-11-09]}),
          :from,
          :to,
          rules,
          opts
        )

      assert [{:to, {"must be at most %{count} days", count: 3} = _}] =
               Enum.map(too_long.errors, fn {f, {m, o}} -> {f, {m, Keyword.take(o, [:count])}} end)

      past =
        DateRules.validate_range(
          changeset(%{from: ~D[2026-10-01], to: ~D[2026-11-01]}),
          :from,
          :to,
          rules,
          opts
        )

      assert [{:from, {"must be on or after %{date}", _}}] = past.errors
    end
  end

  test "today/1 is the day in the zone" do
    assert %Date{} = DateRules.today("Etc/UTC")
    assert %Date{} = DateRules.today("Asia/Kolkata")
  end
end
