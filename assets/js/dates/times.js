// A list of times at the minute step, for a time picker with a step of 5 minutes or more.

import { pad } from "./core.js";
import { h } from "./dom.js";

/** "00:00", "00:15", ... for a step in minutes. */
export function timeOptions(stepMinutes) {
  const out = [];
  for (let m = 0; m < 24 * 60; m += stepMinutes) out.push(`${pad(Math.floor(m / 60))}:${pad(m % 60)}`);
  return out;
}

/** The option nearest to a time (earlier on a tie), for the starting position. */
export function nearest(options, hhmm) {
  if (!options.length) return null;
  const minutes = (t) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
  const target = minutes(hhmm || "09:00");
  return options.reduce((best, t) => (Math.abs(minutes(t) - target) < Math.abs(minutes(best) - target) ? t : best), options[0]);
}

/**
 * @param {string[]} options @param {string | null} selected @param {string | null} active
 * @param {string} idBase @param {(t: string) => void} onPick
 */
export function renderTimes(options, selected, active, idBase, onPick) {
  const list = h("div", { class: "dp-times", role: "listbox", id: `${idBase}-times`, "aria-label": "Times" });
  options.forEach((t, i) => {
    const option = h("div", {
      role: "option",
      id: `${idBase}-time-${i}`,
      class: "dp-time",
      "data-value": t,
      "data-active": t === active,
      "aria-selected": t === selected ? "true" : "false",
      text: t,
    });
    option.addEventListener("click", () => onPick(t));
    list.append(option);
  });
  return list;
}
