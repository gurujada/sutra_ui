// Wall-clock time in a named zone, from the browser's Intl (no time zone database shipped).
// A clock change makes some wall times ambiguous; they are reported, never guessed, the way
// SutraUI.Time.from_wall/3 reports them on the server.

import { pad } from "./core.js";

const formatters = new Map();

function formatter(zone) {
  let f = formatters.get(zone);
  if (!f) {
    f = new Intl.DateTimeFormat("en-US", {
      timeZone: zone,
      hourCycle: "h23",
      year: "numeric",
      month: "numeric",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      second: "numeric",
    });
    formatters.set(zone, f);
  }
  return f;
}

/**
 * The offset of `zone` from UTC at an instant, in minutes (Asia/Kolkata is 330).
 * @param {string} zone @param {number} ms
 */
export function offsetAt(zone, ms) {
  const p = {};
  for (const { type, value } of formatter(zone).formatToParts(new Date(ms))) p[type] = Number(value);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour % 24, p.minute, p.second);
  return Math.round((asUtc - Math.floor(ms / 1000) * 1000) / 60_000);
}

/** "+05:30", "-04:00" */
export function formatOffset(minutes) {
  const sign = minutes < 0 ? "-" : "+";
  const abs = Math.abs(minutes);
  return `${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
}

/** @typedef {{ y: number, m: number, d: number, h: number, mi: number }} Wall */
/** @typedef {{ ms: number, offset: number }} Instant */

/**
 * The instants a wall-clock time can mean in a zone.
 * @param {string} zone
 * @param {Wall} wall
 * @returns {{ kind: "ok", at: Instant }
 *   | { kind: "ambiguous", first: Instant, second: Instant }
 *   | { kind: "gap", before: number, after: number }}
 */
export function resolveWall(zone, wall) {
  const asUtc = Date.UTC(wall.y, wall.m - 1, wall.d, wall.h, wall.mi);
  const day = 86_400_000;
  const before = offsetAt(zone, asUtc - day);
  const after = offsetAt(zone, asUtc + day);
  const offsets = [...new Set([before, after])];

  /** @type {Instant[]} */
  const valid = [];
  for (const offset of offsets) {
    const ms = asUtc - offset * 60_000;
    if (offsetAt(zone, ms) === offset) valid.push({ ms, offset });
  }
  valid.sort((a, b) => a.ms - b.ms);
  if (valid.length === 1) return { kind: "ok", at: valid[0] };
  if (valid.length === 2) return { kind: "ambiguous", first: valid[0], second: valid[1] };
  return { kind: "gap", before, after };
}

/**
 * "2027-03-15T09:00:00+05:30"
 * @param {Wall} wall @param {number} offset minutes
 */
export function isoWithOffset(wall, offset) {
  return `${pad(wall.y, 4)}-${pad(wall.m)}-${pad(wall.d)}T${pad(wall.h)}:${pad(wall.mi)}:00${formatOffset(offset)}`;
}

/**
 * The wall time of an instant in a zone.
 * @param {string} zone @param {number} ms
 * @returns {Wall}
 */
export function wallAt(zone, ms) {
  const p = {};
  for (const { type, value } of formatter(zone).formatToParts(new Date(ms))) p[type] = Number(value);
  return { y: p.year, m: p.month, d: p.day, h: p.hour % 24, mi: p.minute };
}

/** The zone's short name at an instant ("IST", "EDT"), or its offset when it has none. */
export function zoneName(zone, ms, locale = "en-US") {
  const part = new Intl.DateTimeFormat(locale, { timeZone: zone, timeZoneName: "short" })
    .formatToParts(new Date(ms))
    .find((p) => p.type === "timeZoneName");
  const text = part?.value ?? "";
  if (/^GMT[+-]/.test(text) && locale !== "en-IN" && zone === "Asia/Kolkata") return "IST";
  return text || formatOffset(offsetAt(zone, ms));
}

/**
 * Parse an ISO datetime with an offset to its wall time in `zone`.
 * @param {string} iso @param {string} zone
 * @returns {{ wall: Wall, ms: number } | null}
 */
export function fromISO(iso, zone) {
  const ms = Date.parse(iso);
  return Number.isNaN(ms) ? null : { wall: wallAt(zone, ms), ms };
}

/** A wall time as the browser's datetime-local value: "2027-03-15T09:00". */
export const wallValue = (w) => `${pad(w.y, 4)}-${pad(w.m)}-${pad(w.d)}T${pad(w.h)}:${pad(w.mi)}`;

/** Read "2027-03-15T09:00" into a wall time, or null. */
export function parseWall(value) {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(value ?? "");
  return m ? { y: +m[1], m: +m[2], d: +m[3], h: +m[4], mi: +m[5] } : null;
}
