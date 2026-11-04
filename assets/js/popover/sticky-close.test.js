import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

// Execute the actual colocated close method with LiveView-like sticky attributes.
test('popover close replaces sticky open state before a patch', () => {
  const source = readFileSync(new URL('../../../lib/sutra_ui/popover.ex', import.meta.url), 'utf8');
  const body = source.match(/\n        close\(\) \{([\s\S]*?)\n        \},/)[1];
  const close = new Function(body);
  const element = (name, value) => ({
    attrs: { [name]: value }, sticky: { [name]: value },
    setAttribute(key, val) { this.attrs[key] = val; },
    patch() { Object.assign(this.attrs, this.sticky); }
  });
  const trigger = element('aria-expanded', 'true');
  const content = element('aria-hidden', 'false');
  close.call({ trigger, content, js: () => ({
    setAttribute(el, name, value) { el.setAttribute(name, value); el.sticky[name] = value; }
  }) });
  trigger.patch();
  content.patch();
  assert.equal(trigger.attrs['aria-expanded'], 'false');
  assert.equal(content.attrs['aria-hidden'], 'true');
});
