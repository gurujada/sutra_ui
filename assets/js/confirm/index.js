// `data-confirm` without window.confirm(): a click (or a form submit) on an element with
// `data-confirm` is caught before LiveView and phoenix_html see it, the shared confirm dialog
// (`<.confirm_host />`) opens with the message, and on the verb the original click is replayed
// so it passes through. Keep, Esc and the backdrop leave everything as it was.

const HOST_SELECTOR = "[data-sutra-confirm-host]";

/**
 * What the dialog should say for an element, from its data attributes.
 * @param {{getAttribute(name: string): string | null}} el
 */
export function promptFor(el) {
  const tone = el.getAttribute("data-confirm-tone");
  return {
    message: el.getAttribute("data-confirm") || "",
    title: el.getAttribute("data-confirm-title") || "",
    verb: el.getAttribute("data-confirm-verb") || "",
    tone: tone === "primary" ? "primary" : "danger",
  };
}

/**
 * The state of one pending confirmation. The host adapter does the DOM work:
 * `open(prompt)`, `close()`, `focusTrigger(el)`.
 */
export class Confirmer {
  constructor(host) {
    this.host = host;
    this.pending = null;
    this.confirmed = new WeakSet();
  }

  /** True when an event on `el` is a replay that has to pass through. */
  passes(el) {
    return this.confirmed.has(el);
  }

  ask(el, kind = "click") {
    this.pending = { el, kind };
    this.host.open(promptFor(el));
  }

  /** The verb: close the dialog and replay the original action. */
  accept() {
    const pending = this.pending;
    if (!pending) return;
    this.pending = null;
    this.host.close();
    this.#replay(pending);
  }

  /** Keep, Esc or the backdrop: nothing happens, focus returns. */
  cancel() {
    const pending = this.pending;
    if (!pending) return;
    this.pending = null;
    this.host.focusTrigger(pending.el);
  }

  #replay({ el, kind }) {
    this.confirmed.add(el);
    // phoenix_html would ask window.confirm() for the attribute: take it off while the
    // replayed action runs.
    const message = el.getAttribute("data-confirm");
    el.removeAttribute("data-confirm");
    try {
      if (kind === "submit") el.requestSubmit(this.submitter);
      else el.click();
    } finally {
      if (message !== null) el.setAttribute("data-confirm", message);
      this.confirmed.delete(el);
    }
  }
}

function findHost(doc) {
  return doc.querySelector(HOST_SELECTOR);
}

function domHost(win, getRoot) {
  const part = (root, name) => root.querySelector(`[data-confirm-${name}]`);
  return {
    open(prompt) {
      const root = getRoot();
      const set = (name, text, fallback) => {
        const node = part(root, name);
        if (node) node.textContent = text || fallback || "";
      };
      set("title", prompt.title, root.dataset.defaultTitle);
      set("message", prompt.message);
      const ok = root.querySelectorAll("[data-confirm-ok]");
      for (const button of ok) {
        button.hidden = button.dataset.tone !== prompt.tone;
        button.textContent = prompt.verb || button.dataset.defaultVerb || button.textContent;
      }
      root.dataset.tone = prompt.tone;
      const icon = part(root, "icon");
      if (icon) icon.style.display = prompt.tone === "danger" ? "" : "none";
      const dialog = root.querySelector("[phx-hook]") || root.firstElementChild;
      dialog.dispatchEvent(new CustomEvent("phx:show-dialog"));
      // Danger starts on Keep, so Enter does not delete; a plain question starts on the verb.
      win.requestAnimationFrame(() => {
        const target =
          prompt.tone === "danger"
            ? part(root, "cancel")
            : [...root.querySelectorAll("[data-confirm-ok]")].find((b) => !b.hidden);
        target?.focus();
      });
    },
    close() {
      const dialog = getRoot().querySelector("[phx-hook]") || getRoot().firstElementChild;
      dialog.dispatchEvent(new CustomEvent("phx:hide-dialog"));
    },
    focusTrigger(el) {
      if (el?.isConnected) el.focus();
    },
  };
}

let installed = null;

/**
 * Starts catching `[data-confirm]`. Idempotent. Call it from app.js before
 * `liveSocket.connect()`, or let the `<.confirm_host />` hook do it on mount: the listeners
 * are on `window` in the capture phase, so they run before LiveView's and phoenix_html's.
 */
export function installConfirm(doc = document, win = window) {
  if (installed) return installed;
  const confirmer = new Confirmer(domHost(win, () => findHost(doc)));

  const onClick = (event) => {
    const el = event.target?.closest?.("[data-confirm]");
    // A form with data-confirm is caught on submit, not on the click of its button.
    if (!el || el.matches?.("form") || confirmer.passes(el)) return;
    if (!findHost(doc)) return; // no host on the page: phoenix_html's own prompt stays
    event.preventDefault();
    event.stopImmediatePropagation();
    confirmer.ask(el);
  };

  const onSubmit = (event) => {
    const form = event.target;
    if (!form?.matches?.("form[data-confirm]") || confirmer.passes(form) || !findHost(doc)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    confirmer.submitter = event.submitter ?? undefined;
    confirmer.ask(form, "submit");
  };

  const onHostClick = (event) => {
    const root = findHost(doc);
    if (!root || !root.contains(event.target)) return;
    if (event.target.closest("[data-confirm-ok]")) confirmer.accept();
  };

  // Esc, the backdrop and Keep all end in the dialog's hide event.
  const onHide = (event) => {
    const root = findHost(doc);
    if (root && root.contains(event.target)) confirmer.cancel();
  };

  win.addEventListener("click", onClick, true);
  win.addEventListener("submit", onSubmit, true);
  win.addEventListener("click", onHostClick, true);
  win.addEventListener("phx:hide-dialog", onHide, true);
  installed = { confirmer, uninstall() {
    win.removeEventListener("click", onClick, true);
    win.removeEventListener("submit", onSubmit, true);
    win.removeEventListener("click", onHostClick, true);
    win.removeEventListener("phx:hide-dialog", onHide, true);
    installed = null;
  } };
  return installed;
}

export const ConfirmHost = {
  mounted() {
    installConfirm();
  },
};
