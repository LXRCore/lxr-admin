/* LXR-ADMIN — the staff desk | © 2026 iBoss21 / LXRCore */
(function () {
  const $ = (id) => document.getElementById(id);
  const app = $('app');
  const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lxr-admin';
  let L = {}, state = { players: [], server: {}, me: {}, groups: [], tools: {}, pick: null, bans: [] };
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  const post = (name, body) => fetch(`https://${RES}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({ ok: false }));
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); $('search').placeholder = t('ui.search'); }
  const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; };

  // players
  const ACTIONS = [
    { id: 'go' }, { id: 'bring' }, { id: 'freeze', args: () => ({ on: true }) }, { id: 'freeze', label: 'unfreeze', args: () => ({ on: false }) },
    { id: 'heal' }, { id: 'revive' }, { id: 'warn', fields: ['reason'] }, { id: 'kick', fields: ['reason'] }, { id: 'ban', fields: ['reason', 'hours'], bad: true },
    { id: 'give', fields: ['item', 'amount'] }, { id: 'job', fields: ['job', 'grade'] }, { id: 'money', fields: ['account', 'amount'] },
    { id: 'spectate' },
  ];
  function renderPlayers() {
    const q = ($('search').value || '').toLowerCase();
    const list = $('players'); list.innerHTML = '';
    const rows = state.players.filter(p => !q || String(p.id).includes(q) || (p.name || '').toLowerCase().includes(q) || (p.account || '').toLowerCase().includes(q));
    $('count').textContent = t('ui.online', { n: state.players.length });
    if (!rows.length) { list.appendChild(el('div', 'ad-empty lxr-t-smoke', t('ui.nobody'))); return; }
    rows.forEach(p => {
      const row = el('div', 'lxr-row' + (state.pick && state.pick.id === p.id ? ' is-on' : ''));
      row.append(el('span', 'lxr-row-index', String(p.id).padStart(2, '0')), el('span', 'lxr-row-name', p.name || p.account), el('span', 'lxr-row-sub', `${p.job || ''} · ${p.ping} ms${p.groups && p.groups.length ? ' · ' + p.groups[0] : ''}`));
      row.onclick = () => { state.pick = p; renderPlayers(); renderCard(); };
      list.appendChild(row);
    });
  }
  function renderCard() {
    const c = $('card'); c.innerHTML = '';
    const p = state.pick;
    if (!p) { c.appendChild(el('div', 'ad-empty lxr-t-smoke', t('ui.pick_player'))); return; }
    c.append(el('div', 'ad-card__name', p.name || p.account));
    const meta = el('div', 'ad-card__meta'); meta.append(el('span', '', '#' + p.id), el('span', '', p.account), el('span', '', p.job || ''), el('span', '', p.citizenid || ''), el('span', '', `${Math.round(p.x)}, ${Math.round(p.y)}, ${Math.round(p.z)}`)); c.append(meta);
    const acts = el('div', 'ad-actions');
    ACTIONS.filter(a => state.me[a.id]).forEach(a => {
      const b = el('button', 'lxr-btn lxr-btn-sm' + (a.bad ? ' lxr-btn-bad' : ''), t('action.' + (a.label || a.id)));
      b.onclick = async () => {
        const args = a.args ? a.args() : {};
        if (a.fields) return askFields(c, a, p, args);   // inline fields: CEF has no prompt()
        const r = await post('action', { action: a.id, target: p.id, args });
        if (r.ok && (a.id === 'kick' || a.id === 'ban')) { state.pick = null; refresh(); renderCard(); }
      };
      acts.appendChild(b);
    });
    c.append(acts);
    c.append(el('div', 'ad-ask', ''));
  }
  function askFields(card, a, p, args) {
    const box = card.querySelector('.ad-ask'); box.innerHTML = '';
    const head = el('div', 'lxr-mono lxr-t-ash ad-ask__head', t('action.' + (a.label || a.id))); box.append(head);
    const inputs = {};
    a.fields.forEach(f => { const row = el('div', 'ad-form__row'); const i = el('input', 'lxr-input'); i.placeholder = t('field.' + f); inputs[f] = i; row.append(el('span', 'lxr-mono lxr-t-smoke', t('field.' + f)), i); box.append(row); });
    const row = el('div', 'ad-actions');
    const go = el('button', 'lxr-btn lxr-btn-sm' + (a.bad ? ' lxr-btn-bad' : ''), t('ui.confirm'));
    go.onclick = async () => { for (const f in inputs) args[f] = inputs[f].value; const r = await post('action', { action: a.id, target: p.id, args }); box.innerHTML = ''; if (r.ok && (a.id === 'kick' || a.id === 'ban')) { state.pick = null; refresh(); renderCard(); } };
    const no = el('button', 'lxr-btn lxr-btn-ghost lxr-btn-sm', t('ui.cancel')); no.onclick = () => { box.innerHTML = ''; };
    row.append(go, no); box.append(row);
    inputs[a.fields[0]].focus();
  }
  async function refresh() { const r = await post('players'); if (r.ok) { state.players = r.players || []; renderPlayers(); } }

  // server
  function renderServer() {
    const s = state.server || {}; const box = $('stats'); box.innerHTML = '';
    const stat = (k, v) => { const d = el('div', 'ad-stat'); d.append(el('div', 'ad-stat__k', t('ui.' + k)), el('div', 'ad-stat__v', v == null ? '—' : String(v))); box.appendChild(d); };
    stat('online', `${s.players ?? 0} / ${s.max ?? 0}`); stat('uptime', s.uptime != null ? `${Math.floor(s.uptime / 60)}h ${s.uptime % 60}m` : null);
    stat('sky', s.weather ? `${s.weather}${s.nextWeather ? ' → ' + s.nextWeather : ''}` : null); stat('clock', s.hour != null ? `${String(s.hour).padStart(2, '0')}:${String(s.minute || 0).padStart(2, '0')} · ${s.season || ''}${s.frozen ? ' · ' + t('ui.frozen') : ''}` : null);
    $('btn-freeze').textContent = s.frozen ? t('ui.unfreeze_time') : t('ui.freeze_time');
  }
  document.querySelectorAll('[data-server]').forEach(b => b.onclick = async () => {
    const what = b.dataset.server; let args = {};
    if (what === 'announce') args.text = $('announce-text').value; if (what === 'weather') args.kind = $('weather-kind').value; if (what === 'time') args = { hour: Number($('time-hour').value), minute: Number($('time-minute').value) };
    const r = await post('server', { what, args }); if (r.ok) { state.server = r.server; renderServer(); }
  });
  $('btn-freeze').onclick = async () => { const r = await post('server', { what: 'time', args: { freeze: !state.server.frozen } }); if (r.ok) { state.server = r.server; renderServer(); } };

  // me
  function renderTools() {
    document.querySelectorAll('.ad-tool').forEach(b => { const on = !!state.tools[b.dataset.tool]; b.classList.toggle('is-on', on); b.querySelector('.ad-tool__state').textContent = on ? t('ui.on') : t('ui.off'); b.disabled = !state.me[b.dataset.tool]; b.style.opacity = state.me[b.dataset.tool] ? '' : '.35'; });
  }
  document.querySelectorAll('.ad-tool').forEach(b => b.onclick = async () => { const name = b.dataset.tool === 'blips' ? 'blips' : 'tool'; const r = await post(name, { tool: b.dataset.tool, on: !state.tools[b.dataset.tool] }); if (r.ok) { state.tools[b.dataset.tool] = !state.tools[b.dataset.tool]; renderTools(); } });
  $('btn-waypoint').onclick = () => post('teleport', { waypoint: true });
  $('btn-coords').onclick = () => post('teleport', { x: Number($('tp-x').value), y: Number($('tp-y').value), z: Number($('tp-z').value) });

  // reports
  async function loadReports(what, id) { const r = await post('reports', { what: what || 'list', id }); state.reports = r.ok ? (r.reports || []) : []; renderReports(); }
  function renderReports() {
    const list = $('reports'); list.innerHTML = '';
    const open = (state.reports || []).filter(r => r.open), done = (state.reports || []).filter(r => !r.open);
    if (!open.length && !done.length) { list.appendChild(el('div', 'ad-empty lxr-t-smoke', t('ui.no_reports'))); return; }
    [...open, ...done].forEach((r, i) => {
      const row = el('div', 'lxr-row' + (r.open ? '' : ' is-dim'));
      const ago = Math.max(0, Math.round((Date.now() / 1000 - r.at) / 60));
      row.append(el('span', 'lxr-row-index', String(i + 1).padStart(2, '0')), el('span', 'lxr-row-name', `${r.name} · #${r.from}`), el('span', 'lxr-row-sub', `${r.text} · ${ago} min${r.open ? '' : ' · ' + t('ui.closed_by') + ' ' + (r.by || '')}`));
      if (r.open) {
        const go = el('button', 'lxr-btn lxr-btn-ghost lxr-btn-sm', t('action.go')); go.onclick = (e) => { e.stopPropagation(); post('goto', { x: r.x, y: r.y, z: r.z }); };
        const cl = el('button', 'lxr-btn lxr-btn-sm', t('ui.close_report')); cl.onclick = (e) => { e.stopPropagation(); loadReports('close', r.id); };
        row.append(go, cl);
      }
      list.appendChild(row);
    });
  }
  $('btn-reports').onclick = () => loadReports('list');

  // bans
  async function loadBans() { const r = await post('bans'); state.bans = r.ok ? (r.bans || []) : []; renderBans(); }
  function renderBans() {
    const list = $('bans'); list.innerHTML = '';
    if (!state.bans.length) { list.appendChild(el('div', 'ad-empty lxr-t-smoke', t('ui.no_bans'))); return; }
    state.bans.forEach((b, i) => {
      const row = el('div', 'lxr-row');
      const until = b.expire >= 2147483647 ? t('ui.permanent') : new Date(b.expire * 1000).toLocaleString();
      row.append(el('span', 'lxr-row-index', String(i + 1).padStart(2, '0')), el('span', 'lxr-row-name', b.name || '?'), el('span', 'lxr-row-sub', `${b.reason || ''} · ${b.bannedby || ''} · ${until}`));
      if (state.me.unban) { const u = el('button', 'lxr-btn lxr-btn-ghost lxr-btn-sm', t('action.unban')); u.onclick = async (e) => { e.stopPropagation(); const r = await post('unban', { id: b.id }); if (r.ok) loadBans(); }; row.appendChild(u); }
      list.appendChild(row);
    });
  }

  // tabs + shell
  function tab(name) { document.querySelectorAll('.ad-nav__item').forEach(b => b.classList.toggle('is-on', b.dataset.tab === name)); document.querySelectorAll('.ad-tab').forEach(s => s.classList.toggle('lxr-hidden', s.id !== 'tab-' + name)); if (name === 'bans') loadBans(); if (name === 'reports') loadReports('list'); if (name === 'server') renderServer(); if (name === 'me') renderTools(); }
  document.querySelectorAll('.ad-nav__item').forEach(b => b.onclick = () => tab(b.dataset.tab));
  $('btn-refresh').onclick = refresh; $('btn-bans').onclick = loadBans; $('btn-close').onclick = () => post('close');
  $('search').addEventListener('input', renderPlayers);
  document.addEventListener('keydown', e => { if (e.key === 'Backspace' && e.target.tagName !== 'INPUT') post('close'); if (e.key === 'Escape') post('close'); });

  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.brand && m.brand.theme) document.documentElement.dataset.theme = m.brand.theme;
    if (m.locale) { L = m.locale; applyLocale(); }
    if (m.lang) document.body.classList.toggle('lang-ka', m.lang === 'ka');
    if (m.tools) state.tools = m.tools;
    if (m.action === 'open') { const p = m.payload || {}; state.players = p.players || []; state.server = p.server || {}; state.me = p.me || {}; state.groups = p.groups || []; state.pick = null; $('my-groups').textContent = state.groups.join(' · '); renderPlayers(); renderCard(); renderServer(); renderTools(); tab('players'); app.classList.remove('lxr-hidden'); }
    if (m.action === 'tools') renderTools();
    if (m.action === 'close') app.classList.add('lxr-hidden');
    if (m.action === 'clipboard' && navigator.clipboard) navigator.clipboard.writeText(m.text || '').catch(() => {});
  });
  if (window.__LXR_MOCK__) window.postMessage(window.__LXR_MOCK__, '*');
})();
