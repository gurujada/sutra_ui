// Date and time pickers: the browser half of SutraUI.DatePicker.
//
// The server renders the browser's own <input type="date|time|datetime-local"> (the posted
// field, and the whole picker without JavaScript) inside a wrapper that carries the rules, the
// presets and the zone as data attributes. This hook hides those inputs and draws a segmented
// field (typed, stepped with the arrow keys, pasted), a calendar in a div-based popover (a bottom
// sheet on phones) and, for a datetime, the zone's clock changes: a skipped or repeated wall
// time is shown, never guessed. The inputs stay in the form and get their own input and change
// events, so phx-change, used_input? and validation work as with any input.

import { fit, unfit } from "../fit/index.js";
import { pageLocale, viewerTime, zonesDiffer } from "../time/index.js";
import { renderCalendar, summary } from "./calendar.js";
import {
  PRESET_LABELS,
  addMonths,
  checkDate,
  checkRange,
  checkTime,
  moveFocus,
  parse,
  presetValue,
  rangeLength,
  reasonWords,
  toISO,
} from "./core.js";
import { ICONS, emit, h, icon } from "./dom.js";
import { dateParts, segmentGroup, timeParts } from "./fields.js";
import { assemble, parseDateText, parseTimeText } from "./segments.js";
import { nearest, renderTimes, timeOptions } from "./times.js";
import { formatOffset, fromISO, isoWithOffset, parseWall, resolveWall, wallValue, zoneName } from "./zone.js";

export * as core from "./core.js";
export * as segments from "./segments.js";
export * as zone from "./zone.js";

export const SHEET_QUERY = "(max-width: 639px)";

const json = (text, fallback) => {
  try {
    return JSON.parse(text ?? "") ?? fallback;
  } catch {
    return fallback;
  }
};

const dayNumbers = (iso) => {
  const p = parse(iso);
  return p ? { day: p.d, month: p.m, year: p.y } : { day: null, month: null, year: null };
};

export class Picker {
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
    this.locale = d.locale || pageLocale();
    this.weekStart = Number(d.weekStart) || 1;
    this.rules = json(d.rules, {});
    this.presets = json(d.presets, []);
    this.label = d.label || "";
    this.step = Number(d.step) || 1;
    this.hintLabel = d.hintLabel || "your time";
    this.idBase = this.el.id.replace(/-wrapper$/, "");
    this.today = this.rules.today || new Date().toISOString().slice(0, 10);
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
    const dateGroup = (key, label) =>
      segmentGroup({
        parts: dateOrder.parts,
        separator: dateOrder.separator,
        label,
        disabled: this.disabled,
        onEdit: onDate(key),
        parsePaste: (text) => {
          const iso = parseDateText(text, dateOrder.parts.map((p) => p.key));
          return iso ? dayNumbers(iso) : null;
        },
      });
    const timeGroup = () =>
      segmentGroup({
        parts: timeParts(this.step),
        separator: ":",
        label: `${this.label || "Time"}, time`,
        disabled: this.disabled,
        onEdit: (values) => this.edited("time", values),
        parsePaste: (text) => {
          const t = parseTimeText(text);
          return t ? { hour: Number(t.slice(0, 2)), minute: Number(t.slice(3, 5)) } : null;
        },
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
      control.append(this.groups.start.root, h("span", { class: "dp-dash", "aria-hidden": "true", text: "–" }), this.groups.end.root, this.length);
    } else if (this.kind === "time") {
      this.groups.time = timeGroup();
      control.append(this.groups.time.root);
    } else {
      this.groups.date = dateGroup("date", `${this.label || "Date and time"}, date`);
      this.groups.time = timeGroup();
      this.groups.date.links.after = this.groups.time;
      control.append(this.groups.date.root, h("span", { class: "dp-dash", "aria-hidden": "true", text: "·" }), this.groups.time.root);
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
        disabled: this.disabled,
      }, [icon(isTime ? ICONS.clock : ICONS.calendar)]);
      this.opener.addEventListener("click", () => (this.isOpen ? this.close(true) : this.open()));
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
        "data-kind": this.kind,
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
      // The browser's own datetime-local posts no offset: the hook's input posts instead.
      this.main.disabled = true;
      this.posted.disabled = this.disabled;
    }
  }

  // ── native inputs → segments ─────────────────────────────────────────────

  snapshot() {
    // A datetime's own input is only a mirror of what the posted one says (and of what was
    // typed while it said nothing): the posted value is what the server can change.
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
        const [hh, mm] = (this.main.value || "").split(":").map((v) => (v === "" || v === undefined ? null : Number(v)));
        this.groups.time.set({ hour: hh ?? null, minute: mm ?? null });
        break;
      }
      default: {
        const exact = this.posted.value ? fromISO(this.posted.value, this.zone) : null;
        const wall = exact?.wall ?? parseWall(this.main.value);
        this.groups.date.set(wall ? dayNumbers(toISO(wall.y, wall.m, wall.d)) : dayNumbers(""));
        this.groups.time.set(wall ? { hour: wall.h, minute: wall.mi } : { hour: null, minute: null });
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
    // Only a change from the server touches the segments: a half-typed value is not posted,
    // so a patch with nothing new must not wipe it.
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
    let wallText = "";

    if (date && time) {
      const d = parse(date);
      const wall = { y: d.y, m: d.m, d: d.d, h: Number(time.slice(0, 2)), mi: Number(time.slice(3, 5)) };
      wallText = wallValue(wall);
      const r = resolveWall(this.zone, wall);
      if (r.kind === "ok") {
        this.resolution = { kind: "ok", wall, at: r.at };
        posted = isoWithOffset(wall, r.at.offset);
      } else if (r.kind === "ambiguous") {
        const chosen = [r.first, r.second].find((c) => c.offset === this.chosenOffset);
        if (chosen) {
          this.resolution = { kind: "ok", wall, at: chosen, wasAmbiguous: true };
          posted = isoWithOffset(wall, chosen.offset);
        } else {
          this.resolution = { kind: "ambiguous", wall, first: r.first, second: r.second };
        }
      } else {
        this.resolution = { kind: "gap", wall, before: r.before, after: r.after };
      }
    }
    this.lastWall = wallText;
    if (notify) {
      this.write(this.main, wallText, true);
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
      reason = a && b ? checkRange(rules, a, b) : (a && checkDate(rules, a)) || (b && checkDate(rules, b)) || null;
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
    const gap = this.kind === "datetime" && ["gap", "ambiguous"].includes(this.resolution?.kind);
    // The server's own verdict (a changeset error) rides on the input it renders.
    const source = this.main || this.startInput;
    const server = source?.getAttribute("aria-invalid") === "true";
    const described = [source?.getAttribute("aria-describedby"), `${this.idBase}-note`].filter(Boolean).join(" ");
    for (const g of Object.values(this.groups)) g.setInvalid(Boolean(reason) || gap || server, described);
    this.el.toggleAttribute("data-invalid", Boolean(reason) || gap || server);
  }

  renderNote() {
    const parts = [];
    if (this.reasonText) parts.push(h("span", { class: "dp-reason", "data-reason": this.reason, text: this.reasonText }));

    if (this.kind === "datetime") {
      const r = this.resolution;
      const locale = this.locale;
      if (r.kind === "ok") {
        const name = zoneName(this.zone, r.at.ms);
        let hint = "";
        const at = new Date(r.at.ms);
        const viewer = Intl.DateTimeFormat().resolvedOptions().timeZone;
        if (zonesDiffer(at, this.zone, viewer)) hint = ` · ${viewerTime(at, this.zone, viewer, this.hintLabel, locale)}`;
        parts.push(h("span", { class: "dp-zone", "data-viewer-hint": Boolean(hint), text: `${name} (${this.zone})${hint}` }));
      } else if (r.kind === "gap") {
        const t = `${String(r.wall.h).padStart(2, "0")}:${String(r.wall.mi).padStart(2, "0")}`;
        parts.push(
          h("span", { class: "dp-clock", role: "alert", "data-clock": "gap", text: `${t} does not exist on this day in ${this.zone}: clocks jump forward (${formatOffset(r.before)} to ${formatOffset(r.after)}). Pick another time.` }),
        );
      } else if (r.kind === "ambiguous") {
        const t = `${String(r.wall.h).padStart(2, "0")}:${String(r.wall.mi).padStart(2, "0")}`;
        const choose = (c, which) => {
          const b = h("button", { type: "button", class: "dp-offset", "data-offset": c.offset, text: `${which}: ${zoneName(this.zone, c.ms)} (${formatOffset(c.offset)})` });
          b.addEventListener("click", () => this.chooseOffset(c.offset));
          return b;
        };
        parts.push(
          h("span", { class: "dp-clock", role: "alert", "data-clock": "ambiguous" }, [
            `${t} happens twice on this day in ${this.zone}: clocks go back. Which one? `,
            choose(r.first, "First"),
            choose(r.second, "Second"),
          ]),
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
      locale: this.locale,
      today: this.today,
      idBase: this.idBase,
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
    // composedPath, not contains(): a click on a button the popup has since replaced is inside.
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
        })(),
      ]),
    ];

    if (this.kind === "time") {
      const options = timeOptions(this.step);
      children.push(
        renderTimes(options, this.main.value || null, this.timeState.active, this.idBase, (t) => this.pickTime(t)),
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
    // Focusing a day is not the pointer moving over it: it must not move the range preview.
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
      },
    };
  }

  /** Redraw the range preview without moving focus or replacing the hovered button. */
  renderPreview() {
    const state = this.popupState;
    const next = renderCalendar(state, this.calendarHandlers());
    const old = this.popover.querySelector(".dp-cal");
    // Replace the grid only when the preview changed, then put focus back.
    const hadFocus = document.activeElement?.closest?.(".dp-grid");
    old.replaceWith(next);
    this.popover.querySelector(".dp-summary").textContent = summary(state);
    if (hadFocus) this.focusDay();
  }

  presetRow() {
    const items = this.presets
      .map((p) => {
        const key = typeof p === "string" ? p : p.key;
        const label = p.label || PRESET_LABELS[key] || key;
        const value = p.value ?? presetValue(key, this.today, this.weekStart);
        return { key, label, value, custom: p.value !== undefined };
      })
      .filter((p) => p.value !== null && p.value !== undefined);
    if (!items.length) return null;
    const row = h("div", { class: "dp-presets", role: "group", "aria-label": "Presets" });
    for (const p of items) {
      const range = typeof p.value === "object";
      const wantsRange = this.kind === "range";
      if (range && !wantsRange) continue; // a range preset has no place in a one-day picker
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
    const active = list.querySelector('[data-active]');
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
    if (jump !== undefined) {
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
}

/** @type {import("phoenix_live_view").ViewHook & Record<string, any>} */
export const DatePicker = {
  mounted() {
    this.picker = new Picker(this.el);
  },
  updated() {
    this.picker.updated();
  },
  destroyed() {
    this.picker.destroy();
  },
};

export default DatePicker;
