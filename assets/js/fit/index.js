// Keeps an open card inside the viewport and glued to its trigger. The same code is carried
// inline by the popover and dropdown_menu runtime hooks (they cannot import);
// test/sutra_ui/fit_test.exs keeps the copies equal to the body below, between the
// fit:start and fit:end markers.

/**
 * Place the open card with `position: fixed`, from the trigger's rectangle, so a scrolling or
 * `overflow: hidden` ancestor (a dialog body) cannot clip it. It goes on the wanted side, flips
 * to the side with more room, shifts back in when it would run off a screen edge and caps its
 * height to the room. Call it again on scroll and resize while the card is open. Positions
 * come from the CSSOM, never a style attribute.
 * @param {HTMLElement | null} content the card (a `data-popover` element)
 * @param {HTMLElement | null} trigger the element it hangs from
 * @param {string | undefined} wanted a preferred data-side, or "auto"
 * @returns {boolean} false when the trigger has scrolled out of view (close the card)
 */
export function fit(content, trigger, wanted) {
  // fit:start
  if (!content || !trigger) return false;
  const margin = 8;
  const gap = 4;
  const vw = document.documentElement.clientWidth;
  const vh = document.documentElement.clientHeight;
  const t = trigger.getBoundingClientRect();
  const scrolled = content.scrollTop;

  // The visible part of the trigger: the viewport minus what scrolling ancestors clip.
  let clip = { left: 0, top: 0, right: vw, bottom: vh };
  for (let p = trigger.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
    const cs = getComputedStyle(p);
    if (cs.overflowX === 'visible' && cs.overflowY === 'visible') continue;
    const r = p.getBoundingClientRect();
    clip = { left: Math.max(clip.left, r.left), top: Math.max(clip.top, r.top), right: Math.min(clip.right, r.right), bottom: Math.min(clip.bottom, r.bottom) };
  }
  const visible = t.right > clip.left && t.left < clip.right && t.bottom > clip.top && t.top < clip.bottom;

  content.style.position = 'fixed';
  content.style.margin = '0px';
  content.style.translate = 'none';
  content.style.right = 'auto';
  content.style.bottom = 'auto';
  content.style.left = '0px';
  content.style.top = '0px';
  content.style.transitionProperty = 'opacity, scale, display, visibility';
  content.style.minWidth = t.width + 'px';
  content.style.maxWidth = (vw - 2 * margin) + 'px';
  content.style.maxHeight = '';
  if (wanted && wanted !== 'auto') content.setAttribute('data-side', wanted);

  let w = content.offsetWidth;
  const h = content.offsetHeight;
  const below = vh - margin - t.bottom - gap;
  const above = t.top - gap - margin;
  let side = content.getAttribute('data-side') || 'bottom';
  if (side === 'bottom' && h > below && (h <= above || above > below)) side = 'top';
  else if (side === 'top' && h > above && (h <= below || below > above)) side = 'bottom';
  else if (side === 'right' && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = 'left';
  else if (side === 'left' && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = 'right';
  content.setAttribute('data-side', side);

  const align = content.getAttribute('data-align') || 'start';
  let left;
  let top;
  if (side === 'bottom' || side === 'top') {
    const room = Math.max(side === 'bottom' ? below : above, 120);
    content.style.maxHeight = room + 'px';
    w = content.offsetWidth;
    left = align === 'end' ? t.right - w : align === 'center' ? t.left + (t.width - w) / 2 : t.left;
    top = side === 'bottom' ? t.bottom + gap : t.top - gap - Math.min(h, room);
  } else {
    left = side === 'right' ? t.right + gap : t.left - gap - w;
    top = align === 'end' ? t.bottom - h : align === 'center' ? t.top + (t.height - h) / 2 : t.top;
    top = Math.max(margin, Math.min(top, vh - margin - h));
  }
  left = Math.max(margin, Math.min(left, vw - margin - w));
  content.style.left = left + 'px';
  content.style.top = top + 'px';

  // An ancestor with a transform makes `fixed` relative to itself: measure and correct. The
  // box's own open animation scales it around its centre, which is allowed for.
  const r = content.getBoundingClientRect();
  const dx = r.left - (left + (content.offsetWidth - r.width) / 2);
  const dy = r.top - (top + (content.offsetHeight - r.height) / 2);
  if (Math.abs(dx) > 0.5) content.style.left = (left - dx) + 'px';
  if (Math.abs(dy) > 0.5) content.style.top = (top - dy) + 'px';
  content.scrollTop = scrolled;
  return visible;
  // fit:end
}

/**
 * Undo fit(): the card goes back to its stylesheet position.
 * @param {HTMLElement | null} content
 */
export function unfit(content) {
  if (!content) return;
  for (const p of ['position', 'margin', 'translate', 'left', 'right', 'top', 'bottom', 'minWidth', 'maxWidth', 'maxHeight', 'transitionProperty']) {
    content.style[p] = '';
  }
  content.removeAttribute('data-side');
}
