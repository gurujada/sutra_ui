/* sutra_ui select source-hash:ea29019b05b7961b (built by mix assets.build; do not edit) */

// assets/js/fit/index.js
function fit(content, trigger, wanted) {
  if (!content || !trigger) return;
  const margin = 8;
  const gap = 4;
  const vw = document.documentElement.clientWidth;
  const vh = window.innerHeight;
  content.style.marginLeft = "";
  content.style.marginRight = "";
  content.style.marginTop = "";
  content.style.marginBottom = "";
  content.style.maxWidth = vw - 2 * margin + "px";
  content.style.maxHeight = "";
  if (wanted && wanted !== "auto") content.setAttribute("data-side", wanted);
  const t = trigger.getBoundingClientRect();
  const w = content.offsetWidth;
  const h = content.offsetHeight;
  let side = content.getAttribute("data-side") || "bottom";
  const below = vh - margin - t.bottom - gap;
  const above = t.top - gap - margin;
  if (side === "bottom" && h > below && (h <= above || above > below)) side = "top";
  else if (side === "top" && h > above && (h <= below || below > above)) side = "bottom";
  else if (side === "right" && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = "left";
  else if (side === "left" && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = "right";
  content.setAttribute("data-side", side);
  if (side === "bottom") content.style.maxHeight = Math.max(below, 120) + "px";
  if (side === "top") content.style.maxHeight = Math.max(above, 120) + "px";
  const r = content.getBoundingClientRect();
  const left = r.left + (r.width - content.offsetWidth) / 2;
  const top = r.top + (r.height - content.offsetHeight) / 2;
  const width = content.offsetWidth;
  const height = content.offsetHeight;
  let dx = 0;
  let dy = 0;
  if (left + width > vw - margin) dx = vw - margin - (left + width);
  if (left + dx < margin) dx = margin - left;
  if (side === "left" || side === "right") {
    if (top + height > vh - margin) dy = vh - margin - (top + height);
    if (top + dy < margin) dy = margin - top;
  }
  if (dx) {
    content.style.marginLeft = dx + "px";
    content.style.marginRight = -dx + "px";
  }
  if (dy) {
    content.style.marginTop = dy + "px";
    content.style.marginBottom = -dy + "px";
  }
}
function unfit(content) {
  if (!content) return;
  for (const p of ["marginLeft", "marginRight", "marginTop", "marginBottom", "maxWidth", "maxHeight"]) {
    content.style[p] = "";
  }
  content.removeAttribute("data-side");
}

// assets/js/select/index.js
var AUTO_SEARCH_FROM = 10;
var SHEET_QUERY = "(max-width: 639px)";
var TYPEAHEAD_MS = 500;
var PAGE = 10;
function wantsSearch(searchable, count) {
  if (searchable === "true") return true;
  if (searchable === "false") return false;
  return count >= AUTO_SEARCH_FROM;
}
function fold(text2) {
  return String(text2 ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}
function matches(label, query) {
  const hay = fold(label);
  return fold(query).split(/\s+/).filter(Boolean).every((word) => hay.includes(word));
}
function move(key, current, count) {
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
function pushChar(buffer, char, elapsed) {
  return elapsed > TYPEAHEAD_MS ? char : buffer + char;
}
function typeahead(labels, buffer, current) {
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
var text = (el) => (el.dataset.label ?? el.textContent).trim();
var Select = {
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
    this.holder = el.querySelector(":scope > [data-select-input]");
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
      (o) => o.getAttribute("aria-disabled") !== "true" && (!visible || o.getAttribute("aria-hidden") !== "true")
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
    const chosen = this.select ? [...this.select.options].filter((o) => o.selected && o.value !== "") : this.options.filter((o) => o.getAttribute("aria-selected") === "true");
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
      (o) => o.getAttribute("aria-selected") === "true" && o.dataset.value !== ""
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
    this.active?.scrollIntoView?.({ block: "nearest" });
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
      if (scroll) opt.scrollIntoView?.({ block: "nearest" });
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
        if (!this.multiple && this.active) this.choose(this.active);
        this.close(true);
        break;
      default:
        if (printable && !inSearch) {
          e.preventDefault();
          this.remember(key);
        }
    }
  }
};
var index_default = Select;
export {
  AUTO_SEARCH_FROM,
  SHEET_QUERY,
  Select,
  TYPEAHEAD_MS,
  index_default as default,
  fold,
  matches,
  move,
  pushChar,
  typeahead,
  wantsSearch
};
