// Matching and ranking of commands. The same rules run in Elixir (SutraUI.Commands.Match);
// test/fixtures/commands_match.json holds the cases both implementations must agree on.
//
// A query is split into words. Each word, in order, must match a later token than the one the
// previous word matched, tokens being the words of the title followed by the words of the
// keywords. A word matches a token as the start of it (best), inside it, or, for words of five
// letters or more, with one typo in the start of it. Accents and case are ignored.

export const PREFIX = 6;
export const INFIX = 3;
export const TYPO = 2;
const KEYWORD_PENALTY = 1;
const FIRST_TOKEN_BONUS = 3;
const MIN_TYPO_LENGTH = 5;

/**
 * Lower-cases and strips accents.
 * @param {string} text
 * @returns {string}
 */
export function normalize(text) {
  return String(text ?? "")
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLowerCase();
}

/**
 * The words of a text: runs of letters and digits.
 * @param {string} text
 * @returns {string[]}
 */
export function tokens(text) {
  return normalize(text).match(/[\p{L}\p{N}]+/gu) ?? [];
}

/**
 * Optimal string alignment distance (insert, delete, substitute, swap neighbours).
 * @param {string} a
 * @param {string} b
 * @returns {number}
 */
export function distance(a, b) {
  const x = Array.from(a);
  const y = Array.from(b);
  const rows = x.length + 1;
  const cols = y.length + 1;
  const d = Array.from({ length: rows }, (_, i) => {
    const row = new Array(cols).fill(0);
    row[0] = i;
    return row;
  });
  for (let j = 0; j < cols; j++) d[0][j] = j;

  for (let i = 1; i < rows; i++) {
    for (let j = 1; j < cols; j++) {
      const cost = x[i - 1] === y[j - 1] ? 0 : 1;
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost);
      if (i > 1 && j > 1 && x[i - 1] === y[j - 2] && x[i - 2] === y[j - 1]) {
        d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1);
      }
    }
  }
  return d[rows - 1][cols - 1];
}

/**
 * How a query word matches a token: PREFIX, INFIX, TYPO or 0.
 * @param {string} word
 * @param {string} token
 * @returns {number}
 */
export function wordClass(word, token) {
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

/**
 * The score of a query against a title and keywords, or null when it does not match.
 * An empty query matches everything with 0.
 * @param {string} query
 * @param {string} title
 * @param {string[]} [keywords]
 * @returns {number | null}
 */
export function score(query, title, keywords = []) {
  const words = tokens(query);
  if (words.length === 0) return 0;

  const titleTokens = tokens(title);
  const pool = [
    ...titleTokens.map((token) => ({ token, keyword: false })),
    ...tokens(keywords.join(" ")).map((token) => ({ token, keyword: true })),
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

/**
 * Items that match the query, best first: score, then shorter title, then original order.
 * @template T
 * @param {string} query
 * @param {T[]} items
 * @param {(item: T) => {title: string, keywords?: string[]}} text
 * @returns {T[]}
 */
export function rank(query, items, text) {
  const scored = [];
  items.forEach((item, index) => {
    const { title, keywords } = text(item);
    const s = score(query, title, keywords ?? []);
    if (s !== null) scored.push({ item, index, s, length: Array.from(title).length });
  });
  scored.sort((a, b) => b.s - a.s || a.length - b.length || a.index - b.index);
  return scored.map((entry) => entry.item);
}
