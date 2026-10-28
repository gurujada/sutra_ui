// The segmented field: a group of small numeric inputs ("15 / 03 / 2027", "09 : 30"). Typing
// fills a segment and moves on, the arrow keys step it, paste reads a whole value. The
// inputs are unnamed: the posted value lives in the picker's own input (index.js).

import { h } from "./dom.js";
import { SPECS, display, localeOrder, step, typeDigit } from "./segments.js";

/**
 * @typedef {{ key: string, spec: import("./segments.js").Spec, label: string, placeholder: string }} Part
 * @typedef {{ root: HTMLElement, links: { after: Group | null }, inputs: HTMLInputElement[], values: Record<string, number | null>, set: (values: Record<string, number | null>) => void, focus: () => void, setDisabled: (d: boolean) => void, setInvalid: (v: boolean, describedby?: string) => void }} Group
 */

/** The date parts in the locale's order, and the separator between them. */
export function dateParts(locale) {
  const { order, separator } = localeOrder(locale);
  const labels = { day: ["Day", "dd"], month: ["Month", "mm"], year: ["Year", "yyyy"] };
  return {
    separator,
    parts: order.map((key) => ({ key, spec: SPECS[key], label: labels[key][0], placeholder: labels[key][1] })),
  };
}

/** Hour and minute parts; `stepMinutes` is the minute step the arrow keys follow. */
export function timeParts(stepMinutes = 1) {
  return [
    { key: "hour", spec: SPECS.hour, label: "Hour", placeholder: "hh" },
    { key: "minute", spec: { ...SPECS.minute, step: stepMinutes }, label: "Minute", placeholder: "mm" },
  ];
}

/**
 * @param {{ parts: Part[], separator: string, label: string, disabled?: boolean,
 *   onEdit: (values: Record<string, number | null>) => void,
 *   parsePaste?: (text: string) => Record<string, number | null> | null }} options
 * @returns {Group}
 */
export function segmentGroup({ parts, separator, label, disabled = false, onEdit, parsePaste }) {
  /** @type {Record<string, number | null>} */
  const values = Object.fromEntries(parts.map((p) => [p.key, null]));
  const root = h("div", { class: "dp-field", role: "group", "aria-label": label });
  /** @type {HTMLInputElement[]} */
  const inputs = [];
  let buffer = "";

  const paint = (index) => {
    const { key, spec } = parts[index];
    const input = inputs[index];
    input.value = display(spec, values[key]);
    input.setAttribute("aria-valuenow", values[key] === null ? "" : String(values[key]));
    if (values[key] === null) input.removeAttribute("aria-valuenow");
    input.setAttribute("aria-valuetext", values[key] === null ? "Empty" : input.value);
  };

  /** @type {{ after: Group | null }} */
  const links = { after: null };

  const focusAt = (index) => {
    const target = inputs[index];
    if (target) {
      target.focus();
      target.select();
    } else if (index >= inputs.length) {
      // Past the last segment: on to the next field (a range's end, a datetime's time).
      links.after?.focus();
    }
  };

  parts.forEach((part, index) => {
    const { spec } = part;
    const input = /** @type {HTMLInputElement} */ (
      h("input", {
        type: "text",
        inputmode: "numeric",
        autocomplete: "off",
        autocorrect: "off",
        spellcheck: "false",
        enterkeyhint: "next",
        class: `dp-seg dp-seg-${spec.digits}`,
        role: "spinbutton",
        "aria-label": part.label,
        "aria-valuemin": spec.min,
        "aria-valuemax": spec.max,
        placeholder: part.placeholder,
        "data-part": part.key,
        disabled,
      })
    );
    inputs.push(input);

    input.addEventListener("focus", () => {
      buffer = "";
      input.select();
    });

    // Digits arrive as beforeinput so soft keyboards (which send no useful keydown) work too.
    input.addEventListener("beforeinput", (event) => {
      const e = /** @type {InputEvent} */ (event);
      e.preventDefault();
      if (e.inputType === "insertText" && e.data && /^\d+$/.test(e.data)) {
        for (const digit of e.data) {
          const r = typeDigit(spec, buffer, digit);
          buffer = r.buffer;
          values[part.key] = r.value;
          paint(index);
          if (r.advance) {
            buffer = "";
            onEdit({ ...values });
            focusAt(index + 1);
            return;
          }
        }
        onEdit({ ...values });
      } else if (e.inputType.startsWith("delete")) {
        buffer = "";
        values[part.key] = null;
        paint(index);
        onEdit({ ...values });
      } else if (e.inputType === "insertFromPaste" && e.data) {
        pasted(e.data);
      }
    });

    input.addEventListener("keydown", (e) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      switch (e.key) {
        case "ArrowUp":
        case "ArrowDown":
          e.preventDefault();
          buffer = "";
          values[part.key] = step(spec, values[part.key], e.key === "ArrowUp" ? 1 : -1);
          paint(index);
          input.select();
          onEdit({ ...values });
          break;
        case "ArrowLeft":
          e.preventDefault();
          focusAt(index - 1);
          break;
        case "ArrowRight":
          e.preventDefault();
          focusAt(index + 1);
          break;
        case "Backspace":
        case "Delete":
          e.preventDefault();
          buffer = "";
          values[part.key] = null;
          paint(index);
          onEdit({ ...values });
          break;
        case "Home":
          e.preventDefault();
          focusAt(0);
          break;
        case "End":
          e.preventDefault();
          focusAt(inputs.length - 1);
          break;
        default:
          // A separator typed after a digit moves on, as in a native date field.
          if (e.key.length === 1 && /[\s/.\-:,]/.test(e.key)) {
            e.preventDefault();
            focusAt(index + 1);
          } else if (e.key.length === 1 && !/\d/.test(e.key)) {
            e.preventDefault();
          }
      }
    });

    input.addEventListener("paste", (e) => {
      e.preventDefault();
      pasted(e.clipboardData?.getData("text") ?? "");
    });
  });

  function pasted(text) {
    const next = parsePaste?.(text);
    if (!next) return;
    set(next);
    onEdit({ ...values });
  }

  parts.forEach((_, i) => {
    if (i > 0) root.append(h("span", { class: "dp-sep", "aria-hidden": "true", text: separator }));
    root.append(inputs[i]);
  });

  /** @param {Record<string, number | null>} next */
  function set(next) {
    parts.forEach((p, i) => {
      if (p.key in next) values[p.key] = next[p.key];
      paint(i);
    });
  }

  return {
    root,
    links,
    inputs,
    values,
    set,
    focus: () => focusAt(0),
    setDisabled(d) {
      for (const i of inputs) i.disabled = d;
    },
    setInvalid(invalid, describedby) {
      root.toggleAttribute("data-invalid", invalid);
      for (const i of inputs) {
        if (invalid) i.setAttribute("aria-invalid", "true");
        else i.removeAttribute("aria-invalid");
        if (describedby) i.setAttribute("aria-describedby", describedby);
      }
    },
  };
}
