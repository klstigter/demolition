// Run: node --test test/js/day_planning_bar_menu.test.js
// Day Planning bar right-click menu: the same 12 actions, in the same order, in all 4 add-ins
// (12 x 4 = 48 generated checks, each: caption + position + icon + JS->AL wiring).
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const dhx = path.resolve(__dirname, '..', '..', 'src', 'dhx');
const read = (...p) => fs.readFileSync(path.join(dhx, ...p), 'utf8');
const dataHandler = fs.readFileSync(path.resolve(dhx, '..', 'codeunit', 'codeunit_50604_DHXDataHandler.al'), 'utf8');

// [action key, caption]
const EXPECTED = [
    ['OpenDayPlanningCard', 'View'],
    ['OpenDayPlanning', 'Day Plannings'],
    ['OpenCapacity', 'Capacity'],
    ['OpenTask', 'Job Task Card'],
    ['ShowJobResources', 'Job Task Resources'],
    ['OpenDayPlanningVisual', 'Job Task Scheduler'],
    ['OpenResSchedulerTimeline', 'Resource Scheduler'],
    ['OpenResourceSchedulerAssigned', 'Resource Scheduler (assigned)'],
    ['OpenResourceSchedulerRequested', 'Resource Scheduler (Requested)'],
    ['OpenAssignedResourceCard', 'Resource Card (assigned)'],
    ['OpenRequestedResourceCard', 'Resource Card (Requested)'],
    ['OpenSequences', 'Sequences']
];

// Extract the Day Planning bar items, in order, as { action, caption, line }.
const ADDINS = {
    'Task Scheduler': {
        dir: 'projectschedule',
        items() {
            const src = read('projectschedule', 'wrapper.js');
            const re = /data-for="event" data-action="(\w+)">'\s*\+\s*'<span class="dhx-ctx-icon">[\s\S]*?<\/span>([^<']+)<\/div>/g;
            return [...src.matchAll(re)].map(m => ({ action: m[1], caption: m[2].trim(), line: m[0] }));
        },
        al() { return read('projectschedule', 'projectschedule_50621_DHXScheduleBoard.al'); },
        handled(al, action) { return new RegExp(`'${action}':`).test(al); }
    },
    'Requested/Assigned': {
        dir: 'request_assignment',
        items() {
            const src = read('request_assignment', 'wrapper.js');
            const start = src.indexOf('const bar = action');
            const block = src.slice(start, src.indexOf('if (targetInfo.type === "capacity")', start));
            const out = [];
            for (const line of block.split('\n')) {
                const c = line.match(/caption:\s*"([^"]+)"/);
                const a = line.match(/bar\("(\w+)"\)/) || (/openDayPlanningCard\(/.test(line) && ['', 'OpenDayPlanningCard']);
                if (c && a) out.push({ action: a[1], caption: c[1], line });
                else if (/caption:\s*"Sequences"/.test(line)) out.push({ pending: true });
            }
            // "Sequences" is a multi-line addContextMenuItem({...}) call
            const seq = block.match(/caption: "Sequences",[\s\S]*?bar\("(\w+)"\)/);
            if (seq) out.push({ action: seq[1], caption: 'Sequences', line: seq[0] });
            return out.filter(i => !i.pending);
        },
        al() { return read('request_assignment', 'page_50710_DHXRequestAssignmentBoard.al'); },
        handled(al, action) {
            if (action === 'OpenDayPlanningCard') return /trigger OnOpenDayPlanningCard/.test(al);
            return /trigger OnDayPlanningBarAction[\s\S]*?DayPlanningBar_RunByLineId/.test(al);
        }
    },
    'Resource Scheduler': {
        dir: 'resourceschedule_with_capacity',
        items() {
            const src = read('resourceschedule_with_capacity', 'wrapper.js');
            return src.split('\n').map(line => {
                const m = line.match(/evItem\('(?:dp|any)', '(\w+)',.*, '([^']+)'\) \+/);
                return m && { action: m[1], caption: m[2], line };
            }).filter(Boolean);
        },
        al() { return read('resourceschedule_with_capacity', 'page_50706_DHXResourceCapacityScheduler.al'); },
        handled(al, action) {
            return /trigger OnEventContextMenu[\s\S]*?DayPlanningBar_RunByRecordId/.test(al) &&
                (action !== 'OpenCapacity' || /SkillResScheduler_OpenCapacityByEventId/.test(al));
        }
    },
    'Resource Calendar': {
        dir: 'resourceschedule',
        items() {
            const src = read('resourceschedule', 'wrapper.js');
            return src.split('\n').map(line => {
                const m = line.match(/data-for="event"(?: data-dp="1")? data-action="(\w+)">.*?<\/span>([^<]+)<\/div>/);
                return m && { action: m[1], caption: m[2], line };
            }).filter(Boolean);
        },
        al() { return read('resourceschedule', 'page_50619_DHXResourceScheduler.al'); },
        handled(al, action) {
            return action === 'OpenCapacity'
                ? /'OpenCapacity':/.test(al)
                : /trigger OnEventContextMenu[\s\S]*?DayPlanningBar_RunByRecordId/.test(al);
        }
    }
};

const controlAddinAl = dir => fs.readdirSync(path.join(dhx, dir)).filter(f => f.endsWith('ControlAddin.al'))
    .map(f => read(dir, f)).join('\n');

for (const [name, addin] of Object.entries(ADDINS)) {
    const items = addin.items();
    const al = addin.al();
    const addinAl = controlAddinAl(addin.dir);

    test(`${name}: menu has exactly the 12 expected actions and no "Resource" action`, () => {
        assert.deepStrictEqual(items.map(i => i.action), EXPECTED.map(e => e[0]));
        assert.ok(!items.some(i => i.action === 'OpenResource' || i.caption === 'Resource'));
    });

    EXPECTED.forEach(([action, caption], idx) => {
        test(`${name} #${idx + 1} ${caption}: caption, position, icon, handler`, () => {
            const item = items[idx];
            assert.ok(item, `no menu item at position ${idx + 1}`);
            assert.strictEqual(item.action, action, 'action key / position');
            assert.strictEqual(item.caption, caption, 'caption');
            if (action === 'OpenDayPlanningCard') {
                // icon is either inline or via a viewImg variable defined from images/View.png
                const wrapper = read(addin.dir, 'wrapper.js');
                assert.ok(/View\.png/.test(item.line) || (/viewImg/.test(item.line) && /viewImg\s*=[\s\S]{0,200}View\.png/.test(wrapper)),
                    'View uses images/View.png');
            }
            if (action === 'OpenSequences')
                assert.match(item.line, /Sequence_and_AssignmentBoard\.png/, 'Sequences icon');
            assert.ok(addin.handled(al, action), `AL page has no handler path for ${action}`);
            // images used by the menu must be packaged with the control add-in
            if (action === 'OpenDayPlanningCard') assert.match(addinAl, /images\/View\.png/);
            if (action === 'OpenSequences') assert.match(addinAl, /images\/Sequence_and_AssignmentBoard\.png/);
            // every action the add-ins can send must be implemented by the shared dispatcher
            // (Task Scheduler's own OnEventContextMenu / Resource Calendar's own Capacity excepted below)
            const run = dataHandler.slice(dataHandler.indexOf('procedure DayPlanningBar_Run('),
                dataHandler.indexOf('procedure DayPlanningBar_RunByRecordId'));
            assert.match(run, new RegExp(`'${action}':`), `DayPlanningBar_Run has no case ${action}`);
        });
    });
}

test('Requested/Assigned: control add-in declares OnDayPlanningBarAction and the board handles it', () => {
    assert.match(controlAddinAl('request_assignment'), /event OnDayPlanningBarAction\(LineId: Text; Action: Text\)/);
});
