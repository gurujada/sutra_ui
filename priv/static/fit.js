/* sutra_ui fit source-hash:2674ba079a102983 (built by mix assets.build; do not edit) */

// assets/js/fit/index.js
function fit(content, trigger, wanted) {
  if (!content || !trigger) return false;
  const margin = 8;
  const gap = 4;
  const vw = document.documentElement.clientWidth;
  const vh = document.documentElement.clientHeight;
  const t = trigger.getBoundingClientRect();
  const scrolled = content.scrollTop;
  let clip = { left: 0, top: 0, right: vw, bottom: vh };
  for (let p = trigger.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
    const cs = getComputedStyle(p);
    if (cs.overflowX === "visible" && cs.overflowY === "visible") continue;
    const r2 = p.getBoundingClientRect();
    clip = { left: Math.max(clip.left, r2.left), top: Math.max(clip.top, r2.top), right: Math.min(clip.right, r2.right), bottom: Math.min(clip.bottom, r2.bottom) };
  }
  const visible = t.right > clip.left && t.left < clip.right && t.bottom > clip.top && t.top < clip.bottom;
  content.style.position = "fixed";
  content.style.margin = "0px";
  content.style.translate = "none";
  content.style.right = "auto";
  content.style.bottom = "auto";
  content.style.left = "0px";
  content.style.top = "0px";
  content.style.transitionProperty = "opacity, scale, display, visibility";
  content.style.minWidth = t.width + "px";
  content.style.maxWidth = vw - 2 * margin + "px";
  content.style.maxHeight = "";
  if (wanted && wanted !== "auto") content.setAttribute("data-side", wanted);
  let w = content.offsetWidth;
  const h = content.offsetHeight;
  const below = vh - margin - t.bottom - gap;
  const above = t.top - gap - margin;
  let side = content.getAttribute("data-side") || "bottom";
  if (side === "bottom" && h > below && (h <= above || above > below)) side = "top";
  else if (side === "top" && h > above && (h <= below || below > above)) side = "bottom";
  else if (side === "right" && t.right + gap + w > vw - margin && t.left - gap - w >= margin) side = "left";
  else if (side === "left" && t.left - gap - w < margin && t.right + gap + w <= vw - margin) side = "right";
  content.setAttribute("data-side", side);
  const align = content.getAttribute("data-align") || "start";
  let left;
  let top;
  if (side === "bottom" || side === "top") {
    const room = Math.max(side === "bottom" ? below : above, 120);
    content.style.maxHeight = room + "px";
    w = content.offsetWidth;
    left = align === "end" ? t.right - w : align === "center" ? t.left + (t.width - w) / 2 : t.left;
    top = side === "bottom" ? t.bottom + gap : t.top - gap - Math.min(h, room);
  } else {
    left = side === "right" ? t.right + gap : t.left - gap - w;
    top = align === "end" ? t.bottom - h : align === "center" ? t.top + (t.height - h) / 2 : t.top;
    top = Math.max(margin, Math.min(top, vh - margin - h));
  }
  left = Math.max(margin, Math.min(left, vw - margin - w));
  content.style.left = left + "px";
  content.style.top = top + "px";
  const r = content.getBoundingClientRect();
  const dx = r.left - (left + (content.offsetWidth - r.width) / 2);
  const dy = r.top - (top + (content.offsetHeight - r.height) / 2);
  if (Math.abs(dx) > 0.5) content.style.left = left - dx + "px";
  if (Math.abs(dy) > 0.5) content.style.top = top - dy + "px";
  content.scrollTop = scrolled;
  return visible;
}
function unfit(content) {
  if (!content) return;
  for (const p of ["position", "margin", "translate", "left", "right", "top", "bottom", "minWidth", "maxWidth", "maxHeight", "transitionProperty"]) {
    content.style[p] = "";
  }
  content.removeAttribute("data-side");
}
export {
  fit,
  unfit
};
