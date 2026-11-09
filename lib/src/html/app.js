// The page's own script: the map, the tree, the list and the table, drawn
// from the sheet (`#sheet`), the drawings (`#maps`) and the words
// (`#strings`) index.html holds; the route asked of the search compiled from
// Dart (`#route-js`). Inlined into index.html by tool/gen_html.dart.
const S = JSON.parse(document.getElementById('sheet').textContent);
const W = JSON.parse(document.getElementById('strings').textContent);
// The export's own words, with {name} filled in.
const T = (key, args = {}) => (W[key] ?? key).replace(/\{(\w+)\}/g, (_, k) => args[k] ?? '');
for (const el of document.querySelectorAll('[data-t]')) el.textContent = T(el.dataset.t);
for (const el of document.querySelectorAll('[data-title]')) el.title = T(el.dataset.title);
for (const el of document.querySelectorAll('[data-ph]')) el.placeholder = T(el.dataset.ph);
const $ = (s) => document.querySelector(s);
const esc = (t) => String(t ?? '').replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pageById = Object.fromEntries(S.pages.map((p) => [p.id, p]));
const label = (id) => pageById[id].label;
const edges = S.edges;
const entries = S.entries;
// The edges, an item from every page (`from: '*'`) once.
const once = edges.filter((e, i) => !e.anywhere || edges.findIndex((x) => x.anywhere && x.item === e.item) === i);
// The tab bars whose tabs keep their histories: a tab by its first page,
// with its bar; the bar a page is shown in.
const tabItem = {}, barOfPage = {};
for (const bar of S.tabs ?? []) for (const t of bar.pages) tabItem[t.page] = { ...t, bar };
for (const p of S.pages) {
  const bar = (S.tabs ?? []).find((b) => b.pages.some((t) => t.page === p.id || p.tab.includes(t.page)));
  if (bar) barOfPage[p.id] = bar;
}
// A tab's name, in the screen's words: what its trigger says, or, where
// only the code names it (a key, a widget class), its first page's.
const tabText = (t) => {
  const how = t.trigger.split(':', 1)[0];
  return how === 'key' || how === 'type' ? label(t.page) : t.trigger.slice(how.length + 1);
};
// Which tab a page is, or is shown in.
const tabMeta = (p) => tabItem[p.id]
  ? `<div class="meta">${esc(T('tabOf', { tab: tabText(tabItem[p.id]) }))}</div>`
  : p.tab.length ? `<div class="meta">${esc(T('inTabs', { tabs: p.tab.map(label).join(T('stateSeparator')) }))}</div>` : '';
// What switches to a tab, in the screen's words.
const tapWords = (t) => t.trigger.startsWith('other:') ? tabText(t) : T('tap', { text: tabText(t) });
// What a search looks for in a page: its names, memo, states and tags, and
// what is done on it (a button's words find the page it is on); with [dev],
// what developers read too (its id and path, a key or a widget class
// tapped), as only they are shown it.
const said = (e, dev) => {
  if (!e.trigger || e.trigger === 'back') return '';
  const how = e.trigger.split(':', 1)[0];
  return !dev && (how === 'key' || how === 'type') ? '' : e.trigger.slice(how.length + 1);
};
const findText = (p, dev) => [
  p.label, p.section, p.memo,
  ...(dev ? [p.path, p.id] : []),
  ...p.states.map((s) => s.name),
  ...[p, ...p.states].flatMap((x) => x.tags.flatMap((t) => [t.tag, t.label])),
  ...edges.filter((e) => e.from === p.id).map((e) => said(e, dev)),
].filter(Boolean).join(' ').toLowerCase();
// What it looks for in a transition: its pages, states, and what is done.
const findEdge = (e, dev) => [label(e.from), label(e.to), said(e, dev), ...e.when, ...Object.values(e.if).flat(), ...thenNames(e)].filter(Boolean).join(' ').toLowerCase();
// What is searched in, as the developers' information is shown or not.
const forDev = () => !document.body.classList.contains('plain');
const findIn = (el) => forDev() ? el.dataset.findDev : el.dataset.find;
// What the viewer chooses is in the address, and only there: the address is
// what is shown, to pass around as it is. The address's query, and [name]
// set to [value] in it (null: taken out).
const query = () => new URLSearchParams(location.search);
function setQuery(name, value) {
  const url = new URL(location.href);
  if (value == null) url.searchParams.delete(name); else url.searchParams.set(name, value);
  history.replaceState(null, '', url);
}
// An arrow's words: what only the code names, for developers; what anyone
// reads; how the code keeps its pages, for developers.
const edgeWords = (e) => [
  e.labelCode ? `<span class="dev">${esc(e.labelCode)}${e.labelPlain ? ' / ' : ''}</span>` : '',
  esc(e.labelPlain ?? ''),
  e.labelKind ? `<span class="dev">${e.labelCode || e.labelPlain ? ' / ' : ''}${esc(e.labelKind)}</span>` : '',
].join('');
// What a transition is, as a sentence anyone reads: in which state, doing
// what, it leads where, arriving in which state. Shown beside a page tapped
// on the map, and along a route; the map's labels stay short.
const states = (list) => list.join(T('stateSeparator'));
function doing(e) {
  if (!e.trigger) return esc(T('onItsOwn'));
  const how = e.trigger.split(':', 1)[0];
  const what = e.trigger.slice(how.length + 1);
  if (how === 'back') return esc(T('goBack'));
  if (how === 'text' || how === 'label') return esc(T('tap', { text: what }));
  if (how === 'other') return esc(what);
  // A key or a widget class: named only in the code.
  return `<span class="plain-only">${esc(T('unnamed'))}</span><code class="dev">${esc(e.trigger)}</code>`;
}
// The states of its `to` [e] can arrive in from the state [state] of its
// page, as sheet.json resolves them under any values of the conditions:
// one, where said or kept by its name; else the page's first, those its
// data decides and those of the conditions.
const arrival = (e, state) => e.arrive[state] ?? [];
// The states the sheet writes a transition or a deep link arrives in.
const thenNames = (e) => typeof e.then === 'string' ? [e.then] : Object.values(e.then ?? {});
// What the sheet writes it arrives in, from [state] (null: not known, each
// of a `then` by state told). A state kept by its name goes unsaid: nothing
// changes.
function arriving(e, state) {
  if (typeof e.then === 'string') return esc(T('arriving', { state: e.then }));
  if (!e.then) return '';
  if (state != null) return e.then[state] ? esc(T('arriving', { state: e.then[state] })) : '';
  return esc(T('arriving', { state: Object.entries(e.then)
    .map(([from, to]) => T('arrivingFrom', { from, state: to })).join(T('arrivingSeparator')) }));
}
// In which states and while which values of the conditions [e] happens:
// each a part, the parts all needed; empty for any.
const needs = (e) => [...(e.when.length ? [states(e.when)] : []), ...Object.values(e.if).map(states)];
// The values [sets] gives the conditions.
const setting = (sets) => Object.keys(sets ?? {}).length ? esc(T('setting', { values: Object.values(sets).join(T('conditionAnd')) })) : '';
function sentence(e, { from = false, state = null, sets = e.set } = {}) {
  // Their spacing is the words': a comma and a space, or 「、」.
  const when = needs(e).length ? esc(T('inState', { state: needs(e).join(T('conditionAnd')) })) : '';
  // Going back by the back: "back to" says it once.
  const what = e.kind === 'pop' && e.trigger === 'back' ? '' : doing(e) + ' → ';
  const to = e.kind === 'pop' ? esc(T('backTo', { page: label(e.to) })) : `<b>${esc(label(e.to))}</b>`;
  const then = arriving(e, state);
  const redirected = e.kind === 'redirect' ? esc(T('redirected')) : '';
  // [from]: its page's name said first, or what to say instead.
  return `${from ? `<b>${esc(typeof from === 'string' ? from : label(e.from))}</b>: ` : ''}${when}${what}${to}${then}${redirected}${setting(sets)}`;
}
// What the sheet says of a page: its memo, and the values of its tags (a
// page's, or a state's), those of the tags [shown] (by name), each its tag's
// name before it. Only web and mail links are followed: a `javascript:` one
// would run here.
const memoHtml = (p) => p.memo ? `<p class="memo">${esc(p.memo)}</p>` : '';
const followed = (url) => /^(https?:|mailto:)/i.test(url ?? '');
const tagsHtml = (tags, shown = () => true) => {
  const values = tags.filter((t) => shown(t.tag));
  return values.length ? `<p class="tags">${values.map((t) => followed(t.url)
    ? `<a href="${esc(t.url)}" target="_blank" rel="noopener noreferrer" title="${esc(t.url)}"><small>${esc(t.tag)}</small>${esc(t.label)}</a>`
    : `<span${t.url ? ` title="${esc(t.url)}"` : ''}><small>${esc(t.tag)}</small>${esc(t.label)}</span>`).join('')}</p>` : '';
};
// A state's values of the tags it has its own of, other than its page's.
const tagValues = (tags, name) => JSON.stringify(tags.filter((t) => t.tag === name));
const ownTags = (p, s) => s.tags.filter((t) => tagValues(s.tags, t.tag) !== tagValues(p.tags, t.tag));
// The state each page shows on the map, by its place among the page's
// states (see showState); the tags of the one [p] is shown in.
const shownState = {};
const shownTags = (p) => p.states[shownState[p.id] ?? 0].tags;
const codeMeta = (p) => [p.path, p.widget, p.route, p.source].filter(Boolean).map((c) => `<code>${esc(c)}</code>`).join(' · ');
// The ways every state is shot (a platform, a size), the first the map's:
// the one shown, chosen in the header: the one the address names
// (?variant=), else the first.
const variants = S.variants;
let variant = Math.max(0, variants.findIndex((v) => v.name === query().get('variant')));
// [s] as the variant shown draws it: its image, size and error.
const drawn = (s) => s.variants?.[variant] ?? s;
const variantName = () => variants[variant]?.name ?? '';
// A state shutter could not draw says why; one the variant has none of
// says so. As wide as its screen is to the first variant's: a larger screen
// drawn larger, not smaller.
const stateHtml = (s, p) => {
  const d = drawn(s);
  const own = p ? tagsHtml(ownTags(p, s)) : '';
  return `<div class="state" style="--k:${d.width / s.width}">${d.image
    ? `<img src="${esc(d.image)}" alt="${esc(s.name)}" loading="lazy" style="aspect-ratio:${d.width}/${d.height}" data-zoom="${esc(s.name)}">`
    : `<div class="none${d.error ? ' error' : ''}" style="aspect-ratio:${d.width}/${d.height}" title="${esc(d.error ?? '')}">${esc(d.error ?? (s.preview == null ? T('noPreview') : d.shot == null && variant ? T('notInVariant', { variant: variantName() }) : T('noImage')))}</div>`}
  <div class="name">${esc(s.name)}</div>${own}</div>`;
};

$('#app').textContent = S.app;
// When the map was exported, for anyone to tell how old it is; what the
// sheet was written against, when `sheet basis` recorded it, for
// developers.
const exported = (() => {
  try { return new Date(S.generatedAt).toLocaleString(S.locale, { dateStyle: 'medium', timeStyle: 'short' }); } catch { return S.generatedAt; }
})();
// Which app: its version and branch, for anyone; its commit, for
// developers. How current: when it was exported.
const release = S.release ?? {};
$('#meta').innerHTML = [
  release.version ? `<span>${esc(T('version', { version: release.version }))}</span>` : '',
  release.branch ? `<span>${esc(release.branch)}</span>` : '',
  release.commit ? `<code class="dev">${esc(release.commit.slice(0, 10))}</code>` : '',
  `<span>${esc(T('generated', { date: exported }))}</span>`,
  S.basis ? `<span class="dev">${esc(T(S.basis.found ? 'basis' : 'basisUnknown', { commit: S.basis.commit.slice(0, 10) }))}</span>` : '',
].join('');
// The app's code changed since the basis that the sheet names for no page:
// what it says to anyone, and the files, for developers.
const unmapped = S.basis?.unmapped ?? [];
if (unmapped.length) {
  const button = $('#unmapped');
  button.hidden = false;
  button.textContent = T('unmapped', { count: unmapped.length });
  button.onclick = () => openPanel(`<h2 style="margin-top:0;color:var(--text)">${esc(T('unmapped', { count: unmapped.length }))}</h2>
    <p>${esc(T('unmappedAbout'))}</p><p class="dev">${unmapped.map((f) => `<code>${esc(f)}</code>`).join('<br>')}</p>`);
}
// The map fills what the header leaves, however many lines it wraps to.
const fitHeader = () => document.documentElement.style.setProperty('--header-h', $('body > header').offsetHeight + 'px');
fitHeader();
// On a phone, the app's version and date behind its name, tapped.
$('#app').addEventListener('click', () => {
  if (wide()) return;
  document.body.classList.toggle('meta-open');
  fitHeader();
});
$('#pages').innerHTML = S.pages.map((p) => `<option value="${esc(p.label)}">${esc(p.section)}</option>`).join('');
document.documentElement.style.setProperty('--label-height', S.canvas.labelHeight + 'px');

// --- map: the drawing is the export's, as map.svg draws it ---
const map = $('#map-view');
const canvas = $('#canvas');
// The map and the tree as the variant shown lays them out, each page's box
// its screen at the scale the first variant's is drawn at: the first
// variant's is sheet.json's, drawn below; another's, from its own block,
// those laid out alike once.
const M = JSON.parse(document.getElementById('maps').textContent);
const firstLaid = { canvas: S.canvas, sections: S.sections, pages: pageById, tree: S.tree, under: $('#under').innerHTML, over: $('#over').innerHTML };
const laidOut = () => M.drawings[M.variants[variant] ?? 0] ?? firstLaid;
let laid = laidOut();
const boxOf = (id) => laid.pages[id];
const byIndex = (selector) => { const all = []; for (const el of canvas.querySelectorAll(selector)) all[el.dataset.i] = el; return all; };
const bundles = S.bundles;
let edgePaths, edgeLabels, entryLines, entryLabels, bundleLines, bundleLabels, edgeHits;
// Each arrow, and each bundle's line, has a wide line over it to tap,
// unseen, shown or hidden as its own is.
const hitOf = (path) => {
  const hit = path.cloneNode(false);
  hit.classList.add('hit');
  hit.removeAttribute('marker-end');
  hit.removeAttribute('data-ends');
  path.after(hit);
  return hit;
};
const nodes = {};
let islandChips = [];
// A page's image on the map, loaded when the browser sees the map show it
// (lazily: the transform the map is moved by is in what it sees); its name
// is under it.
// A page on the map or the tree, chosen from the keyboard too: Tab to it,
// Enter or Space as a click.
const pressable = (n, label) => {
  n.tabIndex = 0;
  n.setAttribute('role', 'button');
  n.setAttribute('aria-label', label);
  n.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    e.preventDefault();
    n.click();
  });
};
// Without one, it says why, as the list does: no preview yet, not in the
// variant shown, or no image (shutter's error, where it had one, on hover).
const noImage = (s) => {
  const d = drawn(s);
  return `<span class="no-preview" title="${esc(d.error ?? '')}">${esc(s.preview == null ? T('noPreview')
    : d.shot == null && variant ? T('notInVariant', { variant: variantName() }) : T('noImage'))}</span>`;
};
const nodeImage = (s) => {
  const d = drawn(s);
  return d.image ? `<img src="${esc(d.image)}" alt="" loading="lazy" decoding="async">` : noImage(s);
};
// An image that cannot be loaded (index.html passed around without its
// images): said so where it would be, not a broken image.
document.addEventListener('error', (e) => {
  const img = e.target;
  if (!(img instanceof HTMLImageElement) || !img.closest('.node, .state, .card-states, .chip')) return;
  const none = document.createElement(img.closest('.node') ? 'span' : 'div');
  none.className = img.closest('.node') ? 'no-preview' : 'none';
  if (img.closest('.state')) none.style.aspectRatio = img.style.aspectRatio;
  none.textContent = T('noImage');
  img.replaceWith(none);
}, true);
// The map drawn as [laid] lays it out: its arrows, its pages' boxes and its
// sections' names.
function layMap() {
  canvas.style.width = laid.canvas.width + 'px';
  canvas.style.height = laid.canvas.height + 'px';
  for (const svg of canvas.querySelectorAll('svg')) { svg.setAttribute('width', laid.canvas.width); svg.setAttribute('height', laid.canvas.height); }
  $('#under').innerHTML = laid.under;
  $('#over').innerHTML = laid.over;
  edgePaths = byIndex('#under path.edge');
  edgeLabels = byIndex('#over g.lbl');
  entryLines = byIndex('#under g.entry');
  entryLabels = byIndex('#over g.entry');
  bundleLines = byIndex('#under g.bundle');
  bundleLabels = byIndex('#over g.blbl');
  edgeHits = edgePaths.map((p) => p && hitOf(p));
  for (const g of bundleLines) if (g) hitOf(g.querySelector('path'));
  for (const [id, n] of Object.entries(nodes)) {
    const b = boxOf(id);
    n.style.left = b.x + 'px'; n.style.top = b.y + 'px'; n.style.width = b.width + 'px';
    n.querySelector('.img').style.height = b.height + 'px';
  }
  for (const chip of islandChips) chip.remove();
  islandChips = laid.sections.filter((s) => s.name).map(islandChip);
  topSpans = spansAtTops();
}
// Where the arrows and deep links meeting each page's top run through the
// room of its marks (marksHeight above it, as the layout keeps it), and
// where the labels over the map lie in it: [left, right] from the page's
// left, an arrowhead's width either side of a line. An end with the point
// its line leaves towards (each line's data-ends): an arrow's control point,
// a short line's other end.
const marksHeight = S.canvas.marksHeight;
let topSpans = {};
function spansAtTops() {
  const labels = [...$('#over').querySelectorAll('g > rect')].map((r) =>
    ['x', 'y', 'width', 'height'].map((a) => +r.getAttribute(a)));
  const ends = [];
  for (const line of $('#under').querySelectorAll('[data-ends]')) {
    for (const end of line.dataset.ends.split(';')) ends.push(end.split(',').map(Number));
  }
  const spans = {};
  for (const id of Object.keys(nodes)) {
    const b = boxOf(id);
    for (const [x, y, tx, ty] of ends) {
      if (Math.abs(y - b.y) > 1 || x < b.x - 6 || x > b.x + b.width + 6) continue;
      // Where its line is at the top of the marks' room.
      const up = y - ty;
      const far = up <= 0 ? x : up < marksHeight ? tx : x + (tx - x) * marksHeight / up;
      (spans[id] ??= []).push([Math.min(x, far) - 5 - b.x, Math.max(x, far) + 5 - b.x]);
    }
    for (const [x, y, w, h] of labels) {
      if (y >= b.y || y + h <= b.y - marksHeight || x >= b.x + b.width || x + w <= b.x) continue;
      (spans[id] ??= []).push([x - b.x, x + w - b.x]);
    }
  }
  return spans;
}
for (const p of S.pages) {
  const n = document.createElement('div');
  n.className = tabItem[p.id] ? 'node tabbed' : 'node';
  n.dataset.id = p.id;
  const s = drawn(p.states[0]);
  n.innerHTML = `<div class="img">${nodeImage(s)}</div><div class="label"><span>${esc(p.label)}</span><small></small></div><div class="marks"></div>`;
  n.title = T(p.states.length === 1 ? 'statesOfOne' : 'statesOf', { page: p.label, count: p.states.length });
  // In the state it shows (where an arrow arrived): what is looked at stays.
  // A mark that links goes there instead.
  n.addEventListener('click', (e) => {
    if (moved || e.target.closest('a.mark')) return;
    const i = shownState[p.id] ?? 0;
    const hash = `#map/${encodeURIComponent(p.id)}${i ? '/' + encodeURIComponent(p.states[i].name) : ''}`;
    if (location.hash === hash) route(); else location.hash = hash;
  });
  // Twice: the state it shows, large.
  n.addEventListener('dblclick', () => enlarge(p.id));
  pressable(n, p.label);
  canvas.insertBefore(n, $('#over'));
  nodes[p.id] = n;
}
// A section, to go into from the whole map, where its name is too small to
// read: a name of a size to read, whatever the map's.
function islandChip(s) {
  const chip = document.createElement('button');
  chip.className = 'island-chip';
  chip.textContent = s.name;
  chip.title = T('section');
  chip.style.left = s.x + 'px'; chip.style.top = s.y + 'px';
  chip.section = s;
  chip.addEventListener('click', (e) => { e.stopPropagation(); if (!moved) show({ x: s.x - 24, y: s.y - 24, width: s.width + 48, height: s.height + 48 }, true); });
  canvas.appendChild(chip);
  return chip;
}
layMap();
// Each label's background, at the size the browser draws its text: all
// measured first, then all set. Only while the map is shown; again when
// what a label shows changes.
let measured = false;
function backgrounds() {
  if (current !== 'map') { measured = false; return; }
  const groups = [...$('#over').querySelectorAll('g')];
  const boxes = groups.map((g) => g.querySelector('text').getBBox());
  groups.forEach((g, i) => {
    const b = boxes[i];
    const r = g.querySelector('rect');
    const empty = b.width === 0;
    r.setAttribute('x', b.x - 4); r.setAttribute('y', b.y - 2);
    r.setAttribute('width', empty ? 0 : b.width + 8); r.setAttribute('height', empty ? 0 : b.height + 4);
  });
  measured = true;
}
// What a group under the map is for, said on hover and to a screen reader:
// [text] after what [box] holds.
const describe = (box, text) => {
  box.title = text;
  box.insertAdjacentHTML('beforeend', `<span id="${box.id}-about" hidden>${esc(text)}</span>`);
  box.setAttribute('aria-describedby', `${box.id}-about`);
};
// How much the map shows, and what its lines are.
const levels = ['pages', 'flow', 'actions'];
$('#levels').setAttribute('role', 'group');
$('#levels').setAttribute('aria-label', T('show'));
$('#levels').innerHTML = `<span>${esc(T('show'))}</span>${levels.map((l) =>
  `<button data-level="${l}" aria-pressed="false">${esc(T('level_' + l))}</button>`).join('')}`;
describe($('#levels'), T('levelsAbout'));
// The arrows back can be hidden: on a large app they are many, and their
// dashed line says what they do.
$('#legend').innerHTML = [
  edges.some((e) => e.kind !== 'pop') ? `<span class="key e-sheet"><i></i>${esc(T('legendSheet'))}</span>` : '',
  edges.some((e) => e.kind === 'pop') ? `<button class="key e-sheet" id="backToggle" aria-pressed="true" title="${esc(T('backToggle'))}"><i class="dash"></i>${esc(T('legendBack'))}</button>` : '',
  entries.length ? `<span class="key e-entry"><i class="dot"></i>${esc(T('legendEntries'))}</span>` : '',
].join('');
describe($('#legend'), T('legendAbout'));
// What can be shown on the pages, a mark above each that has it and beside
// a page chosen: its memo, each tag; their keys `memo`, `tag:<name>`. Each
// with how many pages have it, for whoever chooses to know where to look.
const notes = [
  ...(S.pages.some((p) => p.memo) ? [{ key: 'memo', name: T('noteMemo'), count: S.pages.filter((p) => p.memo).length }] : []),
  ...(S.tags ?? []).map((t) => ({ key: 'tag:' + t.name, name: t.name,
    count: S.pages.filter((p) => p.states.some((s) => s.tags.some((v) => v.tag === t.name))).length })),
];
if (!edges.length && !entries.length && !notes.length && !(S.conditions ?? []).length) $('#bar').style.display = 'none';
// How tall what is under the map is, for the card on a phone to sit above it.
const fitBar = () => map.style.setProperty('--bar-h', $('#bar').offsetHeight + 'px');
// On a phone, what is under the map opened from its one button.
$('#bar-open').addEventListener('click', () => {
  const open = $('#bar').classList.toggle('open');
  $('#bar-open').setAttribute('aria-expanded', open);
  fitBar();
});
// The pages alone (to look at the screens), with the arrows (to see how they
// lead to each other), or with what each arrow says: as the address says
// (?show=pages, ?show=actions), else with the arrows, for whoever opens the
// map to see how the pages lead to each other.
let level = levels.includes(query().get('show')) ? query().get('show') : 'flow';
function setLevel(l, { remember = true } = {}) {
  level = l;
  map.dataset.level = l;
  for (const b of $('#levels').querySelectorAll('[data-level]')) b.setAttribute('aria-pressed', b.dataset.level === l);
  requestAnimationFrame(fitBar);
  if (remember) setQuery('show', l === 'flow' ? null : l);
}
$('#levels').addEventListener('click', (e) => {
  const b = e.target.closest('[data-level]');
  if (b) setLevel(b.dataset.level);
});
setLevel(level, { remember: false });
// What the map shows that can be hidden, by key: the arrows back (`back`),
// and on the pages, the memo (`memo`) and each tag (`tag:<name>`). Shown
// when the address names it
// (?with=<key>, once for each), and only then: what the buttons show is
// what the address says.
const withNotes = new Set(query().getAll('with').filter(Boolean));
const noteOn = (key) => withNotes.has(key);
// [key] shown or not, in the address.
function keepWith(key, on) {
  if (on) withNotes.add(key); else withNotes.delete(key);
  const url = new URL(location.href);
  url.searchParams.delete('with');
  for (const k of withNotes) url.searchParams.append('with', k);
  history.replaceState(null, '', url);
}
// The arrows back, shown or hidden.
function setBack(on, { remember = true } = {}) {
  map.classList.toggle('no-back', !on);
  $('#backToggle')?.setAttribute('aria-pressed', on);
  if (remember) keepWith('back', on);
}
setBack(noteOn('back'), { remember: false });
$('#backToggle')?.addEventListener('click', () => setBack(map.classList.contains('no-back')));
// How wide a mark is drawn: its words at 11px (`.mark`), and its padding.
const measure = document.createElement('canvas').getContext('2d');
const markWidth = (text) => {
  measure.font = '11px system-ui, sans-serif';
  return Math.ceil(measure.measureText(text).width) + 13;
};
// A page's marks above it: its memo, and each tag the state shown has, a
// link where it is one value that is. In one row no wider than the page,
// those past it in one +N (the card says them all); above the page where
// it covers no arrow meeting it nor label ([topSpans]), at its right where
// it can; where nothing is clear, on the image's top edge (the status
// bar's), at its right: never under an arrow or a label.
function renderMark(p) {
  const marks = [];
  if (p.memo && noteOn('memo')) marks.push({ text: 'ⓘ', title: p.memo, html: `<span class="mark" title="${esc(p.memo)}">ⓘ</span>` });
  for (const t of S.tags ?? []) {
    const values = shownTags(p).filter((v) => v.tag === t.name);
    if (!values.length || !noteOn('tag:' + t.name)) continue;
    const title = values.map((v) => v.label).join('\n');
    const link = values.length === 1 && followed(values[0].url);
    const text = t.name + (link ? ' ↗' : values.length > 1 ? ' ×' + values.length : '');
    marks.push({ text, title: `${t.name}: ${title}`, html: link
      ? `<a class="mark" href="${esc(values[0].url)}" target="_blank" rel="noopener noreferrer" title="${esc(title)}">${esc(t.name)}</a>`
      : `<span class="mark" title="${esc(title)}">${esc(text)}</span>` });
  }
  const width = boxOf(p.id).width;
  const widths = marks.map((m) => markWidth(m.text));
  const across = (k) => widths.slice(0, k).reduce((sum, w) => sum + w + 4, 0);
  let shown = marks.length;
  if (across(shown) - 4 > width) {
    shown--;
    while (shown > 0 && across(shown) + markWidth('+' + (marks.length - shown)) > width) shown--;
  }
  const rest = marks.slice(shown);
  const row = across(shown) + (rest.length ? markWidth('+' + rest.length) : -4);
  const box = nodes[p.id].querySelector('.marks');
  box.innerHTML = marks.slice(0, shown).map((m) => m.html).join('')
    + (rest.length ? `<span class="mark" title="${esc(rest.map((m) => m.title).join('\n'))}">+${rest.length}</span>` : '');
  const spans = topSpans[p.id] ?? [];
  const covers = (l) => spans.reduce((sum, [a, b]) => sum + Math.max(0, Math.min(b, l + row) - Math.max(a, l)), 0);
  const room = width - row;
  let left = room;
  for (const l of spans.flatMap(([a, b]) => [b, a - row, 0])) {
    if (l < 0 || l > room) continue;
    const c = covers(l), best = covers(left);
    if (c < best || (c === best && l > left)) left = l;
  }
  const onImage = covers(left) > 0;
  box.classList.toggle('on-image', onImage);
  box.style.left = (onImage ? Math.max(0, room - 4) : left) + 'px';
}
function renderMarks() {
  for (const p of S.pages) renderMark(p);
}
// What the card says of [p], of what is shown on the pages: its memo, the
// tags of the state shown.
const cardNotes = (p) => (noteOn('memo') ? memoHtml(p) : '')
  + tagsHtml(shownTags(p), (tag) => noteOn('tag:' + tag));
function setNote(key, on) {
  keepWith(key, on);
  for (const b of $('#notes').querySelectorAll('[data-note]')) b.setAttribute('aria-pressed', noteOn(b.dataset.note));
  renderMarks();
  if (focused && $('#card-notes')) $('#card-notes').innerHTML = cardNotes(pageById[focused]);
  requestAnimationFrame(fitBar);
}
if (notes.length) {
  const box = $('#notes');
  box.hidden = false;
  box.setAttribute('role', 'group');
  box.setAttribute('aria-label', T('notes'));
  box.innerHTML = `<span>${esc(T('notes'))}</span>${notes.map((n) =>
    `<button data-note="${esc(n.key)}" aria-pressed="${noteOn(n.key)}" title="${esc(T('noteToggle'))}">${esc(n.name)} <small>${n.count}</small></button>`).join('')}`;
  describe(box, T('notesAbout'));
  box.addEventListener('click', (e) => {
    const b = e.target.closest('[data-note]');
    if (b) setNote(b.dataset.note, !noteOn(b.dataset.note));
  });
}
renderMarks();

let view = { x: 0, y: 0, k: 1 };
// The scales the map reads at: from [readable] up, the arrows' words (12px)
// are 9px or more; under [far], a page is too small to make out, and the
// sections' names stand out to go into.
const readable = 0.75, far = 0.45;
const apply = () => {
  canvas.style.transform = `translate(${view.x}px, ${view.y}px) scale(${view.k})`;
  canvas.style.setProperty('--inv', 1 / view.k);
  const isFar = islandChips.length >= 4 && view.k < far;
  canvas.classList.toggle('far', isFar);
  if (isFar) keepChips();
};
// The sections' names, far out, each at its island's top left; of an
// island the map shows, kept inside the map's sides (a name is wider than a
// small island) and clear of its tools.
function keepChips() {
  const m = map.getBoundingClientRect();
  const t = $('.tools').getBoundingClientRect();
  const tools = { left: t.left - m.left - 8, bottom: t.bottom - m.top + 8 };
  for (const chip of islandChips) {
    const s = chip.section;
    const left = view.x + s.x * view.k, right = left + s.width * view.k;
    const top = view.y + s.y * view.k, bottom = top + s.height * view.k;
    let x = left, y = top;
    if (right > 0 && left < m.width && bottom > 0 && top < m.height) {
      const w = chip.offsetWidth;
      x = Math.max(8, Math.min(x, m.width - 8 - w));
      y = Math.max(8, y);
      if (x + w > tools.left && y < tools.bottom) y = tools.bottom;
    }
    chip.style.left = (x - view.x) / view.k + 'px';
    chip.style.top = (y - view.y) / view.k + 'px';
  }
}
// Whether the map has been moved to show something yet: until then, it
// opens where the app starts ([showStart]).
let placed = false;
// Moves the map to show [box] (in map pixels) whole, gliding there; clear
// of the [left], [right], [top] and [bottom] pixels a panel takes, and of
// the tools at the top. No larger than [max]; with [start], from the top
// left of what it leaves, not in its middle. No smaller than [min]: then
// from its top left, [keep] (a box) in the view.
function show(box, glide, { left = 0, right = 0, top = 0, bottom = 0, min = 0, max = 1.6, start = false, keep = null } = {}) {
  const m = map.getBoundingClientRect();
  if (!m.width) return;
  const tools = $('.tools');
  top = Math.min(Math.max(top, tools.offsetTop + tools.offsetHeight + 8), m.height * 2 / 3);
  right = Math.min(right, m.width / 2);
  const w = m.width - left - right, h = Math.max(m.height - top - bottom, m.height / 3);
  const k = Math.min(w / box.width, h / box.height, max);
  if (k >= min) {
    const dx = start ? 0 : (w - box.width * k) / 2, dy = start ? 0 : (h - box.height * k) / 2;
    view = { k, x: left + dx - box.x * k, y: top + dy - box.y * k };
  } else {
    const pad = 24 / min;
    const at = keep ?? box;
    const x = Math.max(box.x, at.x + at.width + pad - w / min);
    const y = Math.max(box.y, at.y + at.height + S.canvas.labelHeight + pad - h / min);
    view = { k: min, x: left - x * min, y: top - y * min };
  }
  placed = true;
  canvas.classList.toggle('moving', glide);
  apply();
  if (glide) setTimeout(() => canvas.classList.remove('moving'), 460);
}
const whole = () => ({ x: 0, y: 0, width: laid.canvas.width, height: laid.canvas.height });
// The page nearest the middle of the view; and the view moved, at its
// scale, to have it there again (the map laid out anew).
function middlePage() {
  const m = map.getBoundingClientRect();
  const cx = (m.width / 2 - view.x) / view.k, cy = (m.height / 2 - view.y) / view.k;
  let best = null, nearest = Infinity;
  for (const id of Object.keys(nodes)) {
    const b = boxOf(id);
    const d = Math.hypot(b.x + b.width / 2 - cx, b.y + b.height / 2 - cy);
    if (d < nearest) { nearest = d; best = id; }
  }
  return best;
}
function toMiddle(id) {
  const m = map.getBoundingClientRect();
  const b = boxOf(id);
  view.x = m.width / 2 - (b.x + b.width / 2) * view.k;
  view.y = m.height / 2 - (b.y + b.height / 2) * view.k;
  apply();
}
// Where the map opens: whole, where it reads so; else where the app starts,
// its first page with its section, as large as reads, at the map's top left
// with what follows it beside. No larger than drawn: a small section is not
// blown up. Nothing else shows it whole but its button: whole, a large
// app's pages are too small to make out.
function showStart(glide) {
  const m = map.getBoundingClientRect();
  const all = whole();
  if (Math.min(m.width / all.width, m.height / all.height) >= readable) { show(all, glide, { max: 1 }); return; }
  const b = boxOf(S.pages[0].id);
  const island = laid.sections.find((s) => b.x >= s.x && b.y >= s.y && b.x + b.width <= s.x + s.width && b.y + b.height <= s.y + s.height);
  const pad = 24;
  const at = island ? { x: island.x - pad, y: island.y - pad, width: island.width + pad * 2, height: island.height + pad * 2 } : around([S.pages[0].id]);
  show(at, glide, { min: readable, max: 1, start: true, keep: b });
}
// Whether the panels sit beside what the map shows, or across it (a phone):
// as the CSS lays them out.
const wide = () => !matchMedia('(max-width: 640px)').matches;
// Where the map moves what it shows to, clear of the card.
const clearOfCard = (card) => wide() ? { right: card.offsetWidth + 24 } : { bottom: card.offsetHeight + $('#bar').offsetHeight + 32 };
function zoom(f, cx, cy) {
  const m = map.getBoundingClientRect();
  cx ??= m.width / 2; cy ??= m.height / 2;
  const k = Math.max(0.1, Math.min(4, view.k * f));
  view.x = cx - (cx - view.x) * (k / view.k);
  view.y = cy - (cy - view.y) * (k / view.k);
  view.k = k; apply();
}
$('#zin').onclick = () => zoom(1.25);
$('#zout').onclick = () => zoom(0.8);
// From the keyboard, on the map or a page on it: the arrows move it, + and
// - zoom.
map.tabIndex = 0;
map.setAttribute('aria-label', T('tabMap'));
map.addEventListener('keydown', (e) => {
  if (e.target !== map && !e.target.closest('.node')) return;
  if (e.altKey || e.ctrlKey || e.metaKey) return;
  const step = 80;
  const moves = { ArrowLeft: [step, 0], ArrowRight: [-step, 0], ArrowUp: [0, step], ArrowDown: [0, -step] };
  if (moves[e.key]) {
    view.x += moves[e.key][0]; view.y += moves[e.key][1];
    apply();
  } else if (e.key === '+' || e.key === '=') zoom(1.25);
  else if (e.key === '-') zoom(0.8);
  else return;
  e.preventDefault();
});
// The whole map: what is chosen lets go.
$('#fit').onclick = () => {
  if (focused || routed || picked) go('map');
  show(whole(), true);
};

// Brings out the pages [near], the arrows [edgeOn] and the deep links
// [entryOn] say, the page [sel] chosen; the rest faint. Nothing near: all
// as drawn.
function highlight(near, edgeOn, entryOn, sel) {
  canvas.classList.toggle('focusing', near.size > 0);
  for (const [nid, n] of Object.entries(nodes)) {
    n.classList.toggle('near', near.has(nid));
    n.classList.toggle('sel', nid === sel);
  }
  edges.forEach((e, i) => {
    const on = edgeOn(i);
    edgePaths[i]?.classList.toggle('near', on);
    edgeHits[i]?.classList.toggle('near', on);
    edgeLabels[i]?.classList.toggle('near', on);
  });
  entries.forEach((en, i) => {
    const on = entryOn(i);
    entryLines[i].classList.toggle('near', on);
    entryLabels[i].classList.toggle('near', on);
  });
  // A bundle, with any arrow in it.
  bundles.forEach((b, i) => {
    const on = b.edges.some(edgeOn);
    bundleLines[i]?.classList.toggle('near', on);
    bundleLabels[i]?.classList.toggle('near', on);
  });
}
// The pages [ids] with their labels, and room around them, in map pixels.
function around(ids) {
  const boxes = [...ids].map(boxOf);
  const lh = S.canvas.labelHeight;
  const x0 = Math.min(...boxes.map((q) => q.x)), y0 = Math.min(...boxes.map((q) => q.y));
  const x1 = Math.max(...boxes.map((q) => q.x + q.width)), y1 = Math.max(...boxes.map((q) => q.y + q.height + lh));
  const pad = 72;
  return { x: x0 - pad, y: y0 - pad, width: x1 - x0 + pad * 2, height: y1 - y0 + pad * 2 };
}

// Which state each page shows on the map ([shownState]): its first, unless
// another is chosen (beside the page, or as where an arrow arrives); its
// name under the page's then, so whoever looks knows which.
function showState(id, i) {
  const p = pageById[id];
  const s = p.states[i];
  if (!s) return;
  shownState[id] = i;
  const n = nodes[id];
  n.querySelector('.img').innerHTML = nodeImage(s);
  n.querySelector('.label small').textContent = i ? s.name : '';
  n.classList.toggle('other-state', i > 0);
  renderMark(p);
}
const stateIndex = (id, name) => pageById[id].states.findIndex((s) => s.name === name);
// All pages back in their first state: while the conditions keep values
// chosen, the first the app shows them in.
function firstStates() {
  for (const p of S.pages) {
    const i = baseState(p.id);
    if ((shownState[p.id] ?? 0) !== i) showState(p.id, i);
  }
}
// The state of [id] chosen beside it, by name; null for its first, when it
// has more than one but none was chosen.
const chosen = (id) => pageById[id].states.length > 1 ? pageById[id].states[shownState[id] ?? 0].name : null;
// Whether [e] can happen in the state [state] of its page (null: any): one
// its `when` names, of values of the conditions its `if` allows.
const can = (e, state) => {
  if (!state) return true;
  const s = pageById[e.from].states.find((x) => x.name === state);
  return (!e.when.length || e.when.includes(state))
    && Object.entries(s?.if ?? {}).every(([c, v]) => !e.if[c] || e.if[c].includes(v));
};
const statesHtml = (p) => p.states.length < 2 ? '' : `<div class="card-states" aria-label="${esc(T('states'))}">${p.states.map((s, i) =>
  `<button data-state="${i}" aria-pressed="${(shownState[p.id] ?? 0) === i}">${drawn(s).image ? `<img src="${esc(drawn(s).image)}" alt="">` : ''}<span>${esc(s.name)}</span></button>`).join('')}</div>`;
// The transitions out of and into [p], as sentences, those out in the state
// shown; each leads to the page at its other end.
const sentences = (p) => {
  const state = shownName(p.id);
  const goes = (out[p.id] ?? []).filter((e) => can(e, state) && heldEdge(e));
  const comes = (into[p.id] ?? []).filter(heldEdge);
  const item = (e, other, from, state) => `<li><a data-go="map/${esc(other)}">${sentence(e, { from, state })}</a></li>`;
  // In a tab bar, its tabs: a switch to each other one, and to the tab
  // shown again where that goes back to its first page.
  const bar = barOfPage[p.id];
  const own = tabItem[p.id] ? [p.id] : p.tab;
  const tabs = !bar ? [] : bar.pages.flatMap((t) => {
    // In several tabs, which is shown is not known here: each a tap.
    const again = own.length === 1 && own.includes(t.page);
    if (again && (t.page === p.id || bar.retap !== 'first')) return [];
    const when = Object.keys(t.if).length
      ? esc(T('inState', { state: Object.values(t.if).map(states).join(T('conditionAnd')) })) : '';
    const words = again ? T('tapAgain', { text: tabText(t) }) : tapWords(t);
    return [`<li><a data-go="map/${esc(t.page)}">${when}${esc(words)} → <b>${esc(label(t.page))}</b></a></li>`];
  });
  return (goes.length || tabs.length ? `<h4>${esc(T('fromHere'))}</h4><ul class="says">${goes.map((e) => item(e, e.to, false, state)).join('')}${tabs.join('')}</ul>` : '')
    + (comes.length ? `<h4>${esc(T('toHere'))}</h4><ul class="says">${comes.map((e) => e.anywhere
      ? item(e, e.to, T('fromAnywhere'), null) : item(e, e.from, true, null)).join('')}</ul>` : '');
};
// The state [id] is shown in, by name.
const shownName = (id) => pageById[id].states[shownState[id] ?? 0].name;

// The page chosen on the map, and the pages next to it: the map moves to
// show them, the rest faint. In the state chosen beside it: only the arrows
// out that can happen in it, and the pages they arrive at in their states.
let focused = null;
let routed = null;
function focus(id, glide, { state } = {}) {
  const p = pageById[id];
  if (focused !== (p ? id : null) || picked) firstStates();
  focused = p ? id : null;
  routed = null;
  picked = null;
  $('#route').classList.remove('on', 'busy');
  const card = $('#card');
  // Nothing chosen: the map stays where it is.
  if (!focused) { highlight(new Set(), () => false, () => false, null); card.classList.remove('on'); return; }
  if (state != null) {
    // Another state of the page: the pages its arrows arrived at, back first.
    firstStates();
    if (stateIndex(id, state) >= 0) showState(id, stateIndex(id, state));
  }
  const here = shownName(id);
  const near = new Set([focused]);
  // What the map moves to show: an arrow in a bundle is drawn only at its
  // end, so its far page is left to the card.
  const frame = new Set([focused]);
  const on = new Set();
  edges.forEach((e, i) => {
    // Not what the app shows while the conditions keep the values chosen.
    if (!heldIn(i)) return;
    const drawnHere = e.bundle == null;
    // An edge from every page is the page it goes to's, not each page's.
    if (e.from === focused && !e.anywhere && can(e, here)) {
      on.add(i); near.add(e.to);
      if (drawnHere) frame.add(e.to);
      // Of the states it can arrive in, the first; while the conditions
      // keep values chosen, the first the app shows.
      const then = arrival(e, here).find((s) => heldShown?.states[e.to]?.includes(s) ?? true) ?? arrival(e, here)[0];
      if (then && e.to !== focused) showState(e.to, Math.max(0, stateIndex(e.to, then)));
    }
    if (e.to === focused) {
      on.add(i);
      if (!e.anywhere) near.add(e.from);
      if (drawnHere) frame.add(e.from);
    }
  });
  highlight(near, (i) => on.has(i), (i) => entries[i].to === focused && heldEntry(i), focused);
  card.innerHTML = `<div class="card-body">${cardClose}<h3>${esc(p.label)}</h3><div class="meta">${esc(p.section)}</div>${tabMeta(p)}<div class="meta dev">${codeMeta(p)}</div>${statesHtml(p)}<div id="card-notes">${cardNotes(p)}</div>${sentences(p)}</div>
    <div class="actions"><button class="link" id="enlarge">${esc(T('enlarge'))}</button><button class="link" data-go="list/${esc(p.id)}">${esc(T('inList'))}</button><button class="link" data-detail="${esc(p.id)}">${esc(T('detail'))}</button></div>`;
  card.classList.add('on');
  $('#enlarge').onclick = () => enlarge(focused);
  // The pages beside the card, at the right; on a phone, where it lies
  // across the bottom, above it. As large as the arrows' words read: where
  // the pages next to it are too many for that, the page chosen is kept in
  // the view, and the card names them all.
  show(around(frame), glide, { ...clearOfCard(card), min: readable, keep: around([focused]) });
}
// An arrow tapped on the map, or its label (a bundle's: each arrow in it):
// what it is, as a sentence, in the card, with the pages at its ends.
let picked = null;
function pick(list, glide) {
  focused = null;
  routed = null;
  picked = list;
  firstStates();
  $('#route').classList.remove('on', 'busy');
  const ends = new Set(list.flatMap((i) => [edges[i].from, edges[i].to]));
  highlight(ends, (i) => list.includes(i), () => false, null);
  const card = $('#card');
  card.innerHTML = `<div class="card-body">${cardClose}<h3>${esc(T('legendSheet'))}</h3><ul class="says">${list.map((i) => `<li>${sentence(edges[i], { from: true })}</li>`).join('')}</ul></div>
    <div class="actions">${[...ends].map((id) => `<button class="link" data-go="map/${esc(id)}">${esc(label(id))}</button>`).join('')}</div>`;
  card.classList.add('on');
  show(around(ends), glide, clearOfCard(card));
}
// The card closed, as the route's panel is: what is chosen lets go.
const cardClose = `<button class="link close" data-close-card>${esc(T('close'))}</button>`;
// A state chosen beside the page: the map shows it, and its address says it.
$('#card').addEventListener('click', (e) => {
  if (e.target.closest('[data-close-card]')) { go('map'); return; }
  const b = e.target.closest('[data-state]');
  if (!b || !focused) return;
  const p = pageById[focused];
  const i = +b.dataset.state;
  history.replaceState(null, '', `#map/${encodeURIComponent(p.id)}${i ? '/' + encodeURIComponent(p.states[i].name) : ''}`);
  focus(focused, true, { state: p.states[i].name });
});
// The state [id] shows on the map, large.
function enlarge(id) {
  const p = pageById[id];
  const s = p.states[shownState[id] ?? 0];
  const d = drawn(s);
  if (d.image) zoomTo(d.image, [p.label, s.name, variantName()].filter(Boolean).join(' · '));
}

// --- the route between two pages, as the app's navigator goes (its back
// included), from a state and the history the app's start reaches it with:
// lib/src/route.dart, compiled to JavaScript and inlined above as
// contactSheetRouter ---
// What it finds (a route, and what the app shows while conditions keep
// values chosen) is found in workers of their own, one for each kind, so
// that a large app's search never holds the page still, nor one kind the
// other; where a worker cannot be made, here, after the page has said it is
// looking. Each question of a kind answered in turn, by a promise of the
// answer's JSON.
const sheetText = document.getElementById('sheet').textContent;
let router = null, shownOf = null;
const answer = (kind, args) => kind === 'route'
  ? (router ??= contactSheetRouter(sheetText))(...args)
  : (shownOf ??= contactSheetShown(sheetText))(...args);
// In the worker: the same, the sheet given first.
function workerMain() {
  let sheet, router, shown;
  self.onmessage = (e) => {
    const m = e.data;
    if (m.sheet != null) { sheet = m.sheet; return; }
    try {
      const out = m.kind === 'route'
        ? (router ??= contactSheetRouter(sheet))(...m.args)
        : (shown ??= contactSheetShown(sheet))(...m.args);
      self.postMessage({ id: m.id, out });
    } catch (err) {
      self.postMessage({ id: m.id, error: String(err) });
    }
  };
}
let askedCount = 0;
const answerHere = (q) => setTimeout(() => {
  try { q.resolve(answer(q.kind, q.args)); } catch (err) { q.reject(err); }
}, 0);
const workerSource = URL.createObjectURL(new Blob(
  [`${document.getElementById('route-js').textContent}\n(${workerMain})();`],
  { type: 'text/javascript' }));
// A worker, and what it was asked and has not answered; null for none (the
// questions answered here).
function makeWorker() {
  const w = { asked: new Map(), worker: null };
  try {
    w.worker = new Worker(workerSource);
    w.worker.onmessage = (e) => {
      const q = w.asked.get(e.data.id);
      if (!q) return;
      w.asked.delete(e.data.id);
      if (e.data.error != null) q.reject(new Error(e.data.error)); else q.resolve(e.data.out);
    };
    // It could not run: what it was asked, answered here.
    w.worker.onerror = (e) => {
      e.preventDefault();
      w.worker.terminate();
      w.worker = null;
      for (const q of w.asked.values()) answerHere(q);
      w.asked.clear();
    };
    w.worker.postMessage({ sheet: sheetText });
  } catch {
    w.worker = null;
  }
  return w;
}
const workers = { route: makeWorker(), shown: makeWorker() };
const ask = (kind, args) => new Promise((resolve, reject) => {
  const q = { kind, args, resolve, reject };
  const w = workers[kind];
  if (!w.worker) { answerHere(q); return; }
  const id = ++askedCount;
  w.asked.set(id, q);
  w.worker.postMessage({ id, kind, args });
});
// The route: { start: [frame], valuation: { condition: value }, steps:
// [{ edge, from, to, set }] or null }, a frame { page, state }, edge null
// for the back. Each asked for once, by its key, and kept once found.
const routesAsked = {}, routesFound = {};
const routeKey = (from, state, to, valuation) =>
  JSON.stringify([from, state ?? null, to, valuation ? JSON.stringify(valuation) : null]);
const routeOf = (key) => routesAsked[key] ??= ask('route', JSON.parse(key)).then(
  (out) => routesFound[key] = JSON.parse(out),
  (err) => { delete routesAsked[key]; throw err; });
// The address of a route: #route/<from>[/<state>]/<to>, then a
// /<condition>=<value> for each value chosen (an `=` is escaped in names).
function goRoute(from, to, state, valuation) {
  const values = Object.entries(valuation ?? {}).map(([c, v]) => `/${encodeURIComponent(c)}=${encodeURIComponent(v)}`).join('');
  const hash = `#route/${encodeURIComponent(from)}/${state != null ? encodeURIComponent(state) + '/' : ''}${encodeURIComponent(to)}${values}`;
  if (location.hash === hash) route(); else location.hash = hash;
}
function showRoute(from, to, glide, state, valuation) {
  // None chosen for the route: the values the map is shown while.
  valuation ??= Object.keys(held).length ? { ...held } : undefined;
  from = pageById[from] ? from : S.pages[0].id;
  to = pageById[to] ? to : (S.pages.find((p) => p.id !== from) ?? S.pages[0]).id;
  focused = null;
  picked = null;
  const mine = routed = [from, to, state, valuation];
  $('#card').classList.remove('on');
  const key = routeKey(from, state, to, valuation);
  if (routesFound[key]) { drawRoute(routesFound[key], from, to, glide, state); return; }
  // Not found yet: the panel says it is looking, and the route is drawn
  // when it is found, unless something else was chosen meanwhile.
  const box = $('#route');
  box.classList.remove('on');
  box.innerHTML = `<button class="link close" id="routeClose">${esc(T('close'))}</button><h3>${esc(T('route'))}</h3><p class="meta" role="status">${esc(T('routeBusy'))}</p>`;
  box.classList.add('busy');
  $('#routeClose').onclick = () => go('map');
  routeOf(key).then((found) => {
    if (routed === mine) drawRoute(found, from, to, glide, state);
  }, (err) => {
    // Said where it was looked for, not looked for still.
    if (routed !== mine) return;
    box.querySelector('[role=status]').textContent = T('failed', { error: err?.message ?? String(err) });
  });
}
// The route [found] from [from] (in [state]) to [to], in the panel and on
// the map.
function drawRoute(found, from, to, glide, state) {
  const stack = found.start;
  const start = stack[stack.length - 1];
  const steps = from === to ? null : found.steps;
  // Each page along it in the state it arrives in.
  firstStates();
  showState(from, stateIndex(from, start.state));
  for (const st of steps ?? []) showState(st.to.page, stateIndex(st.to.page, st.to.state));
  const said = (st) => {
    if (st.edge != null) return sentence(edges[st.edge], { from: true, state: st.from.state, sets: st.set });
    const from = `<b>${esc(label(st.from.page))}</b>: `;
    const t = tabItem[st.tab];
    // A switch arrives where the tab was left; tapping it again, at its first.
    if (st.move === 'switch') {
      return `${from}${esc(tapWords(t))} → <b>${esc(label(st.to.page))}</b>${st.to.page !== st.tab ? esc(T('asLeft')) : ''}`;
    }
    if (st.move === 'retap') {
      return `${from}${esc(T('tapAgain', { text: tabText(t) }))} → <b>${esc(label(st.to.page))}</b>`;
    }
    return `${from}${esc(T('backTo', { page: label(st.to.page) }))}${setting(st.set)}`;
  };
  const options = (sel) => S.pages.map((p) => `<option value="${esc(p.id)}"${p.id === sel ? ' selected' : ''}>${esc(p.label)}</option>`).join('');
  const states = pageById[from].states.length < 2 ? ''
    : `<span>${esc(T('states'))}</span><select id="routeState">${pageById[from].states.map((s) =>
      `<option value="${esc(s.name)}"${s.name === start.state ? ' selected' : ''}>${esc(s.name)}</option>`).join('')}</select>`;
  // The conditions' values it starts under: as the app's start reaches the
  // page, or as chosen; those its state is of, fixed by it.
  const fixed = pageById[from].states.find((s) => s.name === start.state)?.if ?? {};
  const conditions = (S.conditions ?? []).map((c, i) => `<span>${esc(c.name)}</span><select data-condition="${i}"${fixed[c.name] != null ? ' disabled' : ''}>${c.values.map((v) =>
    `<option value="${esc(v)}"${v === found.valuation[c.name] ? ' selected' : ''}>${esc(v)}</option>`).join('')}</select>`).join('');
  // What a back along the route goes to: the pages under the start.
  const under = stack.length > 1
    ? `<p class="meta">${esc(T('routeUnder', { pages: stack.slice(0, -1).map((f) => label(f.page)).join(' › ') }))}</p>` : '';
  // The other tabs' histories, as left; and what was not searched.
  const left = (found.tabs ?? []).length ? `<p class="meta">${esc(T('routeTabs', {
    tabs: found.tabs.map((t) => t.frames.map((f) => label(f.page)).join(' › ')).join(T('arrivingSeparator')) }))}</p>` : '';
  const short = found.searched === false ? `<p class="meta">${esc(T('routeUnsearched'))}</p>`
    : found.bounded ? `<p class="meta">${esc(found.atLeast != null ? T('routeAtLeast', { count: found.atLeast }) : T('routeBounded'))}</p>` : '';
  const result = from === to ? `<p class="meta">${esc(T('routeSame'))}</p>`
    : !steps ? `<p class="meta">${esc(T('routeNone'))}</p>`
    : `<p class="meta">${esc(T(steps.length === 1 ? 'routeStepsOne' : 'routeSteps', { count: steps.length }))}</p><ol>${steps.map((st) => `<li>${said(st)}</li>`).join('')}</ol>`;
  const box = $('#route');
  box.innerHTML = `<button class="link close" id="routeClose">${esc(T('close'))}</button><h3>${esc(T('route'))}</h3>
    <div class="pick"><span>${esc(T('routeFrom'))}</span><select id="routeFrom">${options(from)}</select>${states}${conditions}
    <span>${esc(T('routeTo'))}</span><select id="routeTo">${options(to)}</select></div>
    <div class="row-actions"><button class="link" id="routeSwap">${esc(T('routeSwap'))}</button></div>${under}${left}${result}${short}`;
  box.classList.remove('busy');
  box.classList.add('on');
  $('#routeFrom').onchange = $('#routeTo').onchange = () => goRoute($('#routeFrom').value, $('#routeTo').value);
  if ($('#routeState')) $('#routeState').onchange = () => goRoute(from, to, $('#routeState').value);
  for (const sel of box.querySelectorAll('[data-condition]')) sel.onchange = () => goRoute(from, to, state,
    Object.fromEntries([...box.querySelectorAll('[data-condition]:not([disabled])')].map((s) => [S.conditions[+s.dataset.condition].name, s.value])));
  $('#routeSwap').onclick = () => goRoute(to, from);
  $('#routeClose').onclick = () => go('map');
  const onPath = new Set((steps ?? []).flatMap((st) => st.edge != null ? [st.edge] : []));
  const near = new Set([from, to, ...(steps ?? []).map((st) => st.to.page)]);
  highlight(near, (i) => onPath.has(i), () => false, null);
  // Beside the panel, where the map is wide enough; on a phone, the panel
  // across the top, under it.
  show(around(near), glide, wide() ? { left: box.offsetWidth + 24 } : { top: box.offsetHeight + 24 });
}
$('#routeOpen').onclick = () => {
  const from = focused ?? S.pages[0]?.id;
  if (from) goRoute(from, S.pages.find((p) => p.id !== from)?.id ?? from);
};

// Dragged with one finger (or the mouse); two fingers pinch it larger or
// smaller around where they are.
let drag = null, moved = false, pinch = null;
const touches = new Map();
const panels = '.tools, #card, #route, .bar';
const apart = () => { const [a, b] = [...touches.values()]; return Math.hypot(a.x - b.x, a.y - b.y); };
map.addEventListener('pointerdown', (e) => {
  if (e.target.closest(panels)) return;
  touches.set(e.pointerId, { x: e.clientX, y: e.clientY });
  if (touches.size === 2) { drag = null; moved = true; pinch = { d: apart(), k: view.k }; return; }
  drag = { x: e.clientX, y: e.clientY, vx: view.x, vy: view.y }; moved = false;
});
window.addEventListener('pointermove', (e) => {
  if (touches.has(e.pointerId)) touches.set(e.pointerId, { x: e.clientX, y: e.clientY });
  if (pinch && touches.size === 2) {
    const [a, b] = [...touches.values()];
    const m = map.getBoundingClientRect();
    zoom(pinch.k * apart() / pinch.d / view.k, (a.x + b.x) / 2 - m.left, (a.y + b.y) / 2 - m.top);
    return;
  }
  if (!drag) return;
  const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
  if (Math.abs(dx) + Math.abs(dy) > 3) { moved = true; map.classList.add('drag'); }
  view.x = drag.vx + dx; view.y = drag.vy + dy; apply();
});
const lift = (e) => {
  touches.delete(e.pointerId);
  if (touches.size < 2) pinch = null;
  drag = null; map.classList.remove('drag'); setTimeout(() => moved = false, 0);
};
window.addEventListener('pointerup', lift);
window.addEventListener('pointercancel', lift);
// A click on the map, off the pages, lets the chosen page, or arrow, go.
map.addEventListener('click', (e) => { if (!moved && (focused || picked) && !e.target.closest('.node, ' + panels)) go('map'); });
// An arrow, or its label, tapped: read in the card.
canvas.addEventListener('click', (e) => {
  if (moved) return;
  const t = e.target.closest('#under path.hit, #over g.lbl, #over g.blbl');
  if (!t) return;
  e.stopPropagation();
  const g = t.closest('[data-i]');
  const i = +g.dataset.i;
  pick(g.matches('g.bundle, g.blbl') ? bundles[i].edges : [i], true);
});
// Over a panel, the wheel scrolls it; elsewhere, it moves the map.
map.addEventListener('wheel', (e) => {
  if (e.target.closest(panels)) return;
  e.preventDefault();
  const m = map.getBoundingClientRect();
  if (e.ctrlKey || e.metaKey || Math.abs(e.deltaY) > Math.abs(e.deltaX) * 2 && !e.shiftKey) {
    zoom(Math.exp(-e.deltaY * 0.002), e.clientX - m.left, e.clientY - m.top);
  } else { view.x -= e.deltaX; view.y -= e.deltaY; apply(); }
}, { passive: false });

// --- list: one page under the other, with where it goes and comes from ---
const chip = (id, e) => {
  const img = drawn(pageById[id].states[0]).image;
  const words = edgeWords(e);
  return `<a class="chip" data-go="list/${esc(id)}">${img ? `<img src="${esc(img)}" alt="" loading="lazy">` : ''}<span>${esc(label(id))}</span>${words ? `<small>${words}</small>` : ''}</a>`;
};
// An item from every page is told once, coming from anywhere, and not among
// each page's own.
const out = {}, into = {}, links = {};
for (const e of once) { if (!e.anywhere) (out[e.from] ??= []).push(e); (into[e.to] ??= []).push(e); }
for (const en of entries) (links[en.to] ??= []).push(en);
const none = `<span class="meta">${esc(T('none'))}</span>`;
const sections = {};
for (const p of S.pages) (sections[p.section] ??= []).push(p);
// Drawn again when another variant is shown.
const renderList = () => $('#page-list').innerHTML = Object.entries(sections).map(([name, pages]) =>
  `<div class="group">${name ? `<h2>${esc(name)}</h2>` : ''}${pages.map((p) => {
    const goes = (out[p.id] ?? []).map((e) => chip(e.to, e)).join('');
    const comes = (into[p.id] ?? []).map((e) => e.anywhere ? `<span class="chip entry">${esc(T('fromAnywhere'))}</span>` : chip(e.from, e)).join('') + (links[p.id] ?? []).map((en) => `<span class="chip entry">${esc(en.via)}</span>`).join('');
    return `<article class="row" id="row-${esc(p.id)}" data-find="${esc(findText(p, false))}" data-find-dev="${esc(findText(p, true))}">
      <header><h3>${esc(p.label)}</h3><span class="meta dev">${codeMeta(p)}</span>
        ${p.sheetChanged.length ? `<span class="badge changed dev" title="${esc(p.sheetChanged.join('\n'))}">${esc(T('sheetChanged'))}</span>` : ''}
        <span class="actions"><button class="link" data-go="map/${esc(p.id)}">${esc(T('onMap'))}</button><button class="link" data-detail="${esc(p.id)}">${esc(T('detail'))}</button></span></header>
      ${memoHtml(p)}${tagsHtml(p.tags)}
      <div class="states">${p.states.map((s) => stateHtml(s, p)).join('')}</div>
      <div class="flows">
        <div><h4>${esc(T('goesTo'))}</h4><div class="chips">${goes || none}</div></div>
        <div><h4>${esc(T('comesFrom'))}</h4><div class="chips">${comes || none}</div></div>
      </div></article>`;
  }).join('')}</div>`).join('');
renderList();
// The search narrows the list, and the table, as it is typed.
function filter() {
  const q = $('#search').value.trim().toLowerCase();
  const table = $('#edge-table');
  table.classList.toggle('filtering', !!q);
  for (const r of table.querySelectorAll('tr[data-find]')) r.style.display = !q || findIn(r).includes(q) ? '' : 'none';
  let any = false;
  for (const g of document.querySelectorAll('#page-list .group')) {
    let shown = 0;
    for (const r of g.querySelectorAll('.row')) {
      const on = !q || findIn(r).includes(q);
      r.style.display = on ? '' : 'none';
      if (on) shown++;
    }
    g.style.display = shown ? '' : 'none';
    any ||= shown > 0;
  }
  $('#nomatch').style.display = any ? 'none' : 'block';
}
// Scrolls to the row of [id]: at once when the page is opened at it,
// gliding when moved to from within.
function toRow(id, glide) {
  const row = document.getElementById('row-' + id);
  if (!row) return;
  if (row.style.display === 'none') { $('#search').value = ''; filter(); }
  row.scrollIntoView({ behavior: glide ? 'smooth' : 'auto', block: 'start' });
  for (const r of document.querySelectorAll('.row.hit')) r.classList.remove('hit');
  row.classList.add('hit');
}

// --- table ---
const link = (id) => `<a data-go="list/${esc(id)}">${esc(label(id))}</a>`;
// Rows of [list] in [cols]. With [grouped], the rows of one page (the first
// column) follow each other and name it once (each names it while the
// search narrows them); each row says what the search finds it by.
function edgeRows(list, cols, grouped) {
  if (!list.length) return `<p class="meta">${esc(T('none'))}</p>`;
  let last;
  return `<div class="scroll"><table><thead><tr>${cols.map((c) => `<th class="${c[2] ?? ''}">${c[0]}</th>`).join('')}</tr></thead><tbody>${
    list.map((e) => {
      const first = cols[0][1](e);
      const again = grouped && first === last;
      last = first;
      const find = e.from ? ` data-find="${esc(findEdge(e, false))}" data-find-dev="${esc(findEdge(e, true))}"` : '';
      return `<tr class="${grouped ? (again ? 'again' : 'group') : ''}"${find}>${cols.map((c) => `<td class="${c[2] ?? ''}">${c[1](e)}</td>`).join('')}</tr>`;
    }).join('')}</tbody></table></div>`;
}
// What the user does, in the screen's words (a text, a semantics label, the
// back, anything else said). What only the code names (a key, a widget
// class) is for developers, as is how the sheet writes it.
function action(e) {
  if (!e.trigger) return '—';
  const how = e.trigger.split(':', 1)[0];
  const code = `<span class="dev"> <code>${esc(e.trigger)}</code></span>`;
  if (how === 'key' || how === 'type') return `<span class="plain-only">—</span>${code}`;
  return esc(how === 'back' ? T('back') : e.trigger.slice(how.length + 1)) + code;
}
// A redirect and a back tell anyone something; push, go and replace only
// how the code keeps its pages.
const forAnyone = (e) => e.kind === 'redirect' || e.kind === 'pop';
const kindWords = (e) => forAnyone(e)
  ? esc(T('kind_' + e.kind)) : `<span class="dev">${esc(T('kind_' + e.kind))}</span>`;
// On a phone, its own column gone, after what is done (each table with a
// move has that column).
const kindAfter = (e) => `<span class="kind-inline${forAnyone(e) ? '' : ' dev'}"> · ${esc(T('kind_' + e.kind))}</span>`;
const COLS = {
  from: [esc(T('colFrom')), (e) => e.anywhere ? esc(T('fromAnywhere')) : link(e.from)],
  to: [esc(T('colTo')), (e) => link(e.to) + arriving(e, null)],
  trigger: [esc(T('colTrigger')), (e) => action(e) + kindAfter(e)],
  when: [esc(T('colWhen')), (e) => esc(needs(e).length ? needs(e).join(T('conditionAnd')) : T('whenAny'))],
  kind: [esc(T('colKind')), kindWords, 'kind'],
  code: [esc(T('colCode')), (e) => e.source ? `<code>${esc(e.source)}</code>` : '—', 'dev'],
  via: [esc(T('colVia')), (e) => esc(e.via)],
};
// The deep links, apart from the transitions between pages.
const entryRows = (list, cols) => list.length ? `<h2>${esc(T('entries'))}</h2>${edgeRows(list, cols)}` : '';
// Read as "on this page, in this state, doing this, leads there": by page,
// in the sheet's order.
const pageOrder = Object.fromEntries(S.pages.map((p, i) => [p.id, i]));
const rowOrder = (e) => e.anywhere ? -1 : pageOrder[e.from];
$('#edge-table').innerHTML = `<h2>${esc(T('tabTable'))}</h2>` + edgeRows([...once].sort((a, b) => rowOrder(a) - rowOrder(b)),
  [COLS.from, COLS.when, COLS.trigger, COLS.to, COLS.kind, COLS.code], true)
  + entryRows(entries, [COLS.to, COLS.via, COLS.code]);

// --- tree: the pages top to bottom, as a site map draws an app; each under
// the page the fewest steps from the app's start first reach it from ---
let tree, treeById;
const treeView = $('#tree-view'), treeCanvas = $('#tree-canvas'), treeSizer = $('#tree-sizer');
// An arrow's words part by part, as the map draws them: what only the code
// names and how it keeps its pages, for developers.
const partsHtml = (e) => [
  e.labelCode ? `<span class="dev">${esc(e.labelCode)}${e.labelParts.length ? ' / ' : ''}</span>` : '',
  e.labelParts.map((p) => `<span class="l-${esc(p.part)}">${esc(p.text)}</span>`).join(' / '),
  e.labelKind ? `<span class="dev">${e.labelCode || e.labelParts.length ? ' / ' : ''}${esc(e.labelKind)}</span>` : '',
].join('');
// Each tree's root, to tell the trees not reached from the app's start.
const rootOf = (t) => { while (t.parent) t = treeById[t.parent]; return t.page; };
let treeNodes = {};
// Drawn again when another variant is shown, as it lays the tree out.
function renderTree() {
  tree = laid.tree;
  treeById = Object.fromEntries(tree.pages.map((t) => [t.page, t]));
  const lines = tree.pages.filter((t) => t.line).map((t) => {
    const pts = [];
    for (let i = 0; i < t.line.length; i += 2) pts.push(t.line[i] + ',' + t.line[i + 1]);
    return `<path d="M${pts.join(' L')}"/>`;
  }).join('');
  const words = tree.pages.filter((t) => t.labelAt).map((t) => {
    const e = t.edge != null ? edges[t.edge] : null;
    const cls = e ? (e.labelParts.length ? '' : ' dev') : ' tab';
    return `<div class="tlabel${cls}" style="left:${t.labelAt[0]}px;top:${t.labelAt[1]}px">${e ? partsHtml(e) : esc(t.label)}</div>`;
  }).join('');
  // Over the trees after the app's: they are not reached from its start.
  const outside = new Set(tree.outside);
  const apart = tree.pages.filter((t) => outside.has(rootOf(t)));
  const heading = apart.length
    ? `<div class="tree-outside" style="left:${Math.min(...apart.map((t) => t.x))}px;top:${tree.pages[0].y - 40}px">${esc(T('treeOutside'))}</div>` : '';
  treeCanvas.style.width = tree.width + 'px';
  treeCanvas.style.height = tree.height + 'px';
  treeCanvas.innerHTML = `<svg width="${tree.width}" height="${tree.height}">${lines}</svg>${heading}${words}`;
  treeNodes = {};
  for (const t of tree.pages) {
    const p = pageById[t.page];
    const s = drawn(p.states[0]);
    const n = document.createElement('div');
    n.className = 'node';
    n.style.left = t.x + 'px'; n.style.top = t.y + 'px'; n.style.width = t.width + 'px';
    n.innerHTML = `<div class="img" style="height:${t.height}px">${s.image ? `<img src="${esc(s.image)}" alt="${esc(p.label)}" loading="lazy">` : nodeImage(p.states[0])}</div><div class="label"><span>${esc(p.label)}</span><small></small></div>`;
    n.title = T(p.states.length === 1 ? 'statesOfOne' : 'statesOf', { page: p.label, count: p.states.length });
    // Its details, over the tree.
    n.addEventListener('click', () => go('page', t.page));
    pressable(n, p.label);
    treeCanvas.appendChild(n);
    treeNodes[t.page] = n;
  }
}
renderTree();
// Larger or smaller.
let tk = 1, treeFitted = false;
function zoomTree(k, cx, cy) {
  const r = treeView.getBoundingClientRect();
  cx ??= r.width / 2; cy ??= r.height / 2;
  const at = { x: (treeView.scrollLeft + cx) / tk, y: (treeView.scrollTop + cy) / tk };
  tk = Math.max(0.2, Math.min(2, k));
  treeCanvas.style.transform = `scale(${tk})`;
  treeSizer.style.width = tree.width * tk + 'px';
  treeSizer.style.height = tree.height * tk + 'px';
  treeView.scrollLeft = at.x * tk - cx;
  treeView.scrollTop = at.y * tk - cy;
}
// As the map opens: whole where it reads so, else as large as reads, from
// its top, the app's start (the first tree's root) in the middle.
const fitTree = () => {
  zoomTree(Math.max(readable, Math.min(1, treeView.clientWidth / tree.width, treeView.clientHeight / tree.height)), 0, 0);
  const root = tree.pages.find((t) => !t.parent);
  treeView.scrollTo(root ? (root.x + root.width / 2) * tk - treeView.clientWidth / 2 : 0, 0);
};
$('#tzin').onclick = () => zoomTree(tk * 1.25);
$('#tzout').onclick = () => zoomTree(tk * 0.8);
// Its button: the whole tree, however small.
$('#tfit').onclick = () => {
  zoomTree(Math.min(1, treeView.clientWidth / tree.width, treeView.clientHeight / tree.height), 0, 0);
  treeView.scrollTo(0, 0);
};
// A pinch, or the wheel with Ctrl or Cmd, zooms; the wheel alone scrolls.
treeView.addEventListener('wheel', (e) => {
  if (!e.ctrlKey && !e.metaKey) return;
  e.preventDefault();
  const r = treeView.getBoundingClientRect();
  zoomTree(tk * Math.exp(-e.deltaY * 0.002), e.clientX - r.left, e.clientY - r.top);
}, { passive: false });
// The page [id] chosen in the tree: scrolled to, and marked.
function showTree(id, glide) {
  if (!treeFitted && treeView.clientWidth) { fitTree(); treeFitted = true; }
  for (const n of treeCanvas.querySelectorAll('.node.sel')) n.classList.remove('sel');
  const t = treeById[id];
  if (!t) return;
  treeNodes[id].classList.add('sel');
  treeView.scrollTo({
    left: (t.x + t.width / 2) * tk - treeView.clientWidth / 2,
    top: t.y * tk - 80,
    behavior: glide ? 'smooth' : 'auto',
  });
}

// --- detail ---
// A dialog over the view: the keyboard in it from its close button, and
// back where it was once it closes.
$('#detail').setAttribute('role', 'dialog');
$('#detail').setAttribute('aria-modal', 'true');
$('#detail').setAttribute('aria-label', T('detail'));
let beforeDialog = null;
function openPanel(html) {
  $('#panel').innerHTML = `<button class="link close" id="close">${esc(T('close'))}</button>${html}`;
  if (!$('#detail').classList.contains('on')) beforeDialog = document.activeElement;
  $('#detail').classList.add('on');
  $('#close').onclick = closePage;
  $('#close').focus();
}
// Back to what had the keyboard before a dialog opened.
function refocus() {
  if (beforeDialog?.isConnected) beforeDialog.focus();
  beforeDialog = null;
}
function openPage(id) {
  const p = pageById[id];
  if (!p) return;
  openPanel(`<h2 style="margin-top:0;color:var(--text)">${esc(p.label)}</h2>
    <p class="meta">${esc(p.section)}</p><p class="meta dev">${codeMeta(p)}</p>
    ${memoHtml(p)}${tagsHtml(p.tags)}
    ${p.sheetChanged.length ? `<p class="meta dev"><span class="badge changed">${esc(T('sheetChanged'))}</span> ${p.sheetChanged.map((f) => `<code>${esc(f)}</code>`).join(' ')}</p>` : ''}
    <div class="states">${p.states.map((s) => `<div>${stateHtml(s, p)}${
      Object.keys(s.uses).length ? `<div class="meta dev">${Object.entries(s.uses).map(([k, v]) => `${esc(k)}: ${esc(v)}`).join(' · ')}</div>` : ''}</div>`).join('')}</div>
    ${p.dependencies.length ? `<div class="dev"><h2>${esc(T('dependencies'))}</h2><table><tbody>${p.dependencies.map((d) => `<tr><td>${esc(d.name)}</td><td>${d.target ? `<code>${esc(d.target)}</code>` : '—'}</td><td>${d.source ? `<code>${esc(d.source)}</code>` : '—'}</td></tr>`).join('')}</tbody></table></div>` : ''}
    <h2>${esc(T('outgoing'))}</h2>${edgeRows(out[id] ?? [], [COLS.when, COLS.trigger, COLS.to, COLS.kind, COLS.code])}
    <h2>${esc(T('incoming'))}</h2>${edgeRows(into[id] ?? [], [COLS.from, COLS.when, COLS.trigger, COLS.kind, COLS.code])}
    ${entryRows(links[id] ?? [], [COLS.via, COLS.code])}`);
}
// Closed, the address is the view's under it again.
function closePage() {
  if (!$('#detail').classList.contains('on')) return;
  $('#detail').classList.remove('on');
  refocus();
  if (location.hash.startsWith('#page/')) {
    const id = decodeURIComponent(location.hash.slice('#page/'.length));
    history.replaceState(null, '', current === 'table' ? '#table' : `#${current}/${encodeURIComponent(id)}`);
  }
}
$('#detail').addEventListener('click', (e) => { if (e.target.id === 'detail') closePage(); });

// --- an image, large: a dialog too, closed by a tap or Escape ---
$('#zoom').setAttribute('role', 'dialog');
$('#zoom').setAttribute('aria-modal', 'true');
$('#zoom').tabIndex = -1;
let beforeZoom = null;
function zoomTo(src, caption) {
  const z = $('#zoom');
  z.querySelector('img').src = src;
  z.querySelector('img').alt = caption;
  z.querySelector('div').textContent = caption;
  z.setAttribute('aria-label', caption);
  if (!z.classList.contains('on')) beforeZoom = document.activeElement;
  z.classList.add('on');
  z.focus();
}
function closeZoom() {
  $('#zoom').classList.remove('on');
  if (beforeZoom?.isConnected) beforeZoom.focus();
  beforeZoom = null;
}
const zoomImage = (img) => zoomTo(img.src, img.dataset.zoom);
$('#zoom').onclick = closeZoom;

// --- what a click does, wherever it is ---
document.addEventListener('click', (e) => {
  const target = e.target.closest('[data-go], [data-detail], img[data-zoom]');
  if (!target) return;
  // The view, then the page's id, whole: an id may hold a /.
  if (target.dataset.go) {
    const to = target.dataset.go, at = to.indexOf('/');
    closePage();
    if (at < 0) go(to); else go(to.slice(0, at), to.slice(at + 1));
  }
  else if (target.dataset.detail) go('page', target.dataset.detail);
  else zoomImage(target);
});
// Escape closes what is on top: the image, the details, then the card or
// the route on the map.
document.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if ($('#zoom').classList.contains('on')) closeZoom();
  else if ($('#detail').classList.contains('on')) closePage();
  else if (current === 'map' && (focused || routed || picked)) go('map');
});

// --- views and their addresses: #map, #map/<page>, #map/<page>/<state>,
// #route/<from>/<to>, #route/<from>/<state>/<to>, #list/<page>,
// #page/<page> (its details, over the view), #table ---
const views = ['map', 'tree', 'list', 'table'];
let current = null;
function go(v, id) {
  const hash = '#' + v + (id ? '/' + encodeURIComponent(id) : '');
  if (location.hash === hash) route(); else location.hash = hash;
}
function route() {
  const [v, ...rest] = location.hash.slice(1).split('/');
  const decode = (r) => { try { return decodeURIComponent(r); } catch { return r; } };
  // A route's conditions are the parts with an `=`, which names escape.
  const ids = rest.filter((r) => !r.includes('=')).map(decode);
  const valuation = Object.fromEntries(rest.filter((r) => r.includes('=')).map((r) => r.split('=', 2).map(decode)));
  // The route is drawn on the map; a page's details open over the view
  // shown, or over the list.
  const name = v === 'route' ? 'map' : v === 'page' ? current ?? 'list' : views.includes(v) ? v : 'map';
  const first = current !== name;
  current = name;
  document.body.dataset.view = name;
  for (const b of document.querySelectorAll('nav button')) {
    b.setAttribute('aria-selected', b.dataset.tab === name);
    b.tabIndex = b.dataset.tab === name ? 0 : -1;
  }
  for (const s of document.querySelectorAll('main > section')) s.classList.toggle('on', s.id === 'sec-' + name);
  if (v === 'page') {
    openPage(ids[0]);
    if (first && name === 'list') requestAnimationFrame(() => toRow(ids[0], false));
    return;
  }
  $('#detail').classList.remove('on');
  if (name === 'map') requestAnimationFrame(() => {
    if (!measured) backgrounds();
    fitBar();
    // A route from a page in a state names three: #route/<from>/<state>/<to>.
    if (v === 'route') {
      const chosen = Object.keys(valuation).length ? valuation : undefined;
      if (ids.length > 2) showRoute(ids[0], ids[2], !first, ids[1], chosen); else showRoute(ids[0], ids[1], !first, undefined, chosen);
    } else focus(ids[0] ?? null, !first, { state: ids[1] });
    if (!placed) showStart(false);
  });
  if (name === 'tree') requestAnimationFrame(() => {
    if (!treeFitted && treeView.clientWidth) { fitTree(); treeFitted = true; }
    if (ids[0]) showTree(ids[0], !first);
    else for (const n of treeCanvas.querySelectorAll('.node.sel')) n.classList.remove('sel');
  });
  if (name === 'list') { if (ids[0]) requestAnimationFrame(() => toRow(ids[0], !first)); else if (first) window.scrollTo(0, 0); }
}
// The views as tabs: one Tab stop, the arrows between them.
$('nav').setAttribute('role', 'tablist');
const tabs = [...document.querySelectorAll('nav button')];
for (const b of tabs) {
  b.setAttribute('role', 'tab');
  b.setAttribute('aria-controls', 'sec-' + b.dataset.tab);
  b.onclick = () => go(b.dataset.tab);
  b.addEventListener('keydown', (e) => {
    const d = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
    if (!d) return;
    e.preventDefault();
    const next = tabs[(tabs.indexOf(b) + d + tabs.length) % tabs.length];
    next.focus();
    go(next.dataset.tab);
  });
}
for (const s of document.querySelectorAll('main > section')) s.setAttribute('role', 'tabpanel');
window.addEventListener('hashchange', route);
let resizing = false;
window.addEventListener('resize', () => {
  if (resizing) return;
  resizing = true;
  requestAnimationFrame(() => {
    resizing = false;
    fitHeader();
    if (current !== 'map') return;
    fitBar();
    if (routed) showRoute(...routed.slice(0, 2), false, ...routed.slice(2));
    else if (picked) pick(picked, false);
    else focus(focused, false);
  });
});
// On paper, every image, not only those scrolled to.
window.addEventListener('beforeprint', () => { for (const img of document.querySelectorAll('img[loading="lazy"]')) img.loading = 'eager'; });

// The search: as typed, the list narrows; a page chosen goes to it.
$('#search').addEventListener('input', filter);
$('#search').addEventListener('change', () => {
  const q = $('#search').value.trim().toLowerCase();
  if (!q) return;
  // The table stays, narrowed; elsewhere, to the page found.
  if (current === 'table') return;
  const hit = S.pages.find((p) => p.label.toLowerCase() === q) ?? S.pages.find((p) => findText(p, forDev()).includes(q));
  if (hit) go(current, hit.id);
});
// Developers' information, shown where the address says so (?dev): only CSS
// changes, and the labels' backgrounds follow their words.
const code = $('#code');
function setCode(on, { remember = true } = {}) {
  document.body.classList.toggle('plain', !on);
  if (remember) setQuery('dev', on ? '' : null);
  // What the search finds follows what is shown.
  filter();
}
// The variant shown: every image follows, and the map and the tree are laid
// out at its screens' sizes. In the address (?variant=), the first's not.
function setVariant(i) {
  // With nothing chosen, the page in the middle of the map stays there.
  const middle = current === 'map' && !focused && !routed && !picked ? middlePage() : null;
  variant = i;
  setQuery('variant', i ? variantName() : null);
  laid = laidOut();
  layMap();
  holdMap();
  measured = false;
  for (const p of S.pages) showState(p.id, shownState[p.id] ?? 0);
  renderList();
  renderTree();
  zoomTree(tk);
  filter();
  // What the map showed, shown again where it is now.
  if (current === 'map') requestAnimationFrame(() => {
    backgrounds();
    if (routed) showRoute(...routed.slice(0, 2), false, ...routed.slice(2));
    else if (picked) pick(picked, false);
    else if (focused) focus(focused, false, { state: chosen(focused) ?? undefined });
    else if (middle) toMiddle(middle);
  });
  // Not shown, the map opens where the app starts again.
  else placed = false;
  if (current === 'tree' && location.hash.startsWith('#tree/')) showTree(decodeURIComponent(location.hash.slice('#tree/'.length)), false);
  if ($('#detail').classList.contains('on') && location.hash.startsWith('#page/')) openPage(decodeURIComponent(location.hash.slice('#page/'.length)));
}
if (variants.length > 1) {
  const pick = $('#variant');
  pick.innerHTML = variants.map((v, i) => `<option value="${i}">${esc(v.name)}</option>`).join('');
  pick.value = String(variant);
  pick.onchange = () => setVariant(+pick.value);
  $('#variant-pick').hidden = false;
}

// --- what the app shows while conditions keep values chosen: from its
// launch with them, nothing done that would change them (a guest, never
// signed in). The rest of the map is gone where it is: the pages keep their
// places, to compare one choice with another. As the address says
// (?if=<condition>=<value>, once for each, an `=` escaped in names); none,
// the whole map. lib/src/route.dart finds it (contactSheetShown), as it
// finds a route, in the worker: until it is found, the map stays as it was,
// and the choices say it is being looked for ---
const held = {};
for (const v of query().getAll('if')) {
  const [c, x] = v.split('=', 2).map((r) => { try { return decodeURIComponent(r); } catch { return r; } });
  if ((S.conditions ?? []).some((k) => k.name === c && k.values.includes(x))) held[c] = x;
}
// What the app shows so, null for the whole map: { states: { page: [state] },
// edges: [place], entries: [place] }, each choice found once.
const heldFound = {};
let heldShown = null;
let heldEdges = new Set(), heldEntries = new Set();
// The choice's key; null for none.
const heldKey = () => Object.keys(held).length
  ? JSON.stringify((S.conditions ?? []).map((c) => held[c.name] ?? null)) : null;
// Whether the edge [e], or the deep link at [i], is shown: an edge from
// every page, drawn once, when it is from any.
const heldEdge = (e) => !heldShown || (e.anywhere
  ? edges.some((x, i) => x.anywhere && x.item === e.item && x.to === e.to && heldEdges.has(i))
  : heldEdges.has(edges.indexOf(e)));
const heldIn = (i) => heldEdge(edges[i]);
const heldEntry = (i) => !heldShown || heldEntries.has(i);
// The state a page is shown in at first: the first the app shows it in.
const baseState = (id) => {
  const names = heldShown?.states[id];
  return names ? Math.max(0, stateIndex(id, names[0])) : 0;
};
// The map drawn as what is shown says: what is not, gone (a bundle, when
// every arrow in it is; a tab's bar, with its page).
function holdMap() {
  const out = (on) => heldShown != null && !on;
  for (const [id, n] of Object.entries(nodes)) n.classList.toggle('held-out', out(heldShown?.states[id]));
  edges.forEach((e, i) => {
    for (const el of [edgePaths[i], edgeHits[i], edgeLabels[i]]) el?.classList.toggle('held-out', out(heldIn(i)));
  });
  entries.forEach((en, i) => {
    for (const el of [entryLines[i], entryLabels[i]]) el?.classList.toggle('held-out', out(heldEntry(i)));
  });
  bundles.forEach((b, i) => {
    for (const el of [bundleLines[i], bundleLabels[i]]) el?.classList.toggle('held-out', out(b.edges.some(heldIn)));
  });
  // The bars, in the order they are drawn: each bar's tabs.
  const tabPages = (S.tabs ?? []).flatMap((bar) => bar.pages.map((t) => t.page));
  canvas.querySelectorAll('g.tabbar').forEach((g, i) => g.classList.toggle('held-out', out(heldShown?.states[tabPages[i]])));
}
// The map as the values chosen say: at once where what they show is found
// already; else once it is, if they are still those chosen, the map shown
// again as it then is.
let holding = 0;
function hold() {
  const mine = ++holding;
  const key = heldKey();
  for (const sel of document.querySelectorAll('[data-held]')) sel.classList.toggle('on', sel.value !== '');
  const busy = (on, failed = null) => {
    $('#held').setAttribute('aria-busy', on ? 'true' : 'false');
    const says = $('#held-busy');
    if (says) {
      says.hidden = !on && failed == null;
      says.textContent = failed == null ? T('heldBusy') : T('failed', { error: failed });
    }
  };
  const show = (found) => {
    busy(false);
    heldShown = found;
    heldEdges = new Set(heldShown?.edges ?? []);
    heldEntries = new Set(heldShown?.entries ?? []);
    holdMap();
    firstStates();
    const none = $('#held-none');
    if (none) none.hidden = !heldShown || Object.keys(heldShown.states).length > 0;
  };
  if (key == null || heldFound[key]) { show(key == null ? null : heldFound[key]); return; }
  busy(true);
  ask('shown', [JSON.stringify(held)]).then((out) => {
    heldFound[key] = JSON.parse(out);
    if (mine !== holding) return;
    show(heldFound[key]);
    requestAnimationFrame(fitBar);
    if (current === 'map') route();
  }, (err) => {
    // Said, the map left as it was, not looked for still.
    if (mine === holding) busy(false, err?.message ?? String(err));
  });
}
// The values chosen, in the address.
function keepHeld() {
  const url = new URL(location.href);
  url.searchParams.delete('if');
  for (const c of S.conditions ?? []) {
    if (held[c.name] != null) url.searchParams.append('if', `${encodeURIComponent(c.name)}=${encodeURIComponent(held[c.name])}`);
  }
  history.replaceState(null, '', url);
}
if ((S.conditions ?? []).length) {
  const box = $('#held');
  box.hidden = false;
  box.setAttribute('role', 'group');
  box.setAttribute('aria-label', T('held'));
  box.innerHTML = `<span>${esc(T('held'))}</span>${S.conditions.map((c, i) => `<label>${esc(c.name)}<select data-held="${i}"><option value="">${esc(T('heldAny'))}</option>${
    c.values.map((v, k) => `<option value="${k}"${held[c.name] === v ? ' selected' : ''}>${esc(v)}</option>`).join('')}</select></label>`).join('')}<span id="held-none" hidden>${esc(T('heldNone'))}</span><span id="held-busy" role="status" hidden>${esc(T('heldBusy'))}</span>`;
  describe(box, T('heldAbout'));
  box.addEventListener('change', (e) => {
    const sel = e.target.closest('[data-held]');
    if (!sel) return;
    const c = S.conditions[+sel.dataset.held];
    if (sel.value === '') delete held[c.name]; else held[c.name] = c.values[+sel.value];
    keepHeld();
    hold();
    requestAnimationFrame(fitBar);
    // What the map shows, shown again as it now is.
    if (current === 'map') route();
  });
}
hold();
code.checked = query().has('dev');
setCode(code.checked, { remember: false });
code.onchange = () => { setCode(code.checked); requestAnimationFrame(backgrounds); };
route();
