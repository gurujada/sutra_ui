/* sutra_ui dates source-hash:de69a780b95d972e (built by mix assets.build; do not edit) */
var __defProp = Object.defineProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// assets/js/fit/index.js
function fit(content, trigger, wanted) {
  if (!content || !trigger) return false;
  const margin = 8;
  const gap = 4;
  const vw = document.documentElement.clientWidth;
  const vh = document.documentElement.clientHeight;
  const t = trigger.getBoundingClientRect();
  const scrolled = content.scrollTop;
  let clip = { left: 0, top: 0, right: vw, bottom: vh };
  for (let p = trigger.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
    const cs = getComputedStyle(p);
    if (cs.overflowX === "visible" && cs.overflowY === "visible") continue;
    const r2 = p.getBoundingClientRect();
    clip = { left: Math.max(clip.left, r2.left), top: Math.max(clip.top, r2.top), right: Math.min(clip.right, r2.right), bottom: Math.min(clip.bottom, r2.bottom) };
  }
  const visible = t.right > clip.left && t.left < clip.right && t.bottom > clip.top && t.top < clip.bottom;
  content.style.position = "fixed";
  content.style.margin = "0px";
  content.style.translate = "none";
  content.style.right = "auto";
  content.style.bottom = "auto";
  content.style.left = "0px";
  content.style.top = "0px";
  content.style.transitionProperty = "opacity, scale, display, visibility";
  content.style.minWidth = t.width + "px";
  content.style.maxWidth = vw - 2 * margin + "px";
  content.style.maxHeight = "";
  if (wanted && wanted !== "auto") content.setAttribute("data-side", wanted);
  let w = content.offsetWidth;
  const h2 = content.offsetHeight;
  const below = vh - margin - t.bottom - gap;
  const above = t.top - gap - margin;
  let side = content.getAttribute("data-side") || "bottom";
  if (side === "bottom" && h2 > below && (h2 <= above || above > below)) side = "top";
  else if (side === "top" && h2 > above && (h2 <= below || below > above)) side = "bottom";
  else if (side === "right" && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = "left";
  else if (side === "left" && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = "right";
  content.setAttribute("data-side", side);
  const align = content.getAttribute("data-align") || "start";
  let left;
  let top;
  if (side === "bottom" || side === "top") {
    const room = Math.max(side === "bottom" ? below : above, 120);
    content.style.maxHeight = room + "px";
    w = content.offsetWidth;
    left = align === "end" ? t.right - w : align === "center" ? t.left + (t.width - w) / 2 : t.left;
    top = side === "bottom" ? t.bottom + gap : t.top - gap - Math.min(h2, room);
  } else {
    left = side === "right" ? t.right + gap : t.left - gap - w;
    top = align === "end" ? t.bottom - h2 : align === "center" ? t.top + (t.height - h2) / 2 : t.top;
    top = Math.max(margin, Math.min(top, vh - margin - h2));
  }
  left = Math.max(margin, Math.min(left, vw - margin - w));
  content.style.left = left + "px";
  content.style.top = top + "px";
  const r = content.getBoundingClientRect();
  const dx = r.left - (left + (content.offsetWidth - r.width) / 2);
  const dy = r.top - (top + (content.offsetHeight - r.height) / 2);
  if (Math.abs(dx) > 0.5) content.style.left = left - dx + "px";
  if (Math.abs(dy) > 0.5) content.style.top = top - dy + "px";
  content.scrollTop = scrolled;
  return visible;
}
function unfit(content) {
  if (!content) return;
  for (const p of ["position", "margin", "translate", "left", "right", "top", "bottom", "minWidth", "maxWidth", "maxHeight", "transitionProperty"]) {
    content.style[p] = "";
  }
  content.removeAttribute("data-side");
}

// assets/js/time/index.js
var MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
];
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
function formatDay(iso, format = "date") {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso ?? "");
  if (!m) return "";
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const month = MONTHS[mo - 1];
  const weekday2 = WEEKDAYS[new Date(Date.UTC(y, mo - 1, d)).getUTCDay()];
  switch (format) {
    case "short":
      return `${d} ${month.slice(0, 3)}`;
    case "long":
      return `${d} ${month} ${y}`;
    case "day":
      return `${weekday2} ${d} ${month.slice(0, 3)}`;
    case "month":
      return `${month} ${y}`;
    default:
      return `${d} ${month.slice(0, 3)} ${y}`;
  }
}
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
  const weekday2 = day(zone) === day(viewerZone) ? "" : new Intl.DateTimeFormat(locale, { timeZone: viewerZone, weekday: "short" }).format(at) + " ";
  return `${weekday2}${clock} ${label}`;
}
function refreshRelative(el, nowMs, locale) {
  const at = Date.parse(el.getAttribute("datetime") ?? "");
  if (Number.isNaN(at)) return null;
  const seconds = Math.floor((nowMs - at) / 1e3);
  const until = Number(el.dataset.until ?? 7 * DAY);
  if (Math.abs(seconds) >= until) {
    return seconds < 0 ? Math.min((-seconds - until + 1) * 1e3, 36e5) : null;
  }
  const style = el.dataset.length === "short" ? "short" : "long";
  const words = relativeWords(seconds, style, locale);
  if (el.textContent !== words) el.textContent = words;
  return Math.abs(seconds) < HOUR ? FAST_MS : SLOW_MS;
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

// assets/js/dates/core.js
var core_exports = {};
__export(core_exports, {
  PRESET_LABELS: () => PRESET_LABELS,
  addDays: () => addDays,
  addMonths: () => addMonths,
  addYears: () => addYears,
  checkDate: () => checkDate,
  checkRange: () => checkRange,
  checkTime: () => checkTime,
  compare: () => compare,
  daysInMonth: () => daysInMonth,
  diffDays: () => diffDays,
  endRefused: () => endRefused,
  fieldTone: () => fieldTone,
  monthGrid: () => monthGrid,
  monthNames: () => monthNames,
  moveFocus: () => moveFocus,
  pad: () => pad,
  parse: () => parse,
  presetValue: () => presetValue,
  rangeLength: () => rangeLength,
  reasonWords: () => reasonWords,
  shortDate: () => shortDate,
  startOfWeek: () => startOfWeek,
  toISO: () => toISO,
  weekday: () => weekday,
  weekdayNames: () => weekdayNames
});
var pad = (n, width = 2) => String(n).padStart(width, "0");
function parse(iso) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(iso ?? ""));
  if (!match) return null;
  const [y, m, d] = [Number(match[1]), Number(match[2]), Number(match[3])];
  return m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(y, m) ? { y, m, d } : null;
}
var toISO = (y, m, d) => `${pad(y, 4)}-${pad(m)}-${pad(d)}`;
var daysInMonth = (y, m) => new Date(Date.UTC(y, m, 0)).getUTCDate();
var utc = (iso) => {
  const p = parse(iso);
  return Date.UTC(p.y, p.m - 1, p.d);
};
var fromUtc = (ms) => {
  const d = new Date(ms);
  return toISO(d.getUTCFullYear(), d.getUTCMonth() + 1, d.getUTCDate());
};
var addDays = (iso, n) => fromUtc(utc(iso) + n * 864e5);
var diffDays = (a, b) => Math.round((utc(b) - utc(a)) / 864e5);
var weekday = (iso) => new Date(utc(iso)).getUTCDay() || 7;
var compare = (a, b) => a < b ? -1 : a > b ? 1 : 0;
function addMonths(iso, n) {
  const { y, m, d } = parse(iso);
  const index = y * 12 + (m - 1) + n;
  const year = Math.floor(index / 12);
  const month = index % 12 + 1;
  return toISO(year, month, Math.min(d, daysInMonth(year, month)));
}
var addYears = (iso, n) => addMonths(iso, n * 12);
function startOfWeek(iso, weekStart = 1) {
  return addDays(iso, -((weekday(iso) - weekStart + 7) % 7));
}
function monthGrid(y, m, weekStart = 1) {
  const first = startOfWeek(toISO(y, m, 1), weekStart);
  return Array.from({ length: 6 }, (_, w) => Array.from({ length: 7 }, (_2, d) => addDays(first, w * 7 + d)));
}
function checkDate(rules, iso) {
  if (!rules) return null;
  if (rules.min && iso < rules.min) return "before_min";
  if (rules.max && iso > rules.max) return "after_max";
  if (rules.disabledDates?.includes(iso)) return "disabled_date";
  if (rules.disabledWeekdays?.includes(weekday(iso))) return "disabled_weekday";
  return null;
}
var rangeLength = (start, end) => diffDays(start, end) + 1;
function checkRange(rules, start, end) {
  const day = checkDate(rules, start) ?? checkDate(rules, end);
  if (day) return day;
  const length = rangeLength(start, end);
  if (length < 1) return "reversed";
  if (rules?.minLength && length < rules.minLength) return "too_short";
  if (rules?.maxLength && length > rules.maxLength) return "too_long";
  return null;
}
function endRefused(rules, start, iso) {
  if (iso < start) return false;
  return checkRange(rules, start, iso) !== null;
}
function checkTime(rules, hhmm) {
  const step2 = rules?.step;
  if (!step2 || step2 <= 1) return null;
  const [h2, m] = hhmm.split(":").map(Number);
  return (h2 * 60 + m) % step2 === 0 ? null : "step";
}
function reasonWords(reason, rules) {
  switch (reason) {
    case "before_min":
      return `Not before ${shortDate(rules.min)}`;
    case "after_max":
      return `Not after ${shortDate(rules.max)}`;
    case "disabled_date":
      return "Not available";
    case "disabled_weekday":
      return "Not available on this weekday";
    case "reversed":
      return "The end is before the start";
    case "too_short":
      return `At least ${rules.minLength} days`;
    case "too_long":
      return `At most ${rules.maxLength} days`;
    case "step":
      return `Every ${rules.step} minutes`;
    default:
      return "";
  }
}
var shortDate = (iso) => formatDay(iso, "date");
var PRESET_LABELS = {
  today: "Today",
  tomorrow: "Tomorrow",
  next_monday: "Next Monday",
  end_of_week: "End of week",
  end_of_month: "End of month",
  last_7_days: "Last 7 days",
  last_30_days: "Last 30 days",
  this_week: "This week",
  this_month: "This month",
  last_month: "Last month"
};
function presetValue(key, today, weekStart = 1) {
  const { y, m } = parse(today);
  switch (key) {
    case "today":
      return today;
    case "tomorrow":
      return addDays(today, 1);
    case "next_monday":
      return addDays(today, 8 - weekday(today));
    case "end_of_week":
      return addDays(startOfWeek(today, weekStart), 6);
    case "end_of_month":
      return toISO(y, m, daysInMonth(y, m));
    case "last_7_days":
      return { start: addDays(today, -6), end: today };
    case "last_30_days":
      return { start: addDays(today, -29), end: today };
    case "this_week": {
      const start = startOfWeek(today, weekStart);
      return { start, end: addDays(start, 6) };
    }
    case "this_month":
      return { start: toISO(y, m, 1), end: toISO(y, m, daysInMonth(y, m)) };
    case "last_month": {
      const first = addMonths(toISO(y, m, 1), -1);
      const p = parse(first);
      return { start: first, end: toISO(p.y, p.m, daysInMonth(p.y, p.m)) };
    }
    default:
      return null;
  }
}
function moveFocus(key, shift, iso, weekStart = 1) {
  switch (key) {
    case "ArrowLeft":
      return addDays(iso, -1);
    case "ArrowRight":
      return addDays(iso, 1);
    case "ArrowUp":
      return addDays(iso, -7);
    case "ArrowDown":
      return addDays(iso, 7);
    case "Home":
      return startOfWeek(iso, weekStart);
    case "End":
      return addDays(startOfWeek(iso, weekStart), 6);
    case "PageUp":
      return shift ? addYears(iso, -1) : addMonths(iso, -1);
    case "PageDown":
      return shift ? addYears(iso, 1) : addMonths(iso, 1);
    default:
      return null;
  }
}
function weekdayNames(weekStart = 1, locale) {
  const fmt = new Intl.DateTimeFormat(locale, { weekday: "short", timeZone: "UTC" });
  return Array.from({ length: 7 }, (_, i) => fmt.format(new Date(Date.UTC(2024, 0, 1 + (weekStart - 1 + i) % 7))));
}
function monthNames(locale, style = "long") {
  const fmt = new Intl.DateTimeFormat(locale, { month: style, timeZone: "UTC" });
  return Array.from({ length: 12 }, (_, i) => fmt.format(new Date(Date.UTC(2024, i, 1))));
}
function fieldTone({ reason, resolutionKind, server }) {
  const invalid = Boolean(reason) || resolutionKind === "gap" || Boolean(server);
  return { invalid, warning: !invalid && resolutionKind === "ambiguous" };
}

// assets/js/dates/dom.js
var SVG = "http://www.w3.org/2000/svg";
function h(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [name, value] of Object.entries(attrs)) {
    if (value === null || value === void 0 || value === false) continue;
    if (name === "class") node.className = value;
    else if (name === "text") node.textContent = value;
    else node.setAttribute(name, value === true && !name.startsWith("aria-") ? "" : String(value));
  }
  for (const child of children) if (child) node.append(child);
  return node;
}
function icon(paths, className = "dp-icon") {
  const svg = document.createElementNS(SVG, "svg");
  for (const [name, value] of Object.entries({
    class: className,
    width: "24",
    height: "24",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    "stroke-width": "2",
    "stroke-linecap": "round",
    "stroke-linejoin": "round",
    "aria-hidden": "true"
  })) {
    svg.setAttribute(name, value);
  }
  for (const d of paths) {
    const path = document.createElementNS(SVG, "path");
    path.setAttribute("d", d);
    svg.append(path);
  }
  return svg;
}
var ICONS = {
  calendar: ["M8 2v4", "M16 2v4", "M3 10h18", "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"],
  clock: ["M12 6v6l4 2", "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z"],
  prev: ["m15 18-6-6 6-6"],
  next: ["m9 18 6-6-6-6"],
  close: ["M18 6 6 18", "m6 6 12 12"],
  warning: ["m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3", "M12 9v4", "M12 17h.01"],
  chevron: ["m6 9 6 6 6-6"]
};
function emit(input) {
  input.dispatchEvent(new Event("input", { bubbles: true }));
  input.dispatchEvent(new Event("change", { bubbles: true }));
}

// assets/js/dates/calendar.js
var dayLabel = (iso) => `${formatDay(iso, "day")} ${parse(iso).y}`;
function shownRange(state) {
  if (state.mode !== "range") return null;
  const { start, end } = state.selected;
  if (state.pending) {
    const to = state.hover && state.hover >= state.pending ? state.hover : state.pending;
    return { start: state.pending, end: to, drawing: true };
  }
  return start && end ? { start, end, drawing: false } : start ? { start, end: start, drawing: false } : null;
}
function summary(state) {
  const range = shownRange(state);
  if (state.mode === "range") {
    if (!range) return "Pick the first day";
    const length = rangeLength(range.start, range.end);
    if (state.pending && !state.hover) return `${formatDay(range.start)}, pick the last day`;
    return `${formatDay(range.start)} \u2013 ${formatDay(range.end)} \xB7 ${length} ${length === 1 ? "day" : "days"}`;
  }
  return state.selected.start ? dayLabel(state.selected.start) : "";
}
function renderCalendar(state, cb) {
  const root = h("div", { class: "dp-cal", "data-view": state.view });
  const names = monthNames(state.locale);
  const title = `${names[state.m - 1]} ${state.y}`;
  const navLabel = state.view === "days" ? ["Previous month", "Next month"] : state.view === "months" ? ["Previous year", "Next year"] : ["Previous years", "Next years"];
  const step2 = state.view === "days" ? 1 : state.view === "months" ? 12 : 144;
  root.append(
    h("div", { class: "dp-cal-head" }, [
      navButton(navLabel[0], ICONS.prev, () => cb.nav(-step2)),
      h("div", { class: "dp-cal-title", "aria-live": "polite" }, [
        h("button", { type: "button", class: "dp-title-btn", "data-pick": "month", "aria-label": `Month, ${names[state.m - 1]}`, text: names[state.m - 1], "aria-expanded": state.view === "months" }),
        h("button", { type: "button", class: "dp-title-btn", "data-pick": "year", "aria-label": `Year, ${state.y}`, text: String(state.y), "aria-expanded": state.view === "years" })
      ]),
      navButton(navLabel[1], ICONS.next, () => cb.nav(step2))
    ])
  );
  root.querySelector('[data-pick="month"]').addEventListener("click", () => cb.view(state.view === "months" ? "days" : "months"));
  root.querySelector('[data-pick="year"]').addEventListener("click", () => cb.view(state.view === "years" ? "days" : "years"));
  if (state.view === "months") root.append(monthList(state, cb));
  else if (state.view === "years") root.append(yearList(state, cb));
  else root.append(dayGrid(state, cb, title));
  return root;
}
function navButton(label, paths, onClick) {
  const b = h("button", { type: "button", class: "dp-nav", "aria-label": label }, [icon(paths)]);
  b.addEventListener("click", onClick);
  return b;
}
var todayParts = (state) => parse(state.today);
var thisMonth = (state, month) => todayParts(state).y === state.y && todayParts(state).m === month;
function monthList(state, cb) {
  const short = monthNames(state.locale, "short");
  const list = h("div", { class: "dp-months", role: "group", "aria-label": `Months of ${state.y}` });
  short.forEach((name, i) => {
    const b = h("button", { type: "button", class: "dp-cell", "data-current": i + 1 === state.m, "data-today": thisMonth(state, i + 1), "aria-current": thisMonth(state, i + 1) ? "date" : null, "aria-pressed": i + 1 === state.m, text: name });
    b.addEventListener("click", () => cb.month(i + 1));
    list.append(b);
  });
  return list;
}
function yearList(state, cb) {
  const list = h("div", { class: "dp-years", role: "group", "aria-label": "Years" });
  for (let i = 0; i < 12; i++) {
    const year = state.yearPage + i;
    const b = h("button", { type: "button", class: "dp-cell", "data-current": year === state.y, "data-today": year === todayParts(state).y, "aria-current": year === todayParts(state).y ? "date" : null, "aria-pressed": year === state.y, text: String(year) });
    b.addEventListener("click", () => cb.year(year));
    list.append(b);
  }
  return list;
}
function dayGrid(state, cb, title) {
  const range = shownRange(state);
  const grid = h("div", { class: "dp-grid", role: "grid", "aria-label": title });
  grid.append(
    h("div", { class: "dp-row", role: "row" }, weekdayNames(state.weekStart, state.locale).map((n) => h("span", { class: "dp-weekday", role: "columnheader", text: n })))
  );
  for (const week of monthGrid(state.y, state.m, state.weekStart)) {
    const row = h("div", { class: "dp-row", role: "row" });
    for (const iso of week) {
      const { m, d } = parse(iso);
      const outside = m !== state.m;
      const reason = refusal(state, iso);
      const isStart = state.selected.start === iso && state.mode === "single";
      const inRange = range && iso >= range.start && iso <= range.end;
      const selected = isStart || range && (iso === range.start || iso === range.end);
      const button = h("button", {
        type: "button",
        class: "dp-day",
        tabindex: iso === state.focus ? "0" : "-1",
        "data-date": iso,
        "data-outside": outside,
        "data-today": iso === state.today,
        "data-selected": !!selected,
        "data-in-range": !!(inRange && state.mode === "range"),
        "data-range-start": !!(range && iso === range.start),
        "data-range-end": !!(range && iso === range.end),
        "data-refused": !!reason,
        "aria-disabled": reason ? "true" : null,
        "aria-current": iso === state.today ? "date" : null,
        "aria-label": dayLabel(iso) + (reason ? `, ${reasonWords(reason, state.rules).toLowerCase()}` : ""),
        text: String(d)
      });
      button.addEventListener("click", () => !reason && cb.pick(iso));
      button.addEventListener("mouseenter", () => cb.hover(iso));
      button.addEventListener("focus", () => cb.hover(iso));
      row.append(h("div", { class: "dp-cell-wrap", role: "gridcell", "aria-selected": selected ? "true" : "false" }, [button]));
    }
    grid.append(row);
  }
  grid.addEventListener("mouseleave", () => cb.hover(null));
  return grid;
}
function refusal(state, iso) {
  const day = checkDate(state.rules, iso);
  if (day) return day;
  if (iso === state.pending) return null;
  if (state.mode === "range" && state.pending && endRefused(state.rules, state.pending, iso)) {
    const length = rangeLength(state.pending, iso);
    return state.rules.maxLength && length > state.rules.maxLength ? "too_long" : "too_short";
  }
  return null;
}

// assets/js/dates/segments.js
var segments_exports = {};
__export(segments_exports, {
  SPECS: () => SPECS,
  assemble: () => assemble,
  clampDay: () => clampDay,
  display: () => display,
  localeOrder: () => localeOrder,
  parseDateText: () => parseDateText,
  parseTimeText: () => parseTimeText,
  step: () => step,
  typeDigit: () => typeDigit
});
var SPECS = {
  day: { type: "day", min: 1, max: 31, digits: 2 },
  month: { type: "month", min: 1, max: 12, digits: 2 },
  year: { type: "year", min: 1, max: 9999, digits: 4 },
  hour: { type: "hour", min: 0, max: 23, digits: 2 },
  minute: { type: "minute", min: 0, max: 59, digits: 2 }
};
function localeOrder(locale) {
  const parts = new Intl.DateTimeFormat(locale, { year: "numeric", month: "2-digit", day: "2-digit", timeZone: "UTC" }).formatToParts(new Date(Date.UTC(2024, 10, 22)));
  const order = parts.filter((p) => ["day", "month", "year"].includes(p.type)).map((p) => (
    /** @type {any} */
    p.type
  ));
  const separator = parts.find((p) => p.type === "literal")?.value.trim() || "/";
  return { order, separator };
}
function typeDigit(spec, buffer, digit) {
  let next = buffer + digit;
  if (next.length > spec.digits) next = digit;
  let value = Number(next);
  if (spec.type !== "year" && value > spec.max) {
    next = digit;
    value = Number(digit);
  }
  const full = next.length >= spec.digits;
  const nothingFits = spec.type !== "year" && value * 10 > spec.max;
  return { buffer: next, value, advance: full || nothingFits };
}
function step(spec, value, dir) {
  const by = spec.step && spec.step > 1 ? spec.step : 1;
  if (value === null || Number.isNaN(value)) return dir > 0 ? spec.min : spec.max - (spec.max - spec.min) % by;
  if (spec.type === "year") return Math.min(spec.max, Math.max(spec.min, value + dir));
  const span = spec.max - spec.min + 1;
  const aligned = spec.step && spec.step > 1 ? Math.round(value / by) * by : value;
  let next = aligned + dir * by;
  if (next > spec.max) next = spec.min;
  if (next < spec.min) next = spec.max - (spec.max - spec.min) % by;
  return (next - spec.min + span) % span + spec.min;
}
var display = (spec, value) => value === null || value === void 0 ? "" : pad(value, spec.digits);
function assemble(day, month, year) {
  if ([day, month, year].some((v) => v === null || v === void 0 || Number.isNaN(v))) return null;
  return parse(toISO(year, month, day)) ? toISO(year, month, day) : null;
}
var clampDay = (day, month, year) => day === null ? null : Math.min(day, daysInMonth(year ?? 2024, month ?? 1));
function parseDateText(text, order) {
  const t = text.trim();
  const iso = /^(\d{4})-(\d{1,2})-(\d{1,2})/.exec(t);
  if (iso) return assemble(Number(iso[3]), Number(iso[2]), Number(iso[1]));
  const nums = t.match(/\d+/g);
  if (!nums || nums.length < 3) return null;
  const by = {};
  order.forEach((type, i) => by[type] = Number(nums[i]));
  if (by.year < 100) by.year += 2e3;
  return assemble(by.day, by.month, by.year);
}
function parseTimeText(text) {
  const t = text.trim();
  const m = /^(\d{1,2})[:.h ]?(\d{2})$/.exec(t) || /^(\d{1,2})$/.exec(t);
  if (!m) return null;
  const h2 = Number(m[1]);
  const mi = m[2] === void 0 ? 0 : Number(m[2]);
  return h2 <= 23 && mi <= 59 ? `${pad(h2)}:${pad(mi)}` : null;
}

// assets/js/dates/fields.js
function dateParts(locale) {
  const { order, separator } = localeOrder(locale);
  const labels = { day: ["Day", "dd"], month: ["Month", "mm"], year: ["Year", "yyyy"] };
  return {
    separator,
    parts: order.map((key) => ({ key, spec: SPECS[key], label: labels[key][0], placeholder: labels[key][1] }))
  };
}
function timeParts(stepMinutes = 1) {
  return [
    { key: "hour", spec: SPECS.hour, label: "Hour", placeholder: "hh" },
    { key: "minute", spec: { ...SPECS.minute, step: stepMinutes }, label: "Minute", placeholder: "mm" }
  ];
}
function segmentGroup({ parts, separator, label, disabled = false, onEdit, parsePaste }) {
  const values = Object.fromEntries(parts.map((p) => [p.key, null]));
  const root = h("div", { class: "dp-field", role: "group", "aria-label": label });
  const inputs = [];
  let buffer = "";
  const paint = (index) => {
    const { key, spec } = parts[index];
    const input = inputs[index];
    input.value = display(spec, values[key]);
    input.setAttribute("aria-valuenow", values[key] === null ? "" : String(values[key]));
    if (values[key] === null) input.removeAttribute("aria-valuenow");
    input.setAttribute("aria-valuetext", values[key] === null ? "Empty" : input.value);
  };
  const links = { after: null };
  const focusAt = (index) => {
    const target = inputs[index];
    if (target) {
      target.focus();
      target.select();
    } else if (index >= inputs.length) {
      links.after?.focus();
    }
  };
  parts.forEach((part, index) => {
    const { spec } = part;
    const input = (
      /** @type {HTMLInputElement} */
      h("input", {
        type: "text",
        inputmode: "numeric",
        autocomplete: "off",
        autocorrect: "off",
        spellcheck: "false",
        enterkeyhint: "next",
        class: `dp-seg dp-seg-${spec.digits}`,
        role: "spinbutton",
        "aria-label": part.label,
        "aria-valuemin": spec.min,
        "aria-valuemax": spec.max,
        placeholder: part.placeholder,
        "data-part": part.key,
        disabled
      })
    );
    inputs.push(input);
    input.addEventListener("focus", () => {
      buffer = "";
      input.select();
    });
    input.addEventListener("beforeinput", (event) => {
      const e = (
        /** @type {InputEvent} */
        event
      );
      e.preventDefault();
      if (e.inputType === "insertText" && e.data && /^\d+$/.test(e.data)) {
        for (const digit of e.data) {
          const r = typeDigit(spec, buffer, digit);
          buffer = r.buffer;
          values[part.key] = r.value;
          paint(index);
          if (r.advance) {
            buffer = "";
            onEdit({ ...values });
            focusAt(index + 1);
            return;
          }
        }
        onEdit({ ...values });
      } else if (e.inputType.startsWith("delete")) {
        buffer = "";
        values[part.key] = null;
        paint(index);
        onEdit({ ...values });
      } else if (e.inputType === "insertFromPaste" && e.data) {
        pasted(e.data);
      }
    });
    input.addEventListener("keydown", (e) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      switch (e.key) {
        case "ArrowUp":
        case "ArrowDown":
          e.preventDefault();
          buffer = "";
          values[part.key] = step(spec, values[part.key], e.key === "ArrowUp" ? 1 : -1);
          paint(index);
          input.select();
          onEdit({ ...values });
          break;
        case "ArrowLeft":
          e.preventDefault();
          focusAt(index - 1);
          break;
        case "ArrowRight":
          e.preventDefault();
          focusAt(index + 1);
          break;
        case "Backspace":
        case "Delete":
          e.preventDefault();
          buffer = "";
          values[part.key] = null;
          paint(index);
          onEdit({ ...values });
          break;
        case "Home":
          e.preventDefault();
          focusAt(0);
          break;
        case "End":
          e.preventDefault();
          focusAt(inputs.length - 1);
          break;
        default:
          if (e.key.length === 1 && /[\s/.\-:,]/.test(e.key)) {
            e.preventDefault();
            focusAt(index + 1);
          } else if (e.key.length === 1 && !/\d/.test(e.key)) {
            e.preventDefault();
          }
      }
    });
    input.addEventListener("paste", (e) => {
      e.preventDefault();
      pasted(e.clipboardData?.getData("text") ?? "");
    });
  });
  function pasted(text) {
    const next = parsePaste?.(text);
    if (!next) return;
    set(next);
    onEdit({ ...values });
  }
  parts.forEach((_, i) => {
    if (i > 0) root.append(h("span", { class: "dp-sep", "aria-hidden": "true", text: separator }));
    root.append(inputs[i]);
  });
  function set(next) {
    parts.forEach((p, i) => {
      if (p.key in next) values[p.key] = next[p.key];
      paint(i);
    });
  }
  return {
    root,
    links,
    inputs,
    values,
    set,
    focus: () => focusAt(0),
    setDisabled(d) {
      for (const i of inputs) i.disabled = d;
    },
    setInvalid(invalid, describedby) {
      root.toggleAttribute("data-invalid", invalid);
      for (const i of inputs) {
        if (invalid) i.setAttribute("aria-invalid", "true");
        else i.removeAttribute("aria-invalid");
        if (describedby) i.setAttribute("aria-describedby", describedby);
      }
    }
  };
}

// assets/js/dates/times.js
function timeOptions(stepMinutes) {
  const out = [];
  for (let m = 0; m < 24 * 60; m += stepMinutes) out.push(`${pad(Math.floor(m / 60))}:${pad(m % 60)}`);
  return out;
}
function nearest(options, hhmm) {
  if (!options.length) return null;
  const minutes = (t) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
  const target = minutes(hhmm || "09:00");
  return options.reduce((best, t) => Math.abs(minutes(t) - target) < Math.abs(minutes(best) - target) ? t : best, options[0]);
}
function renderTimes(options, selected, active, idBase, onPick) {
  const list = h("div", { class: "dp-times", role: "listbox", id: `${idBase}-times`, "aria-label": "Times" });
  options.forEach((t, i) => {
    const option = h("div", {
      role: "option",
      id: `${idBase}-time-${i}`,
      class: "dp-time",
      "data-value": t,
      "data-active": t === active,
      "aria-selected": t === selected ? "true" : "false",
      text: t
    });
    option.addEventListener("click", () => onPick(t));
    list.append(option);
  });
  return list;
}

// assets/js/dates/zone.js
var zone_exports = {};
__export(zone_exports, {
  formatOffset: () => formatOffset,
  fromISO: () => fromISO,
  isoWithOffset: () => isoWithOffset,
  offsetAt: () => offsetAt,
  parseWall: () => parseWall,
  resolveWall: () => resolveWall,
  wallAt: () => wallAt,
  wallValue: () => wallValue,
  zoneName: () => zoneName
});
var formatters = /* @__PURE__ */ new Map();
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
      second: "numeric"
    });
    formatters.set(zone, f);
  }
  return f;
}
function offsetAt(zone, ms) {
  const p = {};
  for (const { type, value } of formatter(zone).formatToParts(new Date(ms))) p[type] = Number(value);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour % 24, p.minute, p.second);
  return Math.round((asUtc - Math.floor(ms / 1e3) * 1e3) / 6e4);
}
function formatOffset(minutes) {
  const sign = minutes < 0 ? "-" : "+";
  const abs = Math.abs(minutes);
  return `${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
}
function resolveWall(zone, wall2) {
  const asUtc = Date.UTC(wall2.y, wall2.m - 1, wall2.d, wall2.h, wall2.mi);
  const day = 864e5;
  const before = offsetAt(zone, asUtc - day);
  const after = offsetAt(zone, asUtc + day);
  const offsets = [.../* @__PURE__ */ new Set([before, after])];
  const valid = [];
  for (const offset of offsets) {
    const ms = asUtc - offset * 6e4;
    if (offsetAt(zone, ms) === offset) valid.push({ ms, offset });
  }
  valid.sort((a, b) => a.ms - b.ms);
  if (valid.length === 1) return { kind: "ok", at: valid[0] };
  if (valid.length === 2) return { kind: "ambiguous", first: valid[0], second: valid[1] };
  return { kind: "gap", before, after };
}
function isoWithOffset(wall2, offset) {
  return `${pad(wall2.y, 4)}-${pad(wall2.m)}-${pad(wall2.d)}T${pad(wall2.h)}:${pad(wall2.mi)}:00${formatOffset(offset)}`;
}
function wallAt(zone, ms) {
  const p = {};
  for (const { type, value } of formatter(zone).formatToParts(new Date(ms))) p[type] = Number(value);
  return { y: p.year, m: p.month, d: p.day, h: p.hour % 24, mi: p.minute };
}
function zoneName(zone, ms, locale = "en-US") {
  const part = new Intl.DateTimeFormat(locale, { timeZone: zone, timeZoneName: "short" }).formatToParts(new Date(ms)).find((p) => p.type === "timeZoneName");
  const text = part?.value ?? "";
  if (/^GMT[+-]/.test(text) && locale !== "en-IN" && zone === "Asia/Kolkata") return "IST";
  return text || formatOffset(offsetAt(zone, ms));
}
function fromISO(iso, zone) {
  const ms = Date.parse(iso);
  return Number.isNaN(ms) ? null : { wall: wallAt(zone, ms), ms };
}
var wallValue = (w) => `${pad(w.y, 4)}-${pad(w.m)}-${pad(w.d)}T${pad(w.h)}:${pad(w.mi)}`;
function parseWall(value) {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(value ?? "");
  return m ? { y: +m[1], m: +m[2], d: +m[3], h: +m[4], mi: +m[5] } : null;
}

// assets/js/dates/index.js
var wallText = (w) => `${String(w.h).padStart(2, "0")}:${String(w.mi).padStart(2, "0")}`;
var shownOffset = (minutes) => formatOffset(minutes).replace("-", "\u2212");
var SHEET_QUERY = "(max-width: 639px)";
var json = (text, fallback) => {
  try {
    return JSON.parse(text ?? "") ?? fallback;
  } catch {
    return fallback;
  }
};
var dayNumbers = (iso) => {
  const p = parse(iso);
  return p ? { day: p.d, month: p.m, year: p.y } : { day: null, month: null, year: null };
};
var Picker = class {
  /** @param {HTMLElement} el */
  constructor(el) {
    this.el = el;
    this.isOpen = false;
    this.locked = false;
    this.popupState = null;
    this.onClick = (e) => this.documentClick(e);
    this.onResize = () => this.place();
    this.onScroll = (e) => {
      if (this.isOpen && !this.popover.contains(e.target)) this.place();
    };
    document.addEventListener("click", this.onClick);
    window.addEventListener("resize", this.onResize);
    window.addEventListener("scroll", this.onScroll, { capture: true, passive: true });
    this.build();
  }
  destroy() {
    document.removeEventListener("click", this.onClick);
    window.removeEventListener("resize", this.onResize);
    window.removeEventListener("scroll", this.onScroll, { capture: true });
    this.unlock();
  }
  // ── setup ──────────────────────────────────────────────────────────────
  config() {
    const d = this.el.dataset;
    this.kind = d.kind;
    this.zone = d.zone || "Etc/UTC";
    this.locale = d.locale || "en-GB";
    this.nameLocale = pageLocale();
    this.weekStart = Number(d.weekStart) || 1;
    this.rules = json(d.rules, {});
    this.presets = json(d.presets, []);
    this.label = d.label || "";
    this.step = Number(d.step) || 1;
    this.hintLabel = d.hintLabel || "your time";
    this.idBase = this.el.id.replace(/-wrapper$/, "");
    this.today = this.rules.today || (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    this.disabled = this.el.hasAttribute("data-disabled");
  }
  refs() {
    const q = (role) => this.el.querySelector(`:scope > [data-dp="${role}"]`);
    this.main = q("main");
    this.startInput = q("start");
    this.endInput = q("end");
    this.posted = q("posted");
    this.presetInput = q("preset");
    this.ui = this.el.querySelector(":scope > .dp-ui");
  }
  build() {
    this.config();
    this.refs();
    this.ui.replaceChildren();
    const dateOrder = dateParts(this.locale);
    const onDate = (key) => (values) => this.edited(key, values);
    const dateGroup = (key, label) => segmentGroup({
      parts: dateOrder.parts,
      separator: dateOrder.separator,
      label,
      disabled: this.disabled,
      onEdit: onDate(key),
      parsePaste: (text) => {
        const iso = parseDateText(text, dateOrder.parts.map((p) => p.key));
        return iso ? dayNumbers(iso) : null;
      }
    });
    const timeGroup = () => segmentGroup({
      parts: timeParts(this.step),
      separator: ":",
      label: `${this.label || "Time"}, time`,
      disabled: this.disabled,
      onEdit: (values) => this.edited("time", values),
      parsePaste: (text) => {
        const t = parseTimeText(text);
        return t ? { hour: Number(t.slice(0, 2)), minute: Number(t.slice(3, 5)) } : null;
      }
    });
    this.groups = {};
    const control = h("div", { class: "dp-control" });
    if (this.kind === "date") {
      this.groups.date = dateGroup("date", this.label || "Date");
      control.append(this.groups.date.root);
    } else if (this.kind === "range") {
      this.groups.start = dateGroup("start", `${this.label || "Range"}, start date`);
      this.groups.end = dateGroup("end", `${this.label || "Range"}, end date`);
      this.length = h("span", { class: "dp-length", "aria-live": "polite" });
      this.groups.start.links.after = this.groups.end;
      const to = h("span", { class: "dp-to" }, [h("span", { class: "dp-dash", "aria-hidden": "true", text: "\u2013" }), this.groups.end.root]);
      control.append(this.groups.start.root, to, this.length);
    } else if (this.kind === "time") {
      this.groups.time = timeGroup();
      control.append(this.groups.time.root);
    } else {
      this.groups.date = dateGroup("date", `${this.label || "Date and time"}, date`);
      this.groups.time = timeGroup();
      this.groups.date.links.after = this.groups.time;
      control.append(this.groups.date.root, h("span", { class: "dp-dash", "aria-hidden": "true", text: "\xB7" }), this.groups.time.root);
    }
    this.hasPopup = this.kind !== "time" || this.step >= 5;
    if (this.hasPopup) {
      const isTime = this.kind === "time";
      this.opener = h("button", {
        type: "button",
        class: "dp-open",
        "aria-haspopup": "dialog",
        "aria-expanded": "false",
        "aria-controls": `${this.idBase}-popover`,
        "aria-label": isTime ? "Choose time" : this.kind === "range" ? "Choose dates" : "Choose date",
        disabled: this.disabled
      }, [icon(isTime ? ICONS.clock : ICONS.calendar)]);
      this.opener.addEventListener("click", () => this.isOpen ? this.close(true) : this.open());
      control.append(this.opener);
    }
    this.control = control;
    this.note = h("div", { class: "dp-note", id: `${this.idBase}-note`, "aria-live": "polite" });
    this.ui.append(control, this.note);
    if (this.hasPopup) {
      this.backdrop = h("div", { class: "dp-backdrop", "aria-hidden": "true" });
      this.backdrop.addEventListener("click", () => this.close(true));
      this.popover = h("div", {
        id: `${this.idBase}-popover`,
        class: "dp-popover",
        role: "dialog",
        "aria-label": this.kind === "time" ? "Choose a time" : this.kind === "range" ? "Choose a range of days" : "Choose a date",
        "aria-hidden": "true",
        "data-kind": this.kind
      });
      this.popover.addEventListener("keydown", (e) => this.popupKeys(e));
      this.popover.addEventListener("mousedown", (e) => {
        if (e.target.closest(".dp-times")) e.preventDefault();
      });
      this.ui.append(this.backdrop, this.popover);
    }
    this.enhance();
    this.readNative();
  }
  /** Hide the browser's inputs; they stay in the form. (Re-run after a LiveView patch.) */
  enhance() {
    this.el.setAttribute("data-enhanced", "");
    for (const input of [this.main, this.startInput, this.endInput].filter(Boolean)) {
      input.tabIndex = -1;
      input.setAttribute("aria-hidden", "true");
    }
    if (this.kind === "datetime") {
      this.main.disabled = true;
      this.posted.disabled = this.disabled;
    }
  }
  // ── native inputs → segments ─────────────────────────────────────────────
  snapshot() {
    if (this.kind === "datetime") return this.posted.value;
    return [this.main?.value, this.startInput?.value, this.endInput?.value].join("|");
  }
  readNative() {
    this.known = this.snapshot();
    switch (this.kind) {
      case "date":
        this.groups.date.set(dayNumbers(this.main.value));
        break;
      case "range":
        this.groups.start.set(dayNumbers(this.startInput.value));
        this.groups.end.set(dayNumbers(this.endInput.value));
        break;
      case "time": {
        const [hh, mm] = (this.main.value || "").split(":").map((v) => v === "" || v === void 0 ? null : Number(v));
        this.groups.time.set({ hour: hh ?? null, minute: mm ?? null });
        break;
      }
      default: {
        const exact = this.posted.value ? fromISO(this.posted.value, this.zone) : null;
        const wall2 = exact?.wall ?? parseWall(this.main.value);
        this.groups.date.set(wall2 ? dayNumbers(toISO(wall2.y, wall2.m, wall2.d)) : dayNumbers(""));
        this.groups.time.set(wall2 ? { hour: wall2.h, minute: wall2.mi } : { hour: null, minute: null });
        this.chosenOffset = exact ? exact.offset : null;
        this.pickedMs = exact?.ms ?? null;
        this.resolveDatetime(false);
      }
    }
    this.refresh();
  }
  updated() {
    this.refs();
    this.enhance();
    if (this.snapshot() !== this.known) this.readNative();
    else if (this.kind === "datetime" && this.main.value !== (this.lastWall ?? "")) this.main.value = this.lastWall ?? "";
    if (this.isOpen) this.show();
    this.refresh();
  }
  // ── segments → native inputs ─────────────────────────────────────────────
  /** A segment group changed because the person typed. */
  edited(key, values) {
    if (this.presetInput) this.presetInput.value = "";
    switch (this.kind) {
      case "date":
        this.write(this.main, this.dateOf(values) ?? "");
        break;
      case "range":
        this.write(key === "start" ? this.startInput : this.endInput, this.dateOf(values) ?? "");
        break;
      case "time":
        this.write(this.main, this.timeOf(values) ?? "");
        break;
      default:
        this.chosenOffset = null;
        this.resolveDatetime(true);
    }
    this.refresh();
  }
  dateOf(values) {
    return assemble(values.day, values.month, values.year);
  }
  timeOf(values) {
    if (values.hour === null || values.minute === null) return null;
    return `${String(values.hour).padStart(2, "0")}:${String(values.minute).padStart(2, "0")}`;
  }
  /** Set a posted input; tell the form only when the value changed. */
  write(input, value, quiet = false) {
    if (!input || input.value === value) return false;
    input.value = value;
    this.known = this.snapshot();
    if (!quiet) emit(input);
    return true;
  }
  /** Work out the instant of the typed wall time in the zone; post it, or say why not. */
  resolveDatetime(notify) {
    const date = this.dateOf(this.groups.date.values);
    const time = this.timeOf(this.groups.time.values);
    this.resolution = { kind: "empty" };
    let posted = "";
    let wallText2 = "";
    if (date && time) {
      const d = parse(date);
      const wall2 = { y: d.y, m: d.m, d: d.d, h: Number(time.slice(0, 2)), mi: Number(time.slice(3, 5)) };
      wallText2 = wallValue(wall2);
      const r = resolveWall(this.zone, wall2);
      if (r.kind === "ok") {
        this.resolution = { kind: "ok", wall: wall2, at: r.at };
        posted = isoWithOffset(wall2, r.at.offset);
      } else if (r.kind === "ambiguous") {
        const chosen = [r.first, r.second].find((c) => c.offset === this.chosenOffset);
        if (chosen) {
          this.resolution = { kind: "ok", wall: wall2, at: chosen, wasAmbiguous: true };
          posted = isoWithOffset(wall2, chosen.offset);
        } else {
          this.resolution = { kind: "ambiguous", wall: wall2, first: r.first, second: r.second };
        }
      } else {
        this.resolution = { kind: "gap", wall: wall2, before: r.before, after: r.after };
      }
    }
    this.lastWall = wallText2;
    if (notify) {
      this.write(this.main, wallText2, true);
      this.write(this.posted, posted);
    } else {
      this.known = this.snapshot();
    }
  }
  chooseOffset(offset) {
    this.chosenOffset = offset;
    this.resolveDatetime(true);
    this.refresh();
  }
  // ── what the person sees besides the segments ────────────────────────────────
  refresh() {
    this.checkRules();
    this.renderNote();
  }
  /** Mark a typed value the rules refuse (the server refuses it too). */
  checkRules() {
    const rules = this.rules;
    let reason = null;
    const dateIso = (key) => this.dateOf(this.groups[key].values);
    if (this.kind === "range") {
      const [a, b] = [dateIso("start"), dateIso("end")];
      reason = a && b ? checkRange(rules, a, b) : a && checkDate(rules, a) || b && checkDate(rules, b) || null;
      this.length.textContent = a && b && rangeLength(a, b) >= 1 ? `${rangeLength(a, b)} ${rangeLength(a, b) === 1 ? "day" : "days"}` : "";
    } else if (this.kind === "time") {
      const t = this.timeOf(this.groups.time.values);
      reason = t ? checkTime(rules, t) : null;
    } else {
      const d = dateIso("date");
      reason = d ? checkDate(rules, d) : null;
      if (!reason && this.kind === "datetime") {
        const t = this.timeOf(this.groups.time.values);
        reason = t ? checkTime(rules, t) : null;
      }
    }
    this.reason = reason;
    this.reasonText = reason ? reasonWords(reason, rules) : "";
    const source = this.main || this.startInput;
    const server = source?.getAttribute("aria-invalid") === "true";
    const described = [source?.getAttribute("aria-describedby"), `${this.idBase}-note`].filter(Boolean).join(" ");
    const tone = fieldTone({
      reason,
      resolutionKind: this.kind === "datetime" ? this.resolution?.kind : null,
      server
    });
    for (const g of Object.values(this.groups)) g.setInvalid(tone.invalid, described);
    this.el.toggleAttribute("data-invalid", tone.invalid);
    this.el.toggleAttribute("data-warning", tone.warning);
  }
  renderNote() {
    const parts = [];
    if (this.reasonText) parts.push(h("span", { class: "dp-reason", "data-reason": this.reason, text: this.reasonText }));
    if (this.kind === "datetime") {
      const r = this.resolution;
      const locale = this.nameLocale;
      if (r.kind === "ok") {
        const name = zoneName(this.zone, r.at.ms);
        let hint = "";
        const at = new Date(r.at.ms);
        const viewer = Intl.DateTimeFormat().resolvedOptions().timeZone;
        if (zonesDiffer(at, this.zone, viewer)) hint = ` \xB7 ${viewerTime(at, this.zone, viewer, this.hintLabel, locale)}`;
        parts.push(h("span", { class: "dp-zone", "data-viewer-hint": Boolean(hint), text: `${name} (${this.zone})${hint}` }));
      } else if (r.kind === "gap") {
        const day = formatDay(toISO(r.wall.y, r.wall.m, r.wall.d));
        parts.push(
          h("span", { class: "dp-clock", role: "alert", "data-clock": "gap", text: `${wallText(r.wall)} does not exist on ${day} in ${this.zone}: clocks jump forward (${shownOffset(r.before)} to ${shownOffset(r.after)}). Pick another time.` })
        );
      } else if (r.kind === "ambiguous") {
        const day = formatDay(toISO(r.wall.y, r.wall.m, r.wall.d));
        const choose = (c) => {
          const b = h("button", { type: "button", class: "dp-offset", "data-offset": c.offset, text: `${wallText(r.wall)} ${zoneName(this.zone, c.ms)} (${shownOffset(c.offset)})` });
          b.addEventListener("click", () => this.chooseOffset(c.offset));
          return b;
        };
        parts.push(
          h("span", { class: "dp-choice", role: "alert", "data-clock": "ambiguous" }, [
            icon(ICONS.warning),
            h("span", { class: "dp-choice-body" }, [
              h("span", { text: `${wallText(r.wall)} happens twice on ${day} in ${this.zone}: clocks go back. Which one?` }),
              h("span", { class: "dp-choice-buttons" }, [choose(r.first), choose(r.second)])
            ])
          ])
        );
      }
    }
    this.note.replaceChildren(...parts);
    this.note.hidden = parts.length === 0;
    this.el.dataset.resolution = this.kind === "datetime" ? this.resolution.kind : "";
  }
  // ── the popup ───────────────────────────────────────────────────────────
  isSheet() {
    return window.matchMedia(SHEET_QUERY).matches;
  }
  open() {
    if (this.isOpen || this.disabled || !this.hasPopup) return;
    this.isOpen = true;
    if (this.kind === "time") this.timeState = { active: nearest(timeOptions(this.step), this.main.value) };
    else this.calendarState();
    this.renderPopup();
    this.show();
    this.focusInside();
  }
  calendarState() {
    const range = this.kind === "range";
    const start = range ? this.dateOf(this.groups.start.values) : this.dateOf(this.groups.date.values);
    const end = range ? this.dateOf(this.groups.end.values) : null;
    const focus = start || this.today;
    const p = parse(focus);
    this.popupState = {
      mode: range ? "range" : "single",
      view: "days",
      y: p.y,
      m: p.m,
      yearPage: p.y - 5,
      focus,
      selected: { start, end },
      pending: null,
      hover: null,
      rules: this.rules,
      weekStart: this.weekStart,
      locale: this.nameLocale,
      today: this.today,
      idBase: this.idBase
    };
  }
  show() {
    this.el.dataset.state = "open";
    this.popover.setAttribute("aria-hidden", "false");
    this.opener.setAttribute("aria-expanded", "true");
    this.place();
  }
  place() {
    if (!this.isOpen) return;
    if (this.isSheet()) {
      unfit(this.popover);
      this.lock();
    } else {
      this.unlock();
      const visible = fit(this.popover, this.control, "bottom");
      if (!visible) this.close(false);
    }
  }
  close(refocus) {
    if (!this.isOpen) return;
    this.isOpen = false;
    this.el.dataset.state = "closed";
    this.popover.setAttribute("aria-hidden", "true");
    this.opener.setAttribute("aria-expanded", "false");
    unfit(this.popover);
    this.unlock();
    this.popupState = null;
    if (refocus) this.opener.focus({ preventScroll: true });
  }
  lock() {
    if (this.locked) return;
    this.locked = true;
    this.prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
  }
  unlock() {
    if (!this.locked) return;
    this.locked = false;
    document.body.style.overflow = this.prevOverflow || "";
  }
  documentClick(e) {
    const label = e.target.closest?.("label");
    const target = this.main || this.startInput;
    if (label && target && label.htmlFor === target.id) {
      e.preventDefault();
      this.groups[this.kind === "range" ? "start" : this.kind === "time" ? "time" : "date"].focus();
      return;
    }
    if (this.isOpen && !e.composedPath().includes(this.el)) this.close(false);
  }
  /** Draw the popup's content from the state. */
  renderPopup(focusDay = false) {
    const children = [
      h("div", { class: "dp-sheet-head" }, [
        h("span", { class: "dp-sheet-title", text: this.label || (this.kind === "time" ? "Choose a time" : "Choose a date") }),
        (() => {
          const b = h("button", { type: "button", class: "dp-sheet-close", "aria-label": "Close" }, [icon(ICONS.close, "dp-icon dp-icon-lg")]);
          b.addEventListener("click", () => this.close(true));
          return b;
        })()
      ])
    ];
    if (this.kind === "time") {
      const options = timeOptions(this.step);
      children.push(
        renderTimes(options, this.main.value || null, this.timeState.active, this.idBase, (t) => this.pickTime(t))
      );
    } else {
      const presets = this.presetRow();
      if (presets) children.push(presets);
      children.push(renderCalendar(this.popupState, this.calendarHandlers()));
      children.push(h("div", { class: "dp-summary", "aria-live": "polite", text: summary(this.popupState) }));
    }
    this.popover.replaceChildren(...children);
    if (focusDay) this.focusDay();
    this.place();
  }
  focusInside() {
    if (this.kind === "time") {
      const active = this.popover.querySelector('[data-active="true"]') || this.popover.querySelector('[role="option"]');
      active?.scrollIntoView?.({ block: "center" });
      this.popover.querySelector(".dp-times")?.setAttribute("tabindex", "0");
      this.popover.querySelector(".dp-times")?.focus({ preventScroll: true });
      this.updateActiveTime();
    } else {
      this.focusDay();
    }
  }
  focusDay() {
    this.refocusing = true;
    this.popover.querySelector(`.dp-day[data-date="${this.popupState.focus}"]`)?.focus({ preventScroll: true });
    this.refocusing = false;
  }
  calendarHandlers() {
    const s = () => this.popupState;
    const showMonth = (iso) => {
      const p = parse(iso);
      Object.assign(s(), { focus: iso, y: p.y, m: p.m });
    };
    return {
      pick: (iso) => this.pickDay(iso),
      nav: (delta) => {
        const state = s();
        const next = addMonths(`${toISO(state.y, state.m, 1)}`, delta);
        const day = Math.min(parse(state.focus).d, 28);
        showMonth(toISO(parse(next).y, parse(next).m, day));
        if (state.view === "years") state.yearPage += delta / 12;
        this.renderPopup(state.view === "days");
      },
      view: (view) => {
        const state = s();
        state.view = view;
        if (view === "years") state.yearPage = state.y - 5;
        this.renderPopup(view === "days");
      },
      month: (m) => {
        const state = s();
        showMonth(toISO(state.y, m, Math.min(parse(state.focus).d, 28)));
        state.view = "days";
        this.renderPopup(true);
      },
      year: (y) => {
        const state = s();
        showMonth(toISO(y, state.m, Math.min(parse(state.focus).d, 28)));
        state.view = "months";
        this.renderPopup();
      },
      hover: (iso) => {
        const state = s();
        if (!state || this.refocusing || state.hover === iso) return;
        state.hover = iso;
        if (state.mode === "range" && state.pending) this.renderPreview();
      },
      focus: (iso) => {
        s().focus = iso;
      }
    };
  }
  /** Redraw the range preview without moving focus or replacing the hovered button. */
  renderPreview() {
    const state = this.popupState;
    const next = renderCalendar(state, this.calendarHandlers());
    const old = this.popover.querySelector(".dp-cal");
    const hadFocus = document.activeElement?.closest?.(".dp-grid");
    old.replaceWith(next);
    this.popover.querySelector(".dp-summary").textContent = summary(state);
    if (hadFocus) this.focusDay();
  }
  presetRow() {
    const items = this.presets.map((p) => {
      const key = typeof p === "string" ? p : p.key;
      const label = p.label || PRESET_LABELS[key] || key;
      const value = p.value ?? presetValue(key, this.today, this.weekStart);
      return { key, label, value, custom: p.value !== void 0 };
    }).filter((p) => p.value !== null && p.value !== void 0);
    if (!items.length) return null;
    const row = h("div", { class: "dp-presets", role: "group", "aria-label": "Presets" });
    for (const p of items) {
      const range = typeof p.value === "object";
      const wantsRange = this.kind === "range";
      if (range && !wantsRange) continue;
      const days = range ? [p.value.start, p.value.end] : [p.value];
      const refused = wantsRange ? checkRange(this.rules, days[0], days[days.length - 1]) : checkDate(this.rules, days[0]);
      const b = h("button", { type: "button", class: "dp-preset", "data-preset": p.key, "aria-disabled": refused ? "true" : null, text: p.label });
      b.addEventListener("click", () => !refused && this.applyPreset(p, days));
      row.append(b);
    }
    return row.children.length ? row : null;
  }
  applyPreset(p, days) {
    if (this.kind === "range") {
      this.setDays({ start: days[0], end: days[days.length - 1] });
    } else {
      this.setDays({ date: days[0] });
    }
    if (this.presetInput && !p.custom) this.write(this.presetInput, p.key);
    this.close(true);
  }
  /** Put chosen days into the segments and the posted inputs, as if typed. */
  setDays({ date, start, end }) {
    if (this.presetInput) this.presetInput.value = "";
    if (this.kind === "range") {
      this.groups.start.set(dayNumbers(start));
      this.groups.end.set(dayNumbers(end));
      this.write(this.startInput, start);
      this.write(this.endInput, end);
    } else if (this.kind === "datetime") {
      this.groups.date.set(dayNumbers(date));
      this.chosenOffset = null;
      this.resolveDatetime(true);
    } else {
      this.groups.date.set(dayNumbers(date));
      this.write(this.main, date);
    }
    this.refresh();
  }
  pickDay(iso) {
    const s = this.popupState;
    if (s.mode === "range") {
      if (!s.pending || iso < s.pending) {
        s.pending = iso;
        s.hover = iso;
        s.focus = iso;
        this.renderPopup(true);
        return;
      }
      this.setDays({ start: s.pending, end: iso });
      this.close(true);
    } else {
      this.setDays({ date: iso });
      this.close(true);
    }
  }
  pickTime(t) {
    this.groups.time.set({ hour: Number(t.slice(0, 2)), minute: Number(t.slice(3, 5)) });
    this.write(this.main, t);
    this.refresh();
    this.close(true);
  }
  updateActiveTime() {
    const list = this.popover.querySelector(".dp-times");
    if (!list) return;
    for (const o of list.querySelectorAll('[role="option"]')) o.toggleAttribute("data-active", o.dataset.value === this.timeState.active);
    const active = list.querySelector("[data-active]");
    if (active) {
      list.setAttribute("aria-activedescendant", active.id);
      const top = active.offsetTop - list.offsetTop;
      if (top < list.scrollTop) list.scrollTop = top;
      else if (top + active.offsetHeight > list.scrollTop + list.clientHeight) list.scrollTop = top + active.offsetHeight - list.clientHeight;
    }
  }
  /** Keys inside the popup: the grid keys, the list keys, Escape. */
  popupKeys(e) {
    if (e.key === "Escape") {
      e.preventDefault();
      e.stopPropagation();
      this.close(true);
      return;
    }
    if (this.kind === "time") return this.timeKeys(e);
    const day = e.target.closest?.(".dp-day");
    if (!day) return;
    const state = this.popupState;
    const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End", "PageUp", "PageDown"];
    if (!keys.includes(e.key)) return;
    e.preventDefault();
    const next = moveFocus(e.key, e.shiftKey, state.focus, this.weekStart);
    if (!next) return;
    state.focus = next;
    const p = parse(next);
    const same = p.y === state.y && p.m === state.m;
    state.y = p.y;
    state.m = p.m;
    if (same) {
      for (const d of this.popover.querySelectorAll(".dp-day")) d.setAttribute("tabindex", d.dataset.date === next ? "0" : "-1");
      this.focusDay();
    } else {
      this.renderPopup(true);
    }
  }
  timeKeys(e) {
    const options = timeOptions(this.step);
    const at = options.indexOf(this.timeState.active);
    const jump = { ArrowDown: 1, ArrowUp: -1, PageDown: 8, PageUp: -8 }[e.key];
    if (jump !== void 0) {
      e.preventDefault();
      this.timeState.active = options[Math.max(0, Math.min(options.length - 1, at + jump))];
      this.updateActiveTime();
    } else if (e.key === "Home" || e.key === "End") {
      e.preventDefault();
      this.timeState.active = options[e.key === "Home" ? 0 : options.length - 1];
      this.updateActiveTime();
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      this.pickTime(this.timeState.active);
    }
  }
};
var DatePicker = {
  mounted() {
    this.picker = new Picker(this.el);
  },
  updated() {
    this.picker.updated();
  },
  destroyed() {
    this.picker.destroy();
  }
};
var index_default = DatePicker;
export {
  DatePicker,
  Picker,
  core_exports as core,
  index_default as default,
  segments_exports as segments,
  wallText,
  zone_exports as zone
};
