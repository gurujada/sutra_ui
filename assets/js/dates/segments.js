// The segmented field: what typing, the arrow keys and paste do to one segment ("DD", "MM",
// "YYYY", "HH", "mm"). Pure functions; the DOM half is in index.js.

import { daysInMonth, parse, pad, toISO } from "./core.js";

/**
 * @typedef {{ type: "day" | "month" | "year" | "hour" | "minute", min: number, max: number, digits: number, step?: number }} Spec
 */

/** @type {Record<string, Spec>} */
export const SPECS = {
  day: { type: "day", min: 1, max: 31, digits: 2 },
  month: { type: "month", min: 1, max: 12, digits: 2 },
  year: { type: "year", min: 1, max: 9999, digits: 4 },
  hour: { type: "hour", min: 0, max: 23, digits: 2 },
  minute: { type: "minute", min: 0, max: 59, digits: 2 },
};

/**
 * The order of the date segments in a locale, with its separator: `en-US` is month, day,
 * year with "/"; `en-GB` is day, month, year.
 * @param {string | undefined} locale
 * @returns {{ order: ("day" | "month" | "year")[], separator: string }}
 */
export function localeOrder(locale) {
  const parts = new Intl.DateTimeFormat(locale, { year: "numeric", month: "2-digit", day: "2-digit", timeZone: "UTC" })
    .formatToParts(new Date(Date.UTC(2024, 10, 22)));
  const order = parts.filter((p) => ["day", "month", "year"].includes(p.type)).map((p) => /** @type {any} */ (p.type));
  const separator = parts.find((p) => p.type === "literal")?.value.trim() || "/";
  return { order, separator };
}

/**
 * Type one digit into a segment. A segment takes digits until it is full or no further digit
 * could make a valid value ("4" in a month cannot become 4x), then asks to move on.
 * @param {Spec} spec
 * @param {string} buffer the digits typed since the segment was focused
 * @param {string} digit
 * @returns {{ buffer: string, value: number, advance: boolean }}
 */
export function typeDigit(spec, buffer, digit) {
  let next = buffer + digit;
  if (next.length > spec.digits) next = digit;
  let value = Number(next);
  if (spec.type !== "year" && value > spec.max) {
    // 3 then 5 in a month: "35" is no month, so 5 replaces 3.
    next = digit;
    value = Number(digit);
  }
  const full = next.length >= spec.digits;
  const nothingFits = spec.type !== "year" && value * 10 > spec.max;
  return { buffer: next, value, advance: full || nothingFits };
}

/**
 * The value after an arrow key; it wraps around inside the segment's range.
 * @param {Spec} spec @param {number | null} value @param {1 | -1} dir
 */
export function step(spec, value, dir) {
  const by = spec.step && spec.step > 1 ? spec.step : 1;
  if (value === null || Number.isNaN(value)) return dir > 0 ? spec.min : spec.max - ((spec.max - spec.min) % by);
  if (spec.type === "year") return Math.min(spec.max, Math.max(spec.min, value + dir));
  const span = spec.max - spec.min + 1;
  const aligned = spec.step && spec.step > 1 ? Math.round(value / by) * by : value;
  let next = aligned + dir * by;
  if (next > spec.max) next = spec.min;
  if (next < spec.min) next = spec.max - ((spec.max - spec.min) % by);
  return ((next - spec.min + span) % span) + spec.min;
}

/** The text a segment shows. */
export const display = (spec, value) => (value === null || value === undefined ? "" : pad(value, spec.digits));

/**
 * A complete ISO date from the three segment values, or null while any is missing or the
 * combination is no day (31 February).
 */
export function assemble(day, month, year) {
  if ([day, month, year].some((v) => v === null || v === undefined || Number.isNaN(v))) return null;
  return parse(toISO(year, month, day)) ? toISO(year, month, day) : null;
}

/** The last valid day number for a month, for clamping the day when the month changes. */
export const clampDay = (day, month, year) => (day === null ? null : Math.min(day, daysInMonth(year ?? 2024, month ?? 1)));

/**
 * Read pasted text as a date: ISO ("2027-03-15"), or three numbers in the locale's order
 * ("15/03/2027", "3-15-2027", "15.3.2027").
 * @param {string} text
 * @param {("day" | "month" | "year")[]} order
 * @returns {string | null}
 */
export function parseDateText(text, order) {
  const t = text.trim();
  const iso = /^(\d{4})-(\d{1,2})-(\d{1,2})/.exec(t);
  if (iso) return assemble(Number(iso[3]), Number(iso[2]), Number(iso[1]));
  const nums = t.match(/\d+/g);
  if (!nums || nums.length < 3) return null;
  const by = {};
  order.forEach((type, i) => (by[type] = Number(nums[i])));
  if (by.year < 100) by.year += 2000;
  return assemble(by.day, by.month, by.year);
}

/** Read pasted text as a time: "9:30", "09:30", "0930". */
export function parseTimeText(text) {
  const t = text.trim();
  const m = /^(\d{1,2})[:.h ]?(\d{2})$/.exec(t) || /^(\d{1,2})$/.exec(t);
  if (!m) return null;
  const h = Number(m[1]);
  const mi = m[2] === undefined ? 0 : Number(m[2]);
  return h <= 23 && mi <= 59 ? `${pad(h)}:${pad(mi)}` : null;
}
