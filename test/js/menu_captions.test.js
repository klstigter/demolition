// Run: node --test test/js
// Static guards for the DHX add-in JS: renaming a menu caption must not break syntax,
// caption-based lookups, the JS->AL event wiring, or image resources.
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..', '..');
const dhx = path.join(root, 'src', 'dhx');
const read = f => fs.readFileSync(f, 'utf8');

// Add-in folders with a hand-written wrapper (not the vendored suite/dhtmlx libs).
const addinDirs = fs.readdirSync(dhx, { withFileTypes: true })
    .filter(d => d.isDirectory()).map(d => path.join(dhx, d.name));
const jsFiles = addinDirs.flatMap(d => fs.readdirSync(d)
    .filter(f => f.endsWith('.js') && !/^(suite|dhtmlx)/i.test(f)).map(f => path.join(d, f)));
const alFiles = dir => fs.readdirSync(dir).filter(f => f.endsWith('.al')).map(f => path.join(dir, f));

test('every add-in JS file parses', () => {
    for (const f of jsFiles) assert.doesNotThrow(() => new vm.Script(read(f), { filename: f }), f);
});

test('caption/label comparisons match a caption that still exists in the same file', () => {
    // e.g. items.filter(x => x.caption === "Capacity Scheduler") must find { caption: "Capacity Scheduler" }
    for (const f of jsFiles) {
        const src = read(f);
        const defined = new Set();
        for (const m of src.matchAll(/\bcaption\s*:\s*(["'])(.+?)\1/g)) defined.add(m[2]);
        for (const m of src.matchAll(/addTreeContextMenuItem\([^,]+,\s*(["'])(.+?)\1/g)) defined.add(m[2]);
        for (const m of src.matchAll(/\bcaption\s*(?:===|==)\s*(["'])(.+?)\1/g))
            assert.ok(defined.has(m[2]), `${path.relative(root, f)}: compares caption to "${m[2]}" but no such caption is defined`);
    }
});

test('Gantt task context menu: every item has a click handler, no duplicate classes', () => {
    const src = read(path.join(dhx, 'ganttdemo2', 'wrapper.js'));
    const start = src.indexOf('var items = [');
    const block = src.slice(start, src.indexOf('items.forEach', start));
    const classes = [...block.matchAll(/cls:\s*"([\w-]+)"/g)].map(m => m[1]);
    assert.ok(classes.length >= 9, 'menu items found');
    assert.strictEqual(new Set(classes).size, classes.length, 'duplicate cls');
    const hStart = src.indexOf('items.forEach', start);
    const handlers = src.slice(hStart, src.indexOf('document.body.appendChild(menu)', hStart));
    for (const c of classes.filter(c => c !== 'ctx-cancel'))
        assert.ok(handlers.includes(`"${c}"`), `no click handler for ${c}`);
    for (const label of ['Show Resource Panel', 'Hide Resource Panel', 'View', 'Day Planning',
        'Task Scheduler', 'Sequence', 'Assignment Board'])
        assert.ok(block.includes(`label: "${label}"`), `missing menu label ${label}`);
});

test('Gantt resource panel toggle: JS flag is maintained and hide event is wired both ways', () => {
    const src = read(path.join(dhx, 'ganttdemo2', 'wrapper.js'));
    assert.match(src, /function RecreateGanttLayout\(showResourcePanel\)\s*\{\s*window\._resPanelVisible = !!showResourcePanel/);
    assert.match(src, /window\._resPanelVisible\s*\?\s*\{ label: "Hide Resource Panel"/);
});

// Folders touched by the caption/menu work (other add-ins have unrelated, pre-existing gaps).
const CHANGED_DIRS = ['ganttdemo2', 'capacity_planning_dashboard', 'projectschedule', 'barchart_daily', 'barchart_weekly', 'request_assignment', 'dayplanning_sequence', 'resourceschedule_with_capacity'];

// Pre-existing: called from JS but never declared in AL (not part of the caption work).
const KNOWN_UNDECLARED = new Set(['OnProjectDataLoaded', 'OnAfterInit']);

test('every InvokeExtensibilityMethod name has a control add-in event and an AL trigger', () => {
    for (const dir of addinDirs.filter(d => CHANGED_DIRS.includes(path.basename(d)))) {
        const js = fs.readdirSync(dir).filter(f => f.endsWith('.js') && !/^(suite|dhtmlx)/i.test(f));
        if (!js.length) continue;
        const als = alFiles(dir).map(read).join('\n').toLowerCase();
        const hasAddin = /controladdin\s+/.test(als);
        if (!hasAddin) continue; // events declared elsewhere (shared add-in); covered by the Gantt/dashboard dirs
        for (const f of js) {
            const src = read(path.join(dir, f));
            const names = new Set([...src.matchAll(/InvokeExtensibilityMethod\(\s*(["'])(\w+)\1/g)].map(m => m[2]));
            for (const n of names) {
                if (KNOWN_UNDECLARED.has(n)) continue;
                assert.ok(als.includes(`event ${n.toLowerCase()}(`), `${path.basename(dir)}/${f}: no "event ${n}" in control add-in`);
                assert.ok(als.includes(`trigger ${n.toLowerCase()}(`), `${path.basename(dir)}/${f}: no "trigger ${n}" in a page`);
            }
        }
    }
});

test('Gantt images used via GetImageResource are registered and exist', () => {
    const dir = path.join(dhx, 'ganttdemo2');
    const used = [...read(path.join(dir, 'wrapper.js')).matchAll(/GetImageResource\('([^']+)'\)/g)].map(m => m[1]);
    const addin = read(path.join(dir, 'GantttControl.controladdin.al'));
    assert.ok(used.includes('images/View.png') && used.includes('images/Sequence_and_AssignmentBoard.png'));
    for (const img of new Set(used)) {
        assert.ok(addin.includes(`'${img}'`), `${img} not in Images list`);
        assert.ok(fs.existsSync(path.join(root, img)), `${img} missing on disk`);
    }
});
