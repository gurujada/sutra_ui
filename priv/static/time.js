/* sutra_ui time source-hash:9641d9ddceb4044f (built by mix assets.build; do not edit) */

// assets/js/time/index.js
var MINUTE = 60;
var HOUR = 3600;
var DAY = 86400;
var FAST_MS = 3e4;
var SLOW_MS = 3e5;
function pageLocale() {
  const lang = globalThis.document?.documentElement?.lang;
  return lang || globalThis.navigator?.language || void 0;
}
function relativeWords(seconds, style, locale) {
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
    style: style === "short" ? "narrow" : "long"
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
function zonesDiffer(at, zone, viewerZone) {
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
    hourCycle: "h23"
  }).format(at);
}
function viewerTime(at, zone, viewerZone, label, locale) {
  const day = (z) => new Intl.DateTimeFormat("en-CA", { timeZone: z }).format(at);
  const clock = new Intl.DateTimeFormat(locale, {
    timeZone: viewerZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23"
  }).format(at);
  const weekday = day(zone) === day(viewerZone) ? "" : new Intl.DateTimeFormat(locale, { timeZone: viewerZone, weekday: "short" }).format(at) + " ";
  return `${weekday}${clock} ${label}`;
}
function refreshRelative(el, nowMs, locale) {
  const at = Date.parse(el.getAttribute("datetime") ?? "");
  if (Number.isNaN(at)) return null;
  const seconds = Math.floor((nowMs - at) / 1e3);
  const until = Number(el.dataset.until ?? 7 * DAY);
  if (Math.abs(seconds) >= until) {
    return seconds < 0 ? Math.min((-seconds - until + 1) * 1e3, 36e5) : null;
  }
  const style = el.dataset.style === "short" ? "short" : "long";
  const words = relativeWords(seconds, style, locale);
  if (el.textContent !== words) el.textContent = words;
  return Math.abs(seconds) < HOUR ? FAST_MS : SLOW_MS;
}
function applyViewerHint(el, locale, viewerZone) {
  el.querySelector("[data-viewer-time]")?.remove();
  const zone = el.dataset.zone;
  const at = new Date(el.getAttribute("datetime") ?? "");
  viewerZone ??= new Intl.DateTimeFormat().resolvedOptions().timeZone;
  if (!zone || Number.isNaN(at.getTime()) || !zonesDiffer(at, zone, viewerZone)) return;
  const label = el.dataset.hintLabel || "your time";
  const phrase = viewerTime(at, zone, viewerZone, label, locale);
  const current = el.getAttribute("title") ?? "";
  const base = current === el.dataset.titleApplied ? el.dataset.titleBase ?? "" : current;
  const title = base ? `${base} \xB7 ${phrase}` : phrase;
  el.dataset.titleBase = base;
  el.dataset.titleApplied = title;
  el.setAttribute("title", title);
  if (el.dataset.hint === "true") {
    const span = document.createElement("span");
    span.dataset.viewerTime = "";
    span.textContent = ` \xB7 ${phrase}`;
    el.append(span);
  }
}
var Ticker = class {
  /**
   * @param {{now?: () => number, setTimer?: Function, clearTimer?: Function, locale?: () => string | undefined}} [env]
   */
  constructor(env = {}) {
    this.now = env.now ?? Date.now;
    this.setTimer = env.setTimer ?? ((fn, ms) => globalThis.setTimeout(fn, ms));
    this.clearTimer = env.clearTimer ?? ((id) => globalThis.clearTimeout(id));
    this.locale = env.locale ?? pageLocale;
    this.elements = /* @__PURE__ */ new Set();
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
};
var ticker = new Ticker();
if (globalThis.document?.addEventListener) {
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") ticker.run();
  });
}
var RelativeTime = {
  mounted() {
    ticker.add(this.el);
  },
  updated() {
    ticker.run();
  },
  destroyed() {
    ticker.remove(this.el);
  }
};
var LocalTime = {
  mounted() {
    applyViewerHint(this.el, pageLocale());
  },
  updated() {
    applyViewerHint(this.el, pageLocale());
  }
};
export {
  FAST_MS,
  LocalTime,
  RelativeTime,
  SLOW_MS,
  Ticker,
  applyViewerHint,
  pageLocale,
  refreshRelative,
  relativeWords,
  viewerTime,
  zonesDiffer
};
