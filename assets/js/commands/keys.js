// Keyboard shortcuts: chords ("mod+k") and sequences ("g h"), and the rules for when a
// shortcut may fire.

export const SEQUENCE_TIMEOUT_MS = 1000;

const MODIFIERS = ["mod", "ctrl", "meta", "alt", "shift"];
const NAMED = { esc: "escape", space: " ", return: "enter", plus: "+" };

/**
 * @typedef {{key: string, mod: boolean, ctrl: boolean, meta: boolean, alt: boolean, shift: boolean}} Chord
 */

/**
 * Parses "mod+k", "shift+/", "?" or "g h" into a list of chords.
 * @param {string} spec
 * @returns {Chord[]}
 */
export function parse(spec) {
  return String(spec ?? "")
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => {
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

/** @returns {boolean} whether the platform's main modifier is Cmd */
export function isMac(platform = globalThis.navigator?.platform ?? "") {
  return /mac|iphone|ipad|ipod/i.test(platform);
}

/**
 * Whether a keyboard event is this chord.
 * @param {Chord} chord
 * @param {{key: string, ctrlKey?: boolean, metaKey?: boolean, altKey?: boolean, shiftKey?: boolean}} event
 * @param {boolean} [mac]
 */
export function matches(chord, event, mac = isMac()) {
  if (!chord.key || String(event.key ?? "").toLowerCase() !== chord.key) return false;

  const wantMeta = chord.meta || (chord.mod && mac);
  const wantCtrl = chord.ctrl || (chord.mod && !mac);
  if (wantMeta !== !!event.metaKey) return false;
  if (wantCtrl !== !!event.ctrlKey) return false;
  if (chord.alt !== !!event.altKey) return false;

  // Shift is part of a symbol ("?", "/" typed with shift): only letters care about it.
  const letter = /^\p{L}$/u.test(chord.key);
  return !letter && !chord.shift ? true : chord.shift === !!event.shiftKey;
}

/** A chord with Ctrl, Cmd or Alt works while typing in a field; a plain key does not. */
export function worksWhileTyping(chords) {
  return chords.length === 1 && (chords[0].mod || chords[0].ctrl || chords[0].meta || chords[0].alt);
}

/**
 * Whether the event came from somewhere text is typed.
 * @param {EventTarget | null} target
 */
export function isTyping(target) {
  const el = /** @type {HTMLElement | null} */ (target);
  if (!el || !el.tagName) return false;
  if (el.isContentEditable) return true;
  const tag = el.tagName.toLowerCase();
  if (tag === "textarea" || tag === "select") return true;
  if (tag !== "input") return false;
  return !["button", "checkbox", "radio", "submit", "reset", "range", "color", "file", "image"].includes(
    String(el.type ?? "text").toLowerCase(),
  );
}

/**
 * Tracks the keys pressed so far toward a sequence.
 * @param {{now?: () => number, timeout?: number}} [options]
 */
export function sequence({ now = () => Date.now(), timeout = SEQUENCE_TIMEOUT_MS } = {}) {
  /** @type {{event: object, at: number}[]} */
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
          (chords) =>
            chords.length === window.length && chords.every((chord, i) => matches(chord, window[i].event, mac)),
        );
        if (hit >= 0) {
          pressed = [];
          return hit;
        }
        const partial = bindings.some(
          (chords) =>
            chords.length > window.length && window.every((p, i) => matches(chords[i], p.event, mac)),
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
    },
  };
}

/**
 * The words on a key cap for a shortcut: "mod+k" is "⌘ K" on a Mac, "Ctrl K" elsewhere.
 * @param {string} spec
 * @param {boolean} [mac]
 * @returns {string[][]} one list of caps per chord
 */
export function label(spec, mac = isMac()) {
  return parse(spec).map((chord) => {
    const caps = [];
    if (chord.mod) caps.push(mac ? "⌘" : "Ctrl");
    if (chord.ctrl) caps.push(mac ? "⌃" : "Ctrl");
    if (chord.alt) caps.push(mac ? "⌥" : "Alt");
    if (chord.shift) caps.push(mac ? "⇧" : "Shift");
    if (chord.meta) caps.push(mac ? "⌘" : "Win");
    const key = chord.key === " " ? "Space" : chord.key.length === 1 ? chord.key.toUpperCase() : capitalize(chord.key);
    caps.push(key);
    return caps;
  });
}

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}
