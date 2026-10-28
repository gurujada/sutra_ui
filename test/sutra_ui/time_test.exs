defmodule SutraUI.TimeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias SutraUI.Time, as: T

  # Mon 5 Oct 2026, 14:30 in Kolkata (UTC+5:30)
  @at ~U[2026-10-05 09:00:00Z]
  @now ~U[2026-10-05 12:00:00Z]

  defp doc(html), do: LazyHTML.from_fragment(html)

  defp attribute(html, selector, name),
    do: html |> doc() |> LazyHTML.query(selector) |> LazyHTML.attribute(name) |> List.first()

  defp text(html, selector), do: html |> doc() |> LazyHTML.query(selector) |> LazyHTML.text()

  describe "format/3" do
    test "words an instant in the zone, 24-hour clock" do
      assert T.format(@at, :day_time, "Asia/Kolkata") == "Mon 5 Oct, 14:30 IST"
      assert T.format(@at, :full, "Asia/Kolkata") == "5 Oct 2026, 14:30 IST"
      assert T.format(@at, :date_time, "Asia/Kolkata") == "5 Oct, 14:30"
      assert T.format(@at, :time, "Asia/Kolkata") == "14:30"
      assert T.format(@at, :date, "Asia/Kolkata") == "5 Oct 2026"
      assert T.format(@at, :short, "Asia/Kolkata") == "5 Oct"
      assert T.format(@at, :long, "Asia/Kolkata") == "5 October 2026"
      assert T.format(@at, :day, "Asia/Kolkata") == "Mon 5 Oct"
      assert T.format(@at, :month, "Asia/Kolkata") == "October 2026"
    end

    test "the zone moves the day" do
      late = ~U[2026-10-05 20:00:00Z]
      assert T.format(late, :day_time, "Asia/Kolkata") == "Tue 6 Oct, 01:30 IST"
      assert T.format(late, :day_time, "America/Los_Angeles") == "Mon 5 Oct, 13:00 PDT"
      assert T.format(late, :day_time, "Etc/UTC") == "Mon 5 Oct, 20:00 UTC"
    end

    test "a Date reads as its day and a NaiveDateTime has no zone words" do
      assert T.format(~D[2026-10-05], :day_time, "Asia/Kolkata") == "5 Oct 2026"
      assert T.format(~D[2026-10-05], :day, nil) == "Mon 5 Oct"
      assert T.format(~N[2026-10-05 14:30:00], :day_time, nil) == "Mon 5 Oct, 14:30"
    end

    test "nil is empty" do
      assert T.format(nil, :date, "Asia/Kolkata") == ""
    end

    test "an instant without a zone raises" do
      assert_raise ArgumentError, ~r/needs the place's zone/, fn -> T.format(@at, :date, nil) end
    end

    test "an unknown format and an unknown zone raise" do
      assert_raise ArgumentError, ~r/unknown time format :nope/, fn ->
        T.format(@at, :nope, "Etc/UTC")
      end

      assert_raise ArgumentError, ~r/unknown time zone "Mars\/Base"/, fn ->
        T.format(@at, :date, "Mars/Base")
      end
    end

    test "without a time zone database it names the missing config" do
      error =
        assert_raise ArgumentError, fn ->
          T.format(@at, :day_time, "Asia/Kolkata",
            time_zone_database: Calendar.UTCOnlyTimeZoneDatabase
          )
        end

      assert error.message =~ "config :elixir, :time_zone_database, Tz.TimeZoneDatabase"
      assert error.message =~ ~s("Asia/Kolkata")

      # UTC needs none.
      assert T.format(@at, :day_time, "Etc/UTC",
               time_zone_database: Calendar.UTCOnlyTimeZoneDatabase
             ) ==
               "Mon 5 Oct, 09:00 UTC"
    end
  end

  describe "relative_words/2" do
    test "long" do
      assert T.relative_words(10, :long) == "now"
      assert T.relative_words(-59, :long) == "now"
      assert T.relative_words(60, :long) == "1 minute ago"
      assert T.relative_words(300, :long) == "5 minutes ago"
      assert T.relative_words(3 * 3600, :long) == "3 hours ago"
      assert T.relative_words(86_400, :long) == "1 day ago"
      assert T.relative_words(-2 * 86_400, :long) == "in 2 days"
      assert T.relative_words(-3600, :long) == "in 1 hour"
    end

    test "short" do
      assert T.relative_words(10, :short) == "now"
      assert T.relative_words(300, :short) == "5m"
      assert T.relative_words(3 * 3600, :short) == "3h"
      assert T.relative_words(2 * 86_400, :short) == "2d"
      assert T.relative_words(-2 * 86_400, :short) == "in 2d"
    end
  end

  describe "relative_time/1" do
    test "renders the final words in a <time> with datetime, title and hook data" do
      assigns = %{at: @at, now: @now}

      html =
        rendered_to_string(
          ~H|<T.relative_time id="t1" at={@at} now={@now} zone="Asia/Kolkata" />|
        )

      assert text(html, "time#t1") == "3 hours ago"
      assert attribute(html, "time", "datetime") == "2026-10-05T09:00:00Z"
      assert attribute(html, "time", "title") == "5 Oct 2026, 14:30 IST"
      assert attribute(html, "time", "phx-hook") == "SutraUI.Time.RelativeTime"
      assert attribute(html, "time", "data-length") == "long"
      assert attribute(html, "time", "data-until") == "604800"
      refute html =~ "<script"
    end

    test "short style" do
      assigns = %{at: @at, now: @now}
      html = rendered_to_string(~H|<T.relative_time at={@at} now={@now} length={:short} />|)
      assert text(html, "time") == "3h"
      assert attribute(html, "time", "data-length") == "short"
    end

    test "a future instant reads 'in'" do
      assigns = %{at: DateTime.add(@now, 2 * 86_400), now: @now}

      assert text(rendered_to_string(~H|<T.relative_time at={@at} now={@now} />|), "time") ==
               "in 2 days"
    end

    test "past `until` it shows the date in the zone: short in the year, with the year before" do
      assigns = %{old: ~U[2026-09-01 09:00:00Z], older: ~U[2025-09-01 09:00:00Z], now: @now}
      html = rendered_to_string(~H|<T.relative_time at={@old} now={@now} zone="Asia/Kolkata" />|)
      assert text(html, "time") == "1 Sep"

      html =
        rendered_to_string(~H|<T.relative_time at={@older} now={@now} zone="Asia/Kolkata" />|)

      assert text(html, "time") == "1 Sep 2025"
    end

    test "until is configurable" do
      assigns = %{at: ~U[2026-10-05 08:00:00Z], now: @now}

      html =
        rendered_to_string(
          ~H|<T.relative_time at={@at} now={@now} until={3600} zone="Etc/UTC" />|
        )

      assert text(html, "time") == "5 Oct"
      assert attribute(html, "time", "data-until") == "3600"
    end

    test "the id is stable for the same values and differs for different ones" do
      assigns = %{a: @at, b: ~U[2026-10-05 08:00:00Z], now: @now}
      one = rendered_to_string(~H|<T.relative_time at={@a} now={@now} />|)
      two = rendered_to_string(~H|<T.relative_time at={@a} now={@now} />|)
      other = rendered_to_string(~H|<T.relative_time at={@b} now={@now} />|)

      assert attribute(one, "time", "id") == attribute(two, "time", "id")
      refute attribute(one, "time", "id") == attribute(other, "time", "id")
    end
  end

  describe "local_time/1" do
    test "an instant shows in the zone with a hook and the hint on" do
      assigns = %{at: @at}

      html =
        rendered_to_string(
          ~H|<T.local_time id="t2" at={@at} format={:day_time} zone="Asia/Kolkata" />|
        )

      assert text(html, "time#t2") == "Mon 5 Oct, 14:30 IST"
      assert attribute(html, "time", "datetime") == "2026-10-05T09:00:00Z"
      assert attribute(html, "time", "title") == "5 Oct 2026, 14:30 IST"
      assert attribute(html, "time", "phx-hook") == "SutraUI.Time.LocalTime"
      assert attribute(html, "time", "data-zone") == "Asia/Kolkata"
      assert attribute(html, "time", "data-hint") == "true"
      assert attribute(html, "time", "data-hint-label") == "your time"
    end

    test "hint can be turned off and relabelled" do
      assigns = %{at: @at}

      off =
        rendered_to_string(
          ~H|<T.local_time at={@at} format={:time} zone="Asia/Kolkata" hint={false} />|
        )

      assert attribute(off, "time", "data-hint") == "false"

      label =
        rendered_to_string(
          ~H|<T.local_time at={@at} format={:time} zone="Asia/Kolkata" hint_label="మీ సమయం" />|
        )

      assert attribute(label, "time", "data-hint-label") == "మీ సమయం"
    end

    test "a date-only format has no hook or hint" do
      assigns = %{at: @at}
      html = rendered_to_string(~H|<T.local_time at={@at} format={:date} zone="Asia/Kolkata" />|)
      assert text(html, "time") == "5 Oct 2026"
      assert attribute(html, "time", "phx-hook") == nil
      assert attribute(html, "time", "data-zone") == nil
    end

    test "the zone decides the day" do
      assigns = %{at: ~U[2026-10-05 20:00:00Z]}
      html = rendered_to_string(~H|<T.local_time at={@at} format={:day} zone="Asia/Kolkata" />|)
      assert text(html, "time") == "Tue 6 Oct"
    end

    test "a Date renders its day with a date datetime" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<T.local_time at={~D[2026-10-05]} format={:day} zone="Asia/Kolkata" />|
        )

      assert text(html, "time") == "Mon 5 Oct"
      assert attribute(html, "time", "datetime") == "2026-10-05"
      assert attribute(html, "time", "phx-hook") == nil
    end

    test "a missing zone raises" do
      assigns = %{at: @at}

      assert_raise ArgumentError, ~r/needs a zone/, fn ->
        rendered_to_string(~H|<T.local_time at={@at} zone={nil} />|)
      end
    end
  end
end
