import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { distance, normalize, rank, score, tokens, wordClass, PREFIX, INFIX, TYPO } from "./match.js";

const fixture = JSON.parse(readFileSync(new URL("../../../test/fixtures/commands_match.json", import.meta.url)));

test("normalize drops accents and case", () => {
  assert.equal(normalize("Café ÉCOLE"), "cafe ecole");
});

test("tokens are runs of letters and digits", () => {
  assert.deepEqual(tokens("Go to Room-12, now!"), ["go", "to", "room", "12", "now"]);
});

test("distance counts one swap of neighbours as one edit", () => {
  assert.equal(distance("abcd", "abdc"), 1);
  assert.equal(distance("kitten", "sitting"), 3);
  assert.equal(distance("", "abc"), 3);
});

test("a word matches as a start, inside, or with one typo (long words only)", () => {
  assert.equal(wordClass("fil", "file"), PREFIX);
  assert.equal(wordClass("ile", "file"), INFIX);
  assert.equal(wordClass("setings", "settings"), TYPO);
  assert.equal(wordClass("flie", "file"), 0, "four letters: no typo allowance");
  assert.equal(wordClass("f", "file"), PREFIX);
  assert.equal(wordClass("i", "file"), 0, "one letter only matches a start");
});

for (const c of fixture.score) {
  test(`score(${JSON.stringify(c.query)}, ${JSON.stringify(c.title)}, ${JSON.stringify(c.keywords)}) is ${c.score}`, () => {
    assert.equal(score(c.query, c.title, c.keywords), c.score);
  });
}

for (const c of fixture.rank) {
  test(`rank(${JSON.stringify(c.query)}) orders ${c.order.join(", ")}`, () => {
    assert.deepEqual(
      rank(c.query, c.items, (i) => i).map((i) => i.title),
      c.order,
    );
  });
}
