defmodule SutraUI.TimeWallTest do
  use ExUnit.Case, async: true

  alias SutraUI.Time, as: T

  describe "from_wall/3" do
    test "an ordinary wall time is one instant" do
      assert {:ok, dt} = T.from_wall(~N[2027-03-15 09:00:00], "Asia/Kolkata")
      assert DateTime.to_iso8601(dt) == "2027-03-15T09:00:00+05:30"
    end

    test "the hour clocks skip is a gap (New York, 8 Mar 2026)" do
      assert {:gap, before, after_gap} = T.from_wall(~N[2026-03-08 02:30:00], "America/New_York")
      assert before.utc_offset + before.std_offset == -5 * 3600
      assert after_gap.utc_offset + after_gap.std_offset == -4 * 3600
    end

    test "the hour that repeats is ambiguous, earlier first (New York, 1 Nov 2026)" do
      assert {:ambiguous, first, second} =
               T.from_wall(~N[2026-11-01 01:30:00], "America/New_York")

      assert first.zone_abbr == "EDT"
      assert second.zone_abbr == "EST"
      assert DateTime.diff(second, first) == 3600
    end

    test "an unknown zone raises" do
      assert_raise ArgumentError, ~r/unknown time zone/, fn ->
        T.from_wall(~N[2027-03-15 09:00:00], "Mars/Base")
      end
    end
  end

  describe "parse_datetime/3" do
    test "a string with an offset is exact, and shown in the zone" do
      assert {:ok, dt} = T.parse_datetime("2027-03-15T09:00:00+05:30", "Asia/Kolkata")
      assert dt.hour == 9 and dt.zone_abbr == "IST"
      assert {:ok, ny} = T.parse_datetime("2027-03-15T09:00:00+05:30", "America/New_York")
      assert ny.hour == 23 and ny.day == 14
    end

    test "the browser's wall time without an offset is read in the zone" do
      assert {:ok, dt} = T.parse_datetime("2027-03-15T09:00", "Asia/Kolkata")
      assert DateTime.to_iso8601(dt) == "2027-03-15T09:00:00+05:30"
    end

    test "an offset tells the two repeated hours apart" do
      assert {:ambiguous, _, _} = T.parse_datetime("2026-11-01T01:30", "America/New_York")
      assert {:ok, first} = T.parse_datetime("2026-11-01T01:30:00-04:00", "America/New_York")
      assert {:ok, second} = T.parse_datetime("2026-11-01T01:30:00-05:00", "America/New_York")
      assert first.zone_abbr == "EDT" and second.zone_abbr == "EST"
    end

    test "a gap is reported" do
      assert {:gap, _, _} = T.parse_datetime("2026-03-08T02:30", "America/New_York")
    end

    test "nothing or nonsense is invalid" do
      assert T.parse_datetime(nil, "Asia/Kolkata") == {:error, :invalid}
      assert T.parse_datetime("", "Asia/Kolkata") == {:error, :invalid}
      assert T.parse_datetime("soon", "Asia/Kolkata") == {:error, :invalid}
    end
  end
end
