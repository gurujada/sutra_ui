// The calendar popup's body: a month grid, a month list and a year list, drawn from a state
// object. It is rebuilt from that state after every change (a month has 42 buttons), which
// keeps the keyboard, the range preview and the rules in one place.

import { addDays, checkDate, endRefused, monthGrid, monthNames, parse, rangeLength, reasonWords, toISO, weekdayNames } from "./core.js";
import { formatDay } from "../time/index.js";
import { ICONS, h, icon } from "./dom.js";

/**
 * @typedef {{
 *   mode: "single" | "range", view: "days" | "months" | "years",
 *   y: number, m: number, yearPage: number, focus: string,
 *   selected: { start: string | null, end: string | null },
 *   pending: string | null, hover: string | null,
 *   rules: import("./core.js").Rules, weekStart: number, locale: string | undefined, today: string, idBase: string
 * }} CalendarState
 * @typedef {{ pick: (iso: string) => void, nav: (delta: number) => void, view: (v: "days" | "months" | "years") => void,
 *   month: (m: number) => void, year: (y: number) => void, hover: (iso: string | null) => void,
 *   focus: (iso: string) => void }} CalendarHandlers
 */

/** "Mon 5 Oct 2026": the weekday and the date in the words of `SutraUI.Time`. */
const dayLabel = (iso) => `${formatDay(iso, "day")} ${parse(iso).y}`;

/** The inclusive range being shown: the chosen one, or the pending start up to the hovered day. */
export function shownRange(state) {
  if (state.mode !== "range") return null;
  const { start, end } = state.selected;
  if (state.pending) {
    const to = state.hover && state.hover >= state.pending ? state.hover : state.pending;
    return { start: state.pending, end: to, drawing: true };
  }
  return start && end ? { start, end, drawing: false } : start ? { start, end: start, drawing: false } : null;
}

/** The words under the grid: what is chosen, and for a range its length. */
export function summary(state) {
  const range = shownRange(state);
  if (state.mode === "range") {
    if (!range) return "Pick the first day";
    const length = rangeLength(range.start, range.end);
    if (state.pending && !state.hover) return `${formatDay(range.start)}, pick the last day`;
    return `${formatDay(range.start)} – ${formatDay(range.end)} · ${length} ${length === 1 ? "day" : "days"}`;
  }
  return state.selected.start ? dayLabel(state.selected.start) : "";
}

/**
 * @param {CalendarState} state
 * @param {CalendarHandlers} cb
 * @returns {HTMLElement}
 */
export function renderCalendar(state, cb) {
  const root = h("div", { class: "dp-cal", "data-view": state.view });
  const names = monthNames(state.locale);
  const title = `${names[state.m - 1]} ${state.y}`;

  const navLabel = state.view === "days" ? ["Previous month", "Next month"] : state.view === "months" ? ["Previous year", "Next year"] : ["Previous years", "Next years"];
  const step = state.view === "days" ? 1 : state.view === "months" ? 12 : 144;

  root.append(
    h("div", { class: "dp-cal-head" }, [
      navButton(navLabel[0], ICONS.prev, () => cb.nav(-step)),
      h("div", { class: "dp-cal-title", "aria-live": "polite" }, [
        h("button", { type: "button", class: "dp-title-btn", "data-pick": "month", "aria-label": `Month, ${names[state.m - 1]}`, text: names[state.m - 1], "aria-expanded": state.view === "months" }),
        h("button", { type: "button", class: "dp-title-btn", "data-pick": "year", "aria-label": `Year, ${state.y}`, text: String(state.y), "aria-expanded": state.view === "years" }),
      ]),
      navButton(navLabel[1], ICONS.next, () => cb.nav(step)),
    ]),
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

function monthList(state, cb) {
  const short = monthNames(state.locale, "short");
  const list = h("div", { class: "dp-months", role: "group", "aria-label": `Months of ${state.y}` });
  short.forEach((name, i) => {
    const isToday = state.today.slice(0, 7) === `${String(state.y).padStart(4, "0")}-${String(i + 1).padStart(2, "0")}`;
    const b = h("button", { type: "button", class: "dp-cell", "data-current": i + 1 === state.m, "data-today": isToday, "aria-pressed": i + 1 === state.m, "aria-current": isToday ? "date" : null, text: name });
    b.addEventListener("click", () => cb.month(i + 1));
    list.append(b);
  });
  return list;
}

function yearList(state, cb) {
  const list = h("div", { class: "dp-years", role: "group", "aria-label": "Years" });
  for (let i = 0; i < 12; i++) {
    const year = state.yearPage + i;
    const isToday = Number(state.today.slice(0, 4)) === year;
    const b = h("button", { type: "button", class: "dp-cell", "data-current": year === state.y, "data-today": isToday, "aria-pressed": year === state.y, "aria-current": isToday ? "date" : null, text: String(year) });
    b.addEventListener("click", () => cb.year(year));
    list.append(b);
  }
  return list;
}

function dayGrid(state, cb, title) {
  const range = shownRange(state);
  const grid = h("div", { class: "dp-grid", role: "grid", "aria-label": title });
  grid.append(
    h("div", { class: "dp-row", role: "row" }, weekdayNames(state.weekStart, state.locale).map((n) => h("span", { class: "dp-weekday", role: "columnheader", text: n }))),
  );

  for (const week of monthGrid(state.y, state.m, state.weekStart)) {
    const row = h("div", { class: "dp-row", role: "row" });
    for (const iso of week) {
      const { m, d } = parse(iso);
      const outside = m !== state.m;
      const reason = refusal(state, iso);
      const isStart = state.selected.start === iso && state.mode === "single";
      const inRange = range && iso >= range.start && iso <= range.end;
      const selected = isStart || (range && (iso === range.start || iso === range.end));
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
        text: String(d),
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

/** Why a day cannot be chosen now: the rules, and for a range being drawn its length. */
export function refusal(state, iso) {
  const day = checkDate(state.rules, iso);
  if (day) return day;
  if (iso === state.pending) return null; // the start itself stays pickable (it restarts the range)
  if (state.mode === "range" && state.pending && endRefused(state.rules, state.pending, iso)) {
    const length = rangeLength(state.pending, iso);
    return state.rules.maxLength && length > state.rules.maxLength ? "too_long" : "too_short";
  }
  return null;
}

/** Re-export for the picker's focus handling. */
export { addDays, toISO };
