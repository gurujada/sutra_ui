import assert from "node:assert/strict";
import { test } from "node:test";

import { Confirmer, installConfirm, promptFor } from "./index.js";

function attrsEl(attrs) {
  const a = { ...attrs };
  return {
    getAttribute: (n) => a[n] ?? null,
    removeAttribute: (n) => delete a[n],
    setAttribute: (n, v) => (a[n] = v),
    attrs: a,
    isConnected: true,
    focused: false,
    focus() { this.focused = true; },
    clicks: 0,
    sawAttribute: [],
    click() { this.clicks++; this.sawAttribute.push(a["data-confirm"] ?? null); },
  };
}

test("promptFor reads the message, title, verb and tone", () => {
  const el = attrsEl({
    "data-confirm": "This removes the Workbook.",
    "data-confirm-title": "Delete it?",
    "data-confirm-verb": "Delete",
  });
  assert.deepEqual(promptFor(el), {
    message: "This removes the Workbook.",
    title: "Delete it?",
    verb: "Delete",
    tone: "danger",
  });
  assert.equal(promptFor(attrsEl({ "data-confirm": "x", "data-confirm-tone": "primary" })).tone, "primary");
  assert.equal(promptFor(attrsEl({ "data-confirm": "x", "data-confirm-tone": "weird" })).tone, "danger");
});

function fakeHost() {
  const log = [];
  return {
    log,
    open: (p) => log.push(["open", p.message]),
    close: () => log.push(["close"]),
    focusTrigger: () => log.push(["focus"]),
  };
}

test("accept closes, replays the click without data-confirm, then restores it", () => {
  const host = fakeHost();
  const c = new Confirmer(host);
  const el = attrsEl({ "data-confirm": "Sure?" });
  c.ask(el);
  assert.deepEqual(host.log, [["open", "Sure?"]]);
  c.accept();
  assert.equal(el.clicks, 1);
  assert.deepEqual(el.sawAttribute, [null]); // phoenix_html saw no data-confirm to prompt on
  assert.equal(el.attrs["data-confirm"], "Sure?");
  assert.equal(c.passes(el), false);
  assert.deepEqual(host.log.at(-1), ["close"]);
});

test("cancel does nothing but return focus; accept after cancel does nothing", () => {
  const host = fakeHost();
  const c = new Confirmer(host);
  const el = attrsEl({ "data-confirm": "Sure?" });
  c.ask(el);
  c.cancel();
  c.accept();
  assert.equal(el.clicks, 0);
  assert.deepEqual(host.log, [["open", "Sure?"], ["focus"]]);
});

test("a submit is replayed with requestSubmit and the original submitter", () => {
  const host = fakeHost();
  const c = new Confirmer(host);
  const form = attrsEl({ "data-confirm": "Send?" });
  const submitter = {};
  const seen = [];
  form.requestSubmit = (s) => seen.push([s, form.attrs["data-confirm"] ?? null]);
  c.submitter = submitter;
  c.ask(form, "submit");
  c.accept();
  assert.deepEqual(seen, [[submitter, null]]);
});

function fakeWindow() {
  const listeners = [];
  return {
    listeners,
    requestAnimationFrame: (fn) => fn(),
    addEventListener: (type, fn, capture) => listeners.push({ type, fn, capture }),
    removeEventListener: (type, fn) => {
      const i = listeners.findIndex((l) => l.type === type && l.fn === fn);
      if (i >= 0) listeners.splice(i, 1);
    },
    fire(type, event) {
      for (const l of [...listeners]) {
        if (event.stopped) break;
        if (l.type === type) l.fn(event);
      }
    },
  };
}

function clickEvent(el) {
  return {
    el,
    target: { closest: (sel) => (sel === "[data-confirm]" && el.attrs["data-confirm"] !== undefined ? el : null) },
    prevented: false,
    stopped: false,
    preventDefault() { this.prevented = true; },
    stopImmediatePropagation() { this.stopped = true; },
  };
}

function fakeDoc(hostPresent) {
  const root = {
    dataset: {},
    contains: () => false,
    querySelector: () => null,
    querySelectorAll: () => [],
    firstElementChild: { dispatchEvent() {} },
  };
  return { querySelector: () => (hostPresent ? root : null) };
}

test("installConfirm catches a click on [data-confirm] in the capture phase", () => {
  const win = fakeWindow();
  const handle = installConfirm(fakeDoc(true), win);
  assert.ok(win.listeners.every((l) => l.capture === true));
  const el = attrsEl({ "data-confirm": "Sure?" });
  const event = clickEvent(el);
  win.fire("click", event);
  assert.equal(event.prevented, true);
  assert.equal(event.stopped, true);
  assert.ok(handle.confirmer.pending);
  assert.equal(installConfirm(fakeDoc(true), win), handle, "idempotent");
  handle.uninstall();
  assert.equal(win.listeners.length, 0);
});

test("without a host on the page the click is left alone", () => {
  const win = fakeWindow();
  const handle = installConfirm(fakeDoc(false), win);
  const event = clickEvent(attrsEl({ "data-confirm": "Sure?" }));
  win.fire("click", event);
  assert.equal(event.prevented, false);
  assert.equal(handle.confirmer.pending, null);
  handle.uninstall();
});

test("a replayed click passes through the interceptor", () => {
  const win = fakeWindow();
  const handle = installConfirm(fakeDoc(true), win);
  const el = attrsEl({ "data-confirm": "Sure?" });
  el.click = () => {
    // what the browser does during the replay: the click reaches the window listeners
    const event = clickEvent({ ...el, attrs: { ...el.attrs } });
    event.target = { closest: () => el };
    win.fire("click", event);
    el.replayPrevented = event.prevented;
  };
  win.fire("click", clickEvent(el));
  handle.confirmer.accept();
  assert.equal(el.replayPrevented, false);
  handle.uninstall();
});

test("a click inside a form hides its data-confirm from phoenix_html until the submit", () => {
  const win = fakeWindow();
  const handle = installConfirm(fakeDoc(true), win);
  const form = attrsEl({ "data-confirm": "Send?" });
  form.matches = (sel) => sel === "form" || sel === "form[data-confirm]";
  const event = clickEvent(form);
  win.fire("click", event);
  // not prevented (the submit follows), but phoenix_html would find nothing to prompt on
  assert.equal(event.prevented, false);
  assert.equal(form.attrs["data-confirm"], undefined);
  assert.equal(handle.confirmer.pending, null);
  // the submit the click causes: caught, and the message is back for the dialog
  const submit = { target: form, prevented: false, preventDefault() { this.prevented = true; }, stopImmediatePropagation() {} };
  win.fire("submit", submit);
  assert.equal(form.attrs["data-confirm"], "Send?");
  assert.equal(submit.prevented, true);
  assert.deepEqual(handle.confirmer.pending && handle.confirmer.pending.kind, "submit");
  handle.uninstall();
});

test("a form click that never submits gets its data-confirm back on the next tick", async () => {
  const win = fakeWindow();
  const handle = installConfirm(fakeDoc(true), win);
  const form = attrsEl({ "data-confirm": "Send?" });
  form.matches = (sel) => sel === "form";
  win.fire("click", clickEvent(form));
  assert.equal(form.attrs["data-confirm"], undefined);
  await new Promise((r) => setTimeout(r, 5));
  assert.equal(form.attrs["data-confirm"], "Send?");
  handle.uninstall();
});
