// Times shown to people: the browser half of SutraUI.Time.
//
// The server renders final English words inside <time datetime title>. This module only
// improves them: relative words are refreshed by one shared page timer (Intl in the page's
// language), and an absolute time gets the viewer's own time added when the browser's zone
// differs from the place's. Nothing here is needed for a correct first paint.

/** @typedef {"long" | "short"} Style */

const MINUTE = 60;
const HOUR = 3600;
const DAY = 86400;

/** Re-render interval while an element is under an hour, then after (milliseconds). */
export const FAST_MS = 30_000;
export const SLOW_MS = 300_000;

/**
 * The page's language: `<html lang>`, then the browser's.
 * @returns {string | undefined}
 */
export function pageLocale() {
  const lang = globalThis.document?.documentElement?.lang;
  return lang || globalThis.navigator?.language || undefined;
}

/**
 * The words for an instant `seconds` ago (negative: in the future).
 * @param {number} seconds
 * @param {Style} style
 * @param {string | undefined} locale
 * @returns {string}
 */
export function relativeWords(seconds, style, locale) {
  const future = seconds < 0;
  const abs = Math.abs(seconds);

  if (abs < MINUTE) return nowWord(locale);

  let value;
  let unit;
  if (abs < HOUR) [value, unit] = [Math.floor(abs / MINUTE), "minute"];
  else if (abs < DAY) [value, unit] = [Math.floor(abs / HOUR), "hour"];
  else [value, unit] = [Math.floor(abs / DAY), "day"];

  if (style === "short" && isEnglish(locale)) {
    const compact = `${value}${unit === "minute" ? "m" : unit === "hour" ? "h" : "d"}`;
    return future ? `in ${compact}` : compact;
  }

  const rtf = new Intl.RelativeTimeFormat(locale, {
    numeric: "always",
    style: style === "short" ? "narrow" : "long",
  });
  return rtf.format(future ? value : -value, unit);
}

function nowWord(locale) {
  if (isEnglish(locale)) return "now";
  return new Intl.RelativeTimeFormat(locale, { numeric: "auto" }).format(0, "second");
}

function isEnglish(locale) {
  return !locale || locale.toLowerCase().startsWith("en");
}

/**
 * Whether a viewer in `viewerZone` sees a different wall time than `zone` at `at`.
 * Two names for the same offset (Asia/Kolkata, Asia/Calcutta) are not different.
 * @param {Date} at
 * @param {string} zone
 * @param {string} viewerZone
 * @returns {boolean}
 */
export function zonesDiffer(at, zone, viewerZone) {
  try {
    return wall(at, zone) !== wall(at, viewerZone);
  } catch {
    return false;
  }
}

function wall(at, zone) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: zone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(at);
}

/**
 * The viewer's time as a short phrase: "23:30 your time", with the weekday ("Sun 23:30
 * your time") when it falls on another day than the place's.
 * @param {Date} at
 * @param {string} zone the place's zone
 * @param {string} viewerZone
 * @param {string} label the words after the time ("your time")
 * @param {string | undefined} locale
 * @returns {string}
 */
export function viewerTime(at, zone, viewerZone, label, locale) {
  const day = (z) => new Intl.DateTimeFormat("en-CA", { timeZone: z }).format(at);
  const clock = new Intl.DateTimeFormat(locale, {
    timeZone: viewerZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(at);
  const weekday =
    day(zone) === day(viewerZone)
      ? ""
      : new Intl.DateTimeFormat(locale, { timeZone: viewerZone, weekday: "short" }).format(at) + " ";
  return `${weekday}${clock} ${label}`;
}

/**
 * Refresh one `<time data-sutra-time="relative">` element.
 * @param {HTMLElement} el
 * @param {number} nowMs
 * @param {string | undefined} locale
 * @returns {number | null} ms until it needs to run again, or null when it is final (a date)
 */
export function refreshRelative(el, nowMs, locale) {
  const at = Date.parse(el.getAttribute("datetime") ?? "");
  if (Number.isNaN(at)) return null;

  const seconds = Math.floor((nowMs - at) / 1000);
  const until = Number(el.dataset.until ?? 7 * DAY);

  // Past `until` the server shows a date in the place's zone; leave those words alone. A
  // future one is looked at again when it comes inside the window.
  if (Math.abs(seconds) >= until) {
    return seconds < 0 ? Math.min((-seconds - until + 1) * 1000, 3_600_000) : null;
  }

  const style = el.dataset.style === "short" ? "short" : "long";
  const words = relativeWords(seconds, style, locale);
  if (el.textContent !== words) el.textContent = words;

  return Math.abs(seconds) < HOUR ? FAST_MS : SLOW_MS;
}

/**
 * Add the viewer's time to one `<time data-sutra-time="local">` element when the browser's
 * zone shows a different wall time. The title always carries it; the visible hint follows
 * `data-hint`.
 * @param {HTMLElement} el
 * @param {string | undefined} locale
 * @param {string | undefined} viewerZone defaults to the browser's
 */
export function applyViewerHint(el, locale, viewerZone) {
  el.querySelector("[data-viewer-time]")?.remove();

  const zone = el.dataset.zone;
  const at = new Date(el.getAttribute("datetime") ?? "");
  viewerZone ??= new Intl.DateTimeFormat().resolvedOptions().timeZone;
  if (!zone || Number.isNaN(at.getTime()) || !zonesDiffer(at, zone, viewerZone)) return;

  const label = el.dataset.hintLabel || "your time";
  const phrase = viewerTime(at, zone, viewerZone, label, locale);

  // A LiveView patch may have put the server's title back; one still carrying our words
  // keeps its remembered base.
  const current = el.getAttribute("title") ?? "";
  const base = current === el.dataset.titleApplied ? (el.dataset.titleBase ?? "") : current;
  const title = base ? `${base} · ${phrase}` : phrase;
  el.dataset.titleBase = base;
  el.dataset.titleApplied = title;
  el.setAttribute("title", title);

  if (el.dataset.hint === "true") {
    const span = document.createElement("span");
    span.dataset.viewerTime = "";
    span.textContent = ` · ${phrase}`;
    el.append(span);
  }
}

/**
 * One timer for every relative time on the page. It runs every 30 s while any element is
 * under an hour, then every five minutes, and stops when nothing is left.
 */
export class Ticker {
  /**
   * @param {{now?: () => number, setTimer?: Function, clearTimer?: Function, locale?: () => string | undefined}} [env]
   */
  constructor(env = {}) {
    this.now = env.now ?? Date.now;
    this.setTimer = env.setTimer ?? ((fn, ms) => globalThis.setTimeout(fn, ms));
    this.clearTimer = env.clearTimer ?? ((id) => globalThis.clearTimeout(id));
    this.locale = env.locale ?? pageLocale;
    /** @type {Set<HTMLElement>} */
    this.elements = new Set();
    this.timer = null;
  }

  add(el) {
    this.elements.add(el);
    this.run();
  }

  remove(el) {
    this.elements.delete(el);
    if (this.elements.size === 0) this.stop();
  }

  stop() {
    if (this.timer !== null) this.clearTimer(this.timer);
    this.timer = null;
  }

  /** Refresh every element now and schedule the next run (or none). */
  run() {
    this.stop();
    const locale = this.locale();
    const nowMs = this.now();
    let next = null;

    for (const el of this.elements) {
      const wait = refreshRelative(el, nowMs, locale);
      if (wait !== null && (next === null || wait < next)) next = wait;
    }

    if (next !== null) this.timer = this.setTimer(() => this.run(), next);
  }
}

const ticker = new Ticker();

if (globalThis.document?.addEventListener) {
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") ticker.run();
  });
}

/** LiveView hook for `<.relative_time>`. */
export const RelativeTime = {
  mounted() {
    ticker.add(this.el);
  },
  updated() {
    ticker.run();
  },
  destroyed() {
    ticker.remove(this.el);
  },
};

/** LiveView hook for `<.local_time>`. */
export const LocalTime = {
  mounted() {
    applyViewerHint(this.el, pageLocale());
  },
  updated() {
    applyViewerHint(this.el, pageLocale());
  },
};
