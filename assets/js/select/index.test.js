import { test } from "node:test";
import assert from "node:assert/strict";
import { AUTO_SEARCH_FROM, fold, matches, move, pushChar, typeahead, wantsSearch } from "./index.js";

test("search is on from ten options and can be forced either way", () => {
  assert.equal(wantsSearch("auto", AUTO_SEARCH_FROM - 1), false);
  assert.equal(wantsSearch("auto", AUTO_SEARCH_FROM), true);
  assert.equal(wantsSearch(undefined, 40), true);
  assert.equal(wantsSearch("true", 3), true);
  assert.equal(wantsSearch("false", 400), false);
});

test("fold ignores case and accents", () => {
  assert.equal(fold("Café Ñandú"), "cafe nandu");
});

test("matches finds every word of the query anywhere in the label", () => {
  assert.ok(matches("Andhra Pradesh", "pra"));
  assert.ok(matches("Andhra Pradesh", "pradesh andhra"));
  assert.ok(matches("Café", "CAFE"));
  assert.ok(!matches("Andhra Pradesh", "kerala"));
  assert.ok(matches("anything", "   "));
});

test("move steps, stops at the ends and jumps", () => {
  assert.equal(move("ArrowDown", -1, 5), 0);
  assert.equal(move("ArrowDown", 4, 5), 4);
  assert.equal(move("ArrowUp", 0, 5), 0);
  assert.equal(move("ArrowUp", -1, 5), 0);
  assert.equal(move("ArrowUp", 3, 5), 2);
  assert.equal(move("Home", 3, 5), 0);
  assert.equal(move("End", 0, 5), 4);
  assert.equal(move("PageDown", 2, 30), 12);
  assert.equal(move("PageDown", 25, 30), 29);
  assert.equal(move("PageUp", 12, 30), 2);
  assert.equal(move("PageUp", 3, 30), 0);
  assert.equal(move("ArrowDown", -1, 0), -1);
});

test("pushChar extends a fresh prefix and restarts a stale one", () => {
  assert.equal(pushChar("a", "b", 100), "ab");
  assert.equal(pushChar("ab", "c", 900), "c");
});

test("typeahead finds the first label with the prefix, wrapping from the active one", () => {
  const labels = ["Apple", "Apricot", "Banana", "Blueberry", "Cherry"];
  assert.equal(typeahead(labels, "b", -1), 2);
  assert.equal(typeahead(labels, "bl", 2), 3);
  assert.equal(typeahead(labels, "ap", 1), 1);
  assert.equal(typeahead(labels, "c", 0), 4);
  assert.equal(typeahead(labels, "z", 0), -1);
  assert.equal(typeahead([], "a", -1), -1);
  assert.equal(typeahead(labels, "", 0), -1);
});

test("a repeated letter cycles through the options that start with it", () => {
  const labels = ["Apple", "Apricot", "Banana", "Avocado"];
  assert.equal(typeahead(labels, "a", -1), 0);
  assert.equal(typeahead(labels, "aa", 0), 1);
  assert.equal(typeahead(labels, "aaa", 1), 3);
  assert.equal(typeahead(labels, "aaaa", 3), 0);
});
