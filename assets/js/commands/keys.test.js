import { test } from "node:test";
import assert from "node:assert/strict";
import { isTyping, label, matches, parse, sequence, worksWhileTyping } from "./keys.js";

const press = (key, extra = {}) => ({ key, ctrlKey: false, metaKey: false, altKey: false, shiftKey: false, ...extra });

test("parse reads chords and sequences", () => {
  assert.deepEqual(parse("mod+k"), [{ key: "k", mod: true, ctrl: false, meta: false, alt: false, shift: false }]);
  assert.equal(parse("g h").length, 2);
  assert.equal(parse("?")[0].key, "?");
  assert.equal(parse("shift+/")[0].shift, true);
  assert.equal(parse("ctrl+alt+Delete")[0].key, "delete");
  assert.equal(parse("esc")[0].key, "escape");
  assert.deepEqual(parse(""), []);
});

test("mod is Cmd on a Mac and Ctrl elsewhere", () => {
  const [chord] = parse("mod+k");
  assert.equal(matches(chord, press("k", { metaKey: true }), true), true);
  assert.equal(matches(chord, press("k", { ctrlKey: true }), true), false);
  assert.equal(matches(chord, press("k", { ctrlKey: true }), false), true);
  assert.equal(matches(chord, press("k", { metaKey: true }), false), false);
});

test("a chord does not match with extra modifiers or another key", () => {
  const [chord] = parse("mod+k");
  assert.equal(matches(chord, press("k", { ctrlKey: true, altKey: true }), false), false);
  assert.equal(matches(chord, press("j", { ctrlKey: true }), false), false);
  assert.equal(matches(chord, press("K", { ctrlKey: true }), false), true, "case of the key is ignored");
});

test("a plain letter does not match with Ctrl held", () => {
  const [chord] = parse("g");
  assert.equal(matches(chord, press("g"), false), true);
  assert.equal(matches(chord, press("g", { ctrlKey: true }), false), false);
  assert.equal(matches(chord, press("g", { shiftKey: true }), false), false);
});

test("a symbol matches whether or not shift made it", () => {
  const [chord] = parse("?");
  assert.equal(matches(chord, press("?", { shiftKey: true }), false), true);
  assert.equal(matches(chord, press("?"), false), true);
});

test("only chords with Ctrl, Cmd or Alt work while typing", () => {
  assert.equal(worksWhileTyping(parse("mod+k")), true);
  assert.equal(worksWhileTyping(parse("alt+j")), true);
  assert.equal(worksWhileTyping(parse("g")), false);
  assert.equal(worksWhileTyping(parse("g h")), false);
  assert.equal(worksWhileTyping(parse("?")), false);
});

test("isTyping is true in text fields and false on buttons", () => {
  assert.equal(isTyping({ tagName: "INPUT", type: "text" }), true);
  assert.equal(isTyping({ tagName: "INPUT", type: "search" }), true);
  assert.equal(isTyping({ tagName: "INPUT", type: "checkbox" }), false);
  assert.equal(isTyping({ tagName: "TEXTAREA" }), true);
  assert.equal(isTyping({ tagName: "DIV", isContentEditable: true }), true);
  assert.equal(isTyping({ tagName: "BUTTON" }), false);
  assert.equal(isTyping(null), false);
});

test("a sequence completes in order and not after the timeout", () => {
  let t = 0;
  const seq = sequence({ now: () => t, timeout: 1000 });
  const bindings = [parse("g h"), parse("g i"), parse("x")];

  assert.equal(seq.push(press("g"), bindings, false), -1);
  t += 300;
  assert.equal(seq.push(press("i"), bindings, false), 1);

  assert.equal(seq.push(press("g"), bindings, false), -1);
  t += 1500;
  assert.equal(seq.push(press("h"), bindings, false), -1, "too slow");
});

test("a wrong second key starts over", () => {
  const seq = sequence({ now: () => 0 });
  const bindings = [parse("g h")];

  assert.equal(seq.push(press("g"), bindings, false), -1);
  assert.equal(seq.push(press("g"), bindings, false), -1, "g again is a new start");
  assert.equal(seq.push(press("h"), bindings, false), 0);
});

test("a single chord completes at once", () => {
  const seq = sequence({ now: () => 0 });
  assert.equal(seq.push(press("k", { ctrlKey: true }), [parse("mod+k")], false), 0);
});

test("label shows key caps for the platform", () => {
  assert.deepEqual(label("mod+k", true), [["⌘", "K"]]);
  assert.deepEqual(label("mod+k", false), [["Ctrl", "K"]]);
  assert.deepEqual(label("g h", false), [["G"], ["H"]]);
  assert.deepEqual(label("shift+enter", false), [["Shift", "Enter"]]);
});
