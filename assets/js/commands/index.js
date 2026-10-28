// The command palette's browser half: a colocated hook on the palette root. The server renders
// the dialog shell (SutraUI.Commands.palette/1) and the action list as JSON in `data-actions`;
// this module owns everything inside the shell once it is mounted: it renders the list,
// handles keys, shortcuts and recent actions, and talks to the server for searches and for
// actions that run there. The list logic is in model.js, matching in match.js, keys in keys.js.

import { announcement, initial, placeholder, reduce, rows, trail } from "./model.js";
import * as keys from "./keys.js";

export { score, rank, normalize, tokens } from "./match.js";
export { reduce, initial, rows, items } from "./model.js";

const SEARCH_DEBOUNCE_MS = 150;
const RECENT_MAX = 5;
const SAFE_PROTOCOLS = ["http:", "https:", "mailto:"];

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
    if (value === null || value === undefined || value === false) continue;
    if (name === "class") node.className = value;
    else if (name === "text") node.textContent = value;
    else node.setAttribute(name, value === true ? "" : String(value));
  }
  for (const child of children) if (child) node.append(child);
  return node;
}

const SVG = "http://www.w3.org/2000/svg";

/** The lucide triangle-alert glyph, drawn here because SutraUI has no icon component. */
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
    "aria-hidden": "true",
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
  for (const chord of keys.label(spec)) {
    for (const cap of chord) group.append(el("kbd", { text: cap }));
  }
  return group;
}

/** @type {import("phoenix_live_view").ViewHook & Record<string, any>} */
export const CommandPalette = {
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
    this.sequence = keys.sequence();
    this.readData();

    this.onShow = () => this.opened();
    this.onHide = () => this.closed();
    this.onInput = () => this.apply(reduce(this.state, { type: "input", value: this.input.value }, this.ctx()));
    this.onKeydown = (e) => this.inputKey(e);
    this.onGlobalKey = (e) => this.globalKey(e);
    this.onListDown = (e) => {
      if (e.target.closest("[role='option']")) e.preventDefault(); // focus stays in the input
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
      if (e.target.closest("button")) e.preventDefault(); // focus stays where it is
    };
    this.onConfirmClick = (e) => {
      const key = e.target.closest("[data-palette-confirm-yes]") ? "Enter" : e.target.closest("[data-palette-confirm-no]") ? "Escape" : null;
      if (key) this.apply(reduce(this.state, { type: "key", key }, this.ctx()));
      if (key === "Escape") this.input.focus();
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
      { kind: "open", chords: keys.parse(this.openShortcut) },
      { kind: "help", chords: keys.parse("?") },
      ...this.actions
        .filter((a) => a.shortcut && !a.disabled)
        .map((action) => ({ kind: "action", action, chords: keys.parse(action.shortcut) })),
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
      // private mode or blocked storage: recent actions are a convenience
    }
  },

  // ---- opening and closing ---------------------------------------------------------------

  opened() {
    if (this.state.open) return;
    const active = document.activeElement;
    this.trigger = active && active !== document.body && !this.dialog.contains(active) ? active : this.trigger;
    this.recent = this.loadRecent();
    this.state = reduce(initial(), { type: "open", page: this.pendingPage }, this.ctx()).state;
    this.pendingPage = undefined;
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

  open(page) {
    this.pendingPage = page;
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
    e.stopPropagation(); // Escape steps back inside the palette instead of closing it
    this.apply(result);
  },

  globalKey(e) {
    if (e.defaultPrevented || e.isComposing || e.repeat) return;
    const typing = keys.isTyping(e.target);
    const usable = this.bindings.filter(
      (b) => (typing ? keys.worksWhileTyping(b.chords) : true) && (b.kind === "open" || !this.state.open),
    );
    if (typing) {
      const rest = this.bindings.filter((b) => !usable.includes(b));
      if (rest.length) this.sequence.reset();
    }
    const hit = this.sequence.push(
      e,
      usable.map((b) => b.chords),
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
        // not inside a LiveView
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
          hidden: true,
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
        this.pushEvent(action.target.event, { ...(action.target.payload ?? {}), ...args });
        done();
        break;
      case "js":
        done();
        this.js().exec(action.target);
        break;
      case "copy":
        globalThis.navigator?.clipboard?.writeText(action.target).catch(() => {});
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
      ...crumbs.flatMap((name, i) => [i > 0 ? el("span", { text: "›", "aria-hidden": "true" }) : null, el("span", { text: name })]).filter(Boolean),
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
        text: action.confirm_label || action.title,
      });
      const no = el("button", { type: "button", class: "btn-outline", "data-palette-confirm-no": true, text: "Cancel" });
      const line = el("p", { class: "command-palette-confirm-message", "data-tone": action.tone }, [
        danger ? alertIcon("command-palette-icon") : null,
        el("span", { text: message }),
      ]);
      const keys = el("p", { class: "command-palette-confirm-keys" }, [
        kbd("enter"),
        document.createTextNode(" confirm "),
        kbd("escape"),
        document.createTextNode(" go back"),
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
    this.list.dataset.emptyText = loading ? "Searching…" : this.el.dataset.emptyText || "No results found.";

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
        "aria-disabled": disabled ? "true" : null,
      },
      [],
    );
    if (action.tone === "danger") node.append(alertIcon("command-palette-icon"));
    else if (action.icon) node.append(el("span", { class: `command-palette-icon ${action.icon}`, "aria-hidden": "true" }));
    const body = el("span", { class: "command-palette-title" }, [el("span", { text: action.title })]);
    if (typeof action.disabled === "string") {
      const reasonId = `${node.id}-reason`;
      body.append(el("span", { id: reasonId, class: "command-palette-reason", text: action.disabled }));
      node.setAttribute("aria-describedby", reasonId);
    }
    else if (row.recent && action.section) body.append(el("span", { class: "command-palette-reason", text: action.section }));
    node.append(body);
    if (action.tone === "danger") node.append(el("span", { class: "sr-only", text: "(destructive)" }));
    if (action.badge) node.append(el("span", { class: "command-palette-badge", text: action.badge }));
    if (action.shortcut) node.append(kbd(action.shortcut));
    if (action.children?.length) node.append(el("span", { class: "command-palette-more", text: "›", "aria-hidden": "true" }));
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
  },
};

export default CommandPalette;
