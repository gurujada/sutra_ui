import assert from "node:assert/strict";
import { test } from "node:test";

import {
  FAST_MS,
  SLOW_MS,
  Ticker,
  applyViewerHint,
  formatDay,
  refreshRelative,
  relativeWords,
  viewerTime,
  zonesDiffer,
} from "./index.js";

const T0 = Date.parse("2026-10-05T09:00:00Z");

function timeEl(attrs = {}, data = {}, text = "") {
  const attributes = { ...attrs };
  return {
    dataset: { ...data },
    textContent: text,
    children: [],
    getAttribute: (name) => attributes[name] ?? null,
    setAttribute: (name, value) => (attributes[name] = value),
    querySelector() {
      return this.children.find((c) => c.dataset.viewerTime !== undefined) ?? null;
    },
    append(child) {
      child.remove = () => (this.children = this.children.filter((c) => c !== child));
      this.children.push(child);
    },
  };
}

test("relativeWords: long English", () => {
  assert.equal(relativeWords(10, "long", "en"), "now");
  assert.equal(relativeWords(60, "long", "en"), "1 minute ago");
  assert.equal(relativeWords(5 * 60, "long", "en"), "5 minutes ago");
  assert.equal(relativeWords(3 * 3600 + 5, "long", "en"), "3 hours ago");
  assert.equal(relativeWords(2 * 86400, "long", "en"), "2 days ago");
  assert.equal(relativeWords(-2 * 86400, "long", "en"), "in 2 days");
});

test("relativeWords: short English matches the server's words", () => {
  assert.equal(relativeWords(10, "short", "en"), "now");
  assert.equal(relativeWords(5 * 60, "short", "en"), "5m");
  assert.equal(relativeWords(3 * 3600, "short", "en"), "3h");
  assert.equal(relativeWords(2 * 86400, "short", "en"), "2d");
  assert.equal(relativeWords(-2 * 86400, "short", "en"), "in 2d");
});

test("relativeWords: another language comes from Intl", () => {
  assert.equal(relativeWords(3 * 3600, "long", "fr"), "il y a 3 heures");
});

test("refreshRelative rewrites the words and says when to run again", () => {
  const el = timeEl({ datetime: "2026-10-05T08:59:00Z" }, { length: "long" }, "1 minute ago");
  assert.equal(refreshRelative(el, T0 + 4 * 60_000, "en"), FAST_MS);
  assert.equal(el.textContent, "5 minutes ago");

  const old = timeEl({ datetime: "2026-10-05T05:00:00Z" }, { length: "short" });
  assert.equal(refreshRelative(old, T0, "en"), SLOW_MS);
  assert.equal(old.textContent, "4h");
});

test("refreshRelative leaves an element past `until` alone and reports it final", () => {
  const el = timeEl({ datetime: "2026-09-01T09:00:00Z" }, { until: "604800" }, "1 Sep");
  assert.equal(refreshRelative(el, T0, "en"), null);
  assert.equal(el.textContent, "1 Sep");
});

test("a future element past `until` turns to words once it is inside the window", () => {
  const el = timeEl({ datetime: "2026-10-12T08:00:00Z" }, { until: "604800" }, "Mon 12 Oct");
  assert.equal(refreshRelative(el, T0 - 2 * 86400_000, "en"), 3_600_000);
  assert.equal(el.textContent, "Mon 12 Oct");
  assert.equal(refreshRelative(el, T0, "en"), SLOW_MS);
  assert.equal(el.textContent, "in 6 days");
});

test("Ticker: one timer, fast while under an hour, then slow, then none", () => {
  let now = T0;
  const timers = [];
  const ticker = new Ticker({
    now: () => now,
    locale: () => "en",
    setTimer: (fn, ms) => (timers.push({ fn, ms }), timers.length),
    clearTimer: () => {},
  });

  const recent = timeEl({ datetime: "2026-10-05T08:59:30Z" }, { length: "long" });
  ticker.add(recent);
  assert.equal(timers.at(-1).ms, FAST_MS);
  assert.equal(recent.textContent, "now");

  now += 90_000;
  timers.at(-1).fn();
  assert.equal(recent.textContent, "2 minutes ago");

  now += 2 * 3600_000;
  timers.at(-1).fn();
  assert.equal(timers.at(-1).ms, SLOW_MS);

  const count = timers.length;
  now += 30 * 86400_000;
  timers.at(-1).fn();
  assert.equal(timers.length, count, "nothing is left to tick: no timer is set");
  assert.equal(ticker.timer, null);
});

test("Ticker.remove stops the timer when the last element goes", () => {
  const ticker = new Ticker({ now: () => T0, locale: () => "en", setTimer: () => 1, clearTimer: () => {} });
  const el = timeEl({ datetime: "2026-10-05T08:59:30Z" });
  ticker.add(el);
  assert.equal(ticker.timer, 1);
  ticker.remove(el);
  assert.equal(ticker.timer, null);
});

test("zonesDiffer compares wall time, not names", () => {
  const at = new Date("2026-10-05T09:00:00Z");
  assert.equal(zonesDiffer(at, "Asia/Kolkata", "Asia/Calcutta"), false);
  assert.equal(zonesDiffer(at, "Asia/Kolkata", "America/Los_Angeles"), true);
  assert.equal(zonesDiffer(at, "Not/AZone", "Asia/Kolkata"), false);
});

test("viewerTime adds the weekday only when the day differs", () => {
  const at = new Date("2026-10-05T18:00:00Z"); // Mon 23:30 in Kolkata
  assert.equal(viewerTime(at, "Asia/Kolkata", "Europe/London", "your time", "en"), "19:00 your time");
  assert.equal(viewerTime(at, "Asia/Kolkata", "Pacific/Auckland", "your time", "en"), "Tue 07:00 your time");
});

test("applyViewerHint sets the title and, with hint on, the visible words", () => {
  globalThis.document = { createElement: () => ({ dataset: {}, textContent: "" }) };
  const el = timeEl(
    { datetime: "2026-10-05T09:00:00Z", title: "Mon 5 Oct 2026, 14:30 IST" },
    { zone: "Asia/Kolkata", hint: "true" },
  );
  applyViewerHint(el, "en", "America/Los_Angeles");
  assert.equal(el.getAttribute("title"), "Mon 5 Oct 2026, 14:30 IST · 02:00 your time");
  assert.equal(el.children[0].textContent, " · 02:00 your time");

  // A second run (a LiveView patch) does not stack the words.
  applyViewerHint(el, "en", "America/Los_Angeles");
  assert.equal(el.getAttribute("title"), "Mon 5 Oct 2026, 14:30 IST · 02:00 your time");
  assert.equal(el.children.length, 1);

  // Same wall time: nothing added.
  const same = timeEl({ datetime: "2026-10-05T09:00:00Z", title: "x" }, { zone: "Asia/Kolkata", hint: "true" });
  applyViewerHint(same, "en", "Asia/Calcutta");
  assert.equal(same.getAttribute("title"), "x");
  assert.equal(same.children.length, 0);

  // Hint off: the title still carries it, no visible span.
  const quiet = timeEl({ datetime: "2026-10-05T09:00:00Z", title: "x" }, { zone: "Asia/Kolkata", hint: "false" });
  applyViewerHint(quiet, "en", "America/Los_Angeles");
  assert.equal(quiet.getAttribute("title"), "x · 02:00 your time");
  assert.equal(quiet.children.length, 0);
});

test("formatDay writes a day in the words of SutraUI.Time", () => {
  assert.equal(formatDay("2026-10-05"), "5 Oct 2026");
  assert.equal(formatDay("2026-10-05", "short"), "5 Oct");
  assert.equal(formatDay("2026-10-05", "long"), "5 October 2026");
  assert.equal(formatDay("2026-10-05", "day"), "Mon 5 Oct");
  assert.equal(formatDay("2026-10-05", "month"), "October 2026");
  assert.equal(formatDay("nonsense"), "");
});
