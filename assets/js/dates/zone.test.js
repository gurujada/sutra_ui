import { test } from "node:test";
import assert from "node:assert/strict";
import { fromISO, formatOffset, isoWithOffset, offsetAt, parseWall, resolveWall, wallAt, wallValue, zoneName } from "./zone.js";

const wall = (y, m, d, h, mi) => ({ y, m, d, h, mi });

test("offsets", () => {
  assert.equal(offsetAt("Asia/Kolkata", Date.UTC(2027, 2, 15)), 330);
  assert.equal(offsetAt("America/New_York", Date.UTC(2026, 0, 15)), -300);
  assert.equal(offsetAt("America/New_York", Date.UTC(2026, 6, 15)), -240);
  assert.equal(offsetAt("Etc/UTC", Date.UTC(2026, 6, 15)), 0);
});

test("formatOffset", () => {
  assert.equal(formatOffset(330), "+05:30");
  assert.equal(formatOffset(-240), "-04:00");
  assert.equal(formatOffset(0), "+00:00");
});

test("an ordinary wall time has one instant", () => {
  const r = resolveWall("Asia/Kolkata", wall(2027, 3, 15, 9, 0));
  assert.equal(r.kind, "ok");
  assert.equal(r.at.offset, 330);
  assert.equal(r.at.ms, Date.UTC(2027, 2, 15, 3, 30));
  assert.equal(isoWithOffset(wall(2027, 3, 15, 9, 0), r.at.offset), "2027-03-15T09:00:00+05:30");
});

test("the hour that clocks skip is a gap (New York, 8 Mar 2026)", () => {
  const r = resolveWall("America/New_York", wall(2026, 3, 8, 2, 30));
  assert.deepEqual(r, { kind: "gap", before: -300, after: -240 });
  assert.equal(resolveWall("America/New_York", wall(2026, 3, 8, 1, 59)).kind, "ok");
  assert.equal(resolveWall("America/New_York", wall(2026, 3, 8, 3, 0)).kind, "ok");
});

test("the hour that repeats is ambiguous, earliest first (New York, 1 Nov 2026)", () => {
  const r = resolveWall("America/New_York", wall(2026, 11, 1, 1, 30));
  assert.equal(r.kind, "ambiguous");
  assert.equal(r.first.offset, -240);
  assert.equal(r.second.offset, -300);
  assert.equal(r.second.ms - r.first.ms, 3_600_000);
  assert.equal(resolveWall("America/New_York", wall(2026, 11, 1, 2, 0)).kind, "ok");
  assert.equal(resolveWall("America/New_York", wall(2026, 11, 1, 0, 59)).kind, "ok");
});

test("a zone without clock changes never gaps", () => {
  for (let h = 0; h < 24; h++) assert.equal(resolveWall("Asia/Kolkata", wall(2026, 3, 8, h, 30)).kind, "ok");
});

test("wallAt and fromISO read an instant in a zone", () => {
  assert.deepEqual(wallAt("Asia/Kolkata", Date.UTC(2027, 2, 15, 3, 30)), wall(2027, 3, 15, 9, 0));
  assert.deepEqual(fromISO("2027-03-15T09:00:00+05:30", "America/New_York").wall, wall(2027, 3, 14, 23, 30));
  assert.equal(fromISO("nope", "Asia/Kolkata"), null);
});

test("wall values round-trip with the browser's datetime-local format", () => {
  assert.equal(wallValue(wall(2027, 3, 5, 9, 5)), "2027-03-05T09:05");
  assert.deepEqual(parseWall("2027-03-05T09:05"), wall(2027, 3, 5, 9, 5));
  assert.equal(parseWall(""), null);
});

test("zoneName", () => {
  assert.equal(zoneName("America/New_York", Date.UTC(2026, 6, 15)), "EDT");
  assert.equal(zoneName("America/New_York", Date.UTC(2026, 0, 15)), "EST");
  assert.equal(zoneName("Asia/Kolkata", Date.UTC(2026, 6, 15)), "IST");
});
