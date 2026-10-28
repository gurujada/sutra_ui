import { test } from "node:test";
import assert from "node:assert/strict";
import { SPECS, assemble, display, localeOrder, parseDateText, parseTimeText, step, typeDigit } from "./segments.js";

test("localeOrder follows the locale", () => {
  assert.deepEqual(localeOrder("en-US").order, ["month", "day", "year"]);
  assert.deepEqual(localeOrder("en-GB").order, ["day", "month", "year"]);
  assert.deepEqual(localeOrder("ja-JP").order, ["year", "month", "day"]);
  assert.equal(localeOrder("en-GB").separator, "/");
  assert.equal(localeOrder("de-DE").separator, ".");
});

test("a day takes two digits, then moves on", () => {
  let r = typeDigit(SPECS.day, "", "1");
  assert.deepEqual(r, { buffer: "1", value: 1, advance: false });
  r = typeDigit(SPECS.day, r.buffer, "5");
  assert.deepEqual(r, { buffer: "15", value: 15, advance: true });
});

test("a digit that cannot start a longer value moves on at once", () => {
  assert.equal(typeDigit(SPECS.day, "", "4").advance, true); // no day 4x
  assert.equal(typeDigit(SPECS.day, "", "3").advance, false); // 30, 31
  assert.equal(typeDigit(SPECS.month, "", "2").advance, true);
  assert.equal(typeDigit(SPECS.month, "", "1").advance, false);
  assert.equal(typeDigit(SPECS.hour, "", "3").advance, true);
});

test("a second digit that makes no value starts over", () => {
  const r = typeDigit(SPECS.month, "1", "5"); // 15 is no month
  assert.deepEqual(r, { buffer: "5", value: 5, advance: true });
});

test("a year takes four digits", () => {
  let r = typeDigit(SPECS.year, "", "2");
  for (const d of ["0", "2"]) r = typeDigit(SPECS.year, r.buffer, d);
  assert.equal(r.advance, false);
  r = typeDigit(SPECS.year, r.buffer, "7");
  assert.deepEqual(r, { buffer: "2027", value: 2027, advance: true });
});

test("arrow keys wrap inside the segment and start from the edge when empty", () => {
  assert.equal(step(SPECS.month, 12, 1), 1);
  assert.equal(step(SPECS.month, 1, -1), 12);
  assert.equal(step(SPECS.day, null, 1), 1);
  assert.equal(step(SPECS.day, null, -1), 31);
  assert.equal(step(SPECS.year, 2027, 1), 2028);
  assert.equal(step(SPECS.hour, 23, 1), 0);
});

test("the minute step moves by the step", () => {
  const spec = { ...SPECS.minute, step: 15 };
  assert.equal(step(spec, 0, 1), 15);
  assert.equal(step(spec, 45, 1), 0);
  assert.equal(step(spec, 0, -1), 45);
  assert.equal(step(spec, 7, 1), 15);
});

test("assemble needs every segment and a real day", () => {
  assert.equal(assemble(15, 3, 2027), "2027-03-15");
  assert.equal(assemble(31, 2, 2027), null);
  assert.equal(assemble(null, 3, 2027), null);
  assert.equal(display(SPECS.day, 5), "05");
  assert.equal(display(SPECS.year, 27), "0027");
  assert.equal(display(SPECS.day, null), "");
});

test("paste reads ISO and the locale's order", () => {
  assert.equal(parseDateText("2027-03-15", ["month", "day", "year"]), "2027-03-15");
  assert.equal(parseDateText("03/15/2027", ["month", "day", "year"]), "2027-03-15");
  assert.equal(parseDateText("15.3.2027", ["day", "month", "year"]), "2027-03-15");
  assert.equal(parseDateText("15/03/27", ["day", "month", "year"]), "2027-03-15");
  assert.equal(parseDateText("31/02/2027", ["day", "month", "year"]), null);
  assert.equal(parseDateText("hello", ["day", "month", "year"]), null);
});

test("paste reads times", () => {
  assert.equal(parseTimeText("9:30"), "09:30");
  assert.equal(parseTimeText("0930"), "09:30");
  assert.equal(parseTimeText("14"), "14:00");
  assert.equal(parseTimeText("25:00"), null);
  assert.equal(parseTimeText("x"), null);
});
