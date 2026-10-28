import { test } from "node:test";
import assert from "node:assert/strict";
import { activeItem, announcement, initial, items, page, placeholder, reduce, rows, trail } from "./model.js";

const A = (id, title, extra = {}) => ({ id, title, keywords: [], kind: "navigate", target: `/${id}`, children: [], args: [], ...extra });

const actions = [
  A("home", "Go home", { section: "Go to" }),
  A("settings", "Settings", { section: "Go to", keywords: ["preferences"] }),
  A("delete", "Delete everything", { section: "Danger", tone: "danger", kind: "server", confirm: "Delete everything?" }),
  A("publish", "Publish", { section: "Danger", disabled: "Add a title first", kind: "server" }),
  A("theme", "Change theme", {
    kind: "server",
    args: [{ name: "theme", label: "Theme", type: "choice", choices: [{ value: "light", label: "Light" }, { value: "dark", label: "Dark" }] }],
  }),
  A("note", "Add a note", { kind: "server", args: [{ name: "note", label: "Note", type: "text", required: true }] }),
  A("open", "Open a workbook", { kind: "server", args: [{ name: "workbook", label: "Which workbook?", type: "search", source: "workbooks" }] }),
  A("more", "More", { kind: null, children: [A("more.copy", "Copy link", { kind: "copy" })] }),
];

const ctx = { actions, sources: [{ id: "workbooks", title: "Workbooks" }], recent: [], openShortcut: "mod+k" };

const opened = () => reduce(initial(), { type: "open" }, ctx).state;
const type = (state, value) => reduce(state, { type: "input", value }, ctx);
const press = (state, key, extra = {}) => reduce(state, { type: "key", key, ...extra }, ctx);

const titles = (state, c = ctx) => items(state, c).map((r) => r.action.title);

test("the root lists every action under its section, in order", () => {
  const list = rows(opened(), ctx);
  assert.deepEqual(
    list.filter((r) => r.type === "heading").map((r) => r.title),
    ["Go to", "Danger"],
  );
  assert.equal(items(opened(), ctx).length, actions.length);
});

test("typing filters and ranks by the matching rules", () => {
  const { state } = type(opened(), "setings");
  assert.deepEqual(titles(state), ["Settings"]);
  assert.deepEqual(titles(type(opened(), "pref").state), ["Settings"], "keywords find it");
  assert.deepEqual(titles(type(opened(), "go ho").state), ["Go home"]);
});

test("typing starts a search of every source, with a newer ref each time", () => {
  const first = type(opened(), "phys");
  assert.deepEqual(first.effects, [{ effect: "search", source: "workbooks", query: "phys", ref: 1 }]);
  const second = type(first.state, "physi");
  assert.equal(second.effects[0].ref, 2);
});

test("an older answer never covers a newer one", () => {
  const s1 = type(opened(), "phys");
  const s2 = type(s1.state, "physi");
  const stale = reduce(s2.state, { type: "results", source: "workbooks", ref: 1, items: [A("w1", "Stale")] }, ctx);
  assert.deepEqual(titles(stale.state), [], "the stale answer is dropped");
  const fresh = reduce(s2.state, { type: "results", source: "workbooks", ref: 2, items: [A("w2", "Physics 2")] }, ctx);
  assert.deepEqual(titles(fresh.state), ["Physics 2"]);
});

test("server results appear under their source heading after the actions", () => {
  const s = type(opened(), "phys").state;
  const done = reduce(s, { type: "results", source: "workbooks", ref: 1, items: [A("w1", "Physics 1")] }, ctx).state;
  const list = rows(done, ctx);
  assert.equal(list.at(-2).title, "Workbooks");
  assert.equal(list.at(-1).action.title, "Physics 1");
});

test("an empty query clears the source results and sends no search", () => {
  const s = reduce(type(opened(), "phys").state, { type: "results", source: "workbooks", ref: 1, items: [A("w1", "Physics 1")] }, ctx).state;
  const cleared = type(s, "");
  assert.deepEqual(cleared.effects, []);
  assert.equal(items(cleared.state, ctx).length, actions.length);
});

test("arrows move the active item and wrap", () => {
  let s = opened();
  assert.equal(s.active, 0);
  s = press(s, "ArrowDown").state;
  assert.equal(s.active, 1);
  s = press(s, "ArrowUp").state;
  s = press(s, "ArrowUp").state;
  assert.equal(s.active, actions.length - 1, "wraps to the last");
  s = press(s, "ArrowDown").state;
  assert.equal(s.active, 0, "wraps to the first");
});

test("typing resets the active item to the first", () => {
  let s = press(opened(), "ArrowDown").state;
  s = type(s, "s").state;
  assert.equal(s.active, 0);
});

test("Enter runs the active action", () => {
  const r = press(opened(), "Enter");
  assert.equal(r.handled, true);
  assert.deepEqual(r.effects, [{ effect: "run", action: actions[0], args: {} }]);
});

test("Enter on a disabled action explains why and does not run", () => {
  const s = type(opened(), "publish").state;
  const r = press(s, "Enter");
  assert.deepEqual(r.effects, []);
  assert.match(r.state.status, /Add a title first/);
  assert.match(announcement(r.state, ctx), /Add a title first/);
});

test("a confirm action asks first; Enter confirms, Escape goes back", () => {
  const s = type(opened(), "delete").state;
  const asked = press(s, "Enter");
  assert.deepEqual(asked.effects, []);
  assert.equal(asked.state.confirm.action.id, "delete");

  const ok = press(asked.state, "Enter");
  assert.equal(ok.effects[0].effect, "run");
  assert.equal(ok.effects[0].action.id, "delete");

  const back = press(asked.state, "Escape");
  assert.equal(back.handled, true);
  assert.equal(back.state.confirm, null);
  assert.equal(back.state.open, true);
});

test("an action with children opens its page; Backspace on empty and Escape go back", () => {
  const s = type(opened(), "more").state;
  const inPage = press(s, "Enter").state;
  assert.deepEqual(trail(inPage), ["More"]);
  assert.deepEqual(titles(inPage), ["Copy link"]);

  assert.deepEqual(trail(press(inPage, "Backspace").state), []);
  assert.deepEqual(trail(press(inPage, "Escape").state), []);

  const typed = type(inPage, "c").state;
  assert.equal(press(typed, "Backspace").handled, false, "Backspace with text edits the text");
});

test("Escape at the first page is left to the dialog to close", () => {
  const r = press(opened(), "Escape");
  assert.equal(r.handled, false);
});

test("a result with its own actions opens them with ArrowRight at the end of the text", () => {
  const withKids = A("w1", "Physics 1", { children: [A("w1.open", "Open"), A("w1.archive", "Archive")] });
  const s = type(opened(), "phys").state;
  const loaded = reduce(s, { type: "results", source: "workbooks", ref: 1, items: [withKids] }, ctx).state;
  const onResult = { ...loaded, active: items(loaded, ctx).findIndex((r) => r.action.id === "w1") };

  assert.equal(press(onResult, "ArrowRight", { caretAtEnd: false }).handled, false);
  const drilled = press(onResult, "ArrowRight", { caretAtEnd: true });
  assert.equal(drilled.handled, true);
  assert.deepEqual(titles(drilled.state), ["Open", "Archive"]);
});

test("a choice argument is asked, filtered, and then runs with the value", () => {
  const s = type(opened(), "theme").state;
  const asking = press(s, "Enter").state;
  assert.equal(page(asking).type, "ask");
  assert.equal(placeholder(asking), "Theme");
  assert.deepEqual(titles(asking), ["Light", "Dark"]);
  assert.deepEqual(titles(type(asking, "da").state), ["Dark"]);

  const picked = press(type(asking, "da").state, "Enter");
  assert.deepEqual(picked.effects, [{ effect: "run", action: actions[4], args: { theme: "dark" } }]);
});

test("a text argument needs a value", () => {
  const asking = press(type(opened(), "note").state, "Enter").state;
  assert.equal(announcement(asking, ctx), "Note");

  const empty = press(asking, "Enter");
  assert.deepEqual(empty.effects, []);
  assert.match(empty.state.status, /Type a value/);

  const typed = press(type(asking, "  hello  ").state, "Enter");
  assert.deepEqual(typed.effects, [{ effect: "run", action: actions[5], args: { note: "hello" } }]);
});

test("a search argument searches its source and picks a result by id", () => {
  const entering = press(type(opened(), "open a").state, "Enter");
  assert.deepEqual(entering.effects, [{ effect: "search", source: "workbooks", query: "", ref: entering.effects[0].ref }]);

  const loaded = reduce(entering.state, { type: "results", source: "workbooks", ref: entering.effects[0].ref, items: [A("w1", "Physics 1")] }, ctx).state;
  assert.deepEqual(titles(loaded), ["Physics 1"]);

  const picked = press(loaded, "Enter");
  assert.deepEqual(picked.effects, [{ effect: "run", action: actions[6], args: { workbook: "w1" } }]);
});

test("a click picks the item at that index", () => {
  const r = reduce(opened(), { type: "pick", index: 1 }, ctx);
  assert.equal(r.effects[0].action.id, "settings");
});

test("recent actions come first when the box is empty", () => {
  const withRecent = { ...ctx, recent: ["settings", "gone", "home"] };
  const list = rows(opened(), withRecent);
  assert.equal(list[0].title, "Recent");
  assert.deepEqual(
    list.filter((r) => r.type === "item").slice(0, 2).map((r) => r.action.id),
    ["settings", "home"],
  );
  assert.equal(items(opened(), withRecent).length, actions.length, "no duplicates");
});

test("the shortcuts page lists actions with shortcuts and the open shortcut", () => {
  const keyed = [A("a", "Alpha", { shortcut: "g a" }), A("b", "Beta")];
  const c = { ...ctx, actions: keyed };
  const s = reduce(initial(), { type: "open", page: "shortcuts" }, c).state;
  assert.deepEqual(items(s, c).map((r) => r.action.title), ["Open the command palette", "Alpha"]);
  assert.deepEqual(reduce(s, { type: "key", key: "Enter" }, c).effects, [], "the open row is inert");
});

test("announcements say how many results or that there are none", () => {
  assert.equal(announcement(opened(), ctx), `${actions.length} results`);
  const local = { ...ctx, sources: [] };
  const typeLocal = (value) => reduce(opened(), { type: "input", value }, local).state;
  assert.equal(announcement(typeLocal("qzxqzx"), local), "No results");
  assert.equal(announcement(typeLocal("setings"), local), "1 result");
  assert.equal(announcement(type(opened(), "phys").state, ctx), "Searching", "no results yet while a search is out");
});

test("a failed server run shows the message and keeps the palette open", () => {
  const r = reduce(opened(), { type: "failed", message: "It did not work" }, ctx);
  assert.equal(r.state.status, "It did not work");
  assert.equal(r.state.open, true);
});

test("start from a shortcut asks for the first argument, or runs a simple action", () => {
  const simple = reduce(initial(), { type: "start", action: actions[0] }, ctx);
  assert.equal(simple.effects[0].effect, "run");

  const asks = reduce(initial(), { type: "start", action: actions[4] }, ctx);
  assert.equal(page(asks.state).type, "ask");
  assert.equal(asks.state.open, true);
});

test("activeItem is the row under the cursor", () => {
  assert.equal(activeItem(opened(), ctx).action.id, "home");
});
