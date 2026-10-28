/* sutra_ui commands source-hash:d1ecd821f7d45272 (built by mix assets.build; do not edit) */

// assets/js/commands/match.js
var PREFIX = 6;
var INFIX = 3;
var TYPO = 2;
var KEYWORD_PENALTY = 1;
var FIRST_TOKEN_BONUS = 3;
var MIN_TYPO_LENGTH = 5;
function normalize(text) {
  return String(text ?? "").normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
}
function tokens(text) {
  return normalize(text).match(/[\p{L}\p{N}]+/gu) ?? [];
}
function distance(a, b) {
  const x = Array.from(a);
  const y = Array.from(b);
  const rows2 = x.length + 1;
  const cols = y.length + 1;
  const d = Array.from({ length: rows2 }, (_, i) => {
    const row = new Array(cols).fill(0);
    row[0] = i;
    return row;
  });
  for (let j = 0; j < cols; j++) d[0][j] = j;
  for (let i = 1; i < rows2; i++) {
    for (let j = 1; j < cols; j++) {
      const cost = x[i - 1] === y[j - 1] ? 0 : 1;
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost);
      if (i > 1 && j > 1 && x[i - 1] === y[j - 2] && x[i - 2] === y[j - 1]) {
        d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1);
      }
    }
  }
  return d[rows2 - 1][cols - 1];
}
function wordClass(word, token) {
  if (token.startsWith(word)) return PREFIX;
  if (word.length >= 2 && token.includes(word)) return INFIX;
  if (word.length >= MIN_TYPO_LENGTH) {
    const chars = Array.from(token);
    for (const length of [word.length - 1, word.length, word.length + 1]) {
      if (length <= chars.length && distance(word, chars.slice(0, length).join("")) === 1) {
        return TYPO;
      }
    }
  }
  return 0;
}
function score(query, title, keywords = []) {
  const words = tokens(query);
  if (words.length === 0) return 0;
  const titleTokens = tokens(title);
  const pool = [
    ...titleTokens.map((token) => ({ token, keyword: false })),
    ...tokens(keywords.join(" ")).map((token) => ({ token, keyword: true }))
  ];
  let from = 0;
  let total = 0;
  let firstAtStart = false;
  for (const [n, word] of words.entries()) {
    let best = null;
    for (const cls of [PREFIX, INFIX, TYPO]) {
      for (let i = from; i < pool.length; i++) {
        if (wordClass(word, pool[i].token) === cls) {
          best = { i, cls };
          break;
        }
      }
      if (best) break;
    }
    if (!best) return null;
    total += best.cls - (pool[best.i].keyword ? KEYWORD_PENALTY : 0);
    if (n === 0 && best.i === 0 && best.cls === PREFIX) firstAtStart = true;
    from = best.i + 1;
  }
  return total + (firstAtStart ? FIRST_TOKEN_BONUS : 0);
}
function rank(query, items2, text) {
  const scored = [];
  items2.forEach((item, index) => {
    const { title, keywords } = text(item);
    const s = score(query, title, keywords ?? []);
    if (s !== null) scored.push({ item, index, s, length: Array.from(title).length });
  });
  scored.sort((a, b) => b.s - a.s || a.length - b.length || a.index - b.index);
  return scored.map((entry) => entry.item);
}

// assets/js/commands/model.js
function initial() {
  return {
    open: false,
    stack: [],
    query: "",
    active: 0,
    results: {},
    confirm: null,
    status: null,
    refs: 0
  };
}
function page(state) {
  return state.stack[state.stack.length - 1];
}
function trail(state) {
  return state.stack.map((p) => p.type === "ask" ? p.arg.label || p.action.title : p.title);
}
function placeholder(state) {
  const p = page(state);
  if (p?.type === "ask") return p.arg.placeholder || p.arg.label || null;
  return null;
}
function itemText(action) {
  return { title: action.title, keywords: [...action.keywords ?? [], action.section ?? ""] };
}
function sectionOf(action) {
  return action.section || null;
}
function grouped(actions, fallbackHeading) {
  const order = [];
  const bySection = /* @__PURE__ */ new Map();
  for (const action of actions) {
    const key2 = sectionOf(action) ?? fallbackHeading ?? "";
    if (!bySection.has(key2)) {
      bySection.set(key2, []);
      order.push(key2);
    }
    bySection.get(key2).push(action);
  }
  const rows2 = [];
  for (const key2 of order) {
    if (key2) rows2.push({ type: "heading", id: `section:${key2}`, title: key2 });
    for (const action of bySection.get(key2)) rows2.push({ type: "item", action });
  }
  return rows2;
}
function rows(state, ctx) {
  const query = state.query.trim();
  const p = page(state);
  if (p?.type === "ask") return askRows(state, p, query);
  if (p?.type === "shortcuts") {
    const withKeys = ctx.actions.filter((a) => a.shortcut);
    const open = { id: "sutra:open", title: "Open the command palette", shortcut: ctx.openShortcut, inert: true };
    return [...ctx.openShortcut ? [{ type: "item", action: open }] : [], ...withKeys.map((a) => ({ type: "item", action: a }))];
  }
  const actions = p ? p.actions : ctx.actions;
  const out = [];
  if (!query) {
    if (!p && ctx.recent?.length) {
      const recent = ctx.recent.map((id) => actions.find((a) => a.id === id)).filter(Boolean);
      if (recent.length) {
        out.push({ type: "heading", id: "section:recent", title: "Recent" });
        for (const action of recent) out.push({ type: "item", action, recent: true });
      }
    }
    const recentIds = new Set(out.filter((r) => r.type === "item").map((r) => r.action.id));
    const rest = actions.filter((a) => !recentIds.has(a.id));
    return out.concat(grouped(rest, p ? null : out.length ? "More" : null));
  }
  const ranked = rank(query, actions, itemText);
  out.push(...grouped(ranked, null));
  if (!p) {
    for (const source of ctx.sources ?? []) {
      const found = state.results[source.id]?.items ?? [];
      if (found.length) {
        out.push({ type: "heading", id: `source:${source.id}`, title: source.title });
        for (const action of found) out.push({ type: "item", action });
      }
    }
  }
  return out;
}
function askRows(state, p, query) {
  if (p.arg.type === "choice") {
    const choices = (p.arg.choices ?? []).map((c) => ({
      id: `${p.action.id}:${c.value}`,
      title: c.label,
      keywords: c.keywords ?? [],
      value: c.value
    }));
    const list = query ? rank(query, choices, itemText) : choices;
    return list.map((action) => ({ type: "item", action, choice: action.value }));
  }
  if (p.arg.type === "search") {
    const found = state.results[p.arg.source]?.items ?? [];
    return found.map((action) => ({ type: "item", action, choice: action.id }));
  }
  return [];
}
function items(state, ctx) {
  return rows(state, ctx).filter((r) => r.type === "item");
}
function activeItem(state, ctx) {
  return items(state, ctx)[state.active];
}
function announcement(state, ctx) {
  if (state.status) return state.status;
  const p = page(state);
  const count = items(state, ctx).length;
  const searching = Object.values(state.results).some((r) => r.loading);
  if (p?.type === "ask" && p.arg.type === "text") return p.arg.label || "Type a value and press Enter";
  if (searching && count === 0) return "Searching";
  if (count === 0) return "No results";
  return count === 1 ? "1 result" : `${count} results`;
}
function move(state, ctx, delta) {
  const list = items(state, ctx);
  const enabled = list.map((r, i) => r.action.disabled ? -1 : i).filter((i) => i >= 0);
  if (enabled.length === 0) return { ...state, active: 0 };
  const at = enabled.indexOf(state.active);
  const next = at === -1 ? delta > 0 ? 0 : enabled.length - 1 : (at + delta + enabled.length) % enabled.length;
  return { ...state, active: enabled[next] };
}
function settle(state, ctx) {
  const list = items(state, ctx);
  if (list.length === 0) return { ...state, active: 0 };
  const active = Math.min(state.active, list.length - 1);
  if (!list[active].action.disabled) return { ...state, active };
  const first = list.findIndex((r) => !r.action.disabled);
  return { ...state, active: first === -1 ? 0 : first };
}
function searchAll(state, ctx) {
  const query = state.query.trim();
  const effects = [];
  const results = { ...state.results };
  let refs = state.refs;
  for (const source of ctx.sources ?? []) {
    if (!query) {
      results[source.id] = { ref: ++refs, loading: false, items: [] };
      continue;
    }
    results[source.id] = { ...results[source.id] ?? { items: [] }, ref: ++refs, loading: true };
    effects.push({ effect: "search", source: source.id, query, ref: refs });
  }
  return { state: { ...state, results, refs }, effects };
}
function searchArg(state, arg) {
  const ref = state.refs + 1;
  const query = state.query.trim();
  return {
    state: {
      ...state,
      refs: ref,
      results: { ...state.results, [arg.source]: { ...state.results[arg.source] ?? { items: [] }, ref, loading: true } }
    },
    effects: [{ effect: "search", source: arg.source, query, ref }]
  };
}
function push(state, nextPage) {
  return { ...state, stack: [...state.stack, nextPage], query: "", active: 0, status: null, confirm: null };
}
function pop(state) {
  return { ...state, stack: state.stack.slice(0, -1), query: "", active: 0, status: null, confirm: null };
}
function proceed(state, ctx, action, args, confirmed) {
  const missing = (action.args ?? []).find((a) => !(a.name in args));
  if (missing) {
    const next = push(state, { type: "ask", action, arg: missing, args });
    return missing.type === "search" ? searchArg(next, missing) : { state: next, effects: [] };
  }
  if (action.confirm && !confirmed) {
    return { state: { ...state, confirm: { action, args }, status: null }, effects: [] };
  }
  return { state: { ...state, confirm: null }, effects: [{ effect: "run", action, args }] };
}
function choose(state, ctx, row) {
  const action = row.action;
  if (action.inert) return { state, effects: [] };
  if (action.disabled) {
    const reason = typeof action.disabled === "string" ? action.disabled : "Not available";
    return { state: { ...state, status: `${action.title}: ${reason}` }, effects: [] };
  }
  const p = page(state);
  if (p?.type === "ask") {
    const args = { ...p.args, [p.arg.name]: row.choice };
    const base = { ...state, stack: state.stack.slice(0, -1), query: "", active: 0, status: null };
    return proceed(base, ctx, p.action, args, false);
  }
  if (action.children?.length && !action.kind) {
    return { state: push(state, { type: "actions", title: action.title, actions: action.children }), effects: [] };
  }
  return proceed(state, ctx, action, {}, false);
}
function drill(state, ctx) {
  const action = activeItem(state, ctx)?.action;
  if (!action?.children?.length || action.disabled) return null;
  return { state: push(state, { type: "actions", title: action.title, actions: action.children }), effects: [] };
}
function step(state, event, ctx) {
  switch (event.type) {
    case "open": {
      const base = { ...initial(), open: true };
      if (event.page === "shortcuts") {
        return { state: { ...base, stack: [{ type: "shortcuts", title: "Keyboard shortcuts" }] }, effects: [] };
      }
      return { state: base, effects: [] };
    }
    case "close":
      return { state: { ...initial() }, effects: [] };
    case "start": {
      const base = { ...initial(), open: true };
      return choose(base, ctx, { action: event.action });
    }
    case "input": {
      let next = { ...state, query: event.value, active: 0, status: null, confirm: null };
      const p = page(next);
      if (!p) return searchAll(next, ctx);
      if (p.type === "ask" && p.arg.type === "search") return searchArg(next, p.arg);
      return { state: next, effects: [] };
    }
    case "results": {
      const current = state.results[event.source];
      if (!current || current.ref !== event.ref) return { state, effects: [] };
      const results = {
        ...state.results,
        [event.source]: { ...current, loading: false, items: event.error ? [] : event.items ?? [], error: event.error ?? null }
      };
      const next = { ...state, results };
      return { state: next, effects: [] };
    }
    case "pick": {
      const row = items(state, ctx)[event.index];
      if (!row) return { state, effects: [] };
      return choose({ ...state, active: event.index }, ctx, row);
    }
    case "failed":
      return { state: { ...state, status: event.message || "That did not work", confirm: null }, effects: [] };
    case "key":
      return key(state, event, ctx);
    default:
      return { state, effects: [] };
  }
}
function key(state, e, ctx) {
  const none = { state, effects: [], handled: false };
  const handled = (result) => ({ ...result, handled: true });
  const p = page(state);
  if (state.confirm) {
    if (e.key === "Enter") {
      const { action, args } = state.confirm;
      return handled(proceed({ ...state, confirm: null }, ctx, action, args, true));
    }
    if (e.key === "Escape" || e.key === "Backspace") {
      return handled({ state: { ...state, confirm: null }, effects: [] });
    }
    return handled({ state, effects: [] });
  }
  switch (e.key) {
    case "ArrowDown":
      return handled({ state: move(state, ctx, 1), effects: [] });
    case "ArrowUp":
      return handled({ state: move(state, ctx, -1), effects: [] });
    case "Enter": {
      if (p?.type === "ask" && p.arg.type === "text") {
        const value = state.query.trim();
        if (!value && p.arg.required !== false) {
          return handled({ state: { ...state, status: "Type a value first" }, effects: [] });
        }
        const args = { ...p.args, [p.arg.name]: value };
        const base = { ...state, stack: state.stack.slice(0, -1), query: "", active: 0, status: null };
        return handled(proceed(base, ctx, p.action, args, false));
      }
      const row = items(state, ctx)[state.active];
      if (!row) return handled({ state, effects: [] });
      return handled(choose(state, ctx, row));
    }
    case "ArrowRight":
    case "Tab": {
      if (e.key === "ArrowRight" && !e.caretAtEnd) return none;
      const opened = drill(state, ctx);
      return opened ? handled(opened) : none;
    }
    case "Backspace":
      if (state.query === "" && state.stack.length > 0) return handled({ state: pop(state), effects: [] });
      return none;
    case "Escape":
      if (state.stack.length > 0) return handled({ state: pop(state), effects: [] });
      return none;
    // the dialog closes on Escape
    default:
      return none;
  }
}
function reduce(state, event, ctx) {
  const result = step(state, event, ctx);
  return { ...result, state: settle(result.state, ctx) };
}

// assets/js/commands/keys.js
var SEQUENCE_TIMEOUT_MS = 1e3;
var MODIFIERS = ["mod", "ctrl", "meta", "alt", "shift"];
var NAMED = { esc: "escape", space: " ", return: "enter", plus: "+" };
function parse(spec) {
  return String(spec ?? "").trim().split(/\s+/).filter(Boolean).map((part) => {
    const chord = { key: "", mod: false, ctrl: false, meta: false, alt: false, shift: false };
    const pieces = part.length > 1 ? part.split(/\+(?=.)/) : [part];
    for (const piece of pieces) {
      const name = piece.toLowerCase();
      if (MODIFIERS.includes(name) && pieces.length > 1) chord[name] = true;
      else chord.key = NAMED[name] ?? name;
    }
    return chord;
  });
}
function isMac(platform = globalThis.navigator?.platform ?? "") {
  return /mac|iphone|ipad|ipod/i.test(platform);
}
function matches(chord, event, mac = isMac()) {
  if (!chord.key || String(event.key ?? "").toLowerCase() !== chord.key) return false;
  const wantMeta = chord.meta || chord.mod && mac;
  const wantCtrl = chord.ctrl || chord.mod && !mac;
  if (wantMeta !== !!event.metaKey) return false;
  if (wantCtrl !== !!event.ctrlKey) return false;
  if (chord.alt !== !!event.altKey) return false;
  const letter = /^\p{L}$/u.test(chord.key);
  return !letter && !chord.shift ? true : chord.shift === !!event.shiftKey;
}
function worksWhileTyping(chords) {
  return chords.length === 1 && (chords[0].mod || chords[0].ctrl || chords[0].meta || chords[0].alt);
}
function isTyping(target) {
  const el2 = (
    /** @type {HTMLElement | null} */
    target
  );
  if (!el2 || !el2.tagName) return false;
  if (el2.isContentEditable) return true;
  const tag = el2.tagName.toLowerCase();
  if (tag === "textarea" || tag === "select") return true;
  if (tag !== "input") return false;
  return !["button", "checkbox", "radio", "submit", "reset", "range", "color", "file", "image"].includes(
    String(el2.type ?? "text").toLowerCase()
  );
}
function sequence({ now = () => Date.now(), timeout = SEQUENCE_TIMEOUT_MS } = {}) {
  let pressed = [];
  return {
    /**
     * Returns the index of the binding that completed, or -1. `bindings` are lists of chords.
     * @param {object} event
     * @param {Chord[][]} bindings
     * @param {boolean} [mac]
     */
    push(event, bindings, mac = isMac()) {
      const t = now();
      pressed = pressed.filter((p) => t - p.at <= timeout);
      pressed.push({ event, at: t });
      for (let attempt = 0; attempt < pressed.length; attempt++) {
        const window = pressed.slice(attempt);
        const hit = bindings.findIndex(
          (chords) => chords.length === window.length && chords.every((chord, i) => matches(chord, window[i].event, mac))
        );
        if (hit >= 0) {
          pressed = [];
          return hit;
        }
        const partial = bindings.some(
          (chords) => chords.length > window.length && window.every((p, i) => matches(chords[i], p.event, mac))
        );
        if (partial) {
          pressed = window;
          return -1;
        }
      }
      pressed = [];
      return -1;
    },
    reset() {
      pressed = [];
    }
  };
}
function label(spec, mac = isMac()) {
  return parse(spec).map((chord) => {
    const caps = [];
    if (chord.mod) caps.push(mac ? "\u2318" : "Ctrl");
    if (chord.ctrl) caps.push(mac ? "\u2303" : "Ctrl");
    if (chord.alt) caps.push(mac ? "\u2325" : "Alt");
    if (chord.shift) caps.push(mac ? "\u21E7" : "Shift");
    if (chord.meta) caps.push(mac ? "\u2318" : "Win");
    const key2 = chord.key === " " ? "Space" : chord.key.length === 1 ? chord.key.toUpperCase() : capitalize(chord.key);
    caps.push(key2);
    return caps;
  });
}
function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

// assets/js/commands/index.js
var SEARCH_DEBOUNCE_MS = 150;
var RECENT_MAX = 5;
var SAFE_PROTOCOLS = ["http:", "https:", "mailto:"];
function parseJSON(text, fallback) {
  try {
    return JSON.parse(text);
  } catch {
    return fallback;
  }
}
function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [name, value] of Object.entries(attrs)) {
    if (value === null || value === void 0 || value === false) continue;
    if (name === "class") node.className = value;
    else if (name === "text") node.textContent = value;
    else node.setAttribute(name, value === true ? "" : String(value));
  }
  for (const child of children) if (child) node.append(child);
  return node;
}
var SVG = "http://www.w3.org/2000/svg";
function alertIcon(className) {
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
  for (const d of ["m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3", "M12 9v4", "M12 17h.01"]) {
    const path = document.createElementNS(SVG, "path");
    path.setAttribute("d", d);
    svg.append(path);
  }
  return svg;
}
function kbd(spec) {
  const group = el("span", { class: "command-palette-keys", "aria-hidden": "true" });
  for (const chord of label(spec)) {
    for (const cap of chord) group.append(el("kbd", { text: cap }));
  }
  return group;
}
var CommandPalette = {
  mounted() {
    this.dialog = this.el.querySelector(".dialog");
    this.root = this.el.querySelector("[data-command-palette]");
    this.input = this.el.querySelector("input[role='combobox']");
    this.list = this.el.querySelector("[role='listbox']");
    this.trailEl = this.el.querySelector("[data-palette-trail]");
    this.hint = this.el.querySelector("[data-palette-hint]");
    this.confirmEl = this.el.querySelector("[data-palette-confirm]");
    this.statusEl = this.el.querySelector("[role='status']");
    this.defaultPlaceholder = this.input.getAttribute("placeholder") || "";
    this.state = initial();
    this.trigger = null;
    this.timers = {};
    this.sequence = sequence();
    this.readData();
    this.onShow = () => this.opened();
    this.onHide = () => this.closed();
    this.onInput = () => this.apply(reduce(this.state, { type: "input", value: this.input.value }, this.ctx()));
    this.onKeydown = (e) => this.inputKey(e);
    this.onGlobalKey = (e) => this.globalKey(e);
    this.onListDown = (e) => {
      if (e.target.closest("[role='option']")) e.preventDefault();
    };
    this.onListClick = (e) => {
      const option = e.target.closest("[role='option']");
      if (option) this.apply(reduce(this.state, { type: "pick", index: Number(option.dataset.index) }, this.ctx()));
    };
    this.onListMove = (e) => {
      const option = e.target.closest("[role='option']");
      const index = option ? Number(option.dataset.index) : -1;
      if (index >= 0 && index !== this.state.active && option.getAttribute("aria-disabled") !== "true") {
        this.state = { ...this.state, active: index };
        this.paintActive(false);
      }
    };
    this.dialog.addEventListener("phx:show-dialog", this.onShow);
    this.dialog.addEventListener("phx:hide-dialog", this.onHide);
    this.input.addEventListener("input", this.onInput);
    this.input.addEventListener("keydown", this.onKeydown);
    this.onConfirmDown = (e) => {
      if (e.target.closest("button")) e.preventDefault();
    };
    this.onConfirmClick = (e) => {
      const key2 = e.target.closest("[data-palette-confirm-yes]") ? "Enter" : e.target.closest("[data-palette-confirm-no]") ? "Escape" : null;
      if (key2) this.apply(reduce(this.state, { type: "key", key: key2 }, this.ctx()));
      if (key2 === "Escape") this.input.focus();
    };
    this.confirmEl.addEventListener("pointerdown", this.onConfirmDown);
    this.confirmEl.addEventListener("click", this.onConfirmClick);
    this.list.addEventListener("pointerdown", this.onListDown);
    this.list.addEventListener("click", this.onListClick);
    this.list.addEventListener("pointermove", this.onListMove);
    document.addEventListener("keydown", this.onGlobalKey);
    this.handleEvent("sutra-ui:command-results", (payload) => {
      if (payload.palette && payload.palette !== this.el.id) return;
      this.apply(reduce(this.state, { type: "results", ...payload }, this.ctx()));
    });
    if (this.dialog.classList.contains("is-open")) this.opened();
  },
  updated() {
    this.readData();
    if (this.state.open) this.render();
  },
  destroyed() {
    this.dialog?.removeEventListener("phx:show-dialog", this.onShow);
    this.dialog?.removeEventListener("phx:hide-dialog", this.onHide);
    this.input?.removeEventListener("input", this.onInput);
    this.input?.removeEventListener("keydown", this.onKeydown);
    this.confirmEl?.removeEventListener("pointerdown", this.onConfirmDown);
    this.confirmEl?.removeEventListener("click", this.onConfirmClick);
    this.list?.removeEventListener("pointerdown", this.onListDown);
    this.list?.removeEventListener("click", this.onListClick);
    this.list?.removeEventListener("pointermove", this.onListMove);
    document.removeEventListener("keydown", this.onGlobalKey);
    Object.values(this.timers).forEach(clearTimeout);
  },
  // ---- data ------------------------------------------------------------------------------
  readData() {
    this.actions = parseJSON(this.el.dataset.actions, []);
    this.sources = parseJSON(this.el.dataset.sources, []);
    this.openShortcut = this.el.dataset.shortcut || "mod+k";
    this.bindings = [
      { kind: "open", chords: parse(this.openShortcut) },
      { kind: "help", chords: parse("?") },
      ...this.actions.filter((a) => a.shortcut && !a.disabled).map((action) => ({ kind: "action", action, chords: parse(action.shortcut) }))
    ].filter((b) => b.chords.length > 0);
  },
  ctx() {
    return { actions: this.actions, sources: this.sources, recent: this.recent ?? [], openShortcut: this.openShortcut };
  },
  recentKey() {
    return `sutra-ui:commands:recent:${this.el.id}`;
  },
  loadRecent() {
    try {
      const ids = parseJSON(globalThis.localStorage?.getItem(this.recentKey()), []);
      return Array.isArray(ids) ? ids.filter((id) => typeof id === "string") : [];
    } catch {
      return [];
    }
  },
  remember(id) {
    if (!this.actions.some((a) => a.id === id)) return;
    const next = [id, ...(this.recent ?? []).filter((r) => r !== id)].slice(0, RECENT_MAX);
    this.recent = next;
    try {
      globalThis.localStorage?.setItem(this.recentKey(), JSON.stringify(next));
    } catch {
    }
  },
  // ---- opening and closing ---------------------------------------------------------------
  opened() {
    if (this.state.open) return;
    const active = document.activeElement;
    this.trigger = active && active !== document.body && !this.dialog.contains(active) ? active : this.trigger;
    this.recent = this.loadRecent();
    this.state = reduce(initial(), { type: "open", page: this.pendingPage }, this.ctx()).state;
    this.pendingPage = void 0;
    this.input.value = "";
    this.root.dataset.state = "open";
    this.render();
    requestAnimationFrame(() => requestAnimationFrame(() => this.input.focus()));
  },
  closed() {
    Object.values(this.timers).forEach(clearTimeout);
    this.timers = {};
    this.state = initial();
    this.root.dataset.state = "closed";
    this.input.value = "";
    const trigger = this.trigger;
    this.trigger = null;
    requestAnimationFrame(() => {
      if (trigger && trigger.isConnected) trigger.focus();
    });
  },
  open(page2) {
    this.pendingPage = page2;
    this.dialog.dispatchEvent(new CustomEvent("phx:show-dialog", { bubbles: true }));
  },
  close() {
    this.dialog.dispatchEvent(new CustomEvent("phx:hide-dialog", { bubbles: true }));
  },
  // ---- keys ------------------------------------------------------------------------------
  inputKey(e) {
    if (e.isComposing) return;
    const caretAtEnd = this.input.selectionStart === this.input.value.length && this.input.selectionEnd === this.input.value.length;
    const result = reduce(this.state, { type: "key", key: e.key, caretAtEnd }, this.ctx());
    if (!result.handled) return;
    e.preventDefault();
    e.stopPropagation();
    this.apply(result);
  },
  globalKey(e) {
    if (e.defaultPrevented || e.isComposing || e.repeat) return;
    const typing = isTyping(e.target);
    const usable = this.bindings.filter(
      (b) => (typing ? worksWhileTyping(b.chords) : true) && (b.kind === "open" || !this.state.open)
    );
    if (typing) {
      const rest = this.bindings.filter((b) => !usable.includes(b));
      if (rest.length) this.sequence.reset();
    }
    const hit = this.sequence.push(
      e,
      usable.map((b) => b.chords)
    );
    if (hit < 0) return;
    const binding = usable[hit];
    e.preventDefault();
    if (binding.kind === "open") {
      if (this.state.open) this.close();
      else this.open();
    } else if (binding.kind === "help") {
      this.open("shortcuts");
    } else {
      this.fromShortcut(binding.action);
    }
  },
  fromShortcut(action) {
    const result = reduce({ ...initial(), open: true }, { type: "start", action }, this.ctx());
    const run = result.effects.find((fx) => fx.effect === "run");
    if (run && !result.state.confirm && result.state.stack.length === 0) {
      this.execute(run.action, run.args);
      return;
    }
    this.open();
    this.apply(result);
  },
  // ---- applying a model result -----------------------------------------------------------
  apply(result) {
    this.state = result.state;
    this.input.value = this.state.query;
    for (const fx of result.effects) this.effect(fx);
    this.render();
  },
  effect(fx) {
    if (fx.effect === "search") {
      clearTimeout(this.timers[fx.source]);
      this.timers[fx.source] = setTimeout(() => {
        this.pushEvent("sutra-ui:command-search", { source: fx.source, query: fx.query, ref: fx.ref });
      }, SEARCH_DEBOUNCE_MS);
    } else if (fx.effect === "run") {
      this.execute(fx.action, fx.args);
    }
  },
  execute(action, args) {
    const done = () => {
      this.remember(action.id);
      try {
        this.pushEvent("sutra-ui:command-ran", { id: action.id });
      } catch {
      }
      if (this.state.open) this.close();
    };
    switch (action.kind) {
      case "navigate":
      case "patch": {
        const link = el("a", {
          href: action.target,
          "data-phx-link": action.kind === "patch" ? "patch" : "redirect",
          "data-phx-link-state": "push",
          hidden: true
        });
        this.el.append(link);
        done();
        link.click();
        link.remove();
        break;
      }
      case "href": {
        const url = new URL(action.target, location.href);
        if (!SAFE_PROTOCOLS.includes(url.protocol)) return;
        done();
        location.assign(url.href);
        break;
      }
      case "event":
        this.pushEvent(action.target.event, { ...action.target.payload ?? {}, ...args });
        done();
        break;
      case "js":
        done();
        this.js().exec(action.target);
        break;
      case "copy":
        globalThis.navigator?.clipboard?.writeText(action.target).catch(() => {
        });
        done();
        break;
      case "server":
        this.pushEvent("sutra-ui:command-run", { id: action.id, args }, (reply) => {
          if (reply && reply.error) this.apply(reduce(this.state, { type: "failed", message: reply.error }, this.ctx()));
          else done();
        });
        break;
      default:
        break;
    }
  },
  // ---- rendering -------------------------------------------------------------------------
  render() {
    const ctx = this.ctx();
    const state = this.state;
    const list = rows(state, ctx);
    const crumbs = trail(state);
    this.input.setAttribute("placeholder", placeholder(state) || this.defaultPlaceholder);
    this.trailEl.hidden = crumbs.length === 0;
    this.trailEl.replaceChildren(
      ...crumbs.flatMap((name, i) => [i > 0 ? el("span", { text: "\u203A", "aria-hidden": "true" }) : null, el("span", { text: name })]).filter(Boolean)
    );
    const confirming = !!state.confirm;
    this.confirmEl.hidden = !confirming;
    this.list.hidden = confirming;
    this.input.setAttribute("aria-expanded", String(!confirming));
    if (confirming) {
      const action = state.confirm.action;
      const danger = action.tone === "danger";
      const message = typeof action.confirm === "string" ? action.confirm : `${action.title}?`;
      const yes = el("button", {
        type: "button",
        class: danger ? "btn-destructive" : "btn",
        "data-palette-confirm-yes": true,
        text: action.confirm_label || action.title
      });
      const no = el("button", { type: "button", class: "btn-outline", "data-palette-confirm-no": true, text: "Cancel" });
      const line = el("p", { class: "command-palette-confirm-message", "data-tone": action.tone }, [
        danger ? alertIcon("command-palette-icon") : null,
        el("span", { text: message })
      ]);
      const keys = el("p", { class: "command-palette-confirm-keys" }, [
        kbd("enter"),
        document.createTextNode(" confirm "),
        kbd("escape"),
        document.createTextNode(" go back")
      ]);
      this.confirmEl.replaceChildren(line, el("div", { class: "command-palette-confirm-buttons" }, [no, yes]), keys);
    }
    const p = state.stack[state.stack.length - 1];
    const text = p?.type === "ask" && p.arg.type === "text";
    this.hint.hidden = !text;
    if (text) this.hint.textContent = "Type, then press Enter";
    this.list.replaceChildren();
    let group = null;
    let index = 0;
    for (const row of list) {
      if (row.type === "heading") {
        const id = `${this.el.id}-h-${this.list.children.length}`;
        group = el("div", { role: "group", "aria-labelledby": id });
        group.append(el("div", { id, class: "command-palette-heading", text: row.title, role: "presentation" }));
        this.list.append(group);
        continue;
      }
      (group ?? this.list).append(this.option(row, index));
      index += 1;
    }
    const loading = Object.values(state.results).some((r) => r.loading);
    const empty = index === 0 && !text && !confirming;
    this.list.dataset.empty = loading ? "searching" : empty ? "empty" : "list";
    this.list.dataset.emptyText = loading ? "Searching\u2026" : this.el.dataset.emptyText || "No results found.";
    this.paintActive(true);
    this.announce(announcement(state, ctx));
  },
  option(row, index) {
    const action = row.action;
    const disabled = !!action.disabled;
    const node = el(
      "div",
      {
        id: `${this.el.id}-opt-${index}`,
        role: "option",
        "data-index": index,
        "data-action-id": action.id,
        "data-state": disabled ? "disabled" : "idle",
        "data-tone": action.tone,
        "aria-selected": "false",
        "aria-disabled": disabled ? "true" : null
      },
      []
    );
    if (action.tone === "danger") node.append(alertIcon("command-palette-icon"));
    else if (action.icon) node.append(el("span", { class: `command-palette-icon ${action.icon}`, "aria-hidden": "true" }));
    const body = el("span", { class: "command-palette-title" }, [el("span", { text: action.title })]);
    if (typeof action.disabled === "string") {
      const reasonId = `${node.id}-reason`;
      body.append(el("span", { id: reasonId, class: "command-palette-reason", text: action.disabled }));
      node.setAttribute("aria-describedby", reasonId);
    } else if (row.recent && action.section) body.append(el("span", { class: "command-palette-reason", text: action.section }));
    node.append(body);
    if (action.tone === "danger") node.append(el("span", { class: "sr-only", text: "(destructive)" }));
    if (action.badge) node.append(el("span", { class: "command-palette-badge", text: action.badge }));
    if (action.shortcut) node.append(kbd(action.shortcut));
    if (action.children?.length) node.append(el("span", { class: "command-palette-more", text: "\u203A", "aria-hidden": "true" }));
    return node;
  },
  paintActive(scroll) {
    const options = Array.from(this.list.querySelectorAll("[role='option']"));
    options.forEach((node, i) => {
      const on = i === this.state.active;
      node.setAttribute("aria-selected", String(on));
      if (!node.hasAttribute("aria-disabled")) node.dataset.state = on ? "active" : "idle";
      else node.dataset.state = "disabled";
      if (on) node.dataset.active = "true";
      else delete node.dataset.active;
    });
    const current = options[this.state.active];
    if (current && !this.list.hidden) {
      this.input.setAttribute("aria-activedescendant", current.id);
      if (scroll) current.scrollIntoView({ block: "nearest" });
    } else {
      this.input.removeAttribute("aria-activedescendant");
    }
  },
  announce(message) {
    clearTimeout(this.announceTimer);
    this.announceTimer = setTimeout(() => {
      this.statusEl.textContent = message;
    }, 150);
  }
};
var index_default = CommandPalette;
export {
  CommandPalette,
  index_default as default,
  initial,
  items,
  normalize,
  rank,
  reduce,
  rows,
  score,
  tokens
};
