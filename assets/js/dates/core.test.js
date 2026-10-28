import { test } from "node:test";
import assert from "node:assert/strict";
import * as c from "./core.js";

test("parse accepts real days only", () => {
  assert.deepEqual(c.parse("2027-03-15"), { y: 2027, m: 3, d: 15 });
  assert.equal(c.parse("2027-02-29"), null);
  assert.equal(c.parse("2028-02-29")?.d, 29);
  assert.equal(c.parse("2027-13-01"), null);
  assert.equal(c.parse(""), null);
  assert.equal(c.parse(null), null);
});

test("addDays, diffDays and weekday work across month and year ends", () => {
  assert.equal(c.addDays("2026-12-31", 1), "2027-01-01");
  assert.equal(c.addDays("2027-03-01", -1), "2027-02-28");
  assert.equal(c.diffDays("2026-03-08", "2026-11-01"), 238);
  assert.equal(c.weekday("2026-11-01"), 7); // Sunday
  assert.equal(c.weekday("2026-03-09"), 1); // Monday
});

test("addMonths clamps the day", () => {
  assert.equal(c.addMonths("2027-01-31", 1), "2027-02-28");
  assert.equal(c.addMonths("2027-03-31", -1), "2027-02-28");
  assert.equal(c.addMonths("2027-12-15", 1), "2028-01-15");
  assert.equal(c.addYears("2028-02-29", 1), "2029-02-28");
});

test("monthGrid is six weeks that start on the chosen weekday and contain the month", () => {
  const grid = c.monthGrid(2026, 3, 1); // March 2026 starts on a Sunday
  assert.equal(grid.length, 6);
  assert.ok(grid.every((w) => w.length === 7));
  assert.equal(grid[0][0], "2026-02-23");
  assert.equal(grid[0][6], "2026-03-01");
  const sunday = c.monthGrid(2026, 3, 7);
  assert.equal(sunday[0][0], "2026-03-01");
  assert.ok(grid.flat().includes("2026-03-31"));
});

test("checkDate reports the first refusal", () => {
  const rules = { min: "2026-10-05", max: "2026-12-31", disabledDates: ["2026-10-20"], disabledWeekdays: [6, 7] };
  assert.equal(c.checkDate(rules, "2026-10-04"), "before_min");
  assert.equal(c.checkDate(rules, "2027-01-01"), "after_max");
  assert.equal(c.checkDate(rules, "2026-10-20"), "disabled_date");
  assert.equal(c.checkDate(rules, "2026-10-10"), "disabled_weekday"); // Saturday
  assert.equal(c.checkDate(rules, "2026-10-21"), null);
  assert.equal(c.checkDate(null, "2026-10-21"), null);
});

test("checkRange counts both ends and checks the order and length", () => {
  const rules = { minLength: 2, maxLength: 7 };
  assert.equal(c.rangeLength("2026-10-01", "2026-10-07"), 7);
  assert.equal(c.checkRange(rules, "2026-10-01", "2026-10-07"), null);
  assert.equal(c.checkRange(rules, "2026-10-01", "2026-10-08"), "too_long");
  assert.equal(c.checkRange(rules, "2026-10-01", "2026-10-01"), "too_short");
  assert.equal(c.checkRange({}, "2026-10-02", "2026-10-01"), "reversed");
  assert.equal(c.checkRange({ min: "2026-10-05" }, "2026-10-01", "2026-10-09"), "before_min");
});

test("endRefused greys days that would break the range length, not earlier ones", () => {
  const rules = { maxLength: 3 };
  assert.equal(c.endRefused(rules, "2026-10-01", "2026-10-03"), false);
  assert.equal(c.endRefused(rules, "2026-10-01", "2026-10-04"), true);
  assert.equal(c.endRefused(rules, "2026-10-05", "2026-10-01"), false); // restarts the range
});

test("checkTime follows the minute step", () => {
  assert.equal(c.checkTime({ step: 15 }, "09:30"), null);
  assert.equal(c.checkTime({ step: 15 }, "09:20"), "step");
  assert.equal(c.checkTime({}, "09:20"), null);
});

test("presets are relative to today", () => {
  const today = "2026-10-28"; // Wednesday
  assert.equal(c.presetValue("today", today), today);
  assert.equal(c.presetValue("tomorrow", today), "2026-10-29");
  assert.equal(c.presetValue("next_monday", today), "2026-11-02");
  assert.equal(c.presetValue("next_monday", "2026-11-02"), "2026-11-09");
  assert.equal(c.presetValue("end_of_week", today, 1), "2026-11-01");
  assert.equal(c.presetValue("end_of_week", today, 7), "2026-10-31");
  assert.equal(c.presetValue("end_of_month", today), "2026-10-31");
  assert.deepEqual(c.presetValue("last_7_days", today), { start: "2026-10-22", end: today });
  assert.deepEqual(c.presetValue("last_30_days", today), { start: "2026-09-29", end: today });
  assert.deepEqual(c.presetValue("this_month", today), { start: "2026-10-01", end: "2026-10-31" });
  assert.deepEqual(c.presetValue("last_month", today), { start: "2026-09-01", end: "2026-09-30" });
  assert.equal(c.presetValue("nope", today), null);
});

test("moveFocus follows the grid keys", () => {
  assert.equal(c.moveFocus("ArrowRight", false, "2026-10-31"), "2026-11-01");
  assert.equal(c.moveFocus("ArrowUp", false, "2026-10-08"), "2026-10-01");
  assert.equal(c.moveFocus("Home", false, "2026-10-28", 1), "2026-10-26");
  assert.equal(c.moveFocus("End", false, "2026-10-28", 1), "2026-11-01");
  assert.equal(c.moveFocus("PageDown", false, "2026-01-31"), "2026-02-28");
  assert.equal(c.moveFocus("PageUp", true, "2026-10-28"), "2025-10-28");
  assert.equal(c.moveFocus("a", false, "2026-10-28"), null);
});

test("names come from Intl in the locale", () => {
  assert.deepEqual(c.weekdayNames(1, "en-US").slice(0, 2), ["Mon", "Tue"]);
  assert.equal(c.weekdayNames(7, "en-US")[0], "Sun");
  assert.equal(c.monthNames("en-US")[2], "March");
});

test("reasonWords says why in plain words", () => {
  assert.equal(c.reasonWords("before_min", { min: "2026-10-05" }), "Not before 5 Oct 2026");
  assert.equal(c.reasonWords("too_long", { maxLength: 14 }), "At most 14 days");
  assert.equal(c.reasonWords("disabled_date", {}), "Not available");
});

test("a repeated hour is a warning until chosen; a skipped time is an error", () => {
  assert.deepEqual(c.fieldTone({ resolutionKind: "ambiguous" }), { invalid: false, warning: true });
  assert.deepEqual(c.fieldTone({ resolutionKind: "gap" }), { invalid: true, warning: false });
  assert.deepEqual(c.fieldTone({ resolutionKind: "ok" }), { invalid: false, warning: false });
  assert.deepEqual(c.fieldTone({ reason: "min", resolutionKind: "ambiguous" }), { invalid: true, warning: false });
  assert.deepEqual(c.fieldTone({ server: true, resolutionKind: "ambiguous" }), { invalid: true, warning: false });
});

