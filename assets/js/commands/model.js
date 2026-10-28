// The palette's state and keyboard model, with no DOM: `reduce(state, event, ctx)` returns the
// next state and the effects the hook must carry out (run an action, search a source, close).
//
// An action is the wire form the server renders (see SutraUI.Commands.Action):
// {id, title, section, keywords, icon, shortcut, badge, tone, disabled, confirm, kind, target,
//  children, args}. `ctx` is {actions, sources: [{id, title}], recent: [id], openShortcut}.

import { rank } from "./match.js";

/** Pages deeper than the root: {type: "actions", title, actions} | {type: "ask", ...} */
export function initial() {
  return {
    open: false,
    stack: [],
    query: "",
    active: 0,
    results: {},
    confirm: null,
    status: null,
    refs: 0,
  };
}

/** @returns {object | undefined} the page on top, undefined at the root */
export function page(state) {
  return state.stack[state.stack.length - 1];
}

/** The text above the list: the page's title with its parents, empty at the root. */
export function trail(state) {
  return state.stack.map((p) => (p.type === "ask" ? p.arg.label || p.action.title : p.title));
}

/** The placeholder to show for the current page, or null for the palette's own. */
export function placeholder(state) {
  const p = page(state);
  if (p?.type === "ask") return p.arg.placeholder || p.arg.label || null;
  return null;
}

function itemText(action) {
  return { title: action.title, keywords: [...(action.keywords ?? []), action.section ?? ""] };
}

function sectionOf(action) {
  return action.section || null;
}

/** Groups ranked or listed actions under their section headings, in order of first appearance. */
function grouped(actions, fallbackHeading) {
  const order = [];
  const bySection = new Map();
  for (const action of actions) {
    const key = sectionOf(action) ?? fallbackHeading ?? "";
    if (!bySection.has(key)) {
      bySection.set(key, []);
      order.push(key);
    }
    bySection.get(key).push(action);
  }
  const rows = [];
  for (const key of order) {
    if (key) rows.push({ type: "heading", id: `section:${key}`, title: key });
    for (const action of bySection.get(key)) rows.push({ type: "item", action });
  }
  return rows;
}

/**
 * Everything shown in the list, in order: headings and items.
 * @returns {{type: "heading", id: string, title: string} | {type: "item", action: object, choice?: string}}[]
 */
export function rows(state, ctx) {
  const query = state.query.trim();
  const p = page(state);

  if (p?.type === "ask") return askRows(state, p, query);

  if (p?.type === "shortcuts") {
    const withKeys = ctx.actions.filter((a) => a.shortcut);
    const open = { id: "sutra:open", title: "Open the command palette", shortcut: ctx.openShortcut, inert: true };
    return [...(ctx.openShortcut ? [{ type: "item", action: open }] : []), ...withKeys.map((a) => ({ type: "item", action: a }))];
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
      value: c.value,
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

/** The items only (no headings), in order. */
export function items(state, ctx) {
  return rows(state, ctx).filter((r) => r.type === "item");
}

/** The row under the cursor, or undefined. */
export function activeItem(state, ctx) {
  return items(state, ctx)[state.active];
}

/** What a screen reader hears after the list changes. */
export function announcement(state, ctx) {
  if (state.status) return state.status;
  const p = page(state);
  const count = items(state, ctx).length;
  const searching = Object.values(state.results).some((r) => r.loading);
  if (p?.type === "ask" && p.arg.type === "text") return p.arg.label || "Type a value and press Enter";
  if (searching && count === 0) return "Searching";
  if (count === 0) return "No results";
  return count === 1 ? "1 result" : `${count} results`;
}

function withActive(state, ctx, active) {
  const count = items(state, ctx).length;
  const wrapped = count === 0 ? 0 : ((active % count) + count) % count;
  return { ...state, active: wrapped };
}

/** Starts a search of every source for the query (root page) and returns the new state and effects. */
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
    results[source.id] = { ...(results[source.id] ?? { items: [] }), ref: ++refs, loading: true };
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
      results: { ...state.results, [arg.source]: { ...(state.results[arg.source] ?? { items: [] }), ref, loading: true } },
    },
    effects: [{ effect: "search", source: arg.source, query, ref }],
  };
}

function push(state, nextPage) {
  return { ...state, stack: [...state.stack, nextPage], query: "", active: 0, status: null, confirm: null };
}

function pop(state) {
  return { ...state, stack: state.stack.slice(0, -1), query: "", active: 0, status: null, confirm: null };
}

/** The next step after an action is chosen: ask an argument, confirm, or run. */
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

/** Opens the children of the active item, if it has some. */
function drill(state, ctx) {
  const action = activeItem(state, ctx)?.action;
  if (!action?.children?.length || action.disabled) return null;
  return { state: push(state, { type: "actions", title: action.title, actions: action.children }), effects: [] };
}

/**
 * @param {object} state
 * @param {object} event {type: "open" | "close" | "input" | "key" | "pick" | "results" | "settled" | "enter-action"}
 * @param {object} ctx
 * @returns {{state: object, effects: object[], handled?: boolean}}
 */
export function reduce(state, event, ctx) {
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
      // A shortcut chose this action while the palette was closed.
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
      if (!current || current.ref !== event.ref) return { state, effects: [] }; // an older answer
      const results = {
        ...state.results,
        [event.source]: { ...current, loading: false, items: event.error ? [] : event.items ?? [], error: event.error ?? null },
      };
      const next = { ...state, results };
      return { state: withActive(next, ctx, Math.min(state.active, Math.max(items(next, ctx).length - 1, 0))), effects: [] };
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
      return handled({ state: withActive(state, ctx, state.active + 1), effects: [] });
    case "ArrowUp":
      return handled({ state: withActive(state, ctx, state.active - 1), effects: [] });
    case "PageDown":
      return handled({ state: withActive(state, ctx, Math.min(state.active + 5, items(state, ctx).length - 1)), effects: [] });
    case "PageUp":
      return handled({ state: withActive(state, ctx, Math.max(state.active - 5, 0)), effects: [] });
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
      return none; // the dialog closes on Escape
    default:
      return none;
  }
}
