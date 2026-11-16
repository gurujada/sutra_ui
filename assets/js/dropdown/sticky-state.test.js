import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

// Run the dropdown's real open/close methods against LiveView-like sticky attributes: a patch
// re-applies the server's attributes except those set through `this.js()`.
const source = readFileSync(new URL('../../../lib/sutra_ui/dropdown_menu.ex', import.meta.url), 'utf8');
const method = (name) => new Function('focusOnTrigger', source.match(new RegExp(`\\n        ${name}\\([^)]*\\) \\{([\\s\\S]*?)\\n        \\},`))[1]);

const element = (attrs) => ({
  attrs: { ...attrs }, server: { ...attrs },
  getAttribute(key) { return this.attrs[key]; },
  setAttribute(key, val) { this.attrs[key] = val; },
  removeAttribute(key) { delete this.attrs[key]; },
  focus() {},
  patch() { Object.assign(this.attrs, this.server); }
});

const hook = () => {
  const trigger = element({ 'aria-expanded': 'false' });
  const popover = element({ 'aria-hidden': 'true' });
  return {
    trigger, popover, el: {}, menuItems: [],
    updateMenuItems() {}, setActiveItem() {},
    js: () => ({ setAttribute(el, name, value) { el.setAttribute(name, value); el.server[name] = value; } })
  };
};

test('an open dropdown stays open through a LiveView patch', () => {
  globalThis.document = { dispatchEvent() {} };
  globalThis.CustomEvent = class { constructor(type, init) { this.type = type; this.detail = init?.detail; } };
  const h = hook();
  method('openPopover').call(h, false);
  h.trigger.patch();
  h.popover.patch();
  assert.equal(h.trigger.attrs['aria-expanded'], 'true');
  assert.equal(h.popover.attrs['aria-hidden'], 'false');
});

test('a closed dropdown stays closed through a LiveView patch', () => {
  globalThis.document = { dispatchEvent() {} };
  globalThis.CustomEvent = class { constructor(type, init) { this.type = type; this.detail = init?.detail; } };
  const h = hook();
  method('openPopover').call(h, false);
  method('closePopover').call(h, false);
  h.trigger.patch();
  h.popover.patch();
  assert.equal(h.trigger.attrs['aria-expanded'], 'false');
  assert.equal(h.popover.attrs['aria-hidden'], 'true');
});
