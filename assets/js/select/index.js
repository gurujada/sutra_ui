// Select in forms: the browser half of SutraUI.Select.
//
// The server renders a real <select> (the posted value, no-JS fallback, validation and
// phx-change target) and, beside it, SutraUI's trigger and list built from the same options.
// This hook hides the <select>, opens the list under the field (a bottom sheet on phones),
// keeps the <select> and the list in step and fires the <select>'s own input and change
// events, so forms, phx-change and to_form keep working. The list is ordinary page markup,
// never the browser's option popup, so it shows in a screen share.

import { fit, unfit } from "../fit/index.js";

/** The list gets a search box from this many options when `searchable` is "auto". */
export const AUTO_SEARCH_FROM = 10;
/** The viewport width below which the list opens as a bottom sheet (Tailwind's `sm`). */
export const SHEET_QUERY = "(max-width: 639px)";
/** Type-ahead keeps a typed prefix this long between keys (milliseconds). */
export const TYPEAHEAD_MS = 500;
const PAGE = 10;

/**
 * Whether the list has a search box.
 * @param {"true" | "false" | "auto" | string | undefined} searchable
 * @param {number} count options in the list
 * @returns {boolean}
 */
export function wantsSearch(searchable, count) {
  if (searchable === "true") return true;
  if (searchable === "false") return false;
  return count >= AUTO_SEARCH_FROM;
}

/**
 * Lowercase without accents, so "cafe" finds "Café".
 * @param {string} text
 * @returns {string}
 */
export function fold(text) {
  return String(text ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();
}

/**
 * Whether `label` matches a search `query` (every word of the query appears in it).
 * @param {string} label
 * @param {string} query
 * @returns {boolean}
 */
export function matches(label, query) {
  const hay = fold(label);
  return fold(query)
    .split(/\s+/)
    .filter(Boolean)
    .every((word) => hay.includes(word));
}

/**
 * The next active position after a navigation key.
 * @param {string} key ArrowDown, ArrowUp, Home, End, PageDown or PageUp
 * @param {number} current the active position, -1 for none
 * @param {number} count how many enabled, visible options there are
 * @returns {number} the new position, -1 when there are none
 */
export function move(key, current, count) {
  if (count <= 0) return -1;
  const last = count - 1;
  switch (key) {
    case "ArrowDown":
      return Math.min(current + 1, last);
    case "ArrowUp":
      return current < 0 ? 0 : Math.max(current - 1, 0);
    case "PageDown":
      return Math.min(Math.max(current, 0) + PAGE, last);
    case "PageUp":
      return Math.max(current - PAGE, 0);
    case "Home":
      return 0;
    case "End":
      return last;
    default:
      return current;
  }
}

/**
 * The typed prefix after another key: it restarts when the last key was too long ago.
 * @param {string} buffer
 * @param {string} char
 * @param {number} elapsed milliseconds since the last key
 * @returns {string}
 */
export function pushChar(buffer, char, elapsed) {
  return elapsed > TYPEAHEAD_MS ? char : buffer + char;
}

/**
 * The position a type-ahead prefix selects. One repeated letter ("ccc") cycles through the
 * options starting with it; a longer prefix finds the first option that starts with it,
 * from the active one on, wrapping.
 * @param {string[]} labels labels of the enabled, visible options in order
 * @param {string} buffer what was typed
 * @param {number} current the active position, -1 for none
 * @returns {number} a position, or -1 when nothing starts with it
 */
export function typeahead(labels, buffer, current) {
  const prefix = fold(buffer);
  if (!prefix || labels.length === 0) return -1;
  const repeated = [...prefix].every((c) => c === prefix[0]);
  const needle = repeated ? prefix[0] : prefix;
  const from = repeated ? current + 1 : Math.max(current, 0);
  for (let i = 0; i < labels.length; i++) {
    const at = (from + i) % labels.length;
    if (fold(labels[at]).startsWith(needle)) return at;
  }
  return -1;
}

const text = (el) => (el.dataset.label ?? el.textContent).trim();

export const Select = {
  mounted() {
    this.isOpen = false;
    this.query = "";
    this.typed = "";
    this.typedAt = 0;
    this.locked = false;
    this.active = null;

    this.onClick = (e) => this.click(e);
    this.onKeydown = (e) => this.keydown(e);
    this.onKeyup = (e) => {
      if (e.key === " " && e.target === this.trigger) e.preventDefault();
    };
    this.onInput = (e) => this.input(e);
    this.onMove = (e) => this.hover(e);
    this.onDown = (e) => {
      // Keep the focus where it is (search box or trigger) while the pointer picks an option.
      if (this.popover.contains(e.target) && e.target !== this.search) e.preventDefault();
    };
    this.onDocClick = (e) => this.documentClick(e);
    this.onReset = () => requestAnimationFrame(() => this.sync());
    this.onResize = () => this.place();
    this.onScroll = (e) => {
      if (this.isOpen && !this.popover.contains(e.target)) this.place();
    };

    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("keydown", this.onKeydown);
    this.el.addEventListener("keyup", this.onKeyup);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("change", this.onInput);
    this.el.addEventListener("mousemove", this.onMove);
    this.el.addEventListener("mousedown", this.onDown);
    document.addEventListener("click", this.onDocClick);
    window.addEventListener("resize", this.onResize);
    window.addEventListener("scroll", this.onScroll, { capture: true, passive: true });

    this.refs();
    this.enhance();
    this.ensureFirst();
    this.sync();
  },

  updated() {
    this.refs();
    this.enhance();
    this.sync();
    if (this.isOpen) {
      this.show();
      this.filter();
      if (this.search) this.search.value = this.query;
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("keydown", this.onKeydown);
    this.el.removeEventListener("keyup", this.onKeyup);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("change", this.onInput);
    this.el.removeEventListener("mousemove", this.onMove);
    this.el.removeEventListener("mousedown", this.onDown);
    document.removeEventListener("click", this.onDocClick);
    window.removeEventListener("resize", this.onResize);
    window.removeEventListener("scroll", this.onScroll, { capture: true });
    this.form?.removeEventListener("reset", this.onReset);
    this.unlock();
  },

  // ---- the elements -------------------------------------------------------------------

  refs() {
    const el = this.el;
    this.select = el.querySelector(":scope > select");
    this.holder = el.querySelector(":scope > [data-select-input]"); // custom-option mode
    this.trigger = el.querySelector(":scope > .select-trigger");
    this.popover = el.querySelector(":scope > [data-popover]");
    this.listbox = this.popover.querySelector('[role="listbox"]');
    this.search = this.popover.querySelector('input[role="combobox"]');
    this.shown = el.querySelector("[data-selected-label]");
    this.multiple = this.select ? this.select.multiple : false;

    const form = (this.select || this.holder)?.form;
    if (form !== this.form) {
      this.form?.removeEventListener("reset", this.onReset);
      form?.addEventListener("reset", this.onReset);
      this.form = form;
    }

    this.options = [...this.listbox.querySelectorAll('[role="option"]')];
    this.options.forEach((opt, i) => {
      if (!opt.id) opt.id = `${this.listbox.id}-option-${i}`;
    });
  },

  /** Hide the real <select> from view and the tab order; it stays in the form. */
  enhance() {
    this.el.setAttribute("data-enhanced", "");
    if (this.select) {
      this.select.tabIndex = -1;
      this.select.setAttribute("aria-hidden", "true");
    }
  },

  /** In custom-option mode a select starts on its first option. */
  ensureFirst() {
    if (this.select || this.holder?.value) return;
    const first = this.enabled(false)[0];
    if (first && this.holder) this.holder.value = first.dataset.value;
  },

  /** Enabled options; `visible` leaves out those a search has hidden. */
  enabled(visible = true) {
    return this.options.filter(
      (o) =>
        o.getAttribute("aria-disabled") !== "true" &&
        (!visible || o.getAttribute("aria-hidden") !== "true"),
    );
  },

  // ---- the value ----------------------------------------------------------------------

  values() {
    if (this.select) return [...this.select.options].filter((o) => o.selected).map((o) => o.value);
    return this.holder ? [this.holder.value] : [];
  },

  /** Bring the list marks and the trigger text in line with the <select>. */
  sync() {
    const values = this.values();
    for (const opt of this.options) {
      opt.setAttribute("aria-selected", String(values.includes(opt.dataset.value)));
    }
    if (!this.shown || this.el.hasAttribute("data-custom-trigger")) return;

    const chosen = this.select
      ? [...this.select.options].filter((o) => o.selected && o.value !== "")
      : this.options.filter((o) => o.getAttribute("aria-selected") === "true");
    const labels = chosen.map((o) => (this.select ? o.text : text(o)).trim());
    const empty = labels.length === 0;

    if (this.multiple && !empty) {
      const chips = labels.map((label) => {
        const chip = document.createElement("span");
        chip.className = "select-chip";
        chip.textContent = label;
        return chip;
      });
      this.shown.replaceChildren(...chips);
    } else {
      const now = empty ? this.el.dataset.prompt || "" : labels[0];
      if (this.shown.textContent !== now || this.shown.children.length) this.shown.textContent = now;
    }
    if (empty) this.shown.setAttribute("data-placeholder", "");
    else this.shown.removeAttribute("data-placeholder");
  },

  choose(opt) {
    if (!opt || opt.getAttribute("aria-disabled") === "true") return;
    const value = opt.dataset.value;
    let changed = false;

    if (this.select) {
      const target = [...this.select.options].find((o) => o.value === value);
      if (!target) return;
      if (this.multiple) {
        target.selected = !target.selected;
        changed = true;
      } else if (this.select.value !== value) {
        this.select.value = value;
        changed = true;
      }
    } else if (this.holder && this.holder.value !== value) {
      this.holder.value = value;
      changed = true;
    }

    this.sync();
    if (changed) {
      const source = this.select || this.holder;
      source.dispatchEvent(new Event("input", { bubbles: true }));
      source.dispatchEvent(new Event("change", { bubbles: true }));
    }
    if (!this.multiple) this.close(true);
  },

  // ---- opening ------------------------------------------------------------------------

  isSheet() {
    return window.matchMedia(SHEET_QUERY).matches;
  },

  openList() {
    if (this.isOpen || this.trigger.disabled) return;
    this.isOpen = true;
    this.query = "";
    if (this.search) this.search.value = "";
    this.show();
    this.filter();

    const selected = this.options.find(
      (o) => o.getAttribute("aria-selected") === "true" && o.dataset.value !== "",
    );
    this.setActive(selected || this.enabled()[0] || null);
    if (this.search && !this.isSheet()) this.search.focus({ preventScroll: true });
  },

  /** The open state, on the elements (also reapplied after a patch). */
  show() {
    this.el.dataset.state = "open";
    this.popover.setAttribute("aria-hidden", "false");
    this.trigger.setAttribute("aria-expanded", "true");
    this.search?.setAttribute("aria-expanded", "true");
    this.place();
    this.reveal(this.active);
  },

  /** Scroll the list (never the page) so an option shows. */
  reveal(opt) {
    if (!opt) return;
    const top = opt.offsetTop - this.listbox.offsetTop;
    const bottom = top + opt.offsetHeight;
    if (top < this.listbox.scrollTop) this.listbox.scrollTop = top;
    else if (bottom > this.listbox.scrollTop + this.listbox.clientHeight) {
      this.listbox.scrollTop = bottom - this.listbox.clientHeight;
    }
  },

  /** Fit under (or over) the field on a screen; a bottom sheet on a phone. */
  place() {
    if (!this.isOpen) return;
    if (this.isSheet()) {
      unfit(this.popover);
      this.lock();
    } else {
      this.unlock();
      fit(this.popover, this.trigger, "bottom");
    }
  },

  close(refocus) {
    if (!this.isOpen) return;
    this.isOpen = false;
    this.el.dataset.state = "closed";
    this.popover.setAttribute("aria-hidden", "true");
    this.trigger.setAttribute("aria-expanded", "false");
    this.search?.setAttribute("aria-expanded", "false");
    unfit(this.popover);
    this.unlock();
    this.query = "";
    if (this.search) this.search.value = "";
    this.filter();
    this.setActive(null);
    if (refocus) this.trigger.focus({ preventScroll: true });
  },

  lock() {
    if (this.locked) return;
    this.locked = true;
    this.prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
  },

  unlock() {
    if (!this.locked) return;
    this.locked = false;
    document.body.style.overflow = this.prevOverflow || "";
  },

  // ---- the active option --------------------------------------------------------------

  setActive(opt, scroll = true) {
    if (this.active && this.active !== opt) this.active.removeAttribute("data-active");
    this.active = opt;
    const targets = [this.trigger, this.search].filter(Boolean);
    if (opt) {
      opt.setAttribute("data-active", "true");
      targets.forEach((t) => t.setAttribute("aria-activedescendant", opt.id));
      if (scroll) this.reveal(opt);
    } else {
      targets.forEach((t) => t.removeAttribute("aria-activedescendant"));
    }
  },

  /** Step the active option by a navigation key. */
  step(key) {
    const list = this.enabled();
    const at = this.active ? list.indexOf(this.active) : -1;
    this.setActive(list[move(key, at, list.length)] ?? null);
  },

  remember(char) {
    const now = Date.now();
    this.typed = pushChar(this.typed, char, now - this.typedAt);
    this.typedAt = now;
    const list = this.enabled();
    const at = typeahead(list.map(text), this.typed, this.active ? list.indexOf(this.active) : -1);
    if (at >= 0) this.setActive(list[at]);
  },

  /** Hide the options a search leaves out. */
  filter() {
    const query = this.query.trim();
    for (const opt of this.options) {
      if (!query || matches(text(opt), query)) opt.removeAttribute("aria-hidden");
      else opt.setAttribute("aria-hidden", "true");
    }
    if (this.isOpen && query) {
      const first = this.enabled()[0] || null;
      this.setActive(first, false);
      this.listbox.scrollTop = 0;
    }
  },

  // ---- events -------------------------------------------------------------------------

  click(e) {
    const t = e.target;
    if (t.closest(".select-trigger") === this.trigger) {
      this.isOpen ? this.close(true) : this.openList();
    } else if (t.closest(".select-backdrop") || t.closest("[data-select-close]")) {
      this.close(true);
    } else {
      const opt = t.closest('[role="option"]');
      if (opt && this.listbox.contains(opt)) this.choose(opt);
    }
  },

  documentClick(e) {
    const t = e.target;
    if (this.select) {
      const label = t.closest?.("label");
      if (label && label.htmlFor === this.select.id) {
        e.preventDefault();
        this.trigger.focus();
        return;
      }
    }
    if (this.isOpen && !this.el.contains(t)) this.close(false);
  },

  hover(e) {
    const opt = e.target.closest?.('[role="option"]');
    if (opt && opt !== this.active && this.enabled().includes(opt)) this.setActive(opt, false);
  },

  input(e) {
    if (e.target !== this.search) return;
    // The search box is not a field of the form: its events stop here.
    e.stopPropagation();
    if (e.type === "input") {
      this.query = this.search.value;
      this.filter();
    }
  },

  keydown(e) {
    const inSearch = e.target === this.search;
    if (e.target !== this.trigger && !inSearch) return;
    if (e.ctrlKey || e.metaKey) return;
    const { key } = e;
    const printable = key.length === 1 && key !== " " && !e.altKey;

    if (!this.isOpen) {
      if (["ArrowDown", "ArrowUp", "Enter", " ", "Home", "End"].includes(key)) {
        e.preventDefault();
        this.openList();
        if (key === "Home" || key === "End") this.step(key);
      } else if (printable) {
        e.preventDefault();
        this.openList();
        this.remember(key);
      }
      return;
    }

    switch (key) {
      case "Escape":
        e.preventDefault();
        e.stopPropagation();
        this.close(true);
        break;
      case "ArrowDown":
      case "ArrowUp":
      case "PageDown":
      case "PageUp":
        e.preventDefault();
        this.step(key);
        break;
      case "Home":
      case "End":
        if (!inSearch) {
          e.preventDefault();
          this.step(key);
        }
        break;
      case "Enter":
        e.preventDefault();
        if (this.active) this.choose(this.active);
        else this.close(true);
        break;
      case " ":
        if (!inSearch) {
          e.preventDefault();
          if (this.active) this.choose(this.active);
        }
        break;
      case "Tab":
        // The active option is taken and focus moves on (the select-only combobox pattern).
        if (!this.multiple && this.active) this.choose(this.active);
        this.close(true);
        break;
      default:
        if (printable && !inSearch) {
          e.preventDefault();
          this.remember(key);
        }
    }
  },
};

export default Select;
