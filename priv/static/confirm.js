/* sutra_ui confirm source-hash:92e40207f63d0123 (built by mix assets.build; do not edit) */

// assets/js/confirm/index.js
var HOST_SELECTOR = "[data-sutra-confirm-host]";
function promptFor(el) {
  const tone = el.getAttribute("data-confirm-tone");
  return {
    message: el.getAttribute("data-confirm") || "",
    title: el.getAttribute("data-confirm-title") || "",
    verb: el.getAttribute("data-confirm-verb") || "",
    tone: tone === "primary" ? "primary" : "danger"
  };
}
var Confirmer = class {
  constructor(host) {
    this.host = host;
    this.pending = null;
    this.confirmed = /* @__PURE__ */ new WeakSet();
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
};
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
      win.requestAnimationFrame(() => {
        const target = prompt.tone === "danger" ? part(root, "cancel") : [...root.querySelectorAll("[data-confirm-ok]")].find((b) => !b.hidden);
        target?.focus();
      });
    },
    close() {
      const dialog = getRoot().querySelector("[phx-hook]") || getRoot().firstElementChild;
      dialog.dispatchEvent(new CustomEvent("phx:hide-dialog"));
    },
    focusTrigger(el) {
      if (el?.isConnected) el.focus();
    }
  };
}
var installed = null;
function installConfirm(doc = document, win = window) {
  if (installed) return installed;
  const confirmer = new Confirmer(domHost(win, () => findHost(doc)));
  const onClick = (event) => {
    const el = event.target?.closest?.("[data-confirm]");
    if (!el || el.matches?.("form") || confirmer.passes(el)) return;
    if (!findHost(doc)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    confirmer.ask(el);
  };
  const onSubmit = (event) => {
    const form = event.target;
    if (!form?.matches?.("form[data-confirm]") || confirmer.passes(form) || !findHost(doc)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    confirmer.submitter = event.submitter ?? void 0;
    confirmer.ask(form, "submit");
  };
  const onHostClick = (event) => {
    const root = findHost(doc);
    if (!root || !root.contains(event.target)) return;
    if (event.target.closest("[data-confirm-ok]")) confirmer.accept();
  };
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
var ConfirmHost = {
  mounted() {
    installConfirm();
  }
};
export {
  ConfirmHost,
  Confirmer,
  installConfirm,
  promptFor
};
