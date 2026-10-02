const CIRC = 119.38;   // 2 * PI * 19
const RING_LEN = 552.9; // 2 * PI * 88
const RING_270 = 414.7; // 270/360 * RING_LEN

let useMPH = true;
// The GetParentResourceName() injected into the FiveM NUI frame returns the
// real resource name reliably, so it does not depend on the timing of the
// config message. If for some reason it is missing, fall back to the folder name
// (toxic_hud). It is updated again if a config message arrives.
let resourceName = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'toxic_hud';

// ---- Send to a NUI callback ----
function post(name, data) {
    fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
    }).catch(() => {});
}

// NUI callback that returns a response (used to read KVP)
function postCb(name, data) {
    return fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
    }).then((r) => r.json()).catch(() => ({}));
}

// Reliably save settings in the client KVP (since localStorage is cleared
// when reconnecting to a server).
function persist(key, value) {
    post('saveSetting', { key, value: value ?? '' });
}

// =========================================================
//  LANGUAGE SETTINGS (i18n)
//  Only the settings menu text is translated. Gauge technical labels
//  (SPEED, RPM, KT etc.) are international, so they stay as they are.
// =========================================================
const I18N = {
    en: {
        title: 'Settings',
        speedUnit: 'Speed unit',
        statusLayout: 'Status HUD',
        layoutFrame: 'Minimap frame',
        layoutRings: 'Rings',
        language: 'Language',
        editPos: '⤢ Edit layout',
        reset: '↺ Reset',
        close: '✓ Close',
        escClose: 'Press ESC to close',
        dragHint: 'Drag elements with your <b>mouse</b>',
        dragDone: '✓ Done',
        minimapLabel: 'MINIMAP',
        hudSize: 'HUD size',
        hudAuto: 'Auto',
    },
    ru: {
        title: 'Настройки',
        speedUnit: 'Единица скорости',
        statusLayout: 'Status HUD',
        layoutFrame: 'Рамка миникарты',
        layoutRings: 'Круги',
        language: 'Язык',
        editPos: '⤢ Изменить расположение',
        reset: '↺ Сброс',
        close: '✓ Закрыть',
        escClose: 'Нажмите ESC, чтобы закрыть',
        dragHint: 'Перетаскивайте элементы <b>мышью</b>',
        dragDone: '✓ Готово',
        minimapLabel: 'МИНИКАРТА',
        hudSize: 'Размер HUD',
        hudAuto: 'Авто',
    },
    zh: {
        title: '设置',
        speedUnit: '速度单位',
        statusLayout: '状态 HUD',
        layoutFrame: '小地图边框',
        layoutRings: '圆环',
        language: '语言',
        editPos: '⤢ 编辑布局',
        reset: '↺ 重置',
        close: '✓ 关闭',
        escClose: '按 ESC 关闭',
        dragHint: '用<b>鼠标</b>拖动元素',
        dragDone: '✓ 完成',
        minimapLabel: '小地图',
        hudSize: 'HUD 大小',
        hudAuto: '自动',
    },
    ko: {
        title: '설정',
        speedUnit: '속도 단위',
        statusLayout: '상태 HUD',
        layoutFrame: '미니맵 프레임',
        layoutRings: '링',
        language: '언어',
        editPos: '⤢ 레이아웃 편집',
        reset: '↺ 초기화',
        close: '✓ 닫기',
        escClose: 'ESC를 눌러 닫기',
        dragHint: '<b>마우스</b>로 요소를 드래그하세요',
        dragDone: '✓ 완료',
        minimapLabel: '미니맵',
        hudSize: 'HUD 크기',
        hudAuto: '자동',
    },
    fr: {
        title: 'Paramètres',
        speedUnit: 'Unité de vitesse',
        statusLayout: 'HUD de statut',
        layoutFrame: 'Cadre minicarte',
        layoutRings: 'Anneaux',
        language: 'Langue',
        editPos: '⤢ Modifier la disposition',
        reset: '↺ Réinitialiser',
        close: '✓ Fermer',
        escClose: 'Appuyez sur ÉCHAP pour fermer',
        dragHint: 'Déplacez les éléments avec la <b>souris</b>',
        dragDone: '✓ Terminé',
        minimapLabel: 'MINICARTE',
        hudSize: 'Taille du HUD',
        hudAuto: 'Auto',
    },
    mn: {
        title: 'Тохиргоо',
        speedUnit: 'Хурдны нэгж',
        statusLayout: 'Status HUD',
        layoutFrame: 'Minimap хүрээ',
        layoutRings: 'Тойрог',
        language: 'Хэл',
        editPos: '⤢ Байрлал засах',
        reset: '↺ Reset',
        close: '✓ Хаах',
        escClose: 'ESC дарж хаана',
        dragHint: 'Элементүүдийг хулганаар <b>чирж</b> байрлуул',
        dragDone: '✓ Дуусгах',
        minimapLabel: 'МИНИМАП',
        hudSize: 'HUD хэмжээ',
        hudAuto: 'Авто',
    },
};

let currentLang = 'en';

// Only write to localStorage/KVP when save=true (only when the player picks it).
// Default / restore calls only update the visuals.
function setLanguage(lang, save = true) {
    if (!I18N[lang]) lang = 'en';
    currentLang = lang;
    if (save) {
        localStorage.setItem('toxichud_lang', lang);
        persist('lang', lang);
    }

    const dict = I18N[lang];
    document.querySelectorAll('[data-i18n]').forEach((el) => {
        const k = el.getAttribute('data-i18n');
        if (dict[k] != null) el.innerHTML = dict[k];
    });
    document.querySelectorAll('#lang-seg button')
        .forEach((b) => b.classList.toggle('active', b.dataset.lang === lang));
    document.documentElement.lang = lang;
}

// =========================================================
//  RESPONSIVE LAYOUT
//  On every resolution (800x600 -> 4K) and aspect ratio (4:3, 5:4,
//  16:10, 16:9, 21:9, 32:9) the HUD should be the right size and line up
//  with the minimap, so:
//    * style.css is written entirely in rem -> the html font-size is
//      computed from the screen size and scales the whole HUD at once;
//    * the minimap (radar) position / size is computed with GTA's formula
//      and passed through CSS variables (radar width = resY/4, height =
//      resY/5.674, so it depends on the aspect ratio);
//    * safezone is taken from the player's GTA settings (client.lua).
// =========================================================

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

const REF_W = 1920, REF_H = 1080;   // reference resolution (design baseline)

// Screen info coming from GTA. GTA's default safeZone is ~0.9, so use that
// until the real value arrives from client.lua.
// mm* is GTA's radar rectangle (px) - comes from client.lua.
const screenInfo = { safeZone: 0.9, aspect: 0, resX: 0, resY: 0, mmX: 0, mmB: 0, mmW: 0, mmH: 0 };

// Player's manual setting (0.7 - 1.5). Multiplied on top of the auto scale.
let userScale = 1;

// Auto scale: relatively large on small screens, not too large on big screens,
// using a sub-linear (power 0.55) curve.
//   800x600  -> ~0.65   1280x720 -> ~0.79   1920x1080 -> 1.00
//   2560x1440-> ~1.17   3840x2160-> ~1.47   3440x1440 -> ~1.17
function autoScale(w, h) {
    const base = Math.min(w / REF_W, h / REF_H);
    return clamp(Math.pow(base, 0.55), 0.58, 2.2);
}

// Recompute all screen metrics and set them in CSS
function computeLayout() {
    const w = window.innerWidth || REF_W;
    const h = window.innerHeight || REF_H;
    const root = document.documentElement;

    const s = autoScale(w, h) * userScale;
    root.style.fontSize = (16 * s).toFixed(3) + 'px';
    root.style.setProperty('--hud-scale', s.toFixed(4));

    // ---- Safezone (GTA's "Safe Zone Size" setting) ----
    // Inset by the same fraction on both axes.
    const inset = clamp((1 - (screenInfo.safeZone || 1)) * 0.5, 0, 0.1);
    const safeX = Math.round(w * inset);
    const safeY = Math.round(h * inset);
    root.style.setProperty('--safe-x', safeX + 'px');
    root.style.setProperty('--safe-y', safeY + 'px');

    // ---- Minimap (radar) ----
    // client.lua computes the rectangle with GTA natives (GetAspectRatio /
    // GetSafeZoneSize / GetActiveScreenResolution) and sends it in pixels.
    // The NUI window size may differ from the game's resolution, so convert by
    // ratio. Only use the approximate calculation while no info has arrived.
    let mmX, mmB, mmW, mmH;
    if (screenInfo.mmW > 0 && screenInfo.mmH > 0) {
        const kx = w / (screenInfo.resX || w);
        const ky = h / (screenInfo.resY || h);
        mmX = screenInfo.mmX * kx;
        mmB = screenInfo.mmB * ky;
        mmW = screenInfo.mmW * kx;
        mmH = screenInfo.mmH * ky;
    } else {
        // aspect differs from w/h when the screen is stretched, so prefer it
        const aspect = screenInfo.aspect > 0 ? screenInfo.aspect : (w / h);
        mmX = safeX;
        mmB = safeY;
        mmW = w / (4 * aspect);
        mmH = h / 5.674;
    }
    root.style.setProperty('--mm-x', Math.round(mmX) + 'px');
    root.style.setProperty('--mm-b', Math.round(mmB) + 'px');
    root.style.setProperty('--mm-w', Math.round(mmW) + 'px');
    root.style.setProperty('--mm-h', Math.round(mmH) + 'px');

    applyPositions();
    fitSpeedo();
}

// Speedometer styles have different widths (the aviation panel is largest),
// so even after auto scaling they may overflow on narrow / short screens.
// Measure the active style and shrink it further if needed.
function fitSpeedo() {
    const wrap = document.getElementById('speedo');
    if (!wrap) return;
    const el = wrap.querySelector('.sp-' + wrap.getAttribute('data-style'));
    if (!el) return;
    el.style.setProperty('--sp-fit', '1');          // reset before measuring
    const w = el.offsetWidth, h = el.offsetHeight;  // (not affected by transform)
    if (!w || !h) return;                           // skip while hidden
    const f = Math.min(1, (window.innerWidth * 0.45) / w, (window.innerHeight * 0.42) / h);
    el.style.setProperty('--sp-fit', f.toFixed(4));

    // If the gauge is in its original place (bottom right), tell CSS the width
    // it occupies so the status circles do not creep toward it. If the player
    // moved it themselves (free), respect that position and reserve nothing.
    let reserved = 0;
    if (!wrap.classList.contains('free')) {
        const r = el.getBoundingClientRect();   // (includes the --sp-fit scale)
        reserved = Math.max(0, Math.round(window.innerWidth - r.left) + 12);
    }
    document.documentElement.style.setProperty('--sp-reserved', reserved + 'px');
}

// Set the HUD's manual scale (0.7 - 1.5)
function setHudScale(v, save = true) {
    userScale = clamp(parseFloat(v) || 1, 0.7, 1.5);
    const slider = document.getElementById('scale-range');
    if (slider && parseFloat(slider.value) !== userScale) slider.value = userScale;
    const out = document.getElementById('scale-val');
    if (out) out.textContent = Math.round(userScale * 100) + '%';
    if (save) {
        localStorage.setItem('toxichud_scale', String(userScale));
        persist('scale', String(userScale));
    }
    computeLayout();
}

// Recompute when the screen size changes (resolution change / window mode)
let layoutRAF = null;
window.addEventListener('resize', () => {
    if (layoutRAF) cancelAnimationFrame(layoutRAF);
    layoutRAF = requestAnimationFrame(() => { layoutRAF = null; computeLayout(); });
});

// =========================================================
//  HUD EDITOR - move elements / save positions
// =========================================================
const POS_KEY = 'toxichud_pos';
let editing = false;
let dragEl = null, dragDX = 0, dragDY = 0;

function movables() {
    return document.querySelectorAll('[data-movable]');
}

// Positions are stored as a screen fraction (0..1) - so even if the player
// changes resolution / aspect ratio, elements stay in the same relative place.
// Old-version px values (left/top) are converted to fractions automatically when read.
function loadPos() {
    let raw;
    try { raw = JSON.parse(localStorage.getItem(POS_KEY) || '{}'); }
    catch (e) { return {}; }
    if (!raw || typeof raw !== 'object') return {};

    const w = window.innerWidth || REF_W, h = window.innerHeight || REF_H;
    const out = {};
    for (const id in raw) {
        const p = raw[id];
        if (!p) continue;
        if (typeof p.x === 'number' && typeof p.y === 'number') {
            out[id] = { x: p.x, y: p.y };
        } else if (typeof p.left === 'number' && typeof p.top === 'number') {
            out[id] = { x: p.left / w, y: p.top / h };   // legacy px -> fraction
        }
    }
    return out;
}
function storePos(obj) {
    const json = JSON.stringify(obj);
    localStorage.setItem(POS_KEY, json);
    persist('pos', json);
}

// Put an element into free-positioning mode
function makeFree(el) {
    el.style.position = 'fixed';
    el.style.right = 'auto';
    el.style.bottom = 'auto';
    el.style.margin = '0';
    el.style.transform = 'none';
}

// Apply the saved positions to the current screen
function applyPositions() {
    const saved = loadPos();
    movables().forEach((el) => {
        // speedo is handled separately by positionSpeedo()
        // (it ignores the saved position for the air / moto styles)
        if (el.id === 'speedo') return;
        const p = saved[el.id];
        if (p) placeAt(el, p);
    });
    positionSpeedo();
}

// Place an element at a position given as a fraction - clamped so it does not leave the screen
function placeAt(el, p) {
    makeFree(el);
    const w = window.innerWidth, h = window.innerHeight;
    const r = el.getBoundingClientRect();
    el.style.left = Math.round(clamp(p.x * w, 0, Math.max(0, w - r.width))) + 'px';
    el.style.top  = Math.round(clamp(p.y * h, 0, Math.max(0, h - r.height))) + 'px';
}

// Write settings restored from KVP into localStorage and re-apply them
function restoreFromKvp(kvp) {
    if (!kvp) return;
    if (kvp.pos)   localStorage.setItem(POS_KEY, kvp.pos);
    if (kvp.unit)  localStorage.setItem('toxichud_unit', kvp.unit);
    if (kvp.lang)  localStorage.setItem('toxichud_lang', kvp.lang);
    if (kvp.scale) localStorage.setItem('toxichud_scale', kvp.scale);
    if (kvp.statusLayout) localStorage.setItem('toxichud_status', kvp.statusLayout);

    // Re-apply position / style / unit / language
    applyPositions();
    // On reconnect, remind the client of the player's chosen minimap position
    // (the radar is a game element, so it does not restore itself).
    pushMinimapPos(loadPos().mmghost || null);
    if (kvp.unit) setUnit(kvp.unit === 'mph');
    if (I18N[kvp.lang]) setLanguage(kvp.lang, false);
    if (kvp.scale) setHudScale(kvp.scale, false);
    if (kvp.statusLayout) setStatusLayout(kvp.statusLayout, false);
}

// Open the settings menu
function enterSettings() {
    document.getElementById('hud-editor').classList.add('open');
    document.getElementById('hud-editor').classList.remove('dragmode');
    document.body.classList.remove('editing');
    editing = false;
}
// Switch to edit-position (drag) mode
function enterDrag() {
    editing = true;
    document.body.classList.add('editing');
    document.getElementById('hud-editor').classList.add('dragmode');
    movables().forEach((el) => el.classList.add('editable'));
}
// Return from drag mode to the menu
function exitDrag() {
    editing = false;
    document.body.classList.remove('editing');
    document.getElementById('hud-editor').classList.remove('dragmode');
    movables().forEach((el) => el.classList.remove('editable'));
}
// Close everything and return to the game
function closeSettings() {
    editing = false;
    document.body.classList.remove('editing');
    const ed = document.getElementById('hud-editor');
    ed.classList.remove('open', 'dragmode');
    movables().forEach((el) => el.classList.remove('editable'));
    post('closeSettings');
}

// ---- Speedo style ----
// The style is decided ONLY by the vehicle type (forceStyle comes from
// client.lua). The player cannot change it manually; 'petrol' if it has not arrived.
// The vehicle HUD now has a single style (.sp-toxic ported from Toxic HUD).
// Previously 7 styles switched by vehicle type, all living in one DOM
// at once, which caused the ENG bar to overlap.
const FALLBACK_STYLE = 'toxic';
let forcedStyle = null;

function applyStyle(name) {
    const el = document.getElementById('speedo');
    if (el.getAttribute('data-style') === name) return;
    el.setAttribute('data-style', name);
    positionSpeedo();
}
// Return to the saved position or the default (bottom right)
function positionSpeedo() {
    const el = document.getElementById('speedo');
    el.style.transform = '';
    // The aviation (air) and motorcycle (moto) panels are much larger than the
    // vehicle speedo, so they ignore the saved position and always appear in
    // the default bottom-right corner.
    const style = el.getAttribute('data-style');
    const saved = (style === 'air' || style === 'moto') ? null : loadPos()['speedo'];
    if (saved) {
        el.classList.add('free');       // scale is anchored from the top-left corner
        placeAt(el, saved);
    } else {
        el.classList.remove('free');    // default: bottom-right corner
        el.style.position = '';
        el.style.left = el.style.top = el.style.right = el.style.bottom = el.style.margin = '';
    }
    fitSpeedo();
}
function refreshStyle() {
    applyStyle(forcedStyle || FALLBACK_STYLE);
}
// Update the bicycle's LCD fields
function updateBike(d) {
    const kmh = (d.mps ?? 0) * 3.6;
    setAll('.sp-bike-speed', kmh.toFixed(1));
    if (d.clock) setAll('.sp-bike-clock', d.clock);
    if (d.temp != null) setAll('.sp-bike-temp', d.temp);
    document.querySelectorAll('.bike-spinner').forEach((s) => s.classList.toggle('spin', kmh > 0.6));
}

// EV digital cluster
function updateEV(d) {
    const mph = (d.mps ?? 0) * 2.236936;
    const kmh = (d.mps ?? 0) * 3.6;
    setAll('.sp-ev-kmh', Math.round(kmh));
    if (d.clock) setAll('.sp-ev-clock', d.clock);
    if (d.temp != null) setAll('.sp-ev-temp', Math.round(d.temp * 9 / 5 + 32));   // °C -> °F

    // Battery (fuel% = charge) and remaining range
    const batt = d.fuel ?? 0;
    document.querySelectorAll('.sp-ev-batt').forEach((e) => {
        e.style.width = batt + '%';
        e.style.background = batt < 15 ? 'var(--warn, #e0644a)' : 'var(--accent-2, #7a8a5e)';
    });
    setAll('.sp-ev-range', Math.round(batt * 4));   // ~4 miles / %

    // Gear (P / R / D)
    let g = 'D';
    if (mph < 1) g = 'P';
    else if (d.gear === 0) g = 'R';
    setAll('.sp-ev-gear', g);

    // Eco score (higher with less power)
    const score = Math.max(0, Math.min(100, Math.round(100 - (d.rpm ?? 0) * 35)));
    setAll('.sp-ev-score', score);

    // Power ring (proportional to speed)
    const frac = Math.max(0, Math.min(1, mph / 160));
    document.querySelectorAll('.ev-power').forEach((r) => {
        r.style.strokeDasharray = `${(405.3 * frac).toFixed(1)} 540.4`;
    });
}

// =========================================================
//  AIR - aviation instrument panel
// =========================================================
const AV = {
    asi: { ds: 225, span: 270, min: 0, max: 160, minor: 5, major: 20, lbl: 20, lblR: 0.64, green: [40, 140], fs: 9 },
    alt: { ds: 0, span: 360, full: true, min: 0, max: 1000, minor: 20, major: 100, lbl: 100, lblFn: (v) => String(v / 100), lblR: 0.66, fs: 9, center: '0', centerCls: 'av-alt-val', centerFs: 11 },
    vsi: { ds: 110, span: 320, min: -2, max: 2, minor: 0.5, major: 1, lbl: 1, lblFn: (v) => String(Math.abs(v)), lblR: 0.64, fs: 9 },
    rpm: { ds: 225, span: 270, min: 0, max: 11, minor: 0.5, major: 1, lbl: 1, lblFn: (v) => String(v * 10), lblR: 0.6, green: [6, 10], red: 10.4, fs: 7.5 },
};

function buildAv(svg, cfg) {
    const cx = 60, cy = 60, r = 52;
    svg.appendChild(svgEl('circle', { cx, cy, r, class: 'av-face' }));
    const { ds, span, min, max } = cfg;
    const steps = Math.round((max - min) / cfg.minor);
    for (let i = 0; i <= steps; i++) {
        if (cfg.full && i === steps) continue;     // do not draw a duplicate tick at 360°
        const v = min + i * cfg.minor;
        const f = (v - min) / (max - min);
        const deg = ds + f * span;
        const majPos = (v - min) / cfg.major;
        const major = Math.abs(majPos - Math.round(majPos)) < 1e-6;
        const inner = r - (major ? 9 : 5);
        const [x1, y1] = polar(cx, cy, r - 2, deg);
        const [x2, y2] = polar(cx, cy, inner, deg);
        svg.appendChild(svgEl('line', { x1, y1, x2, y2, class: 'av-tick' + (major ? ' major' : '') }));
    }
    if (cfg.lbl) {
        for (let v = min; v <= max + 1e-6; v += cfg.lbl) {
            if (cfg.full && v === max) continue;
            const f = (v - min) / (max - min);
            const [lx, ly] = polar(cx, cy, r * cfg.lblR, ds + f * span);
            const t = svgEl('text', { x: lx, y: ly, class: 'av-num', 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': cfg.fs });
            t.textContent = cfg.lblFn ? cfg.lblFn(v) : String(Math.round(v));
            svg.appendChild(t);
        }
    }
    if (cfg.green) {
        svg.appendChild(svgEl('path', { d: arcPath(cx, cy, r - 1, ds + (cfg.green[0] - min) / (max - min) * span, ds + (cfg.green[1] - min) / (max - min) * span), class: 'av-green' }));
    }
    if (cfg.red != null) {
        svg.appendChild(svgEl('path', { d: arcPath(cx, cy, r - 1, ds + (cfg.red - min) / (max - min) * span, ds + span), class: 'av-redline' }));
    }
    if (cfg.center !== undefined) {
        const t = svgEl('text', { x: cx, y: cy + 20, class: 'av-center-txt ' + (cfg.centerCls || ''), 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': cfg.centerFs || 11 });
        t.textContent = cfg.center;
        svg.appendChild(t);
    }
    const rotor = svgEl('g', { class: 'av-rotor' });
    rotor.appendChild(svgEl('polygon', { points: `${cx - 2.5},${cy + 9} ${cx + 2.5},${cy + 9} ${cx},${cy - (r - 12)}`, class: 'av-needle' }));
    svg.appendChild(rotor);
    svg.appendChild(svgEl('circle', { cx, cy, r: 4, class: 'av-hub' }));
    cfg._rotor = rotor;
}

function buildAtt(svg) {
    const cx = 60, cy = 60, r = 52;
    const defs = svgEl('defs', {});
    const cp = svgEl('clipPath', { id: 'avClip' });
    cp.appendChild(svgEl('circle', { cx, cy, r }));
    defs.appendChild(cp);
    svg.appendChild(defs);
    const wrap = svgEl('g', { 'clip-path': 'url(#avClip)' });
    const hor = svgEl('g', { class: 'av-horizon' });
    hor.appendChild(svgEl('rect', { x: cx - 130, y: cy - 170, width: 260, height: 170, class: 'av-sky' }));
    hor.appendChild(svgEl('rect', { x: cx - 130, y: cy, width: 260, height: 170, class: 'av-ground' }));
    hor.appendChild(svgEl('line', { x1: cx - 60, y1: cy, x2: cx + 60, y2: cy, class: 'av-hline' }));
    for (let p = -30; p <= 30; p += 10) {
        if (p === 0) continue;
        const yy = cy - p * 1.2;
        const half = (p % 20 === 0) ? 16 : 9;
        hor.appendChild(svgEl('line', { x1: cx - half, y1: yy, x2: cx + half, y2: yy, class: 'av-ladder' }));
    }
    wrap.appendChild(hor);
    svg.appendChild(wrap);
    svg.appendChild(svgEl('circle', { cx, cy, r, class: 'av-bezel' }));
    svg.appendChild(svgEl('path', { d: `M ${cx - 20} ${cy} h 12 M ${cx + 8} ${cy} h 12 M ${cx} ${cy - 2} v 4`, class: 'av-acft' }));
    svg.appendChild(svgEl('polygon', { points: `${cx},${cy - r + 2} ${cx - 5},${cy - r + 11} ${cx + 5},${cy - r + 11}`, class: 'av-bankptr' }));
    AV._att = hor;
}

function buildHsi(svg) {
    const cx = 60, cy = 60, r = 52;
    svg.appendChild(svgEl('circle', { cx, cy, r, class: 'av-face' }));
    const rose = svgEl('g', { class: 'av-rose' });
    for (let d = 0; d < 360; d += 5) {
        const major = d % 30 === 0;
        const inner = r - (major ? 9 : 5);
        const [x1, y1] = polar(cx, cy, r - 2, d);
        const [x2, y2] = polar(cx, cy, inner, d);
        rose.appendChild(svgEl('line', { x1, y1, x2, y2, class: 'av-tick' + (major ? ' major' : '') }));
    }
    const dirs = { 0: 'N', 90: 'E', 180: 'S', 270: 'W' };
    for (let d = 0; d < 360; d += 30) {
        const [lx, ly] = polar(cx, cy, r * 0.7, d);
        const t = svgEl('text', { x: lx, y: ly, class: 'av-num', 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': 8 });
        t.textContent = dirs[d] || String(d / 10);
        rose.appendChild(t);
    }
    svg.appendChild(rose);
    svg.appendChild(svgEl('polygon', { points: `${cx},${cy - r + 3} ${cx - 4},${cy - r + 11} ${cx + 4},${cy - r + 11}`, class: 'av-lubber' }));
    svg.appendChild(svgEl('path', { d: `M ${cx} ${cy - 12} v 24 M ${cx - 8} ${cy} h 16`, class: 'av-acft' }));
    AV._rose = rose;
}

function buildAirCluster() {
    document.querySelectorAll('.sp-air [data-av]').forEach((svg) => {
        const t = svg.dataset.av;
        if (t === 'att') buildAtt(svg);
        else if (t === 'hsi') buildHsi(svg);
        else if (AV[t]) buildAv(svg, AV[t]);
    });
}

function setAvNeedle(name, f) {
    const cfg = AV[name];
    if (!cfg || !cfg._rotor) return;
    const deg = cfg.ds + clamp(f, 0, 1) * cfg.span;
    cfg._rotor.setAttribute('transform', `rotate(${deg.toFixed(2)} 60 60)`);
}

function updateAir(d) {
    const knots = (d.mps ?? 0) * 1.94384;
    setAvNeedle('asi', knots / AV.asi.max);

    const altFt = (d.alt ?? 0) * 3.28084;
    setAvNeedle('alt', (((altFt % 1000) + 1000) % 1000) / 1000);
    setAll('.av-alt-val', Math.round(altFt));

    const vs = (d.vspeed ?? 0) * 196.85 / 1000;     // x1000 fpm
    setAvNeedle('vsi', (clamp(vs, -2, 2) + 2) / 4);

    setAvNeedle('rpm', clamp(d.rpm ?? 0, 0, 1));

    // Attitude - roll + pitch
    if (AV._att) {
        const roll = d.roll ?? 0, pitch = d.pitch ?? 0;
        AV._att.setAttribute('transform', `rotate(${(-roll).toFixed(1)} 60 60) translate(0 ${(pitch * 1.2).toFixed(1)})`);
    }
    // Heading compass
    if (AV._rose) {
        const bearing = ((360 - (d.heading ?? 0)) % 360 + 360) % 360;
        AV._rose.setAttribute('transform', `rotate(${(-bearing).toFixed(1)} 60 60)`);
    }
}
function setUnit(mph) {
    useMPH = mph;
    localStorage.setItem('toxichud_unit', mph ? 'mph' : 'kmh');
    persist('unit', mph ? 'mph' : 'kmh');
    document.querySelectorAll('#unit-seg button')
        .forEach((b) => b.classList.toggle('active', (b.dataset.unit === 'mph') === mph));
}

// ---- Status HUD layout: 'frame' (around the minimap) | 'rings' (circles) ----
let statusLayout = 'frame';
function setStatusLayout(v, save = true) {
    statusLayout = (v === 'rings') ? 'rings' : 'frame';
    document.body.dataset.status = statusLayout;
    document.querySelectorAll('#status-seg button')
        .forEach((b) => b.classList.toggle('active', b.dataset.status === statusLayout));
    if (save) {
        localStorage.setItem('toxichud_status', statusLayout);
        persist('statusLayout', statusLayout);
    }
    computeLayout();
}

// =========================================================
//  PULLING SETTINGS FROM THE CLIENT
//  IMPORTANT: the 'config' message is sent when the resource starts, but if the
//  NUI page's JS has not loaded yet that message is LOST
//  (SendNUIMessage does not queue). In that case screenInfo stayed at its
//  default values (safeZone 0.9, resX/resY 0), the minimap rectangle was
//  computed wrongly, and the status frame drifted sideways off the radar.
//  So as soon as the page loads it pulls the data ITSELF -
//  client.lua's loadSettings also calls sendScreenInfo().
// =========================================================
function pullSettings(cfg) {
    return postCb('loadSettings').then((kvp) => {
        kvp = kvp || {};
        restoreFromKvp(kvp);

        // Server defaults: use the 'config' message if it came,
        // otherwise take them from the loadSettings reply (cfg* fields).
        const useMph = (cfg && cfg.useMPH !== undefined) ? cfg.useMPH : kvp.cfgUseMPH;
        const lang   = (cfg && cfg.lang   !== undefined) ? cfg.lang   : kvp.cfgLang;
        const scale  = (cfg && cfg.scale  !== undefined) ? cfg.scale  : kvp.cfgScale;

        if (!localStorage.getItem('toxichud_unit') && useMph !== undefined && useMph !== null) {
            setUnit(useMph === true || useMph === 'true');
        }
        if (!localStorage.getItem('toxichud_lang') && I18N[lang]) setLanguage(lang, false);
        if (!localStorage.getItem('toxichud_scale') && scale) setHudScale(scale, false);

        computeLayout();   // lay out the frame using the new minimap rectangle
    }).catch(() => {});
}

// Pass the minimap position to client.lua (p = {x, y} screen fraction,
// from the top-left corner; null = return to the game default).
function pushMinimapPos(p) {
    post('setMinimapPos', p || {});
}

function resetPositions() {
    localStorage.removeItem(POS_KEY);
    persist('pos', '');   // also delete from KVP
    pushMinimapPos(null);  // also return the radar to the game's default position
    movables().forEach((el) => {
        el.classList.remove('free');
        el.style.position = el.style.left = el.style.top = '';
        el.style.right = el.style.bottom = el.style.transform = el.style.margin = '';
    });
    // After returning to the default positions, re-fit the scale
    computeLayout();
}

// Drag logic - each element separately
document.addEventListener('mousedown', (e) => {
    if (!editing) return;
    const el = e.target.closest('[data-movable]');
    if (!el) return;
    dragEl = el;
    const r = el.getBoundingClientRect();
    dragDX = e.clientX - r.left;
    dragDY = e.clientY - r.top;
    el.classList.add('free');
    makeFree(el);
    el.style.left = r.left + 'px';
    el.style.top = r.top + 'px';
    e.preventDefault();
});
document.addEventListener('mousemove', (e) => {
    if (!dragEl) return;
    const r = dragEl.getBoundingClientRect();
    let left = Math.max(0, Math.min(window.innerWidth - r.width, e.clientX - dragDX));
    let top = Math.max(0, Math.min(window.innerHeight - r.height, e.clientY - dragDY));
    dragEl.style.left = left + 'px';
    dragEl.style.top = top + 'px';
});
document.addEventListener('mouseup', () => {
    if (!dragEl) return;
    const r = dragEl.getBoundingClientRect();
    const saved = loadPos();
    // Save as a screen fraction - persists on other resolutions / aspect ratios too
    saved[dragEl.id] = {
        x: +(r.left / window.innerWidth).toFixed(5),
        y: +(r.top / window.innerHeight).toFixed(5),
    };
    storePos(saved);
    if (dragEl.id === 'speedo') fitSpeedo();
    // If the minimap box was dragged, move the real radar as well
    if (dragEl.id === 'mmghost') pushMinimapPos(saved.mmghost);
    dragEl = null;
});

// Close / go back with ESC
document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    const ed = document.getElementById('hud-editor');
    if (!ed.classList.contains('open')) return;
    if (ed.classList.contains('dragmode')) exitDrag();
    else closeSettings();
});

window.addEventListener('DOMContentLoaded', () => {
    // Restore saved position / style / unit / size
    setHudScale(localStorage.getItem('toxichud_scale') || 1, false);   // calls computeLayout
    applyPositions();
    refreshStyle();
    setStatusLayout(localStorage.getItem('toxichud_status') || 'frame', false);
    const savedUnit = localStorage.getItem('toxichud_unit');
    setUnit(savedUnit ? savedUnit === 'mph' : useMPH);
    const savedLang = localStorage.getItem('toxichud_lang');
    setLanguage(I18N[savedLang] ? savedLang : 'en', false);

    // Pull the saved settings + minimap rectangle straight from the client
    // (do not wait for the 'config' message - it may have been lost if it was
    //  sent before the page loaded).
    pullSettings();

    // Menu buttons
    document.getElementById('editor-close')?.addEventListener('click', closeSettings);
    document.getElementById('editor-reset')?.addEventListener('click', resetPositions);
    document.getElementById('btn-move')?.addEventListener('click', enterDrag);
    document.getElementById('drag-done')?.addEventListener('click', exitDrag);

    // Choose unit
    document.querySelectorAll('#unit-seg button').forEach((b) => {
        b.addEventListener('click', () => setUnit(b.dataset.unit === 'mph'));
    });
    // Choose status HUD layout
    document.querySelectorAll('#status-seg button').forEach((b) => {
        b.addEventListener('click', () => setStatusLayout(b.dataset.status));
    });
    // Choose language
    document.querySelectorAll('#lang-seg button').forEach((b) => {
        b.addEventListener('click', () => setLanguage(b.dataset.lang));
    });
    // HUD size (extra adjustment on top of the auto scale)
    const scaleRange = document.getElementById('scale-range');
    if (scaleRange) {
        scaleRange.addEventListener('input', () => setHudScale(scaleRange.value, false));
        scaleRange.addEventListener('change', () => setHudScale(scaleRange.value, true));
    }
    document.getElementById('scale-reset')?.addEventListener('click', () => setHudScale(1));

    // Final calculation once style / size have fully loaded
    requestAnimationFrame(computeLayout);
});

// ---- helpers ----
function setCircle(key, pct) {
    const clamped = Math.max(0, Math.min(100, pct ?? 0));
    document.querySelectorAll(`.status-circle[data-key="${key}"]`).forEach((el) => {
        // 1) Straight bars (minimap frame and engine damage) - div fill.
        //    Vertical bars fill by height, horizontal ones by width.
        const bar = el.querySelector('.bar-fill');
        if (bar) {
            if (el.classList.contains('sf-left') || el.classList.contains('sf-right')) {
                bar.style.height = clamped.toFixed(1) + '%';
            } else {
                bar.style.width = clamped.toFixed(1) + '%';
            }
            return;
        }
        // 2) Circle - stroke-dashoffset
        const fill = el.querySelector('.fill');
        if (fill) fill.style.strokeDashoffset = CIRC - (CIRC * clamped) / 100;
    });
}

function showCircle(key, visible) {
    document.querySelectorAll(`.status-circle[data-key="${key}"]`)
        .forEach((el) => { el.style.display = visible ? '' : 'none'; });
}

function fmtMoney(prefix, n) {
    return prefix + (n ?? 0).toLocaleString('en-US');
}

function gearLabel(gear) {
    if (gear === 0) return 'R';
    if (gear === undefined || gear === null) return 'N';
    return String(gear);
}

// Update the text of all selected elements (all speedo styles at once)
function setAll(sel, val) {
    document.querySelectorAll(sel).forEach((e) => { e.textContent = val; });
}

// =========================================================
//  MODERN PRO - analog gauges (SVG)
// =========================================================
const SVGNS = 'http://www.w3.org/2000/svg';
function svgEl(tag, attrs) {
    const e = document.createElementNS(SVGNS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    return e;
}
// deg: angle measured clockwise from the top
function polar(cx, cy, r, deg) {
    const a = (deg - 90) * Math.PI / 180;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
}
function arcPath(cx, cy, r, d0, d1) {
    const [x0, y0] = polar(cx, cy, r, d0);
    const [x1, y1] = polar(cx, cy, r, d1);
    const large = ((d1 - d0) % 360) > 180 ? 1 : 0;
    return `M ${x0} ${y0} A ${r} ${r} 0 ${large} 1 ${x1} ${y1}`;
}

// =========================================================
//  MOTO - classic dual analog motorcycle gauges
//  (left: speedo km/h, right: tachometer x1000, middle: fuel,
//   odometer inside the speedo, indicator lights below)
// =========================================================
const MOTO = {
    speedo: { cx: 120, cy: 116, r: 102, ds: 225, span: 270, min: 0, max: 250, minor: 10, major: 50,
              lbl: 50, lblR: 0.72, fs: 17, cap: 'km/h', capY: 0.66, odo: true },
    tach:   { cx: 350, cy: 116, r: 102, ds: 225, span: 270, min: 0, max: 12, minor: 0.5, major: 1,
              lbl: 1, lblR: 0.74, fs: 16, cap: 'x1000r/min', capY: 0.58, blue: [8, 12] },
    fuel:   { cx: 235, cy: 52, r: 30, ds: 300, span: 120, min: 0, max: 1, minor: 0.25, major: 0.5,
              lblMap: [[0, 'E'], [1, 'F']], lblR: 0.52, fs: 11, small: true },
};

function buildMotoGauge(g, cfg) {
    const { cx, cy, r, ds, span, min, max, major, minor } = cfg;
    // Chrome bezel + black face
    g.appendChild(svgEl('circle', { cx, cy, r: r, class: 'moto-bezel' }));
    g.appendChild(svgEl('circle', { cx, cy, r: r - 4, class: 'moto-bezel2' }));
    g.appendChild(svgEl('circle', { cx, cy, r: r - 5, class: 'moto-face' }));

    // Ticks
    const steps = Math.round((max - min) / minor);
    for (let i = 0; i <= steps; i++) {
        const v = min + i * minor;
        const f = (v - min) / (max - min);
        const deg = ds + f * span;
        const majPos = (v - min) / major;
        const isMajor = Math.abs(majPos - Math.round(majPos)) < 1e-6;
        const inner = r - (isMajor ? (cfg.small ? 7 : 14) : (cfg.small ? 4 : 8));
        const [x1, y1] = polar(cx, cy, r - 7, deg);
        const [x2, y2] = polar(cx, cy, inner, deg);
        let cls = 'moto-tick' + (isMajor ? ' major' : '');
        if (cfg.blue && v >= cfg.blue[0] - 1e-6 && v <= cfg.blue[1] + 1e-6) cls += ' blue';
        g.appendChild(svgEl('line', { x1, y1, x2, y2, class: cls }));
    }

    const label = (lx, ly, txt, cls, fs) => {
        const t = svgEl('text', { x: lx, y: ly, class: cls, 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': fs });
        t.textContent = txt;
        g.appendChild(t);
    };

    // Number labels
    if (cfg.lbl) {
        for (let v = min; v <= max + 1e-6; v += cfg.lbl) {
            const f = (v - min) / (max - min);
            const [lx, ly] = polar(cx, cy, r * cfg.lblR, ds + f * span);
            label(lx, ly, String(Math.round(v)), 'moto-num', cfg.fs);
        }
    }
    // Fixed labels (E / F)
    if (cfg.lblMap) {
        cfg.lblMap.forEach(([f, txt]) => {
            const [lx, ly] = polar(cx, cy, r * cfg.lblR, ds + f * span);
            label(lx, ly, txt, 'moto-num', cfg.fs);
        });
    }
    // Bottom caption (km/h, x1000r/min)
    if (cfg.cap) label(cx, cy + cfg.capY * r, cfg.cap, 'moto-cap', cfg.small ? 8 : 11);

    // Odometer window (speedo only)
    if (cfg.odo) {
        const ow = 72, oh = 17, oy = cy + 0.3 * r;
        g.appendChild(svgEl('rect', { x: cx - ow / 2, y: oy, width: ow, height: oh, rx: 2, class: 'moto-odo-box' }));
        const t = svgEl('text', { x: cx, y: oy + oh / 2 + 1, class: 'moto-odo-txt sp-moto-odo', 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': 12 });
        t.textContent = '000000';
        g.appendChild(t);
    }

    // Red needle
    const rotor = svgEl('g', {});
    const len = r - (cfg.small ? 8 : 12);
    const w = cfg.small ? 2.6 : 4;
    const tail = cfg.small ? 9 : 15;
    rotor.appendChild(svgEl('polygon', {
        points: `${cx - w},${cy + tail} ${cx + w},${cy + tail} ${cx + 1},${cy - len} ${cx - 1},${cy - len}`,
        class: 'moto-needle',
    }));
    g.appendChild(rotor);
    g.appendChild(svgEl('circle', { cx, cy, r: cfg.small ? 5 : 8, class: 'moto-hub' }));
    cfg._rotor = rotor;
}

function buildMotoCluster() {
    document.querySelectorAll('.moto-cluster [data-moto]').forEach((g) => {
        const cfg = MOTO[g.dataset.moto];
        if (cfg) buildMotoGauge(g, cfg);
    });
    setMotoNeedle('speedo', 0); setMotoNeedle('tach', 0); setMotoNeedle('fuel', 1);
}

function setMotoNeedle(name, f) {
    const cfg = MOTO[name];
    if (!cfg || !cfg._rotor) return;
    f = Math.max(0, Math.min(1, f));
    const deg = cfg.ds + f * cfg.span;
    cfg._rotor.setAttribute('transform', `rotate(${deg.toFixed(2)} ${cfg.cx} ${cfg.cy})`);
}

function updateMoto(d) {
    const kmh = (d.mps ?? 0) * 3.6;
    setMotoNeedle('speedo', kmh / MOTO.speedo.max);
    setMotoNeedle('tach', (d.rpm ?? 0) * 12 / MOTO.tach.max);   // rpm 0..1 -> 0..12k
    setMotoNeedle('fuel', (d.fuel ?? 0) / 100);

    // Indicator lights
    const left  = document.querySelector('.sp-moto-left');
    const right = document.querySelector('.sp-moto-right');
    const beam  = document.querySelector('.sp-moto-beam');
    const neut  = document.querySelector('.sp-moto-neutral');
    if (left)  left.classList.toggle('blink', d.indLeft === true);
    if (right) right.classList.toggle('blink', d.indRight === true);
    if (beam) {
        // The telltale lights up with the low beam and turns bright blue on high beam
        beam.classList.toggle('on', d.lights === true || d.highbeam === true);
        beam.classList.toggle('high', d.highbeam === true);
    }
    if (neut)  neut.classList.toggle('on', kmh < 1);   // N lights up when stopped
}

// ---- message handler ----
window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || !msg.action) return;

    switch (msg.action) {
        case 'config': {
            if (msg.data.resourceName) resourceName = msg.data.resourceName;
            pullSettings(msg.data);
            break;
        }

        // Screen resolution / aspect ratio / safezone - from client.lua
        // (arrives again when the player changes GTA's settings)
        case 'screen': {
            const d = msg.data || {};
            if (typeof d.safeZone === 'number') screenInfo.safeZone = d.safeZone;
            if (typeof d.aspect === 'number') screenInfo.aspect = d.aspect;
            if (typeof d.resX === 'number') screenInfo.resX = d.resX;
            if (typeof d.resY === 'number') screenInfo.resY = d.resY;
            if (typeof d.mmX === 'number') screenInfo.mmX = d.mmX;
            if (typeof d.mmB === 'number') screenInfo.mmB = d.mmB;
            if (typeof d.mmW === 'number') screenInfo.mmW = d.mmW;
            if (typeof d.mmH === 'number') screenInfo.mmH = d.mmH;
            // Which corner the radar is in - CSS uses this to put the status cluster
            // on the opposite side of the minimap.
            if (d.mmPos) document.body.dataset.mmpos = d.mmPos;
            computeLayout();
            break;
        }

        case 'openSettings': {
            enterSettings();
            break;
        }

        case 'status': {
            const d = msg.data;
            setCircle('health', d.health);
            setCircle('armor', d.armor);

            if (d.hunger !== undefined && d.hunger !== null) {
                showCircle('hunger', true); setCircle('hunger', d.hunger);
            } else showCircle('hunger', false);

            if (d.thirst !== undefined && d.thirst !== null) {
                showCircle('thirst', true); setCircle('thirst', d.thirst);
            } else showCircle('thirst', false);

            if (d.stress !== undefined && d.stress !== null) {
                showCircle('stress', true); setCircle('stress', d.stress);
            } else showCircle('stress', false);

            // Stamina
            if (d.stamina !== undefined && d.stamina !== null) {
                showCircle('stamina', true); setCircle('stamina', d.stamina);
            } else showCircle('stamina', false);

            // Lung capacity (time left to breathe underwater)
            if (d.lung !== undefined && d.lung !== null) {
                showCircle('lung', true); setCircle('lung', d.lung);
                document.querySelectorAll('.status-circle[data-key="lung"]')
                    .forEach((e) => e.classList.toggle('low', d.lung <= 25));
            } else showCircle('lung', false);

            // Voice (microphone) - lights up while talking, shows the range badge
            const voiceEl = document.querySelector('.status-circle[data-key="voice"]');
            if (voiceEl) {
                // range (1=near, 2=normal, 3=far) -> fill percentage
                const range = d.voiceRange ?? 2;
                setCircle('voice', (range / 3) * 100);
                const badge = document.getElementById('voice-range');
                if (badge) badge.textContent = range;
                voiceEl.classList.toggle('talking', d.voice === true);
            }
            break;
        }

        case 'speedo': {
            const wrap = document.getElementById('speedo');
            if (!msg.data.visible) {
                if (!editing) wrap.classList.add('is-hidden');  // do not hide in edit mode
                break;
            }
            wrap.classList.remove('is-hidden');

            const d = msg.data;

            // ---- Speed (mps -> mph/kmh) ----
            const mps = d.mps ?? 0;
            const speed = Math.floor(useMPH ? mps * 2.236936 : mps * 3.6);
            setAll('.sp-speed', speed);
            setAll('.sp-unit', useMPH ? 'MPH' : 'KMH');
            setAll('.sp-gear', gearLabel(d.gear));

            // ---- Speed bar (percentage of the vehicle's top speed) ----
            const pct = Math.max(0, Math.min(100, d.speedPct ?? 0));
            document.querySelectorAll('.sp-speed-bar').forEach((b) => {
                b.style.width = pct + '%';
            });

            // ---- Fuel ----
            const fuel = Math.max(0, Math.min(100, Math.round(d.fuel ?? 0)));
            setAll('.sp-fuel', fuel);
            document.querySelectorAll('.sp-stat-fuel')
                .forEach((e) => e.classList.toggle('low', fuel <= 15));

            // ---- Engine health ----
            const eng = Math.max(0, Math.min(100, Math.round(d.engineHealth ?? 100)));
            setAll('.sp-eng', eng);
            document.querySelectorAll('.sp-stat-eng')
                .forEach((e) => e.classList.toggle('low', eng <= 40));
            break;
        }

        case 'info': {
            const d = msg.data;

            // Compass / street info
            if (d.onlyCompass) {
                const street = document.getElementById('street');
                if (d.dir !== undefined && d.dir !== null) {
                    street.classList.remove('is-hidden');
                    document.getElementById('street-dir').textContent = d.dir;
                    document.getElementById('street-deg').textContent = (d.deg ?? 0) + '°';
                    document.getElementById('street-name').textContent = d.street || '—';
                    document.getElementById('street-left').textContent = d.streetLeft || '';
                    document.getElementById('street-right').textContent = d.streetRight || '';
                } else {
                    street.classList.add('is-hidden');
                }
                break;
            }

            // Time / job / money
            if (d.id !== undefined && d.id !== null) {
                document.getElementById('info-id').textContent = '#' + d.id;
            }
            document.getElementById('info-time').textContent = d.time ?? '00:00';
            document.getElementById('info-job').textContent = d.job ?? '';
            // Job grade - separate chip
            const gradeEl = document.getElementById('info-grade');
            if (gradeEl) {
                gradeEl.textContent = d.grade ?? '';
                gradeEl.parentElement.style.display = d.grade ? '' : 'none';
            }
            document.getElementById('info-cash').textContent = fmtMoney(d.prefix, d.cash);
            document.getElementById('info-bank').textContent = fmtMoney(d.prefix, d.bank);
            break;
        }

        case 'hide': {
            document.body.style.display = 'none';
            break;
        }

        case 'show': {
            document.body.style.display = '';
            // Measuring is impossible while hidden, so re-fit as soon as it is shown
            requestAnimationFrame(computeLayout);
            break;
        }
    }
});
