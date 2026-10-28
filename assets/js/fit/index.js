// Keeps an open card inside the viewport. The same code is carried inline by the popover and
// dropdown_menu runtime hooks (they cannot import); test/sutra_ui/fit_test.exs keeps the
// copies equal to the body below, between the fit:start and fit:end markers.

/**
 * Flip the card to the other side when it would run off, then shift it back in. Positions
 * come from the CSSOM (margins), never a style attribute.
 * @param {HTMLElement | null} content the open card (absolutely positioned by its data-side)
 * @param {HTMLElement | null} trigger the element it hangs from
 * @param {string | undefined} wanted a preferred data-side, or "auto"
 */
export function fit(content, trigger, wanted) {
  // fit:start
  if (!content || !trigger) return;
  const margin = 8;
  const gap = 4;
  const vw = document.documentElement.clientWidth;
  const vh = window.innerHeight;
  content.style.marginLeft = '';
  content.style.marginRight = '';
  content.style.marginTop = '';
  content.style.marginBottom = '';
  content.style.maxWidth = (vw - 2 * margin) + 'px';
  content.style.maxHeight = '';
  if (wanted && wanted !== 'auto') content.setAttribute('data-side', wanted);

  const t = trigger.getBoundingClientRect();
  const w = content.offsetWidth;
  const h = content.offsetHeight;
  let side = content.getAttribute('data-side') || 'bottom';
  const below = vh - margin - t.bottom - gap;
  const above = t.top - gap - margin;
  if (side === 'bottom' && h > below && (h <= above || above > below)) side = 'top';
  else if (side === 'top' && h > above && (h <= below || below > above)) side = 'bottom';
  else if (side === 'right' && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = 'left';
  else if (side === 'left' && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = 'right';
  content.setAttribute('data-side', side);

  if (side === 'bottom') content.style.maxHeight = Math.max(below, 120) + 'px';
  if (side === 'top') content.style.maxHeight = Math.max(above, 120) + 'px';

  // The box without its open animation's scale, around its centre.
  const r = content.getBoundingClientRect();
  const left = r.left + (r.width - content.offsetWidth) / 2;
  const top = r.top + (r.height - content.offsetHeight) / 2;
  const width = content.offsetWidth;
  const height = content.offsetHeight;
  let dx = 0;
  let dy = 0;
  if (left + width > vw - margin) dx = vw - margin - (left + width);
  if (left + dx < margin) dx = margin - left;
  if (side === 'left' || side === 'right') {
    if (top + height > vh - margin) dy = vh - margin - (top + height);
    if (top + dy < margin) dy = margin - top;
  }
  if (dx) {
    content.style.marginLeft = dx + 'px';
    content.style.marginRight = -dx + 'px';
  }
  if (dy) {
    content.style.marginTop = dy + 'px';
    content.style.marginBottom = -dy + 'px';
  }
  // fit:end
}

/**
 * Undo fit(): the card goes back to its stylesheet position.
 * @param {HTMLElement | null} content
 */
export function unfit(content) {
  if (!content) return;
  for (const p of ['marginLeft', 'marginRight', 'marginTop', 'marginBottom', 'maxWidth', 'maxHeight']) {
    content.style[p] = '';
  }
  content.removeAttribute('data-side');
}
