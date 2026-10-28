import assert from "node:assert/strict";
import { test } from "node:test";

import { Countdown, DelayedNotice, NOTICE_DELAY_MS, ToastGroup } from "./index.js";

function fakeClock() {
  let now = 0;
  let nextId = 1;
  const timers = new Map();
  return {
    now: () => now,
    set(fn, ms) {
      const id = nextId++;
      timers.set(id, { at: now + ms, fn });
      return id;
    },
    clear: (id) => timers.delete(id),
    advance(ms) {
      const target = now + ms;
      for (;;) {
        const due = [...timers.entries()].filter(([, t]) => t.at <= target).sort((a, b) => a[1].at - b[1].at)[0];
        if (!due) break;
        timers.delete(due[0]);
        now = due[1].at;
        due[1].fn();
      }
      now = target;
    },
    pending: () => timers.size,
  };
}

test("Countdown fires once after its duration", () => {
  const clock = fakeClock();
  let fired = 0;
  const c = new Countdown(5000, () => fired++, clock);
  c.start();
  clock.advance(4999);
  assert.equal(fired, 0);
  clock.advance(1);
  assert.equal(fired, 1);
  clock.advance(10000);
  assert.equal(fired, 1);
});

test("Countdown pauses and resumes with the time left", () => {
  const clock = fakeClock();
  let fired = 0;
  const c = new Countdown(5000, () => fired++, clock);
  c.start();
  clock.advance(2000);
  c.pause();
  assert.equal(c.remaining(), 3000);
  clock.advance(60000);
  assert.equal(fired, 0);
  assert.equal(clock.pending(), 0);
  c.resume();
  clock.advance(2999);
  assert.equal(fired, 0);
  clock.advance(1);
  assert.equal(fired, 1);
});

test("Countdown pause and resume are idempotent; cancel stops it", () => {
  const clock = fakeClock();
  let fired = 0;
  const c = new Countdown(1000, () => fired++, clock);
  c.start();
  c.pause();
  c.pause();
  c.resume();
  c.resume();
  clock.advance(500);
  c.cancel();
  clock.advance(5000);
  assert.equal(fired, 0);
  assert.equal(clock.pending(), 0);
});

test("DelayedNotice: a short blip shows nothing", () => {
  const clock = fakeClock();
  const log = [];
  const n = new DelayedNotice(NOTICE_DELAY_MS, () => log.push("show"), () => log.push("hide"), clock);
  n.lost();
  clock.advance(2000);
  n.back();
  clock.advance(5000);
  assert.deepEqual(log, []);
});

test("DelayedNotice: shows after the delay and hides on reconnect", () => {
  const clock = fakeClock();
  const log = [];
  const n = new DelayedNotice(NOTICE_DELAY_MS, () => log.push("show"), () => log.push("hide"), clock);
  n.lost();
  n.lost();
  clock.advance(NOTICE_DELAY_MS);
  assert.deepEqual(log, ["show"]);
  n.lost();
  n.back();
  assert.deepEqual(log, ["show", "hide"]);
  n.back();
  assert.deepEqual(log, ["show", "hide"]);
});

// A hook instance over fake elements.
function fakeNode(id, data = {}) {
  const listeners = {};
  const attrs = new Set();
  const closeButton = { listeners: {}, addEventListener(t, fn) { this.listeners[t] = fn; } };
  return {
    id,
    dataset: { toastId: id, state: "open", ...data },
    style: { props: {}, setProperty(k, v) { this.props[k] = v; } },
    listeners,
    attrs,
    addEventListener(t, fn) { listeners[t] = fn; },
    toggleAttribute(name, on) { on ? attrs.add(name) : attrs.delete(name); },
    querySelector: (sel) => (sel === "[data-toast-close]" ? closeButton : null),
    closeButton,
    removed: false,
    remove() { this.removed = true; },
  };
}

function hook(nodes, { live = false } = {}) {
  const sent = [];
  const el = {
    dataset: { live: String(live) },
    querySelectorAll: () => nodes,
    querySelector: (sel) => (sel === "[data-toast-stack]" ? { stack: true } : null),
    addEventListener() {},
  };
  const h = Object.create(ToastGroup);
  h.el = el;
  h.pushEventTo = (_t, event, payload) => sent.push(["to", event, payload]);
  h.pushEvent = (event, payload) => sent.push(["lv", event, payload]);
  h.live = live;
  h.entries = new Map();
  h.bound = new WeakSet();
  return { h, sent };
}

test("sync: sets the duration variable and starts a countdown only for timed toasts", () => {
  const timed = fakeNode("a", { duration: "5000" });
  const sticky = fakeNode("b", { duration: "0" });
  const { h } = hook([timed, sticky]);
  h.sync();
  assert.equal(timed.style.props["--toast-duration"], "5000ms");
  assert.ok(h.entries.get("a").countdown);
  assert.equal(h.entries.get("b").countdown, null);
  h.entries.get("a").countdown.cancel();
});

test("sync: forgets toasts that left the DOM and cancels their timers", () => {
  const a = fakeNode("a", { duration: "5000" });
  const nodes = [a];
  const { h } = hook(nodes);
  h.sync();
  const countdown = h.entries.get("a").countdown;
  nodes.length = 0;
  h.sync();
  assert.equal(h.entries.size, 0);
  assert.equal(countdown.done, true);
});

test("sync: a new version restarts the countdown", () => {
  const a = fakeNode("a", { duration: "5000", version: "0" });
  const { h } = hook([a]);
  h.sync();
  const first = h.entries.get("a").countdown;
  a.dataset.version = "1";
  h.sync();
  assert.equal(first.done, true);
  assert.notEqual(h.entries.get("a").countdown, first);
  h.entries.get("a").countdown.cancel();
});

test("hover and focus pause the countdown; leaving both resumes it", () => {
  const a = fakeNode("a", { duration: "5000" });
  const { h } = hook([a]);
  h.sync();
  const c = h.entries.get("a").countdown;
  a.listeners.mouseenter();
  assert.equal(c.paused, true);
  assert.ok(a.attrs.has("data-paused"));
  a.listeners.focusin();
  a.listeners.mouseleave();
  assert.equal(c.paused, true);
  a.listeners.focusout();
  assert.equal(c.paused, false);
  assert.ok(!a.attrs.has("data-paused"));
  c.cancel();
});

test("close on a live page asks the component; a flash toast also clears the flash", () => {
  const a = fakeNode("a", { duration: "0", flash: "info" });
  const { h, sent } = hook([a], { live: true });
  h.sync();
  a.closeButton.listeners.click();
  assert.deepEqual(sent, [
    ["lv", "lv:clear-flash", { key: "info" }],
    ["to", "dismiss", { id: "a" }],
  ]);
});

test("close without LiveView plays the exit and removes the element", async () => {
  const a = fakeNode("a", { duration: "0" });
  const { h } = hook([a]);
  h.sync();
  a.closeButton.listeners.click();
  assert.equal(a.dataset.state, "closing");
  a.listeners.animationend();
  assert.equal(a.removed, true);
});

test("a toast the server marks closing is removed after its exit (live)", () => {
  const a = fakeNode("a", { duration: "0", state: "closing" });
  const { h, sent } = hook([a], { live: true });
  h.sync();
  a.listeners.animationend();
  assert.deepEqual(sent, [["to", "remove", { id: "a" }]]);
});
