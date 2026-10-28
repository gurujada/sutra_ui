/* sutra_ui toast source-hash:d2bd8de3b2c45498 (built by mix assets.build; do not edit) */

// assets/js/toast/index.js
var NOTICE_DELAY_MS = 3e3;
var EXIT_FALLBACK_MS = 400;
var realClock = {
  now: () => Date.now(),
  set: (fn, ms) => setTimeout(fn, ms),
  clear: (id) => clearTimeout(id)
};
var Countdown = class {
  constructor(ms, onDone, clock = realClock) {
    this.total = ms;
    this.left = ms;
    this.onDone = onDone;
    this.clock = clock;
    this.timer = null;
    this.startedAt = 0;
    this.paused = false;
    this.done = false;
  }
  start() {
    this.paused = false;
    this.#arm();
  }
  pause() {
    if (this.paused || this.done) return;
    this.paused = true;
    if (this.timer !== null) {
      this.clock.clear(this.timer);
      this.timer = null;
      this.left = Math.max(0, this.left - (this.clock.now() - this.startedAt));
    }
  }
  resume() {
    if (!this.paused || this.done) return;
    this.paused = false;
    this.#arm();
  }
  cancel() {
    this.done = true;
    if (this.timer !== null) this.clock.clear(this.timer);
    this.timer = null;
  }
  remaining() {
    if (this.timer === null) return this.left;
    return Math.max(0, this.left - (this.clock.now() - this.startedAt));
  }
  #arm() {
    if (this.done) return;
    this.startedAt = this.clock.now();
    this.timer = this.clock.set(() => {
      this.timer = null;
      this.done = true;
      this.left = 0;
      this.onDone();
    }, this.left);
  }
};
var DelayedNotice = class {
  constructor(ms, show, hide, clock = realClock) {
    this.ms = ms;
    this.show = show;
    this.hide = hide;
    this.clock = clock;
    this.timer = null;
    this.visible = false;
  }
  lost() {
    if (this.timer !== null || this.visible) return;
    this.timer = this.clock.set(() => {
      this.timer = null;
      this.visible = true;
      this.show();
    }, this.ms);
  }
  back() {
    if (this.timer !== null) this.clock.clear(this.timer);
    this.timer = null;
    if (this.visible) {
      this.visible = false;
      this.hide();
    }
  }
};
function toast(kind, body, opts = {}) {
  window.dispatchEvent(new CustomEvent("sutra:toast", { detail: { kind, body, ...opts } }));
}
function reducedMotion() {
  return typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches;
}
var ToastGroup = {
  mounted() {
    this.live = this.el.dataset.live === "true";
    this.entries = /* @__PURE__ */ new Map();
    this.bound = /* @__PURE__ */ new WeakSet();
    this.onBrowserToast = (e) => {
      if (this.live) this.pushEventTo(this.stack(), "toast", e.detail);
    };
    window.addEventListener("sutra:toast", this.onBrowserToast);
    if (this.handleEvent) {
      this.handleEvent("toast", (detail) => {
        if (this.live) this.pushEventTo(this.stack(), "toast", detail);
      });
    }
    this.setupNotice();
    if (typeof MutationObserver === "function") {
      this.observer = new MutationObserver(() => this.sync());
      this.observer.observe(this.el, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["data-state", "data-version", "data-duration"]
      });
    }
    this.sync();
  },
  updated() {
    this.sync();
    this.showNotice();
  },
  destroyed() {
    window.removeEventListener("sutra:toast", this.onBrowserToast);
    this.observer?.disconnect();
    for (const entry of this.entries.values()) entry.countdown?.cancel();
    this.notice?.back();
    this.entries.clear();
  },
  stack() {
    return this.el.querySelector("[data-toast-stack]");
  },
  sync() {
    const present = /* @__PURE__ */ new Set();
    for (const node of this.el.querySelectorAll("[data-toast]")) {
      const id = node.dataset.toastId || node.id;
      present.add(id);
      let entry = this.entries.get(id);
      const version = node.dataset.version || "0";
      if (!entry || entry.node !== node || entry.version !== version) {
        entry?.countdown?.cancel();
        entry = { node, version, countdown: null, finishing: false, hovered: false, focused: false };
        this.entries.set(id, entry);
        this.bind(node, id);
        const ms = Number(node.dataset.duration || 0);
        if (ms > 0 && node.dataset.state !== "closing") {
          node.style?.setProperty("--toast-duration", `${ms}ms`);
          entry.countdown = new Countdown(ms, () => this.close(node, id));
          entry.countdown.start();
        }
      }
      if (node.dataset.state === "closing") this.finish(node, id);
    }
    for (const [id, entry] of this.entries) {
      if (present.has(id)) continue;
      entry.countdown?.cancel();
      this.entries.delete(id);
    }
  },
  bind(node, id) {
    if (this.bound.has(node)) return;
    this.bound.add(node);
    const settle = () => {
      const entry = this.entries.get(id);
      if (!entry?.countdown) return;
      if (entry.hovered || entry.focused) {
        entry.countdown.pause();
        node.toggleAttribute("data-paused", true);
      } else {
        entry.countdown.resume();
        node.toggleAttribute("data-paused", false);
      }
    };
    const track = (field, value) => () => {
      const entry = this.entries.get(id);
      if (entry) entry[field] = value;
      settle();
    };
    node.addEventListener("mouseenter", track("hovered", true));
    node.addEventListener("mouseleave", track("hovered", false));
    node.addEventListener("focusin", track("focused", true));
    node.addEventListener("focusout", track("focused", false));
    node.querySelector("[data-toast-close]")?.addEventListener("click", () => this.close(node, id));
  },
  /** Dismiss: the server marks it closing (data-state) and the exit animation runs. */
  close(node, id) {
    const entry = this.entries.get(id);
    if (!entry || entry.finishing) return;
    entry.countdown?.cancel();
    if (!this.live) {
      node.dataset.state = "closing";
      this.finish(node, id);
      return;
    }
    if (node.dataset.flash) this.pushEvent("lv:clear-flash", { key: node.dataset.flash });
    this.pushEventTo(this.stack(), "dismiss", { id });
  },
  /** Plays the exit animation, then removes the toast. */
  finish(node, id) {
    const entry = this.entries.get(id);
    if (!entry || entry.finishing) return;
    entry.finishing = true;
    entry.countdown?.cancel();
    const remove = () => {
      if (this.live) this.pushEventTo(this.stack(), "remove", { id });
      else node.remove();
    };
    if (reducedMotion()) return remove();
    let removed = false;
    const once = () => {
      if (removed) return;
      removed = true;
      remove();
    };
    node.addEventListener("animationend", once, { once: true });
    setTimeout(once, EXIT_FALLBACK_MS);
  },
  setupNotice() {
    const first = this.el.querySelector("[data-toast-notice]");
    if (!first) return;
    const delay = Number(first.dataset.delay || NOTICE_DELAY_MS);
    this.notice = new DelayedNotice(
      delay,
      () => this.showNotice(),
      () => this.showNotice()
    );
    this.el.addEventListener("sutra:connection-lost", () => this.notice.lost());
    this.el.addEventListener("sutra:connection-back", () => this.notice.back());
    this.showNotice();
  },
  /** Re-applies the notice's state: a LiveView patch can reset the hidden attribute. */
  showNotice() {
    const el = this.el.querySelector("[data-toast-notice]");
    if (el && this.notice) el.hidden = !this.notice.visible;
  }
};
export {
  Countdown,
  DelayedNotice,
  NOTICE_DELAY_MS,
  ToastGroup,
  toast
};
