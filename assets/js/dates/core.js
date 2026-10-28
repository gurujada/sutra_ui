// Dates as plain strings ("2027-03-15"), so no time zone can move a day. All arithmetic runs
// in UTC on those strings; a zone only matters for instants (zone.js).

/** @typedef {{ today?: string, min?: string | null, max?: string | null, disabledDates?: string[], disabledWeekdays?: number[], minLength?: number | null, maxLength?: number | null, step?: number | null }} Rules */

export const pad = (n, width = 2) => String(n).padStart(width, "0");

/**
 * Split a valid ISO date; null when it is not a real calendar day.
 * @param {string} iso
 * @returns {{ y: number, m: number, d: number } | null}
 */
export function parse(iso) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(iso ?? ""));
  if (!match) return null;
  const [y, m, d] = [Number(match[1]), Number(match[2]), Number(match[3])];
  return m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(y, m) ? { y, m, d } : null;
}

/** @param {number} y @param {number} m @param {number} d */
export const toISO = (y, m, d) => `${pad(y, 4)}-${pad(m)}-${pad(d)}`;

/** @param {number} y @param {number} m 1-12 */
export const daysInMonth = (y, m) => new Date(Date.UTC(y, m, 0)).getUTCDate();

const utc = (iso) => {
  const p = parse(iso);
  return Date.UTC(p.y, p.m - 1, p.d);
};
const fromUtc = (ms) => {
  const d = new Date(ms);
  return toISO(d.getUTCFullYear(), d.getUTCMonth() + 1, d.getUTCDate());
};

/** @param {string} iso @param {number} n */
export const addDays = (iso, n) => fromUtc(utc(iso) + n * 86_400_000);

/** Whole days from `a` to `b` (negative when b is earlier). */
export const diffDays = (a, b) => Math.round((utc(b) - utc(a)) / 86_400_000);

/** ISO weekday: Monday is 1, Sunday is 7. */
export const weekday = (iso) => new Date(utc(iso)).getUTCDay() || 7;

/** Earlier is negative. Compares ISO strings. */
export const compare = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

/**
 * Months later (negative: earlier); the day is kept, or clamped to the month's last day.
 * @param {string} iso @param {number} n
 */
export function addMonths(iso, n) {
  const { y, m, d } = parse(iso);
  const index = y * 12 + (m - 1) + n;
  const year = Math.floor(index / 12);
  const month = (index % 12) + 1;
  return toISO(year, month, Math.min(d, daysInMonth(year, month)));
}

/** @param {string} iso @param {number} n */
export const addYears = (iso, n) => addMonths(iso, n * 12);

/** The first day of the week (1 Monday .. 7 Sunday) on or before `iso`. */
export function startOfWeek(iso, weekStart = 1) {
  return addDays(iso, -((weekday(iso) - weekStart + 7) % 7));
}

/**
 * The six weeks of a month grid, as ISO dates.
 * @param {number} y @param {number} m 1-12 @param {number} weekStart 1 Monday .. 7 Sunday
 * @returns {string[][]}
 */
export function monthGrid(y, m, weekStart = 1) {
  const first = startOfWeek(toISO(y, m, 1), weekStart);
  return Array.from({ length: 6 }, (_, w) => Array.from({ length: 7 }, (_, d) => addDays(first, w * 7 + d)));
}

// ── Rules ──────────────────────────────────────────────────────────────────

/**
 * Why a day is refused, or null. The reasons are the server's (SutraUI.DateRules).
 * @param {Rules} rules @param {string} iso
 * @returns {"before_min" | "after_max" | "disabled_date" | "disabled_weekday" | null}
 */
export function checkDate(rules, iso) {
  if (!rules) return null;
  if (rules.min && iso < rules.min) return "before_min";
  if (rules.max && iso > rules.max) return "after_max";
  if (rules.disabledDates?.includes(iso)) return "disabled_date";
  if (rules.disabledWeekdays?.includes(weekday(iso))) return "disabled_weekday";
  return null;
}

/** Days in a range, both ends counted. */
export const rangeLength = (start, end) => diffDays(start, end) + 1;

/**
 * Why a range is refused, or null.
 * @param {Rules} rules @param {string} start @param {string} end
 * @returns {ReturnType<typeof checkDate> | "reversed" | "too_short" | "too_long"}
 */
export function checkRange(rules, start, end) {
  const day = checkDate(rules, start) ?? checkDate(rules, end);
  if (day) return day;
  const length = rangeLength(start, end);
  if (length < 1) return "reversed";
  if (rules?.minLength && length < rules.minLength) return "too_short";
  if (rules?.maxLength && length > rules.maxLength) return "too_long";
  return null;
}

/**
 * Whether choosing `iso` as the end of a range that starts at `start` would be refused, for
 * greying days out while a range is being drawn.
 */
export function endRefused(rules, start, iso) {
  if (iso < start) return false; // choosing it restarts the range
  return checkRange(rules, start, iso) !== null;
}

/** Why a time ("09:30") is refused, or null: only the minute step applies. */
export function checkTime(rules, hhmm) {
  const step = rules?.step;
  if (!step || step <= 1) return null;
  const [h, m] = hhmm.split(":").map(Number);
  return (h * 60 + m) % step === 0 ? null : "step";
}

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

/** Words for a refusal, as the field's note. */
export function reasonWords(reason, rules) {
  switch (reason) {
    case "before_min": return `Not before ${shortDate(rules.min)}`;
    case "after_max": return `Not after ${shortDate(rules.max)}`;
    case "disabled_date": return "Not available";
    case "disabled_weekday": return "Not available on this weekday";
    case "reversed": return "The end is before the start";
    case "too_short": return `At least ${rules.minLength} days`;
    case "too_long": return `At most ${rules.maxLength} days`;
    case "step": return `Every ${rules.step} minutes`;
    default: return "";
  }
}

/** "5 Oct 2026" */
export function shortDate(iso) {
  const p = parse(iso);
  return p ? `${p.d} ${MONTHS[p.m - 1].slice(0, 3)} ${p.y}` : "";
}

export const monthName = (m) => MONTHS[m - 1];

// ── Presets ────────────────────────────────────────────────────────────────

/** The labels of the presets the library knows; apps add their own with a value. */
export const PRESET_LABELS = {
  today: "Today",
  tomorrow: "Tomorrow",
  next_monday: "Next Monday",
  end_of_week: "End of week",
  end_of_month: "End of month",
  last_7_days: "Last 7 days",
  last_30_days: "Last 30 days",
  this_week: "This week",
  this_month: "This month",
  last_month: "Last month",
};

/**
 * The day (or range) a preset stands for today. Relative keys stay relative: a shared link
 * with `last_7_days` always means the 7 days up to the day it is opened.
 * @param {string} key
 * @param {string} today ISO
 * @param {number} weekStart 1 Monday .. 7 Sunday
 * @returns {string | { start: string, end: string } | null}
 */
export function presetValue(key, today, weekStart = 1) {
  const { y, m } = parse(today);
  switch (key) {
    case "today": return today;
    case "tomorrow": return addDays(today, 1);
    case "next_monday": return addDays(today, 8 - weekday(today));
    case "end_of_week": return addDays(startOfWeek(today, weekStart), 6);
    case "end_of_month": return toISO(y, m, daysInMonth(y, m));
    case "last_7_days": return { start: addDays(today, -6), end: today };
    case "last_30_days": return { start: addDays(today, -29), end: today };
    case "this_week": {
      const start = startOfWeek(today, weekStart);
      return { start, end: addDays(start, 6) };
    }
    case "this_month": return { start: toISO(y, m, 1), end: toISO(y, m, daysInMonth(y, m)) };
    case "last_month": {
      const first = addMonths(toISO(y, m, 1), -1);
      const p = parse(first);
      return { start: first, end: toISO(p.y, p.m, daysInMonth(p.y, p.m)) };
    }
    default: return null;
  }
}

// ── Calendar keys ──────────────────────────────────────────────────────────

/**
 * Where a key moves the focused day in the grid (the WAI-ARIA grid keys); null for any
 * other key.
 * @param {string} key @param {boolean} shift @param {string} iso @param {number} weekStart
 */
export function moveFocus(key, shift, iso, weekStart = 1) {
  switch (key) {
    case "ArrowLeft": return addDays(iso, -1);
    case "ArrowRight": return addDays(iso, 1);
    case "ArrowUp": return addDays(iso, -7);
    case "ArrowDown": return addDays(iso, 7);
    case "Home": return startOfWeek(iso, weekStart);
    case "End": return addDays(startOfWeek(iso, weekStart), 6);
    case "PageUp": return shift ? addYears(iso, -1) : addMonths(iso, -1);
    case "PageDown": return shift ? addYears(iso, 1) : addMonths(iso, 1);
    default: return null;
  }
}

/** The weekday headers, from `weekStart`, in `locale` (short names). */
export function weekdayNames(weekStart = 1, locale) {
  const fmt = new Intl.DateTimeFormat(locale, { weekday: "short", timeZone: "UTC" });
  // 2024-01-01 is a Monday.
  return Array.from({ length: 7 }, (_, i) => fmt.format(new Date(Date.UTC(2024, 0, 1 + ((weekStart - 1 + i) % 7)))));
}

/** Month names in `locale`. */
export function monthNames(locale, style = "long") {
  const fmt = new Intl.DateTimeFormat(locale, { month: style, timeZone: "UTC" });
  return Array.from({ length: 12 }, (_, i) => fmt.format(new Date(Date.UTC(2024, i, 1))));
}
