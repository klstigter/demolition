// DHX Request / Assignment Scheduler — ported from the standalone Vite demo
// (KLAAS/DHTMLX/src/main.js) to run as a Business Central Control Add-in.
//
// BC boundary (only real behavioral difference from the source demo):
//   - BOOT() (called by startupScript.js) builds the DOM and wires every UI
//     event listener, then raises ControlReady().
//   - AL responds by calling SetPlanningData(jsonTxt) with the real payload
//     (resources/dayTaskLines/capacitySlots/skillColors/statusColors/workdays).
//     The demo's fetchPlanningData()/getDemoPlanningData() synthetic-data path
//     is replaced by this one AL-driven entry point.
//   - Six commit actions (accept/reject sequence, assign/move/resize/unassign
//     a Day Task Line) call Microsoft.Dynamics.NAV.InvokeExtensibilityMethod
//     at the same points the demo already mutates its in-memory model — the
//     demo itself never made any server call (planningActions.js was an
//     unused stub), so these call sites are new, not changed.
//   - Whole-Sequence drag/drop stays provisional (JS-only) until Accept is
//     clicked; individual slot drags/moves/resizes commit to BC immediately
//     on drop — confirmed product decision, matches the demo's existing
//     two-tier "provisional vs immediate" visual behavior exactly.
//   - There is no numeric "Sequence No." in Business Central. A "Sequence" is
//     the distinct (Job No., Job Task No., Skill) combination; wherever the
//     demo displayed a numeric `seq`, this port uses the Skill code instead
//     (fully preserves every label/tooltip that referenced `line.seq`).

let currentWorkdayStart = 7;
let currentWorkdayEnd = 18;
let showWeekends = false;

// Populated by SetPlanningData(); see "applyPlanningData" below.
let workdays = [];
let resources = [];
// O(1) lookup for the very common "find the resource by key" pattern — see
// rebuildResourcesByKey(). With 200+ real resources, `resources.find(...)`
// scans the whole array; several call sites run it once per Day Task Line
// inside assignmentEvents()'s per-line loop (called on every render), which
// at real BC scale (thousands of lines) is a genuine main-thread-blocking
// freeze, not just a demo-scale inefficiency.
let resourcesByKey = new Map();

function rebuildResourcesByKey() {
  resourcesByKey = new Map();
  resources.forEach(r => resourcesByKey.set(r.key, r));
}

function findResource(key) {
  return resourcesByKey.get(key);
}
let skillColors = [];
let statusColors = { ok: { backgroundColor: "#DDF2E5", textColor: "#26613A" } };
let dayTaskLines = [];
let capacitySlots = [];
// O(1) lookup for capacityFor() — see rebuildCapacitySlotIndex(). Real BC data
// can carry thousands of capacity slots (many resources x many workdays);
// capacityFor() is called once per assigned Day Task Line on every render AND
// on every pointermove during a drag (via validateCapacity), so a linear
// .filter() over the whole array here was a genuine main-thread-blocking
// freeze at that scale, not just a demo-scale inefficiency.
let capacitySlotIndex = new Map();

function rebuildCapacitySlotIndex() {
  capacitySlotIndex = new Map();
  capacitySlots.forEach(slot => {
    const key = `${slot.resourceId}|${slot.dayIndex}`;
    let bucket = capacitySlotIndex.get(key);
    if (!bucket) {
      bucket = [];
      capacitySlotIndex.set(key, bucket);
    }
    bucket.push(slot);
  });
}
let sequenceRows = [];
let requestTree = [];

// sequenceRequiredSkill() used to do sequenceRows.find(row => row.key === X)
// on every call. It's invoked once per Day Task Line (via
// requestedSkillForLine) from inside per-resource/per-line render loops that
// each already iterate the full dayTaskLines/resources arrays, so an O(N)
// scan here multiplied the render cost by sequenceRows.length on top of
// everything else - part of the same freeze as capacitySlotIndex above.
let sequenceRowsByKey = new Map();

function rebuildSequenceRowsByKey() {
  sequenceRowsByKey = new Map();
  sequenceRows.forEach(row => sequenceRowsByKey.set(row.key, row));
}

// visibleResources() re-checks "does this resource have an assigned line
// with skill X" by scanning the entire dayTaskLines array once per resource
// (resources.filter(r => ... dayTaskLines.some(...))) - an O(resources x
// dayTaskLines) scan on every render once a skill filter is active, which is
// exactly the state entered by clicking a skill/sequence row. Indexing
// dayTaskLines by assignedResource -> Set of skills up front turns that into
// O(resources + dayTaskLines).
let assignedResourceSkillSets = new Map();

function rebuildAssignedResourceSkillSets() {
  assignedResourceSkillSets = new Map();
  dayTaskLines.forEach(line => {
    if (!line.assignedResource) return;
    const skill = requestedSkillForLine(line);
    if (!skill) return;
    let set = assignedResourceSkillSets.get(line.assignedResource);
    if (!set) {
      set = new Set();
      assignedResourceSkillSets.set(line.assignedResource, set);
    }
    set.add(skill);
  });
}

let requestScheduler = null;
let resourceScheduler = null;

// DOM references — assigned in BOOT() once the markup exists.
let dragStatus, resultStatus, resetBtn, undoBtn, acceptAllBtn, rejectAllBtn;
let sequenceEndDateInput, scopeSequenceLabel, scopeSummary, scope30Btn;
let requestFilterBtn, clearRequestFilterBtn, requestFilterActiveDot, requestFilterSummary;
let requestFilterPopover, jobFilterSelect, taskFilterSelect, applyRequestFilterBtn;
let planningSetupBtn, planningSetupPopover, showWeekendsInput, workdayStartInput, workdayEndInput;
let sequenceSkillBehaviorInput, hierarchyDensityInput, applyPlanningSetupBtn;
let manualFilterBtn, resetFilterBtn, resourceFilterSummary, filterActiveDot, manualFilterPopover;
let plannerSplit, requestPane, resourcePane, paneSplitter;
let sequenceDragTooltip, assignmentDetailTooltip, requestDetailTooltip;
let assignmentTimelineScrollbar, assignmentTimelineScrollbarContent;
let resourceSkillWarningTooltip, slotContextMenu;
let simplePopupBackdrop, simplePopupText, simplePopupCloseBtn;

let sequenceSkillBehavior = "highlight";
let hierarchyDensity = "compact";

function addWorkdays(date, amount) {
  const d = new Date(date);
  let remaining = amount;
  while (remaining > 0) {
    d.setDate(d.getDate() + 1);
    if (d.getDay() !== 0 && d.getDay() !== 6) remaining--;
  }
  return d;
}

function atTime(day, hour) {
  const d = new Date(day);
  d.setHours(Math.floor(hour), Math.round((hour % 1) * 60), 0, 0);
  return d;
}

function getPlanningStart() {
  return atTime(workdays[0], currentWorkdayStart);
}

function getPlanningEnd() {
  return atTime(workdays[workdays.length - 1], currentWorkdayEnd);
}

function getRangeHours() {
  return Math.round((getPlanningEnd() - getPlanningStart()) / 3600000);
}

function isWeekend(date) {
  const day = date.getDay();
  return day === 0 || day === 6;
}

function shouldHideTimelineDate(date) {
  const hour = date.getHours();

  if (!showWeekends && isWeekend(date)) return true;
  return hour < currentWorkdayStart || hour >= currentWorkdayEnd;
}

function nonWorkingTimelineClass(date) {
  return isWeekend(date) ? "non-working-day-cell" : "";
}

let activeSkillFilter = null;
let activeSkillSequenceKey = null;
let requestJobFilter = "";
let requestTaskFilter = "";
let pendingRequestJobFilter = "";
let pendingRequestTaskFilter = "";
let manualSkillFilter = null;
let pendingManualSkillFilter = null;

let globalSelectionEndDate = null;
let activeScopeSequenceKey = null;

function safeSkillClass(skill) {
  return String(skill ?? "unknown")
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "") || "unknown";
}

function getSkillColor(skill) {
  return (
    skillColors.find(item => item.skill === skill) ?? {
      skill,
      backgroundColor: "#D9EEF8",
      borderColor: "#5AA6C8",
      textColor: "#035B7E"
    }
  );
}

function installSkillColorStyles() {
  let style = document.getElementById("requestSkillColorStyles");

  if (!style) {
    style = document.createElement("style");
    style.id = "requestSkillColorStyles";
    document.head.appendChild(style);
  }

  const okBackground =
    statusColors?.ok?.backgroundColor || "#DDF2E5";
  const okText =
    statusColors?.ok?.textColor || "#26613A";

  style.textContent = skillColors
    .map(item => {
      const cls = safeSkillClass(item.skill);
      const background = item.backgroundColor || "#D9EEF8";
      const border = item.borderColor || "#5AA6C8";
      const text = item.textColor || "#035B7E";

      return `
#requestScheduler .dhx_cal_event_line.request-skill-${cls},
#requestScheduler .dhx_cal_event.request-skill-${cls} .dhx_body {
  background: ${background} !important;
  border: 1px solid ${border} !important;
  color: ${text} !important;
}
#requestScheduler .seq-cell.request-skill-${cls} .seq-title {
  color: ${text};
}
#requestScheduler .dhx_cal_event_line.request-skill-${cls}.request-assigned.request-assignment-exact-match,
#requestScheduler .dhx_cal_event.request-skill-${cls}.request-assigned.request-assignment-exact-match .dhx_body {
  background: ${okBackground} !important;
  background-color: ${okBackground} !important;
  color: ${okText} !important;
  border: 2px solid ${border} !important;
  border-color: ${border} !important;
  opacity: 1 !important;
}`;
    })
    .join("\n");
}

function installStatusColorStyles() {
  let style =
    document.getElementById("statusColorStyles");

  if (!style) {
    style = document.createElement("style");
    style.id = "statusColorStyles";
    document.head.appendChild(style);
  }

  const okBackground =
    statusColors?.ok?.backgroundColor || "#DDF2E5";

  const okText =
    statusColors?.ok?.textColor || "#26613A";

  style.textContent = `
#resourceScheduler .assignment-ok,
#resourceScheduler .assignment-ok .dhx_body,
#resourceScheduler .dhx_cal_event_line.assignment-ok {
  background: ${okBackground} !important;
  background-color: ${okBackground} !important;
  color: ${okText} !important;
  opacity: 1 !important;
}`;
}

function sequenceRequiredSkill(sequenceKey) {
  return sequenceRowsByKey.get(sequenceKey)?.requiredSkill ?? null;
}

function dateOnlyKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function parseDateOnly(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  const [year, month, day] = String(value).split("-").map(Number);
  if (!year || !month || !day) return null;
  return new Date(year, month - 1, day);
}

function allPlanningLines() {
  return [...dayTaskLines].sort((a, b) => a.date - b.date);
}

function defaultGlobalSelectionEndDate() {
  const lines = allPlanningLines();
  if (!lines.length) return null;

  const uniqueWorkdays = [];
  const seen = new Set();

  lines.forEach(line => {
    const key = dateOnlyKey(line.date);
    if (!seen.has(key)) {
      seen.add(key);
      uniqueWorkdays.push(new Date(line.date));
    }
  });

  return uniqueWorkdays[Math.min(29, uniqueWorkdays.length - 1)] ?? null;
}

function getGlobalSelectionEndDate() {
  if (!globalSelectionEndDate) {
    globalSelectionEndDate = defaultGlobalSelectionEndDate();
  }
  return globalSelectionEndDate ? new Date(globalSelectionEndDate) : null;
}

function setGlobalSelectionEndDate(date) {
  const lines = allPlanningLines();
  if (!lines.length || !date) return;

  const minDate = new Date(lines[0].date);
  const maxDate = new Date(lines[lines.length - 1].date);
  let value = new Date(date);

  if (value < minDate) value = minDate;
  if (value > maxDate) value = maxDate;

  globalSelectionEndDate = value;
}

function sameOrBeforeDay(date, endDate) {
  const a = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const b = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
  return a <= b;
}

function sequenceAllLines(sequenceKey) {
  return dayTaskLines
    .filter(line => line.sequenceKey === sequenceKey)
    .sort((a, b) => a.dayIndex - b.dayIndex);
}

function sequenceLinesInScope(sequenceKey) {
  const endDate = getGlobalSelectionEndDate();
  if (!endDate) return [];

  return sequenceAllLines(sequenceKey)
    .filter(line => sameOrBeforeDay(line.date, endDate));
}

function lineIsInSequenceScope(line) {
  const endDate = getGlobalSelectionEndDate();
  return !!endDate && sameOrBeforeDay(line.date, endDate);
}

function updateSequenceScopeEditor(sequenceKey = activeScopeSequenceKey) {
  activeScopeSequenceKey = sequenceKey || activeScopeSequenceKey || null;

  const lines = allPlanningLines();
  const endDate = getGlobalSelectionEndDate();

  if (!lines.length || !endDate) return;

  sequenceEndDateInput.disabled = false;
  scope30Btn.disabled = false;

  sequenceEndDateInput.min = dateOnlyKey(lines[0].date);
  sequenceEndDateInput.max = dateOnlyKey(lines[lines.length - 1].date);
  sequenceEndDateInput.value = dateOnlyKey(endDate);

  scopeSequenceLabel.textContent = "All sequences";

  const total = dayTaskLines.length;
  const included = dayTaskLines.filter(line => sameOrBeforeDay(line.date, endDate)).length;

  scopeSummary.textContent =
    `${included} of ${total} Day Task Lines in horizon · through ${endDate.toLocaleDateString("en-GB")}`;
}

function activateSequenceScope(sequenceKey, { render = true } = {}) {
  activeScopeSequenceKey = sequenceKey;
  getGlobalSelectionEndDate();
  updateSequenceScopeEditor(sequenceKey);
  if (render) renderRequest();
}

function setScopeToNext30Workdays() {
  const lines = allPlanningLines();
  if (!lines.length) return;

  const uniqueWorkdays = [];
  const seen = new Set();

  lines.forEach(line => {
    const key = dateOnlyKey(line.date);
    if (!seen.has(key)) {
      seen.add(key);
      uniqueWorkdays.push(new Date(line.date));
    }
  });

  setGlobalSelectionEndDate(
    uniqueWorkdays[Math.min(29, uniqueWorkdays.length - 1)]
  );

  updateSequenceScopeEditor(activeScopeSequenceKey);
  renderRequest();
}

function resourceHasSkill(resource, skill) {
  return !skill || resource.skills.includes(skill);
}

function appliedResourceSkillFilter() {
  return manualSkillFilter || activeSkillFilter || null;
}

function updateResourceFilterUi() {
  const skill = appliedResourceSkillFilter();
  const source = manualSkillFilter ? "manual" : activeSkillFilter ? "sequence" : "none";
  const active = !!skill;

  resourceFilterSummary.textContent =
    !active
      ? ""
      : skill === "Assigned"
        ? `Assigned: ${activeSkillFilter || "—"}`
        : `Skill: ${skill}`;

  manualFilterBtn.title =
    active
      ? `Applied filter: ${skill} (${source})`
      : "Applied filter: none";

  resetFilterBtn.title =
    active
      ? `Clear applied filter: ${skill}`
      : "No resource-skill filter is currently applied";

  manualFilterBtn.classList.toggle("filter-is-active", active);
  resetFilterBtn.disabled = !active;
  filterActiveDot.classList.toggle("visible", active);

  manualFilterBtn.setAttribute("aria-pressed", active ? "true" : "false");
}

function resourceHasAcceptedAssignment(resourceId) {
  return dayTaskLines.some(
    line =>
      line.assignedResource === resourceId &&
      line.sequenceAccepted
  );
}

function requestedSkillForLine(line) {
  return (
    line?.requiredSkill ||
    sequenceRequiredSkill(line?.sequenceKey) ||
    ""
  );
}

function effectiveResourceFilterSkill() {
  const filter = appliedResourceSkillFilter();

  return filter === "Assigned"
    ? (activeSkillFilter || "")
    : (filter || "");
}

function resourceVisibleOnlyByAssignedSkill(resource) {
  const skill = effectiveResourceFilterSkill();

  if (!resource || !skill) return false;
  if (resourceHasSkill(resource, skill)) return false;

  return dayTaskLines.some(line =>
    line.assignedResource === resource.key &&
    requestedSkillForLine(line) === skill
  );
}

function isoWeekNumber(dateValue) {
  const date =
    dateValue instanceof Date
      ? new Date(dateValue)
      : new Date(dateValue);

  if (Number.isNaN(date.getTime())) return "";

  const utcDate = new Date(
    Date.UTC(
      date.getFullYear(),
      date.getMonth(),
      date.getDate()
    )
  );

  const day = utcDate.getUTCDay() || 7;
  utcDate.setUTCDate(
    utcDate.getUTCDate() + 4 - day
  );

  const yearStart =
    new Date(
      Date.UTC(
        utcDate.getUTCFullYear(),
        0,
        1
      )
    );

  return Math.ceil(
    (((utcDate - yearStart) / 86400000) + 1) / 7
  );
}

function formatStandardTooltipDate(dateValue) {
  const date =
    dateValue instanceof Date
      ? dateValue
      : new Date(dateValue);

  if (Number.isNaN(date.getTime())) return "";

  const weekday =
    date.toLocaleDateString(
      undefined,
      { weekday: "long" }
    );

  const month =
    date.toLocaleDateString(
      undefined,
      { month: "short" }
    );

  return (
    `${weekday} (wk ${isoWeekNumber(date)}) ` +
    `${month} ${date.getDate()}, ${date.getFullYear()}`
  );
}

function decorateDayScaleWeekNumbers(rootId) {
  const root =
    document.getElementById(rootId);

  if (!root) return;

  const scale =
    root.querySelector(".dhx_cal_scale");

  if (!scale) return;

  const bars =
    [...scale.querySelectorAll(".dhx_scale_bar")];

  if (!bars.length) return;

  const rows = new Map();

  bars.forEach(bar => {
    const top =
      Math.round(
        bar.getBoundingClientRect().top
      );

    if (!rows.has(top)) {
      rows.set(top, []);
    }

    rows.get(top).push(bar);
  });

  const orderedRows =
    [...rows.entries()]
      .sort((a, b) => a[0] - b[0])
      .map(([, cells]) => cells);

  if (orderedRows.length < 2) return;

  const dayCells =
    orderedRows[0].length < orderedRows[1].length
      ? orderedRows[0]
      : orderedRows[1];

  const start =
    new Date(getPlanningStart());

  let dayIndex = 0;

  dayCells.forEach(cell => {
    if (cell.querySelector(".planner-week-number")) {
      dayIndex += 1;
      return;
    }

    const date =
      workdays[dayIndex]
        ? new Date(workdays[dayIndex])
        : new Date(
            start.getFullYear(),
            start.getMonth(),
            start.getDate() + dayIndex
          );

    const badge =
      document.createElement("span");

    badge.className =
      "planner-week-number";

    badge.textContent =
      String(isoWeekNumber(date));

    cell.style.position = "relative";
    cell.appendChild(badge);

    dayIndex += 1;
  });
}

function decorateDayHeaders() {
  decorateDayScaleWeekNumbers("requestScheduler");
  decorateDayScaleWeekNumbers("resourceScheduler");
}

function formatPlannerDate(dateValue) {
  const date =
    dateValue instanceof Date
      ? dateValue
      : new Date(dateValue);

  if (Number.isNaN(date.getTime())) {
    return "";
  }

  return date.toLocaleDateString(
    undefined,
    {
      day: "2-digit",
      month: "short",
      year: "numeric"
    }
  );
}

function formatRequestTooltipTime(hourValue) {
  if (!Number.isFinite(hourValue)) return "—";

  const totalMinutes = Math.round(hourValue * 60);
  const hours = Math.floor(totalMinutes / 60) % 24;
  const minutes = totalMinutes % 60;

  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`;
}

function formatPlannerTimeRange(start, duration) {
  if (
    !Number.isFinite(start) ||
    !Number.isFinite(duration)
  ) {
    return "—";
  }

  return (
    `${formatRequestTooltipTime(start)}–` +
    `${formatRequestTooltipTime(start + duration)}`
  );
}

function requestTooltipHtml(line) {
  if (!line) return "";

  const skill =
    line.requiredSkill ||
    sequenceRequiredSkill(line.sequenceKey) ||
    "—";

  const sequenceNo =
    line.seq ??
    sequenceRows.find(row => row.key === line.sequenceKey)?.seq ??
    "—";

  const jobNo =
    line.projectId || "—";

  const jobDescription =
    line.projectName || "—";

  const taskNo =
    line.taskId || "—";

  const taskDescription =
    line.taskName || "—";

  const resource =
    findResource(line.assignedResource);

  const requestedTime =
    formatPlannerTimeRange(
      line.requestedStart,
      line.requestedDuration
    );

  const assignedTime =
    line.assignedResource
      ? formatPlannerTimeRange(
          line.assignedStart,
          line.assignedDuration
        )
      : "—";

  const assignedResource =
    resource?.label || "—";

  const timeChanged =
    !!line.assignedResource &&
    (
      line.requestedStart !== line.assignedStart ||
      line.requestedDuration !== line.assignedDuration
    );

  return `
    <div class="standard-tooltip-context">
      <div class="standard-tooltip-context-title">Job and Task</div>
      <div class="standard-tooltip-context-line">${jobNo} — ${jobDescription}</div>
      <div class="standard-tooltip-context-line">${taskNo} — ${taskDescription}</div>
    </div>

    <div class="standard-tooltip-head">
      <div class="standard-tooltip-title">Skill: ${skill}</div>
      <div class="standard-tooltip-detail">Sqnc ${sequenceNo}</div>
      <div class="standard-tooltip-detail">${new Date(line.date).toLocaleDateString(undefined, { weekday: "long" })} (wk ${isoWeekNumber(line.date)})</div>
      <div class="standard-tooltip-detail">${new Date(line.date).toLocaleDateString(undefined, { month: "short", day: "2-digit", year: "numeric" })}</div>
    </div>

    <table class="standard-tooltip-table">
      <thead>
        <tr>
          <th></th>
          <th>Request</th>
          <th>Assigned</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>Time</th>
          <td>${requestedTime}</td>
          <td class="${timeChanged ? "standard-tooltip-different" : ""}">${assignedTime}</td>
        </tr>
        <tr>
          <th>Resource</th>
          <td>—</td>
          <td>${assignedResource}</td>
        </tr>
      </tbody>
    </table>`;
}

function moveRequestTooltip(clientX, clientY) {
  if (
    !requestDetailTooltip ||
    requestDetailTooltip.hidden
  ) {
    return;
  }

  const offsetX = 14;
  const offsetY = 16;
  const rect =
    requestDetailTooltip.getBoundingClientRect();

  const left = Math.min(
    window.innerWidth - rect.width - 6,
    clientX + offsetX
  );

  const top = Math.min(
    window.innerHeight - rect.height - 6,
    clientY + offsetY
  );

  requestDetailTooltip.style.left =
    `${Math.max(6, left)}px`;

  requestDetailTooltip.style.top =
    `${Math.max(6, top)}px`;
}

function showRequestTooltip(line, clientX, clientY) {
  if (!requestDetailTooltip || !line) return;

  requestDetailTooltip.innerHTML =
    requestTooltipHtml(line);

  requestDetailTooltip.hidden = false;

  moveRequestTooltip(clientX, clientY);
}

function hideRequestTooltip() {
  if (!requestDetailTooltip) return;
  requestDetailTooltip.hidden = true;
}

function formatWarningDate(dateValue) {
  const date =
    dateValue instanceof Date
      ? dateValue
      : new Date(dateValue);

  if (Number.isNaN(date.getTime())) {
    return "";
  }

  return date.toLocaleDateString(
    undefined,
    {
      day: "2-digit",
      month: "short",
      year: "numeric"
    }
  );
}

function resourceAssignedSkillProblemDates(resource, skill) {
  if (!resource || !skill) return [];

  const unique = new Map();

  dayTaskLines
    .filter(line =>
      line.assignedResource === resource.key &&
      requestedSkillForLine(line) === skill
    )
    .forEach(line => {
      const date =
        line.date instanceof Date
          ? line.date
          : new Date(line.date);

      if (Number.isNaN(date.getTime())) return;

      const key =
        `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;

      unique.set(key, date);
    });

  return [...unique.values()]
    .sort((a, b) => a - b);
}

function resourceAssignedSkillWarningText(resource) {
  const skill = effectiveResourceFilterSkill();

  if (!resource || !skill) return "";

  return (
    `The requested skill ${skill} is not included in the skill set of ${resource.label}.`
  );
}

function resourceSkillWarningTooltipHtml(resource) {
  const skill = effectiveResourceFilterSkill();
  if (!resource || !skill) return "";

  const reason =
    resourceAssignedSkillWarningText(resource);

  const dates =
    resourceAssignedSkillProblemDates(
      resource,
      skill
    );

  const dateHtml =
    dates.length
      ? dates
          .map(date =>
            `<span class="resource-warning-date">${formatWarningDate(date)}</span>`
          )
          .join("")
      : `<span class="resource-warning-date">—</span>`;

  return `
    <div class="resource-warning-title">
      Skill warning
    </div>
    <table class="resource-warning-table">
      <tbody>
        <tr>
          <th>Resource</th>
          <td>${resource.label}</td>
        </tr>
        <tr>
          <th>Requested skill</th>
          <td class="resource-warning-problem">${skill} ⚠</td>
        </tr>
        <tr>
          <th>Reason</th>
          <td>${reason}</td>
        </tr>
        <tr>
          <th>Problem dates</th>
          <td>
            <div class="resource-warning-dates">
              ${dateHtml}
            </div>
          </td>
        </tr>
      </tbody>
    </table>`;
}

function moveResourceSkillWarningTooltip(clientX, clientY) {
  if (
    !resourceSkillWarningTooltip ||
    resourceSkillWarningTooltip.hidden
  ) {
    return;
  }

  const offsetX = 14;
  const offsetY = 16;
  const rect =
    resourceSkillWarningTooltip.getBoundingClientRect();

  const left = Math.min(
    window.innerWidth - rect.width - 6,
    clientX + offsetX
  );

  const top = Math.min(
    window.innerHeight - rect.height - 6,
    clientY + offsetY
  );

  resourceSkillWarningTooltip.style.left =
    `${Math.max(6, left)}px`;

  resourceSkillWarningTooltip.style.top =
    `${Math.max(6, top)}px`;
}

function showResourceSkillWarningTooltip(resource, clientX, clientY) {
  if (!resourceSkillWarningTooltip || !resource) return;

  resourceSkillWarningTooltip.innerHTML =
    resourceSkillWarningTooltipHtml(resource);

  resourceSkillWarningTooltip.hidden = false;

  moveResourceSkillWarningTooltip(
    clientX,
    clientY
  );
}

function hideResourceSkillWarningTooltip() {
  if (!resourceSkillWarningTooltip) return;

  resourceSkillWarningTooltip.hidden = true;
}

function visibleResources() {
  const skill = appliedResourceSkillFilter();

  if (!skill) {
    return resources;
  }

  if (skill === "Assigned") {
    if (!activeSkillFilter) {
      return [];
    }

    return resources.filter(resource =>
      assignedResourceSkillSets.get(resource.key)?.has(activeSkillFilter)
    );
  }

  return resources.filter(resource =>
    resourceHasSkill(resource, skill) ||
    assignedResourceSkillSets.get(resource.key)?.has(skill)
  );
}

function resourceIsSkillCandidate(resourceId) {
  const resource = findResource(resourceId);
  const filter = appliedResourceSkillFilter();

  if (!resource) return false;

  if (filter === "Assigned") {
    return !!activeSkillFilter && resourceHasSkill(resource, activeSkillFilter);
  }

  return resourceHasSkill(resource, filter);
}

function activateSkillFilter(sequenceKey, { render = true } = {}) {
  const skill = sequenceRequiredSkill(sequenceKey);
  if (!skill) return;

  activeSkillSequenceKey = sequenceKey;
  activeSkillFilter = skill;
  updateResourceFilterUi();

  if (render) {
    renderResources();
    renderRequest();
  }

  const applied = appliedResourceSkillFilter();
  dragStatus.textContent =
    `Required skill: ${skill}` +
    (manualSkillFilter ? ` · manual filter overrides with ${applied}` : "") +
    ` · showing ${visibleResources().length} resource row${visibleResources().length === 1 ? "" : "s"}`;
}

function clearSkillFilter({ render = true } = {}) {
  activeSkillFilter = null;
  activeSkillSequenceKey = null;
  updateResourceFilterUi();

  if (render) {
    renderResources();
    renderRequest();
  }
}

function capacityFor(resourceId, dayIndex) {
  return capacitySlotIndex.get(`${resourceId}|${dayIndex}`) || [];
}

function capacityForDate(resourceId, date) {
  if (isWeekend(date)) return [];

  const dayIndex = workdays.findIndex(day =>
    day.getFullYear() === date.getFullYear() &&
    day.getMonth() === date.getMonth() &&
    day.getDate() === date.getDate()
  );

  if (dayIndex < 0) return [];
  return capacityFor(resourceId, dayIndex);
}

function lineFitsCapacity(line, resourceId) {
  const requestEnd = line.assignedStart + line.assignedDuration;
  return capacityFor(resourceId, line.dayIndex).some(
    slot => line.assignedStart >= slot.start && requestEnd <= slot.end
  );
}

function validateCapacity(lines, resourceId) {
  const invalid = (lines || []).filter(line => !lineFitsCapacity(line, resourceId));
  return { ok: invalid.length === 0, invalid };
}

function capacityHourAvailable(resourceId, date) {
  if (isWeekend(date)) return false;

  const hour = date.getHours();
  return capacityForDate(resourceId, date).some(
    slot => hour >= slot.start && hour < slot.end
  );
}

function formatHour(hour) {
  const h = Math.floor(hour);
  const m = Math.round((hour - h) * 60);
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}

function ensureLowerTimelineLeftShield() {
  const root =
    document.getElementById("resourceScheduler");

  const data =
    root?.querySelector(".dhx_cal_data");

  const resourceCell =
    root?.querySelector(".dhx_matrix_scell");

  if (!root || !data || !resourceCell) return;

  let shield =
    root.querySelector(".timeline-left-shield");

  if (!shield) {
    shield = document.createElement("div");
    shield.className = "timeline-left-shield";
    root.appendChild(shield);
  }

  const rootRect =
    root.getBoundingClientRect();
  const dataRect =
    data.getBoundingClientRect();
  const resourceRect =
    resourceCell.getBoundingClientRect();

  const width =
    Math.max(
      0,
      resourceRect.right -
      rootRect.left +
      2
    );

  shield.style.left = "0px";
  shield.style.top =
    `${dataRect.top - rootRect.top}px`;
  shield.style.width =
    `${width}px`;
  shield.style.height =
    `${data.clientHeight}px`;
}

function ensureCapacityOverlayLayer(root, data) {
  let layer = root.querySelector(".capacity-overlay-layer");

  if (!layer) {
    layer = document.createElement("div");
    layer.className = "capacity-overlay-layer";
    root.appendChild(layer);
  }

  const rootRect = root.getBoundingClientRect();
  const dataRect = data.getBoundingClientRect();

  const resourceCell =
    root.querySelector(".dhx_matrix_scell");

  const resourceCellRect =
    resourceCell?.getBoundingClientRect();

  const timelineLeftAbs =
    resourceCellRect?.right ?? dataRect.left;

  const dataRightAbs =
    dataRect.left + data.clientWidth;

  const timelineWidth =
    Math.max(0, dataRightAbs - timelineLeftAbs);

  layer.style.left =
    `${timelineLeftAbs - rootRect.left}px`;
  layer.style.top =
    `${dataRect.top - rootRect.top}px`;
  layer.style.width =
    `${timelineWidth}px`;
  layer.style.height =
    `${data.clientHeight}px`;

  return layer;
}

function clearRequestBaselineMarkers() {
  document
    .querySelectorAll("#resourceScheduler .assignment-request-baseline")
    .forEach(element => element.remove());
}

function drawRequestBaselineMarkers() {
  clearRequestBaselineMarkers();

  const schedulerRoot =
    document.getElementById("resourceScheduler");

  if (!schedulerRoot) return;

  dayTaskLines
    .filter(line => {
      if (!line.assignedResource) return false;

      const requestedStart = Number(line.requestedStart);
      const requestedEnd =
        requestedStart + Number(line.requestedDuration);

      const assignedStart = Number(line.assignedStart);
      const assignedEnd =
        assignedStart + Number(line.assignedDuration);

      return (
        requestedStart !== assignedStart ||
        requestedEnd !== assignedEnd
      );
    })
    .forEach(line => {
      const assignmentEventId = `ASG-${line.id}`;

      const assignmentElement =
        schedulerRoot.querySelector(
          `.dhx_cal_event_line[event_id="${assignmentEventId}"], ` +
          `.dhx_cal_event_line[data-event-id="${assignmentEventId}"]`
        );

      if (!assignmentElement) return;

      let assignmentEvent = null;

      try {
        assignmentEvent =
          resourceScheduler.getEvent(assignmentEventId);
      } catch (_error) {
        return;
      }

      if (!assignmentEvent) return;

      const assignmentRect =
        assignmentElement.getBoundingClientRect();

      const schedulerRect =
        schedulerRoot.getBoundingClientRect();

      const assignedStart =
        Number(line.assignedStart);

      const assignedDuration =
        Number(line.assignedDuration);

      const requestedStart =
        Number(line.requestedStart);

      const requestedDuration =
        Number(line.requestedDuration);

      if (
        !Number.isFinite(assignedStart) ||
        !Number.isFinite(assignedDuration) ||
        !Number.isFinite(requestedStart) ||
        !Number.isFinite(requestedDuration) ||
        assignedDuration <= 0
      ) {
        return;
      }

      const pixelsPerHour =
        assignmentRect.width / assignedDuration;

      const requestedLeft =
        assignmentRect.left -
        schedulerRect.left +
        (requestedStart - assignedStart) * pixelsPerHour;

      const requestedWidth =
        requestedDuration * pixelsPerHour;

      const requestedSkill =
        line.requiredSkill ||
        sequenceRequiredSkill(line.sequenceKey);

      const skillColor =
        getSkillColor(requestedSkill);

      const marker =
        document.createElement("div");

      marker.className =
        "assignment-request-baseline";

      marker.dataset.dayTaskLineId =
        String(line.id);

      marker.style.left =
        `${requestedLeft}px`;

      marker.style.top =
        `${assignmentRect.bottom - schedulerRect.top - 1}px`;

      marker.style.width =
        `${Math.max(4, requestedWidth)}px`;

      marker.style.backgroundColor = "#D9534F";

      marker.style.borderColor = "#D9534F";

      schedulerRoot.appendChild(marker);
    });
}

function drawCapacitySlotLabels() {
  ensureLowerTimelineLeftShield();

  const root =
    document.getElementById("resourceScheduler");
  const data =
    root?.querySelector(".dhx_cal_data");

  if (!root || !data) return;

  const timeline =
    resourceScheduler.getView("resources");

  if (
    !timeline ||
    typeof timeline.posFromDate !== "function" ||
    typeof timeline.getSectionTop !== "function" ||
    typeof timeline.getScrollPosition !== "function"
  ) {
    return;
  }

  const layer =
    ensureCapacityOverlayLayer(root, data);

  layer.replaceChildren();

  const scroll =
    timeline.getScrollPosition() || {
      left: 0,
      top: 0
    };

  const viewportWidth =
    layer.clientWidth;
  const viewportHeight =
    layer.clientHeight;

  const capacityTopInset = 8;
  const capacityHeight = 32;

  capacitySlots.forEach(
    (slot, capacityIndex) => {
      const slotDate =
        workdays[slot.dayIndex];

      if (!slotDate || isWeekend(slotDate)) {
        return;
      }

      const currentResources =
        visibleResources();

      if (
        !currentResources.some(
          resource =>
            resource.key === slot.resourceId
        )
      ) {
        return;
      }

      const startDate =
        atTime(slotDate, slot.start);
      const endDate =
        atTime(slotDate, slot.end);

      const contentLeft =
        timeline.posFromDate(startDate);
      const contentRight =
        timeline.posFromDate(endDate);

      if (
        !Number.isFinite(contentLeft) ||
        !Number.isFinite(contentRight)
      ) {
        return;
      }

      const left =
        contentLeft - scroll.left;
      const width =
        Math.max(1, contentRight - contentLeft);

      if (
        left + width <= 0 ||
        left >= viewportWidth
      ) {
        return;
      }

      const sectionTop =
        timeline.getSectionTop(
          slot.resourceId
        );

      if (
        !Number.isFinite(sectionTop) ||
        sectionTop < 0
      ) {
        return;
      }

      const top =
        sectionTop -
        scroll.top +
        capacityTopInset;

      if (
        top + capacityHeight <= 0 ||
        top >= viewportHeight
      ) {
        return;
      }

      const overlay =
        document.createElement("div");

      overlay.className =
        "capacity-slot-overlay";

      overlay.dataset.resourceId =
        slot.resourceId;
      overlay.dataset.capacityIndex =
        String(capacityIndex);

      const oneHourRight =
        timeline.posFromDate(
          atTime(
            slotDate,
            Math.min(
              currentWorkdayEnd,
              slot.start + 1
            )
          )
        );

      const cellWidth =
        Math.max(
          1,
          oneHourRight - contentLeft
        );

      overlay.dataset.cellWidth =
        String(cellWidth);

      overlay.title =
        `Capacity ${formatHour(slot.start)}–${formatHour(slot.end)} · drag left/right to move`;

      overlay.style.left =
        `${left}px`;
      overlay.style.top =
        `${top}px`;
      overlay.style.width =
        `${width}px`;

      overlay.innerHTML =
        `<span class="capacity-slot-label">${formatHour(slot.start)}–${formatHour(slot.end)}</span>`;

      layer.appendChild(overlay);
    }
  );

  requestAnimationFrame(() => {
    drawRequestBaselineMarkers();
  });
}

function capacityFailureText(lines, resourceId) {
  const resource = findResource(resourceId);
  const validation = validateCapacity(lines, resourceId);
  if (validation.ok) return "";

  if (validation.invalid.length === 1) {
    const line = validation.invalid[0];
    const day = line.date.toLocaleDateString("en-GB", {
      weekday: "short",
      day: "2-digit",
      month: "short"
    });
    return `${resource.label}: ${line.projectId} / ${line.taskId} / Seq ${line.seq} on ${day} does not fit capacity.`;
  }

  return `${resource.label}: ${validation.invalid.length} of ${lines.length} time slots do not fit capacity.`;
}

// Sequence rows / Job > Job Task > Sequence tree are rebuilt every time
// SetPlanningData() delivers fresh data (see applyPlanningData below).
// A "Sequence" row's identity is the distinct (Job No., Job Task No., Skill,
// Sequence No.) combination already carried on each Day Task Line as
// `sequenceKey` (AL includes the real "Sequence No." in that key - see
// codeunit 50604's ReqAssign_BuildDayTaskLinesJson), so two independently-
// created threads sharing the same Job/Task/Skill (e.g. "Elektrisch - Seq 1"
// and "- Seq 2") render as separate rows here, matching the Day Planning
// Sequence add-in's own row grouping. `seq` is the real numeric Sequence No.
function rebuildRequestTree() {
  const rowsByKey = new Map();

  allPlanningLines().forEach(line => {
    if (!rowsByKey.has(line.sequenceKey)) {
      rowsByKey.set(line.sequenceKey, {
        key: line.sequenceKey,
        label: `${line.requiredSkill} - Seq ${line.seq}`,
        projectId: line.projectId,
        projectName: line.projectName,
        taskId: line.taskId,
        taskName: line.taskName,
        seq: line.seq,
        description: `${line.requiredSkill} - Seq ${line.seq}`,
        requiredSkill: line.requiredSkill,
        kind: "sequence"
      });
    }
  });

  sequenceRows = Array.from(rowsByKey.values());
  rebuildSequenceRowsByKey();

  const projectMap = new Map();

  sequenceRows.forEach(row => {
    if (!projectMap.has(row.projectId)) {
      projectMap.set(row.projectId, {
        key: `PROJECT-${row.projectId}`,
        label: `${row.projectId} — ${row.projectName}`,
        projectId: row.projectId,
        projectName: row.projectName,
        kind: "project",
        open: true,
        children: []
      });
    }

    const project = projectMap.get(row.projectId);
    let task = project.children.find(child => child.taskId === row.taskId);

    if (!task) {
      task = {
        key: `TASK-${row.projectId}-${row.taskId}`,
        label: `${row.taskId} — ${row.taskName}`,
        projectId: row.projectId,
        projectName: row.projectName,
        taskId: row.taskId,
        taskName: row.taskName,
        kind: "task",
        open: true,
        children: []
      };
      project.children.push(task);
    }

    task.children.push(row);
  });

  requestTree = Array.from(projectMap.values());
}

function filteredRequestTree() {
  const filterBySkill =
    sequenceSkillBehavior === "filter" &&
    !!activeSkillFilter;

  return requestTree
    .filter(project =>
      !requestJobFilter ||
      project.projectId === requestJobFilter
    )
    .map(project => {
      const filteredTasks = project.children
        .filter(task =>
          !requestTaskFilter ||
          task.taskId === requestTaskFilter
        )
        .map(task => ({
          ...task,
          children: task.children.filter(sequence =>
            !filterBySkill ||
            sequence.requiredSkill === activeSkillFilter
          )
        }))
        .filter(task => task.children.length > 0);

      return {
        ...project,
        children: filteredTasks
      };
    })
    .filter(project => project.children.length > 0);
}

function requestLineMatchesFilters(line) {
  if (requestJobFilter && line.projectId !== requestJobFilter) return false;
  if (requestTaskFilter && line.taskId !== requestTaskFilter) return false;

  if (
    sequenceSkillBehavior === "filter" &&
    activeSkillFilter &&
    line.requiredSkill !== activeSkillFilter
  ) {
    return false;
  }

  return true;
}

function populateRequestFilters() {
  const currentJob = pendingRequestJobFilter;
  const currentTask = pendingRequestTaskFilter;

  jobFilterSelect.innerHTML = '<option value="">All</option>';

  requestTree.forEach(project => {
    const option = document.createElement("option");
    option.value = project.projectId;
    option.textContent = `${project.projectId} — ${project.projectName}`;
    jobFilterSelect.appendChild(option);
  });

  jobFilterSelect.value = currentJob;

  const availableTasks = requestTree
    .filter(project =>
      !currentJob || project.projectId === currentJob
    )
    .flatMap(project =>
      project.children.map(task => ({
        projectId: project.projectId,
        taskId: task.taskId,
        taskName: task.taskName
      }))
    );

  taskFilterSelect.innerHTML = '<option value="">All</option>';

  availableTasks.forEach(task => {
    const option = document.createElement("option");
    option.value = task.taskId;
    option.textContent = currentJob
      ? `${task.taskId} — ${task.taskName}`
      : `${task.projectId} / ${task.taskId} — ${task.taskName}`;
    taskFilterSelect.appendChild(option);
  });

  if (
    currentTask &&
    !availableTasks.some(task => task.taskId === currentTask)
  ) {
    pendingRequestTaskFilter = "";
  }

  taskFilterSelect.value = pendingRequestTaskFilter;
}

function updateRequestFilterUi() {
  const active =
    !!requestJobFilter || !!requestTaskFilter;

  requestFilterBtn.classList.toggle(
    "filter-active",
    active
  );

  requestFilterActiveDot.classList.toggle(
    "visible",
    active
  );

  clearRequestFilterBtn.disabled = !active;

  if (!active) {
    requestFilterSummary.hidden = true;
    requestFilterSummary.textContent = "";
    requestFilterBtn.title = "Filter Request by Job / Task";
    return;
  }

  const parts = [];

  if (requestJobFilter) {
    parts.push(`Job: ${requestJobFilter}`);
  }

  if (requestTaskFilter) {
    parts.push(`Task: ${requestTaskFilter}`);
  }

  const summary = parts.join(" / ");

  requestFilterSummary.textContent = summary;
  requestFilterSummary.hidden = false;
  requestFilterBtn.title = summary;
}

function applyRequestFilters() {
  requestJobFilter = pendingRequestJobFilter;
  requestTaskFilter = pendingRequestTaskFilter;

  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;

  requestFilterPopover.hidden = true;

  updateRequestFilterUi();
  renderRequest();
}

const selectedLineIds = new Set();
let selectedSequenceKey = null;
let selectionAnchorId = null;

// Whole-sequence drops remain provisional until accepted.
// Multiple provisional sequences can exist at the same time.
const pendingSequences = new Map(); // sequenceKey -> { resourceId }

let acceptedLeftResize = null;
let capacityMoveDrag = null;

const undoStack = [];

function getSelectedLines() {
  return dayTaskLines
    .filter(line => selectedLineIds.has(line.id))
    .filter(line => line.sequenceAccepted || lineIsInSequenceScope(line))
    .sort((a, b) => a.dayIndex - b.dayIndex);
}

function clearSelection({ render = true } = {}) {
  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;
  clearSkillFilter({ render: true });
  if (render) renderRequest();
}

function setSingleSelection(line, { render = true } = {}) {
  selectedLineIds.clear();
  selectedLineIds.add(line.id);
  selectedSequenceKey = line.sequenceKey;
  selectionAnchorId = line.id;

  activateSkillFilter(line.sequenceKey, { render: true });
  activateSequenceScope(line.sequenceKey, { render: false });

  if (render) renderRequest();

  requestAnimationFrame(() => {
    if (!sequenceEndDateInput.disabled) {
      sequenceEndDateInput.focus();
    }
  });
}

function toggleSelection(line, { render = true } = {}) {
  // A multi-selection may never span more than one Sequence row.
  if (selectedSequenceKey && selectedSequenceKey !== line.sequenceKey) {
    selectedLineIds.clear();
    selectedSequenceKey = line.sequenceKey;
    selectionAnchorId = line.id;
    selectedLineIds.add(line.id);
    activateSkillFilter(line.sequenceKey, { render: true });
    activateSequenceScope(line.sequenceKey, { render: false });
    dragStatus.textContent =
      `Started a new selection on ${line.taskId} / Seq ${line.seq} · skill ${line.requiredSkill}. Selections cannot span Sequence rows.`;
    if (render) renderRequest();
    return;
  }

  selectedSequenceKey = line.sequenceKey;
  activateSkillFilter(line.sequenceKey, { render: true });
  activateSequenceScope(line.sequenceKey, { render: false });

  if (selectedLineIds.has(line.id)) {
    selectedLineIds.delete(line.id);
    if (selectionAnchorId === line.id) {
      selectionAnchorId = getSelectedLines()[0]?.id ?? null;
    }
  } else {
    selectedLineIds.add(line.id);
    selectionAnchorId = line.id;
  }

  if (selectedLineIds.size === 0) {
    selectedSequenceKey = null;
    selectionAnchorId = null;
    clearSkillFilter({ render: true });
  }

  if (render) renderRequest();
}

function selectRange(line, { render = true } = {}) {
  const anchor = selectionAnchorId ? findLine(selectionAnchorId) : null;

  if (!anchor || anchor.sequenceKey !== line.sequenceKey) {
    setSingleSelection(line, { render });
    return;
  }

  const from = Math.min(anchor.dayIndex, line.dayIndex);
  const to = Math.max(anchor.dayIndex, line.dayIndex);

  selectedLineIds.clear();
  dayTaskLines
    .filter(item =>
      item.sequenceKey === line.sequenceKey &&
      item.dayIndex >= from &&
      item.dayIndex <= to
    )
    .forEach(item => selectedLineIds.add(item.id));

  selectedSequenceKey = line.sequenceKey;
  activateSkillFilter(line.sequenceKey, { render: true });
  if (render) renderRequest();
}

function describeSelection() {
  const lines = getSelectedLines();
  if (!lines.length) return "No Day Task Lines selected";

  const first = lines[0];
  if (lines.length === 1) {
    return `1 Day Task Line selected · ${first.taskId} / Seq ${first.seq}`;
  }

  return `${lines.length} Day Task Lines selected · ${first.taskId} / Seq ${first.seq}`;
}

function refreshSelectionClasses() {
  document
    .querySelectorAll("#requestScheduler .request-multi-selected")
    .forEach(el => el.classList.remove("request-multi-selected"));

  document
    .querySelectorAll("#requestScheduler .dhx_cal_event_line, #requestScheduler .dhx_cal_event")
    .forEach(el => {
      const lineId = lineIdFromRequestElement(el);
      if (
        lineId &&
        (selectedLineIds.has(lineId) || selectedLineIds.has(Number(lineId)))
      ) {
        el.classList.add("request-multi-selected");
      }
    });
}

function sequenceLines(sequenceKey) {
  return dayTaskLines.filter(line => line.sequenceKey === sequenceKey);
}

function sequenceIsPending(sequenceKey) {
  return pendingSequences.has(sequenceKey);
}

function sequenceIsAccepted(sequenceKey) {
  const lines = sequenceLines(sequenceKey);
  return lines.length > 0 && lines.every(line => line.sequenceAccepted);
}

// Mirrors the exact check the sequence-drag pointerdown handler uses to
// decide whether to show "All Day Task Lines in this Sequence are already
// assigned" instead of starting a drag - so the row's icon can predict that
// outcome up front instead of only surfacing it after a failed drag attempt.
function sequenceAllLinesAssigned(sequenceKey) {
  const lines = sequenceLinesInScope(sequenceKey);
  return lines.length > 0 && lines.every(line => !!line.assignedResource);
}

function pendingSequencesForResource(resourceId) {
  return Array.from(pendingSequences.entries())
    .filter(([, info]) => info.resourceId === resourceId)
    .map(([sequenceKey]) => sequenceKey);
}

function updateDecisionButtons() {
  const count = pendingSequences.size;

  acceptAllBtn.disabled = count === 0;
  acceptAllBtn.textContent = count ? `Accept All (${count})` : "Accept All";

  rejectAllBtn.disabled = count === 0;
  rejectAllBtn.textContent = count ? `Reject All (${count})` : "Reject All";
}

function acceptSequenceKeys(sequenceKeys, undoLabel) {
  const keys = [...new Set(sequenceKeys)].filter(key => pendingSequences.has(key));
  if (!keys.length || transferAnimating) return;

  const acceptedState = keys.map(key => {
    const info = pendingSequences.get(key);
    const lines = sequenceLines(key);
    return {
      sequenceKey: key,
      resourceId: info.resourceId,
      previousAccepted: lines.map(line => ({
        id: line.id,
        sequenceAccepted: line.sequenceAccepted
      }))
    };
  });

  undoStack.push({
    label: undoLabel,
    type: "accept-sequences",
    acceptedState
  });

  acceptedState.forEach(item => {
    const lines = sequenceLines(item.sequenceKey);

    lines.forEach(line => {
      line.sequenceAccepted = true;
    });
    pendingSequences.delete(item.sequenceKey);

    // This is the ONLY point where a whole-sequence drag actually persists —
    // the drop itself only staged it client-side (pendingSequences).
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAcceptSequence", [
      JSON.stringify({
        sequenceKey: item.sequenceKey,
        resourceId: item.resourceId,
        lines: lines.map(line => ({
          id: line.id,
          startHour: line.assignedStart,
          durationHours: line.assignedDuration
        }))
      })
    ]);
  });

  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;

  updateUndoButton();
  updateDecisionButtons();
  renderAll();
}

function acceptForResource(resourceId) {
  const keys = pendingSequencesForResource(resourceId);
  if (!keys.length) return;

  const resource = findResource(resourceId);
  acceptSequenceKeys(
    keys,
    `Accept ${keys.length} sequence${keys.length === 1 ? "" : "s"} on ${resource?.label ?? resourceId}`
  );

  resultStatus.textContent =
    `${keys.length} provisional sequence${keys.length === 1 ? "" : "s"} accepted on ${resource?.label ?? resourceId}.`;
  dragStatus.textContent = "Accepted — individual Day Task Lines are now independent.";
}

function acceptAllPending() {
  const keys = Array.from(pendingSequences.keys());
  if (!keys.length) return;

  acceptSequenceKeys(
    keys,
    `Accept all ${keys.length} provisional sequence${keys.length === 1 ? "" : "s"}`
  );

  resultStatus.textContent =
    `${keys.length} provisional sequence${keys.length === 1 ? "" : "s"} accepted.`;
  dragStatus.textContent = "All provisional sequences accepted.";
}

function rejectSequenceKeys(sequenceKeys, undoLabel) {
  if (transferAnimating) return;

  const keys = [...new Set(sequenceKeys)]
    .filter(key => pendingSequences.has(key));

  if (!keys.length) return;

  const rejectedState = keys.map(key => {
    const info = pendingSequences.get(key);
    const lines = sequenceLines(key);

    return {
      sequenceKey: key,
      resourceId: info.resourceId,
      previousState: lines.map(line => ({
        id: line.id,
        assignedResource: line.assignedResource,
        assignedDuration: line.assignedDuration,
        sequenceAccepted: line.sequenceAccepted
      }))
    };
  });

  undoStack.push({
    label: undoLabel,
    type: "reject-sequences",
    rejectedState
  });

  rejectedState.forEach(item => {
    sequenceLines(item.sequenceKey).forEach(line => {
      line.assignedResource = null;
      line.sequenceAccepted = false;
    });
    pendingSequences.delete(item.sequenceKey);

    // Nothing was ever persisted for a provisional sequence — Reject is
    // purely a client-side discard. AL is notified only so it can drop any
    // bookkeeping of its own (e.g. telemetry); it must not need to.
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnRejectSequence", [
      JSON.stringify({ sequenceKey: item.sequenceKey })
    ]);
  });

  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;

  updateUndoButton();
  updateDecisionButtons();
  renderAll();
}

function rejectForResource(resourceId) {
  const keys = pendingSequencesForResource(resourceId);
  if (!keys.length) return;

  const resource = findResource(resourceId);

  rejectSequenceKeys(
    keys,
    `Reject ${keys.length} sequence${keys.length === 1 ? "" : "s"} on ${resource?.label ?? resourceId}`
  );

  resultStatus.textContent =
    `${keys.length} provisional sequence${keys.length === 1 ? "" : "s"} rejected on ${resource?.label ?? resourceId}.`;
  dragStatus.textContent =
    "Rejected — the Day Task Lines are available for planning again.";
}

function rejectAllPending() {
  const keys = Array.from(pendingSequences.keys());
  if (!keys.length) return;

  rejectSequenceKeys(
    keys,
    `Reject all ${keys.length} provisional sequence${keys.length === 1 ? "" : "s"}`
  );

  resultStatus.textContent =
    `${keys.length} provisional sequence${keys.length === 1 ? "" : "s"} rejected.`;
  dragStatus.textContent = "All provisional sequences returned to request.";
}

function updateUndoButton() {
  undoBtn.disabled = undoStack.length === 0;
  if (undoStack.length === 0) {
    undoBtn.textContent = "Undo";
    undoBtn.title = "Nothing to undo";
  } else {
    const last = undoStack[undoStack.length - 1];
    undoBtn.textContent = "Undo";
    undoBtn.title = `Undo: ${last.label} (Ctrl+Z)`;
  }
}

function pushUndo(label, lines, metadata = {}) {
  undoStack.push({
    label,
    type: "assignment",
    state: lines.map(line => ({
      id: line.id,
      assignedResource: line.assignedResource
    })),
    ...metadata
  });
  updateUndoButton();
}

function undoLastAssignment() {
  if (transferAnimating) return;
  const action = undoStack.pop();
  if (!action) return;

  if (action.type === "accept-sequences") {
    action.acceptedState.forEach(item => {
      item.previousAccepted.forEach(previous => {
        const line = findLine(previous.id);
        if (line) line.sequenceAccepted = previous.sequenceAccepted;
      });
      pendingSequences.set(item.sequenceKey, { resourceId: item.resourceId });
    });
    updateDecisionButtons();
  } else if (action.type === "reject-sequences") {
    action.rejectedState.forEach(item => {
      item.previousState.forEach(previous => {
        const line = findLine(previous.id);
        if (line) {
          line.assignedResource = previous.assignedResource;
          line.assignedDuration = previous.assignedDuration;
          line.sequenceAccepted = previous.sequenceAccepted;
        }
      });
      pendingSequences.set(item.sequenceKey, { resourceId: item.resourceId });
    });
    updateDecisionButtons();
  } else if (action.type === "edit-accepted") {
    const line = findLine(action.lineId);
    if (line) {
      line.assignedResource = action.previous.assignedResource;
      line.assignedStart = action.previous.assignedStart;
      line.assignedDuration = action.previous.assignedDuration;
    }
  } else if (action.type === "capacity-move") {
    const slot = capacitySlots[action.capacityIndex];
    if (slot) {
      slot.start = action.previous.start;
      slot.end = action.previous.end;
    }
  } else if (action.type === "unassign-line") {
    restoreAssignmentSnapshot(action.previous);
  } else if (action.type === "unassign-sequence") {
    action.previous.forEach(restoreAssignmentSnapshot);

    if (action.pendingState) {
      pendingSequences.set(
        action.sequenceKey,
        action.pendingState
      );
      updateDecisionButtons();
    }
  } else {
    action.state.forEach(previous => {
      const line = findLine(previous.id);
      if (line) line.assignedResource = previous.assignedResource;
    });

    if (action.sequenceKey && pendingSequences.has(action.sequenceKey)) {
      pendingSequences.delete(action.sequenceKey);
      updateDecisionButtons();
    }
  }

  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;
  dragStatus.textContent = "Ready";
  resultStatus.textContent = `Undone: ${action.label}`;
  clearResourceDropHighlight();
  renderAll();
  updateUndoButton();
}

function requestEvents() {
  return dayTaskLines
    .filter(line => requestLineMatchesFilters(line))
    .map(line => ({
    id: line.id,
    text: `${line.requestedStart}:00–${line.requestedStart + line.requestedDuration}:00`,
    start_date: atTime(line.date, line.requestedStart),
    end_date: atTime(line.date, line.requestedStart + line.requestedDuration),
    sequence_id: line.sequenceKey,
    taskId: line.taskId,
    seq: line.seq,
    dayTaskLineId: line.id,
    assigned: !!line.assignedResource
  }));
}

function lineAssignmentTimeMatchesRequest(line) {
  if (!line || !line.assignedResource) return false;

  const requestedStart = Number(line.requestedStart);
  const requestedEnd =
    requestedStart + Number(line.requestedDuration);

  const assignedStart = Number(line.assignedStart);
  const assignedEnd =
    assignedStart + Number(line.assignedDuration);

  return (
    Math.abs(requestedStart - assignedStart) < 0.001 &&
    Math.abs(requestedEnd - assignedEnd) < 0.001
  );
}

function lineAssignmentSkillMatchesRequest(line) {
  if (!line || !line.assignedResource) return false;

  const resource =
    findResource(line.assignedResource);

  const requestedSkill =
    requestedSkillForLine(line);

  return (
    !!resource &&
    !!requestedSkill &&
    resourceHasSkill(resource, requestedSkill)
  );
}

function lineIsOk(line) {
  return (
    !!line?.sequenceAccepted &&
    lineAssignmentTimeMatchesRequest(line) &&
    lineAssignmentSkillMatchesRequest(line)
  );
}

function assignmentEvents() {
  const visibleIds = new Set(visibleResources().map(resource => resource.key));

  return dayTaskLines
    .filter(line =>
      (!activeSkillFilter || requestedSkillForLine(line) === activeSkillFilter) &&
      line.assignedResource &&
      (
        line.sequenceAccepted ||
        visibleIds.has(line.assignedResource)
      )
    )
    .map(line => {
      const resource = findResource(line.assignedResource);
      const conflict = !lineFitsCapacity(line, line.assignedResource);

      return {
        id: `ASG-${line.id}`,
        text: `${line.requiredSkill || sequenceRequiredSkill(line.sequence_id) || "—"} · ${line.taskId}/${line.seq}`,
        start_date: atTime(line.date, line.assignedStart),
        end_date: atTime(line.date, line.assignedStart + line.assignedDuration),
        resource_id: line.assignedResource,
        dayTaskLineId: line.id,
        conflict,
        accepted: !!line.sequenceAccepted,
        ok: lineIsOk(line),
        skill: requestedSkillForLine(line),
        skillMismatch: (() => {
          const assignedResource =
            findResource(line.assignedResource);

          const requestedSkill =
            requestedSkillForLine(line);

          return (
            !!assignedResource &&
            !!requestedSkill &&
            !resourceHasSkill(assignedResource, requestedSkill)
          );
        })(),
        timeMismatch: (() => {
          const requestedStart =
            Number(line.requestedStart ?? line.assignedStart);

          const requestedEnd =
            requestedStart +
            Number(line.requestedDuration ?? line.assignedDuration);

          const assignedStart =
            Number(line.assignedStart);

          const assignedEnd =
            assignedStart +
            Number(line.assignedDuration);

          return (
            Math.abs(requestedStart - assignedStart) > 0.001 ||
            Math.abs(requestedEnd - assignedEnd) > 0.001
          );
        })(),
        requestedStartHour: Number(line.requestedStart ?? line.assignedStart),
        requestEndHour:
          Number(line.requestedStart ?? line.assignedStart) +
          Number(line.requestedDuration ?? line.assignedDuration),
        showRequestBaseline: (() => {
          const requestedStart =
            Number(line.requestedStart ?? line.assignedStart);

          const requestEnd =
            requestedStart +
            Number(line.requestedDuration ?? line.assignedDuration);

          const assignedStart = Number(line.assignedStart);
          const assignedEnd =
            assignedStart + Number(line.assignedDuration);

          return (
            Math.abs(requestedStart - assignedStart) > 0.001 ||
            Math.abs(requestEnd - assignedEnd) > 0.001
          );
        })(),
        title: ""
      };
    });
}

function populatePlanningSetupInputs() {
  if (!workdayStartInput.options.length) {
    for (let hour = 0; hour <= 23; hour++) {
      const startOption = document.createElement("option");
      startOption.value = String(hour);
      startOption.textContent = `${String(hour).padStart(2, "0")}:00`;
      workdayStartInput.appendChild(startOption);

      const endOption = document.createElement("option");
      endOption.value = String(hour);
      endOption.textContent = `${String(hour).padStart(2, "0")}:00`;
      workdayEndInput.appendChild(endOption);
    }
  }

  showWeekendsInput.checked = showWeekends;
  workdayStartInput.value = String(currentWorkdayStart);
  workdayEndInput.value = String(currentWorkdayEnd);
  sequenceSkillBehaviorInput.value = sequenceSkillBehavior;
  hierarchyDensityInput.value = hierarchyDensity;
}

function updatePlanningSetupButtonUi() {
  planningSetupBtn.title =
    `Timeline setup: ${showWeekends ? "show" : "hide"} weekends · ` +
    `${formatHour(currentWorkdayStart)}–${formatHour(currentWorkdayEnd)}`;
}

function applySchedulerTimelineSetup(scheduler, viewName) {
  const view =
    scheduler.matrix?.[viewName] ||
    scheduler.getView?.();

  if (view) {
    view.x_start = currentWorkdayStart;
    view.x_size = getRangeHours();

    if (viewName === "request") {
      view.folder_dy =
        hierarchyDensity === "compact"
          ? 20
          : 34;
    }
  }

  const start = new Date(getPlanningStart());
  const end = new Date(getPlanningEnd());

  scheduler.setCurrentView(start, viewName);

  const activeView = scheduler.getView?.();
  if (activeView && typeof activeView.setRange === "function") {
    activeView.setRange(start, end);
    scheduler.setCurrentView(start, viewName);
  }
}

function applyPlanningSetup() {
  const nextShowWeekends = !!showWeekendsInput.checked;
  const nextStart = Number(workdayStartInput.value);
  const nextEnd = Number(workdayEndInput.value);
  const nextSequenceSkillBehavior =
    sequenceSkillBehaviorInput.value === "filter"
      ? "filter"
      : "highlight";
  const nextHierarchyDensity =
    hierarchyDensityInput.value === "normal"
      ? "normal"
      : "compact";

  if (!Number.isFinite(nextStart) || !Number.isFinite(nextEnd) || nextEnd <= nextStart) {
    dragStatus.textContent = "Setup error: end time must be later than start time.";
    return;
  }

  showWeekends = nextShowWeekends;
  currentWorkdayStart = nextStart;
  currentWorkdayEnd = nextEnd;
  sequenceSkillBehavior = nextSequenceSkillBehavior;
  hierarchyDensity = nextHierarchyDensity;

  document.body.classList.toggle(
    "hierarchy-density-normal",
    hierarchyDensity === "normal"
  );
  document.body.classList.toggle(
    "hierarchy-density-compact",
    hierarchyDensity === "compact"
  );

  updatePlanningSetupButtonUi();
  planningSetupPopover.hidden = true;

  applySchedulerTimelineSetup(requestScheduler, "request");
  applySchedulerTimelineSetup(resourceScheduler, "resources");

  renderAll();
  fitPlannerToViewport();

  dragStatus.textContent =
    `Timeline setup applied: ${showWeekends ? "weekends visible" : "weekends hidden"} · ` +
    `${formatHour(currentWorkdayStart)}–${formatHour(currentWorkdayEnd)}.`;
}

let contextMenuTarget = null;

function showSimplePopup(message) {
  simplePopupText.textContent = message;
  simplePopupBackdrop.hidden = false;
}

function hideSimplePopup() {
  simplePopupBackdrop.hidden = true;
}

function hideSlotContextMenu() {
  slotContextMenu.hidden = true;
  slotContextMenu.replaceChildren();
  contextMenuTarget = null;
}

function contextMenuIconSvg(kind) {
  if (kind === "unassign") {
    return `
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <path d="M8 6h10v12H8z"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"/>
        <path d="M3 12h9M3 12l3-3M3 12l3 3"
              fill="none"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"
              stroke-linejoin="round"/>
      </svg>`;
  }

  if (kind === "modify") {
    return `
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <path d="M5 17.5V20h2.5L18.7 8.8l-2.5-2.5L5 17.5z"
              fill="none"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linejoin="round"/>
        <path d="M14.9 7.6l2.5 2.5"
              fill="none"
              stroke="currentColor"
              stroke-width="1.6"
              stroke-linecap="round"/>
      </svg>`;
  }

  return `
    <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
      <rect x="4" y="3" width="16" height="18" rx="2"
            fill="none"
            stroke="currentColor"
            stroke-width="1.6"/>
      <path d="M8 8h8M8 12h8M8 16h5"
            fill="none"
            stroke="currentColor"
            stroke-width="1.6"
            stroke-linecap="round"/>
    </svg>`;
}

function addContextMenuItem({ caption, icon, action }) {
  const button = document.createElement("button");
  button.type = "button";
  button.innerHTML = `
    <span class="context-menu-icon" aria-hidden="true">
      ${contextMenuIconSvg(icon)}
    </span>
    <span>${caption}</span>`;

  button.addEventListener("click", event => {
    event.stopPropagation();
    hideSlotContextMenu();
    action?.();
  });

  slotContextMenu.appendChild(button);
}

function showSlotContextMenu(event, targetInfo) {
  event.preventDefault();
  event.stopPropagation();

  contextMenuTarget = targetInfo;
  slotContextMenu.replaceChildren();

  if (targetInfo.type === "sequence") {
    addContextMenuItem({
      caption: "Unassign",
      icon: "unassign",
      action: () => unassignSequence(targetInfo.sequenceKey)
    });

    addContextMenuItem({
      caption: "Modify sequence",
      icon: "modify",
      action: () => showSimplePopup("Under Construction")
    });
  }

  if (targetInfo.type === "request") {
    addContextMenuItem({
      caption: "Unassign",
      icon: "unassign",
      action: () => unassignDayTaskLine(targetInfo.lineId)
    });

    addContextMenuItem({
      caption: "Open Card",
      icon: "card",
      action: () => showSimplePopup("Under Construction")
    });
  }

  if (targetInfo.type === "assignment") {
    addContextMenuItem({
      caption: "Open Card",
      icon: "card",
      action: () => showSimplePopup("Under Construction")
    });
  }

  if (!slotContextMenu.children.length) return;

  slotContextMenu.hidden = false;

  const menuRect = slotContextMenu.getBoundingClientRect();
  const maxLeft = Math.max(4, window.innerWidth - menuRect.width - 4);
  const maxTop = Math.max(4, window.innerHeight - menuRect.height - 4);

  slotContextMenu.style.left = `${Math.min(event.clientX, maxLeft)}px`;
  slotContextMenu.style.top = `${Math.min(event.clientY, maxTop)}px`;
}

function snapshotAssignmentState(line) {
  return {
    lineId: line.id,
    assignedResource: line.assignedResource,
    sequenceAccepted: line.sequenceAccepted,
    assignedStart: line.assignedStart,
    assignedDuration: line.assignedDuration
  };
}

function restoreAssignmentSnapshot(snapshot) {
  const line = findLine(snapshot.lineId);
  if (!line) return;

  line.assignedResource = snapshot.assignedResource;
  line.sequenceAccepted = snapshot.sequenceAccepted;
  line.assignedStart = snapshot.assignedStart;
  line.assignedDuration = snapshot.assignedDuration;
}

function clearAssignmentState(line) {
  line.assignedResource = null;
  line.sequenceAccepted = false;
  line.assignedStart = line.requestedStart;
  line.assignedDuration = line.requestedDuration;
}

function unassignDayTaskLine(lineId) {
  const line = findLine(lineId);
  if (!line) return;

  if (!line.assignedResource) {
    renderAll();
    return;
  }

  undoStack.push({
    label: `Unassign ${line.taskId} / Sequence ${line.seq}`,
    type: "unassign-line",
    previous: snapshotAssignmentState(line)
  });

  // A pending (not-yet-accepted) sequence was never persisted, so unassigning
  // one of its lines has nothing to tell BC about.
  const wasPersisted = !pendingSequences.has(line.sequenceKey);

  clearAssignmentState(line);

  if (pendingSequences.has(line.sequenceKey)) {
    pendingSequences.delete(line.sequenceKey);
    updateDecisionButtons();
  }

  if (wasPersisted) {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnUnassignDayTaskLine", [
      JSON.stringify({ id: line.id })
    ]);
  }

  selectedLineIds.clear();
  selectedLineIds.add(line.id);
  selectedSequenceKey = line.sequenceKey;
  selectionAnchorId = line.id;

  updateUndoButton();
  renderAll();
}

function unassignSequence(sequenceKey) {
  if (!selectedSequenceKey || selectedSequenceKey !== sequenceKey) {
    showSimplePopup("Select a Sequence first before using Unassign.");
    return;
  }

  const lines = sequenceLines(sequenceKey);
  const assignedLines = lines.filter(line => !!line.assignedResource);

  if (!assignedLines.length) {
    showSimplePopup("No assigned Day Task Lines");
    return;
  }

  const wasPending = pendingSequences.has(sequenceKey);

  undoStack.push({
    label: `Unassign complete Sequence`,
    type: "unassign-sequence",
    sequenceKey,
    pendingState: wasPending
      ? { ...pendingSequences.get(sequenceKey) }
      : null,
    previous: assignedLines.map(snapshotAssignmentState)
  });

  assignedLines.forEach(clearAssignmentState);
  pendingSequences.delete(sequenceKey);

  if (!wasPending) {
    assignedLines.forEach(line => {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnUnassignDayTaskLine", [
        JSON.stringify({ id: line.id })
      ]);
    });
  }

  selectedLineIds.clear();
  lines.forEach(line => selectedLineIds.add(line.id));
  selectedSequenceKey = sequenceKey;
  selectionAnchorId = lines[0]?.id ?? null;

  updateDecisionButtons();
  updateUndoButton();
  renderAll();
}

function isRequestFulfilled(line) {
  if (!line || !line.assignedResource) return false;

  const requestedStart = Number(line.requestedStart);
  const requestedEnd =
    requestedStart + Number(line.requestedDuration);

  const assignedStart = Number(line.assignedStart);
  const assignedEnd =
    assignedStart + Number(line.assignedDuration);

  return (
    Math.abs(requestedStart - assignedStart) < 0.001 &&
    Math.abs(requestedEnd - assignedEnd) < 0.001
  );
}

function createRequestScheduler() {
  const sch = Scheduler.getSchedulerInstance();

  sch.plugins({
    timeline: true,
    treetimeline: true
  });

  sch.config.header = [];
  sch.xy.nav_height = 0;
  sch.config.multi_day = false;
  sch.config.drag_create = false;
  sch.config.drag_resize = false;
  sch.config.details_on_dblclick = false;
  sch.config.details_on_create = false;
  sch.config.readonly_form = true;
  sch.config.xml_date = "%Y-%m-%d %H:%i";

  const requestSections =
    sch.serverList("requestSections", filteredRequestTree());

  sch.createTimelineView({
    name: "request",
    x_unit: "hour",
    x_step: 1,
    x_start: currentWorkdayStart,
    x_size: getRangeHours(),
    x_length: 24,
    x_date: "%H",
    second_scale: {
      x_unit: "day",
      x_date: "%D %d %M"
    },
    y_unit: requestSections,
    y_property: "sequence_id",
    render: "tree",
    scrollable: true,
    smart_rendering: true,
    column_width: 28,
    dy: 34,
    folder_dy: hierarchyDensity === "compact" ? 20 : 34,
    event_dy: 20,
    section_autoheight: false,
    fit_events: false,
    columns: [
      {
        name: "sequence",
        label: "Sequences",
        width: 230,
        template: section => {
          if (section.kind === "project") {
            return `<div class="project-group-cell hierarchy-clickable" data-project-click="${section.key}"><strong>${section.label}</strong></div>`;
          }

          if (section.kind === "task") {
            return `<div class="task-group-cell hierarchy-clickable" data-task-click="${section.key}"><strong>${section.label}</strong></div>`;
          }

          const accepted = sequenceIsAccepted(section.key);
          const pending = sequenceIsPending(section.key);
          const allAssigned = !accepted && sequenceAllLinesAssigned(section.key);
          const skillMatches =
            sequenceSkillBehavior === "highlight" &&
            !!activeSkillFilter &&
            section.requiredSkill === activeSkillFilter;

          return `
          <div
            class="seq-cell hierarchy-clickable request-skill-${safeSkillClass(section.requiredSkill)} ${pending ? "sequence-pending-cell" : ""} ${activeSkillSequenceKey === section.key ? "sequence-skill-active" : ""} ${skillMatches ? "sequence-skill-match" : ""}"
            data-sequence-select="${section.key}"
            title="Required skill: ${section.requiredSkill}">
            ${
              accepted
                ? `<span class="seq-state-icon" title="Accepted; individual slots are independent">✓</span>`
                : allAssigned
                ? `<span class="seq-state-icon" title="All Day Task Lines in this Sequence are already assigned">✓</span>`
                : `<span class="seq-drag"
                        data-sequence-key="${section.key}"
                        title="Drag complete sequence">☰</span>`
            }
            <span class="seq-info">
              <span class="seq-title skill-first-title">
                ${section.requiredSkill} - Seq ${section.seq}
              </span>
              <span class="seq-subtitle">
                selected through ${getGlobalSelectionEndDate()?.toLocaleDateString("en-GB") ?? "—"}
                ${pending ? " · provisional" : accepted ? " · accepted" : allAssigned ? " · assigned" : ""}
              </span>
            </span>
          </div>`;
        }
      }
    ]
  });

  sch.templates.event_class = function(start, end, event) {
    const idClass = `dtl-${String(event.dayTaskLineId).replace(/[^a-zA-Z0-9_-]/g, "_")}`;
    const selectedClass = selectedLineIds.has(event.dayTaskLineId)
      ? " request-multi-selected"
      : "";
    const pendingClass = sequenceIsPending(event.sequence_id)
      ? " request-sequence-pending"
      : "";
    const acceptedClass = sequenceIsAccepted(event.sequence_id)
      ? " request-sequence-accepted"
      : "";
    const line = findLine(event.dayTaskLineId);
    const scopeClass = line && !line.sequenceAccepted && !lineIsInSequenceScope(line)
      ? " request-outside-scope"
      : " request-inside-scope";
    let timeCompareClass = "";

    if (line?.assignedResource) {
      timeCompareClass =
        isRequestFulfilled(line)
          ? " request-assignment-exact-match"
          : " request-assignment-time-diff";
    }

    const skillClass =
      ` request-skill-${safeSkillClass(line?.requiredSkill ?? sequenceRequiredSkill(event.sequence_id))}`;

    return `${event.assigned ? "request-assigned" : "request-event"} ${idClass}${selectedClass}${pendingClass}${acceptedClass}${scopeClass}${timeCompareClass}${skillClass}`;
  };

  sch.templates.event_bar_text = function(start, end, event) {
    return event.text;
  };

  // Request bars use custom pointer drag so one or many selected
  // Day Task Lines can move together between Scheduler instances.
  sch.attachEvent("onBeforeDrag", function() {
    return false;
  });

  sch.templates.timeline_cell_class = function(_ev, date) {
    return nonWorkingTimelineClass(date);
  };

  // Timeline view templates are also exposed by the view name.
  // Use the Request-specific cell template so Saturday/Sunday get
  // the same non-working background as the Resource pane.
  sch.templates.request_cell_class = function(_ev, date) {
    return nonWorkingTimelineClass(date);
  };

  sch.templates.timeline_scalex_class = function(date) {
    return nonWorkingTimelineClass(date);
  };

  sch.templates.request_scalex_class = function(date) {
    return nonWorkingTimelineClass(date);
  };

  // Show operational time; weekends can be shown or hidden from setup.
  sch.ignore_request = function(date) {
    return shouldHideTimelineDate(date);
  };

  sch.init("requestScheduler", getPlanningStart(), "request");

  // Clamp the view to the first requested workday through the 30th workday.
  const requestView = sch.getView();
  if (requestView && typeof requestView.setRange === "function") {
    requestView.setRange(new Date(getPlanningStart()), new Date(getPlanningEnd()));
    sch.setCurrentView(new Date(getPlanningStart()), "request");
  }
  return sch;
}

function formatPlannerTime(value) {
  const numeric = Number(value);
  const hours = Math.floor(numeric);
  const minutes = Math.round((numeric - hours) * 60);

  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}`;
}

function assignmentTooltipHtml(line) {
  if (!line) return "";

  const requestedStart =
    Number(line.requestedStart ?? line.assignedStart);

  const requestedEnd =
    requestedStart +
    Number(line.requestedDuration ?? line.assignedDuration);

  const assignedStart =
    Number(line.assignedStart);

  const assignedEnd =
    assignedStart +
    Number(line.assignedDuration);

  const skill =
    line.requiredSkill ||
    sequenceRequiredSkill(line.sequence_id) ||
    "—";

  const sequenceNo =
    line.seq ??
    sequenceRows.find(row => row.key === line.sequenceKey)?.seq ??
    "—";

  const jobNo =
    line.projectId || "—";

  const jobDescription =
    line.projectName || "—";

  const taskNo =
    line.taskId || "—";

  const taskDescription =
    line.taskName || "—";

  const resource =
    findResource(line.assignedResource);

  const resourceLabel =
    resource?.label ||
    resource?.name ||
    line.assignedResource ||
    "—";

  const timeDiffers =
    Math.abs(requestedStart - assignedStart) > 0.001 ||
    Math.abs(requestedEnd - assignedEnd) > 0.001;

  return `
    <div class="standard-tooltip-context">
      <div class="standard-tooltip-context-title">Job and Task</div>
      <div class="standard-tooltip-context-line">${jobNo} — ${jobDescription}</div>
      <div class="standard-tooltip-context-line">${taskNo} — ${taskDescription}</div>
    </div>

    <div class="standard-tooltip-head">
      <div class="standard-tooltip-title">Skill: ${skill}</div>
      <div class="standard-tooltip-detail">Sqnc ${sequenceNo}</div>
      <div class="standard-tooltip-detail">${new Date(line.date).toLocaleDateString(undefined, { weekday: "long" })} (wk ${isoWeekNumber(line.date)})</div>
      <div class="standard-tooltip-detail">${new Date(line.date).toLocaleDateString(undefined, { month: "short", day: "2-digit", year: "numeric" })}</div>
    </div>

    <table class="standard-tooltip-table">
      <thead>
        <tr>
          <th></th>
          <th>Request</th>
          <th>Assigned</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>Time</th>
          <td>${formatPlannerTime(requestedStart)}–${formatPlannerTime(requestedEnd)}</td>
          <td class="${timeDiffers ? "standard-tooltip-different" : ""}">
            ${formatPlannerTime(assignedStart)}–${formatPlannerTime(assignedEnd)}
          </td>
        </tr>
        <tr>
          <th>Resource</th>
          <td>—</td>
          <td>${resourceLabel}</td>
        </tr>
      </tbody>
    </table>`;
}

function moveAssignmentDetailTooltip(clientX, clientY) {
  if (!assignmentDetailTooltip || assignmentDetailTooltip.hidden) return;

  const offsetX = 14;
  const offsetY = 16;
  const rect = assignmentDetailTooltip.getBoundingClientRect();

  const left = Math.min(
    window.innerWidth - rect.width - 6,
    clientX + offsetX
  );

  const top = Math.min(
    window.innerHeight - rect.height - 6,
    clientY + offsetY
  );

  assignmentDetailTooltip.style.left =
    `${Math.max(6, left)}px`;

  assignmentDetailTooltip.style.top =
    `${Math.max(6, top)}px`;
}

function showAssignmentDetailTooltip(line, clientX, clientY) {
  if (!assignmentDetailTooltip || !line) return;

  assignmentDetailTooltip.innerHTML =
    assignmentTooltipHtml(line);

  assignmentDetailTooltip.hidden = false;
  moveAssignmentDetailTooltip(clientX, clientY);
}

function hideAssignmentDetailTooltip() {
  if (!assignmentDetailTooltip) return;
  assignmentDetailTooltip.hidden = true;
}

function createResourceScheduler() {
  const sch = Scheduler.getSchedulerInstance();

  sch.plugins({
    timeline: true
  });

  sch.config.header = [];
  sch.xy.nav_height = 0;
  sch.config.multi_day = false;
  sch.config.drag_create = false;
  sch.config.drag_resize = true;
  sch.config.drag_move = true;
  sch.config.details_on_dblclick = false;
  sch.config.details_on_create = false;

  const resourceSections = sch.serverList("resourceSections", visibleResources());

  sch.createTimelineView({
    name: "resources",
    x_unit: "hour",
    x_step: 1,
    x_start: currentWorkdayStart,
    x_size: getRangeHours(),
    x_length: 24,
    x_date: "%H",
    second_scale: {
      x_unit: "day",
      x_date: "%D %d %M"
    },
    y_unit: resourceSections,
    y_property: "resource_id",
    render: "bar",
    scrollable: true,
    smart_rendering: true,
    column_width: 28,
    dy: 34,
    event_dy: 18,
    section_autoheight: false,
    fit_events: false,
    columns: [
      {
        name: "resource",
        label: "Resource",
        width: 230,
        template: section => {
          const pendingCount = pendingSequencesForResource(section.key).length;

          return `
          <div class="resource-cell">
            <div class="resource-name-line">
              <div
                class="resource-name resource-clickable"
                data-resource-click="${section.key}"
                title="Skills: ${section.skills.join(", ")}">
                ${section.label}
                ${
                  resourceVisibleOnlyByAssignedSkill(section)
                    ? `<span
                         class="resource-skill-warning"
                         data-resource-warning="${section.key}"
                         aria-label="${resourceAssignedSkillWarningText(section)}">⚠</span>`
                    : ""
                }
              </div>
              ${
                pendingCount
                  ? `<span class="resource-decision-buttons">
                       <button
                         type="button"
                         class="resource-accept-btn"
                         data-resource-id="${section.key}"
                         title="Accept provisional sequence assignment${pendingCount === 1 ? "" : "s"}">
                         Accept${pendingCount > 1 ? ` (${pendingCount})` : ""}
                       </button>
                       <button
                         type="button"
                         class="resource-reject-btn"
                         data-resource-id="${section.key}"
                         title="Reject provisional sequence assignment${pendingCount === 1 ? "" : "s"}">
                         Reject${pendingCount > 1 ? ` (${pendingCount})` : ""}
                       </button>
                     </span>`
                  : ""
              }
            </div>
          </div>`;
        }
      }
    ]
  });

  sch.templates.event_class = function(start, end, event) {
    const base =
      event.conflict ? "assignment-conflict" : "assignment-event";

    const skillMismatch =
      event.skillMismatch ? " assignment-skill-mismatch" : "";

    const requestMismatch =
      event.skillMismatch || event.timeMismatch
        ? " assignment-request-mismatch"
        : "";

    const okClass = event.ok ? " assignment-ok" : "";

    return `${base}${skillMismatch}${requestMismatch}${okClass} ${event.accepted ? "assignment-accepted-editable" : "assignment-provisional-locked"}`;
  };

  sch.templates.event_text = function(start, end, event) {
    const handle = event.accepted
      ? `<span class="assignment-left-resize-handle" title="Drag to change start time"></span>`
      : "";

    return `${handle}<span class="assignment-label">${event.text ?? ""}</span>`;
  };

  sch.templates.event_bar_text = function(start, end, event) {
    return event.text;
  };

  sch.templates.event_class = (function(originalEventClass) {
    return function(start, end, event) {
      return originalEventClass
        ? originalEventClass(start, end, event)
        : (event.cssClass || "");
    };
  })(sch.templates.event_class);

  // Capacity is shown only by the taller capacity-slot-overlay background.
  // Resource cells also receive a weekend/non-working background class when visible.
  sch.templates.resources_cell_class = function(_ev, date) {
    return nonWorkingTimelineClass(date);
  };

  sch.templates.timeline_scalex_class = function(date) {
    return nonWorkingTimelineClass(date);
  };

  let acceptedEdit = null;

  sch.attachEvent("onBeforeDrag", function(id, mode) {
    const event = sch.getEvent(id);
    if (!event) return false;

    const line = findLine(event.dayTaskLineId);
    if (!line) return false;

    // Provisional and accepted assignments may move or resize.
    if (mode !== "move" && mode !== "resize") return false;

    acceptedEdit = {
      id,
      mode,
      lineId: line.id,
      previous: {
        assignedResource: line.assignedResource,
        assignedStart: line.assignedStart,
        assignedDuration: line.assignedDuration
      },
      originalStart: new Date(event.start_date),
      originalEnd: new Date(event.end_date)
    };

    return true;
  });

  sch.attachEvent("onBeforeEventChanged", function(event) {
    if (!acceptedEdit || event.id !== acceptedEdit.id) return true;

    const line = findLine(acceptedEdit.lineId);
    if (!line || !line.sequenceAccepted) return false;

    if (acceptedEdit.mode === "resize") {
      // Native DHTMLX resize controls the right edge.
      // Left-edge resize is handled separately by the custom pointer handle.
      event.start_date = new Date(acceptedEdit.originalStart);

      const durationHours =
        (event.end_date.getTime() - event.start_date.getTime()) / 3600000;

      if (durationHours < 1) {
        event.end_date = new Date(event.start_date.getTime() + 3600000);
      }

      const maxEnd = atTime(line.date, currentWorkdayEnd);
      if (event.end_date > maxEnd) {
        event.end_date = maxEnd;
      }

      return event.end_date > event.start_date;
    }

    if (acceptedEdit.mode === "move") {
      const originalDurationHours =
        (acceptedEdit.originalEnd.getTime() -
          acceptedEdit.originalStart.getTime()) /
        3600000;

      // Whole-bar drag may change Resource and time-of-day.
      // Keep the Day Task Line on its current date and preserve duration.
      let newStart =
        event.start_date.getHours() +
        event.start_date.getMinutes() / 60;

      newStart =
        Math.round(newStart * 2) / 2;

      newStart = Math.max(
        currentWorkdayStart,
        newStart
      );

      newStart = Math.min(
        currentWorkdayEnd - originalDurationHours,
        newStart
      );

      event.start_date =
        atTime(line.date, newStart);

      event.end_date =
        atTime(
          line.date,
          newStart + originalDurationHours
        );

      return !!findResource(event.resource_id);
    }

    return false;
  });

  sch.attachEvent("onEventChanged", function(id, event) {
    if (!acceptedEdit || id !== acceptedEdit.id) return;

    const line = findLine(acceptedEdit.lineId);
    if (!line) {
      acceptedEdit = null;
      return;
    }

    if (acceptedEdit.mode === "move") {
      line.assignedResource = event.resource_id;
      line.assignedStart =
        event.start_date.getHours() +
        event.start_date.getMinutes() / 60;

      line.assignedDuration =
        (event.end_date.getTime() -
          event.start_date.getTime()) /
        3600000;
    } else if (acceptedEdit.mode === "resize") {
      line.assignedDuration =
        (event.end_date.getTime() - event.start_date.getTime()) / 3600000;
    }

    undoStack.push({
      label:
        acceptedEdit.mode === "move"
          ? `Move ${line.taskId} / Sequence ${line.seq} assignment`
          : `Resize ${line.taskId} / Sequence ${line.seq} duration`,
      type: "edit-accepted",
      lineId: line.id,
      previous: acceptedEdit.previous
    });

    // Accepted assignments are already persisted — a native DHTMLX
    // move/resize on one commits to BC immediately, same as every other
    // individual (non-provisional) edit path in this file.
    if (acceptedEdit.mode === "move") {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnMoveAssignment", [
        JSON.stringify({
          id: line.id,
          resourceId: line.assignedResource,
          startHour: line.assignedStart,
          durationHours: line.assignedDuration
        })
      ]);
    } else if (acceptedEdit.mode === "resize") {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResizeAssignment", [
        JSON.stringify({
          id: line.id,
          startHour: line.assignedStart,
          durationHours: line.assignedDuration
        })
      ]);
    }

    const conflict = !lineFitsCapacity(line, line.assignedResource);

    resultStatus.textContent =
      acceptedEdit.mode === "move"
        ? `${line.taskId} / Seq ${line.seq} moved to ${findResource(line.assignedResource)?.label ?? line.assignedResource}` +
          (conflict ? " · warning: outside capacity" : " · fits capacity")
        : `${line.taskId} / Seq ${line.seq} duration changed to ${line.assignedDuration.toFixed(1)} h` +
          (conflict ? " · warning: outside capacity" : " · fits capacity");

    dragStatus.textContent = "Ready";
    acceptedEdit = null;

    updateUndoButton();
    renderAll();
  });

  sch.attachEvent("onDragEnd", function() {
    // If DHTMLX cancels an edit before onEventChanged, clear the temporary state.
    requestAnimationFrame(() => {
      if (acceptedEdit && !sch.getState().drag_id) {
        acceptedEdit = null;
      }
    });
    return true;
  });

  // Use the identical horizontal scale as the request scheduler.
  sch.ignore_resources = function(date) {
    return shouldHideTimelineDate(date);
  };

  sch.init("resourceScheduler", getPlanningStart(), "resources");

  const resourceView = sch.getView();
  if (resourceView && typeof resourceView.setRange === "function") {
    resourceView.setRange(new Date(getPlanningStart()), new Date(getPlanningEnd()));
    sch.setCurrentView(new Date(getPlanningStart()), "resources");
  }
  return sch;
}

let sharedHorizontalScrollLock = false;
let sharedVisibleTimelineDate = null;

function getTimelineView(scheduler, viewName) {
  return (
    scheduler.getView?.(viewName) ||
    scheduler.getView?.()
  );
}

function getTimelineHorizontalScroll(scheduler, viewName) {
  const timeline = getTimelineView(scheduler, viewName);

  if (timeline?.getScrollPosition) {
    return timeline.getScrollPosition()?.left || 0;
  }

  const data =
    scheduler.$container?.querySelector(".dhx_cal_data");

  return data?.scrollLeft || 0;
}

function visibleDateFromTimelineScroll(scheduler, viewName) {
  const timeline = getTimelineView(scheduler, viewName);
  if (!timeline) return null;

  const left = getTimelineHorizontalScroll(
    scheduler,
    viewName
  );

  if (typeof timeline.dateFromPos === "function") {
    const date = timeline.dateFromPos(left);

    if (date instanceof Date && !Number.isNaN(date.getTime())) {
      return new Date(date);
    }
  }

  return null;
}

function scrollTimelineToDate(scheduler, viewName, date) {
  const timeline = getTimelineView(scheduler, viewName);

  if (
    !timeline ||
    !(date instanceof Date) ||
    Number.isNaN(date.getTime())
  ) {
    return;
  }

  if (typeof timeline.scrollTo === "function") {
    timeline.scrollTo(new Date(date));
    return;
  }

  if (
    typeof timeline.posFromDate === "function"
  ) {
    const left = timeline.posFromDate(date);
    const data =
      scheduler.$container?.querySelector(".dhx_cal_data");

    if (data) {
      data.scrollLeft = left;
    }
  }
}

function syncRequestToAssignmentDate(date = null) {
  if (sharedHorizontalScrollLock) return;

  const visibleDate =
    date ||
    visibleDateFromTimelineScroll(
      resourceScheduler,
      "resources"
    );

  if (!(visibleDate instanceof Date)) return;

  sharedVisibleTimelineDate =
    new Date(visibleDate);

  sharedHorizontalScrollLock = true;

  scrollTimelineToDate(
    requestScheduler,
    "request",
    sharedVisibleTimelineDate
  );

  sharedHorizontalScrollLock = false;

  scheduleCapacityOverlaySync();

  requestAnimationFrame(() => {
    drawRequestBaselineMarkers();
  });
}

function markRequestHorizontalScrollContainers() {
  const root =
    document.getElementById("requestScheduler");

  if (!root) return;

  root.querySelectorAll("*").forEach(element => {
    const style = getComputedStyle(element);

    if (
      (style.overflowX === "auto" ||
       style.overflowX === "scroll") &&
      element.scrollWidth > element.clientWidth + 2
    ) {
      element.classList.add(
        "hide-request-horizontal-scrollbar"
      );
    }
  });

  root
    .querySelectorAll(
      ".dhx_timeline_scrollable_data, " +
      ".dhx_cal_data, " +
      ".dhx_matrix_data"
    )
    .forEach(element => {
      element.classList.add(
        "hide-request-horizontal-scrollbar"
      );
    });
}

let externalScrollbarSyncLock = false;

function syncExternalAssignmentScrollbarGeometry() {
  if (
    !assignmentTimelineScrollbar ||
    !assignmentTimelineScrollbarContent
  ) {
    return;
  }

  // Must be the actual scrolling element (.dhx_cal_data itself is
  // overflow:hidden and never scrolls - its scrollWidth == clientWidth,
  // which previously starved the proxy's range down to ~230px against a
  // true content width of ~9470px, and its scrollLeft is always 0, which
  // pinned the proxy thumb at the leftmost position regardless of where
  // the real timeline was scrolled to).
  const data =
    document.querySelector(
      "#resourceScheduler .dhx_timeline_data_wrapper.dhx_timeline_scrollable_data"
    );

  if (!data) return;

  assignmentTimelineScrollbarContent.style.width =
    `${Math.max(data.scrollWidth, data.clientWidth)}px`;

  if (!externalScrollbarSyncLock) {
    assignmentTimelineScrollbar.scrollLeft =
      data.scrollLeft || 0;
  }
}

function externalAssignmentScrollbarChanged() {
  if (
    externalScrollbarSyncLock ||
    !assignmentTimelineScrollbar ||
    !resourceScheduler
  ) {
    return;
  }

  const data =
    document.querySelector(
      "#resourceScheduler .dhx_timeline_data_wrapper.dhx_timeline_scrollable_data"
    );

  if (!data) return;

  externalScrollbarSyncLock = true;

  // Direct pixel copy - both elements now share the exact same scrollWidth/clientWidth
  // (see syncExternalAssignmentScrollbarGeometry), so no date round-trip is needed here.
  // The previous implementation routed this through dateFromPos -> scrollTimelineToDate
  // (posFromDate + DHTMLX's own timeline.scrollTo), and then re-read data.scrollLeft back
  // into the proxy afterwards - any rounding drift introduced by that pixel<->date
  // conversion (or by scrollTo not landing synchronously) fed straight back into the
  // proxy's own scrollLeft, re-triggering this handler and compounding every frame. That
  // only became visible as a slow, un-ending drift in Chrome (Edge apparently coalesces/
  // settles the re-entrant writes before they're perceptible).
  data.scrollLeft = assignmentTimelineScrollbar.scrollLeft;

  const timeline =
    getTimelineView(resourceScheduler, "resources");

  const date =
    timeline && typeof timeline.dateFromPos === "function"
      ? timeline.dateFromPos(assignmentTimelineScrollbar.scrollLeft)
      : null;

  if (date instanceof Date && !Number.isNaN(date.getTime())) {
    syncRequestToAssignmentDate(date);
  }

  requestAnimationFrame(() => {
    externalScrollbarSyncLock = false;
  });
}

function installHorizontalTimelineSync() {
  markRequestHorizontalScrollContainers();

  const resourceTimeline =
    resourceScheduler.getView("resources");

  if (
    resourceTimeline?.attachEvent &&
    !resourceTimeline._sharedDateScrollBound
  ) {
    resourceTimeline._sharedDateScrollBound = true;

    resourceTimeline.attachEvent(
      "onScroll",
      function(left) {
        if (sharedHorizontalScrollLock) return;

        const visibleDate =
          typeof resourceTimeline.dateFromPos === "function"
            ? resourceTimeline.dateFromPos(left || 0)
            : null;

        syncRequestToAssignmentDate(
          visibleDate instanceof Date
            ? visibleDate
            : null
        );
      }
    );
  }

  // Same real-scrolling-element fix as syncExternalAssignmentScrollbarGeometry:
  // .dhx_cal_data itself never scrolls, so this listener never fired on real
  // user scrolling of the resource timeline.
  const resourceData =
    document
      .getElementById("resourceScheduler")
      ?.querySelector(".dhx_timeline_data_wrapper.dhx_timeline_scrollable_data");

  if (
    resourceData &&
    !resourceData.dataset.sharedDateScrollBound
  ) {
    resourceData.dataset.sharedDateScrollBound = "1";

    resourceData.addEventListener(
      "scroll",
      () => {
        if (sharedHorizontalScrollLock) return;
        syncRequestToAssignmentDate();
        if (!externalScrollbarSyncLock) {
          syncExternalAssignmentScrollbarGeometry();
        }
      },
      { passive: true }
    );
  }

  // The proxy scrollbar's own native drag/scroll was never wired back to the
  // real timeline - externalAssignmentScrollbarChanged existed but nothing
  // called it, so dragging the proxy thumb had zero effect on the actual grid.
  if (
    assignmentTimelineScrollbar &&
    !assignmentTimelineScrollbar.dataset.sharedDateScrollBound
  ) {
    assignmentTimelineScrollbar.dataset.sharedDateScrollBound = "1";

    assignmentTimelineScrollbar.addEventListener(
      "scroll",
      externalAssignmentScrollbarChanged,
      { passive: true }
    );
  }

  // Assignment is always the master. Re-apply after DHTMLX renders.
  requestAnimationFrame(() => {
    markRequestHorizontalScrollContainers();
    syncRequestToAssignmentDate();
  });

  setTimeout(() => {
    markRequestHorizontalScrollContainers();
    syncRequestToAssignmentDate();
  }, 0);
}

let paneSplitDrag = null;
let requestPaneRatio = 0.50;
let paneRatioWasManuallyChanged = false;

function fitPlannerToViewport() {
  const rect = plannerSplit.getBoundingClientRect();

  // Available planner height depends on the actual rendered page position.
  const bottomMargin = 42;
  const viewportHeight =
    document.documentElement.clientHeight || window.innerHeight;

  const available = Math.max(
    460,
    viewportHeight - Math.max(0, rect.top) - bottomMargin
  );

  plannerSplit.style.height = `${available}px`;

  const splitterHeight =
    paneSplitter.getBoundingClientRect().height || 10;

  const usableHeight =
    Math.max(1, available - splitterHeight);

  const minRequest = 220;
  const minResource = 220;

  // Default is 50/50 of the usable screen-dependent planner height.
  // If the user has moved the splitter, preserve that chosen ratio.
  let requestHeight =
    usableHeight * requestPaneRatio;

  requestHeight = Math.max(
    minRequest,
    Math.min(usableHeight - minResource, requestHeight)
  );

  requestPane.style.height = `${requestHeight}px`;
  resourcePane.style.height =
    `${usableHeight - requestHeight}px`;

  resizeSchedulersAfterSplit();
}
function resizeSchedulersAfterSplit() {
  // Guards a narrow window before the first SetPlanningData() call has
  // created the scheduler instances (e.g. a passive window "resize" firing
  // while BC is still building the initial payload).
  if (!requestScheduler || !resourceScheduler) return;

  invalidateResourceRowElementsCache();

  requestAnimationFrame(() => {
    requestScheduler.setCurrentView();
    resourceScheduler.setCurrentView();

    requestAnimationFrame(() => {
      drawCapacitySlotLabels();
    });
  });
}

function setRequestPaneHeight(nextHeight, { manual = true } = {}) {
  const splitRect = plannerSplit.getBoundingClientRect();
  const splitterHeight = paneSplitter.getBoundingClientRect().height || 10;

  const minRequest = 220;
  const minResource = 220;
  const usableHeight =
    Math.max(1, splitRect.height - splitterHeight);

  const maxRequest = Math.max(
    minRequest,
    usableHeight - minResource
  );

  const clamped = Math.max(
    minRequest,
    Math.min(maxRequest, nextHeight)
  );

  requestPane.style.height = `${clamped}px`;
  resourcePane.style.height = `${usableHeight - clamped}px`;

  requestPaneRatio =
    clamped / usableHeight;

  if (manual) {
    paneRatioWasManuallyChanged = true;
  }

  paneSplitter.setAttribute(
    "aria-valuenow",
    String(Math.round(clamped))
  );

  resizeSchedulersAfterSplit();
}

function beginPaneSplit(event) {
  if (event.button !== undefined && event.button !== 0) return;

  const requestRect = requestPane.getBoundingClientRect();

  paneSplitDrag = {
    pointerId: event.pointerId,
    startY: event.clientY,
    startHeight: requestRect.height
  };

  paneSplitter.setPointerCapture?.(event.pointerId);
  document.body.classList.add("pane-resizing");

  event.preventDefault();
}

function movePaneSplit(event) {
  if (!paneSplitDrag || event.pointerId !== paneSplitDrag.pointerId) return;

  const delta = event.clientY - paneSplitDrag.startY;
  setRequestPaneHeight(paneSplitDrag.startHeight + delta);
}

function finishPaneSplit(event) {
  if (!paneSplitDrag) return;

  if (
    event.pointerId !== undefined &&
    event.pointerId !== paneSplitDrag.pointerId
  ) {
    return;
  }

  paneSplitDrag = null;
  document.body.classList.remove("pane-resizing");
}

function assignmentEventFromElement(element) {
  if (!element) return null;

  const eventElement = element.closest(".dhx_cal_event, .dhx_cal_event_line");
  if (!eventElement) return null;

  const eventId =
    eventElement.getAttribute("event_id") ||
    eventElement.getAttribute("data-event-id");

  if (!eventId) return null;

  try {
    return resourceScheduler.getEvent(eventId);
  } catch {
    return null;
  }
}

function hourFromPointerX(clientX, line) {
  const root = document.getElementById("resourceScheduler");
  const data = root.querySelector(".dhx_cal_data");
  if (!data) return null;

  const cells = Array.from(data.querySelectorAll(".dhx_matrix_cell"))
    .map(el => ({ el, rect: el.getBoundingClientRect() }))
    .filter(item => item.rect.width > 4 && item.rect.height > 10);

  if (!cells.length) return null;

  const rowTop = Math.min(...cells.map(item => item.rect.top));
  const rowCells = cells
    .filter(item => Math.abs(item.rect.top - rowTop) < 4)
    .sort((a, b) => a.rect.left - b.rect.left);

  if (!rowCells.length) return null;

  const workdayIndex = line.dayIndex;
  const hoursPerDay = currentWorkdayEnd - currentWorkdayStart;
  const firstCell = rowCells[0].rect;
  const cellWidth = firstCell.width;

  // Convert pointer to absolute visible operational-hour index.
  const absoluteHourIndex =
    (clientX - firstCell.left) / cellWidth;

  const dayStartIndex = workdayIndex * hoursPerDay;
  const hourWithinDay =
    currentWorkdayStart + (absoluteHourIndex - dayStartIndex);

  return Math.max(
    currentWorkdayStart,
    Math.min(currentWorkdayEnd - 1, hourWithinDay)
  );
}

function beginCapacityMove(event, overlay) {
  const capacityIndex = Number(overlay.dataset.capacityIndex);
  const cellWidth = Number(overlay.dataset.cellWidth);

  if (!Number.isInteger(capacityIndex) || !capacitySlots[capacityIndex]) return;
  if (!Number.isFinite(cellWidth) || cellWidth <= 0) return;

  const slot = capacitySlots[capacityIndex];
  const duration = slot.end - slot.start;

  event.preventDefault();
  event.stopPropagation();

  capacityMoveDrag = {
    pointerId: event.pointerId,
    capacityIndex,
    overlay,
    cellWidth,
    startClientX: event.clientX,
    originalStart: slot.start,
    originalEnd: slot.end,
    duration,
    previewStart: slot.start
  };

  overlay.classList.add("capacity-slot-dragging");
  overlay.setPointerCapture?.(event.pointerId);

  resultStatus.textContent =
    `${findResource(slot.resourceId)?.label ?? slot.resourceId}: ` +
    `moving capacity ${formatHour(slot.start)}–${formatHour(slot.end)}`;
}

function moveCapacityMove(event) {
  if (!capacityMoveDrag || event.pointerId !== capacityMoveDrag.pointerId) return;

  const state = capacityMoveDrag;
  const deltaPixels = event.clientX - state.startClientX;
  const deltaHours = deltaPixels / state.cellWidth;

  // Snap complete slot movement to 30-minute steps.
  let newStart =
    Math.round((state.originalStart + deltaHours) * 2) / 2;

  // Keep the entire capacity slot inside the operational day.
  newStart = Math.max(currentWorkdayStart, newStart);
  newStart = Math.min(currentWorkdayEnd - state.duration, newStart);

  const visualDeltaHours = newStart - state.originalStart;
  const visualDeltaPixels = visualDeltaHours * state.cellWidth;

  state.previewStart = newStart;

  state.overlay.style.transform =
    `translate3d(${visualDeltaPixels}px, 0, 0)`;

  const newEnd = newStart + state.duration;
  const label = state.overlay.querySelector(".capacity-slot-label");
  if (label) {
    label.textContent =
      `${formatHour(newStart)}–${formatHour(newEnd)}`;
  }

  state.overlay.title =
    `Capacity ${formatHour(newStart)}–${formatHour(newEnd)} · release to move`;
}

function finishCapacityMove(event) {
  if (!capacityMoveDrag || event.pointerId !== capacityMoveDrag.pointerId) return;

  const state = capacityMoveDrag;
  capacityMoveDrag = null;

  const slot = capacitySlots[state.capacityIndex];
  if (!slot) return;

  state.overlay.classList.remove("capacity-slot-dragging");

  const newStart = state.previewStart;
  const newEnd = newStart + state.duration;

  if (Math.abs(newStart - state.originalStart) < 0.001) {
    renderResources();
    resultStatus.textContent = "Capacity position unchanged.";
    return;
  }

  undoStack.push({
    label:
      `Move capacity ${slot.resourceId} ${formatHour(state.originalStart)}–${formatHour(state.originalEnd)}`,
    type: "capacity-move",
    capacityIndex: state.capacityIndex,
    previous: {
      start: state.originalStart,
      end: state.originalEnd
    }
  });

  slot.start = newStart;
  slot.end = newEnd;

  updateUndoButton();
  renderResources();

  const resource =
    findResource(slot.resourceId);

  resultStatus.textContent =
    `${resource?.label ?? slot.resourceId}: capacity moved to ` +
    `${formatHour(slot.start)}–${formatHour(slot.end)}.`;
}

function requestLineFromPointerTarget(target) {
  const eventElement =
    target?.closest?.(".dhx_cal_event_line, .dhx_cal_event");

  if (!eventElement) return null;

  const eventId =
    eventElement.getAttribute("event_id") ||
    eventElement.getAttribute("data-event-id") ||
    eventElement.dataset?.eventId;

  if (eventId !== null && eventId !== undefined) {
    try {
      const schedulerEvent =
        requestScheduler.getEvent(eventId);

      if (schedulerEvent?.dayTaskLineId) {
        return findLine(schedulerEvent.dayTaskLineId);
      }
    } catch (_error) {}
  }

  const className =
    typeof eventElement.className === "string"
      ? eventElement.className
      : eventElement.className?.baseVal || "";

  const match =
    className.match(/dtl-([A-Za-z0-9_-]+)/);

  if (!match) return null;

  return (
    dayTaskLines.find(
      line =>
        String(line.id).replace(/[^a-zA-Z0-9_-]/g, "_") === match[1]
    ) || null
  );
}

function assignmentLineFromPointerTarget(target) {
  const eventElement =
    target.closest(".dhx_cal_event, .dhx_cal_event_line");

  if (!eventElement) return null;

  const eventId =
    eventElement.getAttribute("event_id") ||
    eventElement.getAttribute("data-event-id");

  let schedulerEvent = null;

  try {
    schedulerEvent = resourceScheduler.getEvent(eventId);
  } catch {
    schedulerEvent = null;
  }

  if (!schedulerEvent?.dayTaskLineId) return null;

  const line = findLine(schedulerEvent.dayTaskLineId);

  return line?.assignedResource ? line : null;
}

function capacityOverlayAtPoint(clientX, clientY) {
  const overlays = Array.from(
    document.querySelectorAll(
      "#resourceScheduler .capacity-slot-overlay"
    )
  );

  return overlays.find(overlay => {
    const rect = overlay.getBoundingClientRect();
    return (
      clientX >= rect.left &&
      clientX <= rect.right &&
      clientY >= rect.top &&
      clientY <= rect.bottom
    );
  }) || null;
}

function beginAcceptedLeftResize(event, handleOrEventElement) {
  const eventElement =
    handleOrEventElement?.matches?.(".dhx_cal_event, .dhx_cal_event_line")
      ? handleOrEventElement
      : handleOrEventElement?.closest?.(".dhx_cal_event, .dhx_cal_event_line");

  const eventId =
    eventElement?.getAttribute("event_id") ||
    eventElement?.getAttribute("data-event-id");

  if (!eventId) return;

  const schedulerEvent = resourceScheduler.getEvent(eventId);
  if (!schedulerEvent?.accepted) return;

  const line = findLine(schedulerEvent.dayTaskLineId);
  if (!line?.sequenceAccepted) return;

  event.preventDefault();
  event.stopPropagation();

  acceptedLeftResize = {
    pointerId: event.pointerId,
    eventId,
    lineId: line.id,
    originalStart: line.assignedStart,
    originalDuration: line.assignedDuration,
    originalEnd: line.assignedStart + line.assignedDuration,
    currentStart: line.assignedStart
  };

  handleOrEventElement.setPointerCapture?.(event.pointerId);
  dragStatus.textContent = "Resize accepted Day Task Line start time";
}

function moveAcceptedLeftResize(event) {
  if (!acceptedLeftResize || event.pointerId !== acceptedLeftResize.pointerId) return;

  const line = findLine(acceptedLeftResize.lineId);
  if (!line) return;

  const pointerHour = hourFromPointerX(event.clientX, line);
  if (pointerHour == null) return;

  // Snap to 30-minute steps.
  let newStart = Math.round(pointerHour * 2) / 2;

  // Keep at least 1 hour duration and stay within workday.
  newStart = Math.max(currentWorkdayStart, newStart);
  newStart = Math.min(newStart, acceptedLeftResize.originalEnd - 1);

  acceptedLeftResize.currentStart = newStart;

  const schedulerEvent = resourceScheduler.getEvent(acceptedLeftResize.eventId);
  if (!schedulerEvent) return;

  schedulerEvent.start_date = atTime(line.date, newStart);
  schedulerEvent.end_date = atTime(line.date, acceptedLeftResize.originalEnd);

  resourceScheduler.updateEvent(acceptedLeftResize.eventId);
}

function finishAcceptedLeftResize(event) {
  if (!acceptedLeftResize || event.pointerId !== acceptedLeftResize.pointerId) return;

  const state = acceptedLeftResize;
  acceptedLeftResize = null;

  const line = findLine(state.lineId);
  if (!line) return;

  const newStart = state.currentStart;
  const newDuration = state.originalEnd - newStart;

  if (
    Math.abs(newStart - state.originalStart) < 0.001 &&
    Math.abs(newDuration - state.originalDuration) < 0.001
  ) {
    renderAll();
    dragStatus.textContent = "Ready";
    return;
  }

  undoStack.push({
    label: `Change ${line.taskId} / Sequence ${line.seq} start time`,
    type: "edit-accepted",
    lineId: line.id,
    previous: {
      assignedResource: line.assignedResource,
      assignedStart: state.originalStart,
      assignedDuration: state.originalDuration
    }
  });

  line.assignedStart = newStart;
  line.assignedDuration = newDuration;

  // Accepted assignment — persist the new start/duration immediately.
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResizeAssignment", [
    JSON.stringify({
      id: line.id,
      startHour: line.assignedStart,
      durationHours: line.assignedDuration
    })
  ]);

  const conflict = !lineFitsCapacity(line, line.assignedResource);

  resultStatus.textContent =
    `${line.projectId} / ${line.taskId} / Seq ${line.seq} start changed to ${formatHour(line.assignedStart)}` +
    (conflict ? " · warning: outside capacity" : " · fits capacity");

  dragStatus.textContent = "Ready";
  updateUndoButton();
  renderAll();
}

let assignmentPointerEdit = null;

function getAssignmentEditHit(target) {
  const eventElement =
    target?.closest?.("#resourceScheduler .dhx_cal_event_line.assignment-event");

  if (!eventElement) return null;

  const eventId =
    eventElement.getAttribute("event_id") ||
    eventElement.getAttribute("data-event-id") ||
    eventElement.dataset?.eventId;

  if (!eventId) return null;

  let schedulerEvent;
  try {
    schedulerEvent = resourceScheduler.getEvent(eventId);
  } catch (_error) {
    return null;
  }

  if (!schedulerEvent) return null;

  const line = findLine(schedulerEvent.dayTaskLineId);
  if (!line) return null;

  return { eventElement, schedulerEvent, line };
}

function assignmentPixelsPerHour(line) {
  const view =
    resourceScheduler.getView?.("resources") ||
    resourceScheduler.getView?.();

  if (!view || typeof view.posFromDate !== "function") return 1;

  const x1 = view.posFromDate(
    atTime(line.date, Number(line.assignedStart))
  );
  const x2 = view.posFromDate(
    atTime(line.date, Number(line.assignedStart) + 1)
  );

  return Math.max(1, Math.abs(x2 - x1));
}

function resourceAtY(clientY) {
  const rows =
    [...document.querySelectorAll("#resourceScheduler .dhx_matrix_scell")];

  const visible = visibleResources();

  for (let index = 0; index < rows.length; index++) {
    const rect = rows[index].getBoundingClientRect();

    if (clientY >= rect.top && clientY <= rect.bottom) {
      return visible[index]?.key || null;
    }
  }

  return null;
}

function beginAssignmentPointerEdit(e) {
  if (e.button !== 0) return;

  const hit = getAssignmentEditHit(e.target);
  if (!hit) return;

  const rect = hit.eventElement.getBoundingClientRect();
  const edgeWidth = 8;

  let mode = "move";
  if (e.clientX <= rect.left + edgeWidth) {
    mode = "resize-start";
  } else if (e.clientX >= rect.right - edgeWidth) {
    mode = "resize-end";
  }

  assignmentPointerEdit = {
    pointerId: e.pointerId,
    lineId: hit.line.id,
    mode,
    startClientX: e.clientX,
    originalResource: hit.line.assignedResource,
    originalStart: Number(hit.line.assignedStart),
    originalDuration: Number(hit.line.assignedDuration),
    pixelsPerHour: assignmentPixelsPerHour(hit.line)
  };

  try {
    hit.eventElement.setPointerCapture?.(e.pointerId);
  } catch (_error) {}

  e.preventDefault();
  e.stopPropagation();
}

function moveAssignmentPointerEdit(e) {
  const state = assignmentPointerEdit;
  if (!state || e.pointerId !== state.pointerId) return;

  const line = findLine(state.lineId);
  if (!line) return;

  let delta =
    (e.clientX - state.startClientX) /
    Math.max(1, state.pixelsPerHour);

  // 30-minute snapping
  delta = Math.round(delta * 2) / 2;

  const originalEnd =
    state.originalStart + state.originalDuration;

  if (state.mode === "resize-start") {
    const newStart =
      Math.max(
        currentWorkdayStart,
        Math.min(originalEnd - 1, state.originalStart + delta)
      );

    line.assignedStart = newStart;
    line.assignedDuration = originalEnd - newStart;
  } else if (state.mode === "resize-end") {
    const newEnd =
      Math.max(
        state.originalStart + 1,
        Math.min(currentWorkdayEnd, originalEnd + delta)
      );

    line.assignedDuration = newEnd - state.originalStart;
  } else {
    const newStart =
      Math.max(
        currentWorkdayStart,
        Math.min(
          currentWorkdayEnd - state.originalDuration,
          state.originalStart + delta
        )
      );

    line.assignedStart = newStart;

    const newResource = resourceAtY(e.clientY);
    if (newResource) {
      line.assignedResource = newResource;
    }
  }

  renderAll();

  e.preventDefault();
  e.stopPropagation();
}

function finishAssignmentPointerEdit(e) {
  const state = assignmentPointerEdit;
  if (!state || e.pointerId !== state.pointerId) return;

  assignmentPointerEdit = null;

  const line = findLine(state.lineId);
  if (!line) return;

  const changed =
    line.assignedResource !== state.originalResource ||
    Math.abs(Number(line.assignedStart) - state.originalStart) > 0.001 ||
    Math.abs(Number(line.assignedDuration) - state.originalDuration) > 0.001;

  if (!changed) return;

  undoStack.push({
    label: `Edit ${line.taskId} / Sequence ${line.seq} assignment`,
    type: "edit-accepted",
    lineId: line.id,
    previous: {
      assignedResource: state.originalResource,
      assignedStart: state.originalStart,
      assignedDuration: state.originalDuration
    }
  });

  // This editor only ever runs on lines that already have a real assignment
  // (getAssignmentEditHit requires an existing assignment-event bar), so the
  // change is always committed immediately.
  if (state.mode === "move") {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnMoveAssignment", [
      JSON.stringify({
        id: line.id,
        resourceId: line.assignedResource,
        startHour: line.assignedStart,
        durationHours: line.assignedDuration
      })
    ]);
  } else {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResizeAssignment", [
      JSON.stringify({
        id: line.id,
        startHour: line.assignedStart,
        durationHours: line.assignedDuration
      })
    ]);
  }

  updateUndoButton();
  renderAll();
}

let capacityScrollFrame = 0;

function scheduleCapacityOverlaySync() {
  if (capacityScrollFrame) return;

  capacityScrollFrame = requestAnimationFrame(() => {
    capacityScrollFrame = 0;
    drawCapacitySlotLabels();
  });
}

function mountRequestFilterToolbar() {
  const headingBlock =
    document.querySelector("#requestPane .request-heading-block");

  const heading =
    headingBlock?.querySelector("h2");

  const toolbar =
    document.querySelector(".request-filter-toolbar");

  if (!headingBlock || !heading || !toolbar) return;

  let host =
    headingBlock.querySelector(".request-title-filter-host");

  if (!host) {
    host = document.createElement("span");
    host.className = "request-title-filter-host";
    heading.insertAdjacentElement("afterend", host);
  }

  if (toolbar.parentElement !== host) {
    host.appendChild(toolbar);
  }

  toolbar.classList.remove("request-filter-toolbar-mounted");
}

function renderRequest() {
  requestScheduler.updateCollection(
    "requestSections",
    filteredRequestTree()
  );
  requestScheduler.clearAll();
  requestScheduler.parse(requestEvents());
  requestScheduler.updateView();

  requestAnimationFrame(mountRequestFilterToolbar);
  requestAnimationFrame(decorateDayHeaders);

  requestAnimationFrame(() => {
    installHorizontalTimelineSync();
    syncRequestToAssignmentDate(
      sharedVisibleTimelineDate
    );
  });
}

function renderResources() {
  invalidateResourceRowElementsCache();
  rebuildAssignedResourceSkillSets();

  const sections = visibleResources();

  resourceScheduler.updateCollection("resourceSections", sections);
  resourceScheduler.clearAll();
  resourceScheduler.parse(assignmentEvents());
  resourceScheduler.updateView();

  // Let DHTMLX finish its Timeline DOM, then draw the thin capacity slot labels.
  requestAnimationFrame(() => {
    drawCapacitySlotLabels();
    drawRequestBaselineMarkers();
  });

  requestAnimationFrame(decorateDayHeaders);

  requestAnimationFrame(() => {
    installHorizontalTimelineSync();
    syncRequestToAssignmentDate(
      sharedVisibleTimelineDate
    );
    syncExternalAssignmentScrollbarGeometry();
  });
}

function renderAll() {
  renderRequest();
  renderResources();
}

function findLine(id) {
  return dayTaskLines.find(x => x.id === id);
}

let transferAnimating = false;
let liveFlyers = [];
let liveDragOrigin = null;
let livePointer = null;
let liveWaveFrame = 0;

function requestElementForLine(lineId) {
  const safe = String(lineId).replace(/[^a-zA-Z0-9_-]/g, "_");
  return document.querySelector(`#requestScheduler .dtl-${safe}`);
}

function getResourceRowRect(resourceId) {
  const currentResources = visibleResources();
  const index = currentResources.findIndex(r => r.key === resourceId);
  if (index < 0) return null;

  const rows = getResourceRowElements();
  if (rows[index]) return rows[index].getBoundingClientRect();

  const data = document.querySelector("#resourceScheduler .dhx_cal_data");
  if (!data) return null;

  const dataRect = data.getBoundingClientRect();
  const rowHeight = 52;
  return {
    top: dataRect.top + index * rowHeight - (data.scrollTop || 0),
    bottom: dataRect.top + (index + 1) * rowHeight - (data.scrollTop || 0),
    height: rowHeight
  };
}

function clearLiveFlyers() {
  if (liveWaveFrame) {
    cancelAnimationFrame(liveWaveFrame);
    liveWaveFrame = 0;
  }
  liveFlyers.forEach(item => item.el.remove());
  liveFlyers = [];
  liveDragOrigin = null;
  livePointer = null;
}

const DHX_WEEKDAY_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const DHX_MONTH_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// Matches the request/resource timelines' second_scale x_date format ("%D %d
// %M" -> "Mon 24 Aug"), so a day header cell can be found by its own label
// text rather than by position/index into the DOM.
function dhxDayScaleLabel(date) {
  return `${DHX_WEEKDAY_SHORT[date.getDay()]} ${String(date.getDate()).padStart(2, "0")} ${DHX_MONTH_SHORT[date.getMonth()]}`;
}

// Estimates where a Day Task Line's request bar WOULD sit on screen even when
// it isn't currently rendered (scrolled outside the visible date range, or
// culled by smart_rendering) - so its synthetic drag flyer spawns over its
// actual date column/row, matching the demo's "flyer starts on top of its
// real bar" look instead of appearing wherever the pointer happens to be.
//
// Deliberately locates the day header cell by matching its rendered label
// text (e.g. "Mon 24 Aug") instead of indexing into workdays[] by position:
// this DHTMLX build's day-scale cells (.dhx_scale_bar) don't reliably line
// up 1:1 with workdays[] by DOM order (buffered/duplicate header cells for
// horizontal-scroll sync), so a positional index produced the wrong column
// entirely - live testing showed flyers landing near the start of the
// timeline instead of over their real date.
function estimateRequestLineRect(line) {
  const root = document.getElementById("requestScheduler");
  if (!root) return null;

  const rowCell = root.querySelector(
    `.seq-cell[data-sequence-select="${CSS.escape(line.sequenceKey)}"]`
  );
  if (!rowCell) return null;

  const label = dhxDayScaleLabel(line.date);
  const candidates = [
    ...root.querySelectorAll(".dhx_scale_bar"),
    ...root.querySelectorAll(".dhx_second_scale_bar")
  ].filter(bar => bar.textContent.trim() === label);

  if (!candidates.length) return null;

  // Several near-duplicate header cells can share this label (frozen/synced
  // copies) - the widest, on-screen one is the real rendered day column.
  const dayCell = candidates
    .map(bar => bar.getBoundingClientRect())
    .filter(rect => rect.width > 20 && rect.bottom > 0 && rect.top < window.innerHeight)
    .sort((a, b) => b.width - a.width)[0];

  if (!dayCell) return null;

  // NOT getRangeHours() - that returns the TOTAL hour span across the whole
  // multi-day horizon (it's the DHTMLX x_size for the hour-unit primary
  // scale), not one day's visible work-hour window. Using it here collapsed
  // every synthetic flyer's width to a sliver, clamped up to the 20px floor.
  const hoursVisiblePerDay = currentWorkdayEnd - currentWorkdayStart;
  if (!hoursVisiblePerDay) return null;

  const xWithinDay =
    ((line.requestedStart - currentWorkdayStart) / hoursVisiblePerDay) * dayCell.width;
  const width = (line.requestedDuration / hoursVisiblePerDay) * dayCell.width;

  const rowRect = rowCell.getBoundingClientRect();

  return {
    left: dayCell.left + xWithinDay,
    top: rowRect.top,
    width: Math.max(20, width),
    height: rowRect.height
  };
}

function createLiveFlyers(lines, pointerX, pointerY) {
  clearLiveFlyers();

  const linesById = new Map(lines.map(line => [String(line.id), line]));
  const foundIds = new Set();

  const visible = Array.from(
    document.querySelectorAll("#requestScheduler .dhx_cal_event_line, #requestScheduler .dhx_cal_event")
  )
    .map(source => {
      const lineId = lineIdFromRequestElement(source);
      const line = lineId ? linesById.get(lineId) : null;
      if (!line) return null;
      const rect = source.getBoundingClientRect();
      if (
        rect.width < 3 ||
        rect.height < 3 ||
        rect.bottom < 0 ||
        rect.top > window.innerHeight
      ) return null;
      foundIds.add(String(line.id));
      return { line, source, rect };
    })
    .filter(Boolean)
    .sort((a, b) => a.rect.left - b.rect.left);

  // Lines whose bar isn't currently on screen (scrolled outside the visible date
  // range, or never rendered at all under DHTMLX's smart_rendering row/virtualization)
  // still need a flyer - otherwise dragging a sequence whose lines span outside the
  // current horizontal scroll position shows no floating indicator at all, even
  // though the drag itself is working.
  const missing = lines.filter(line => !foundIds.has(String(line.id)));

  if (!visible.length && !missing.length) return;

  const leadRect = visible.length
    ? visible[0].rect
    : (missing.length && estimateRequestLineRect(missing[0])) ||
      { left: pointerX - 45, top: pointerY - 11, width: 90, height: 22 };

  liveDragOrigin = {
    pointerX,
    pointerY,
    leadLeft: leadRect.left,
    leadTop: leadRect.top
  };

  livePointer = {
    x: pointerX,
    y: pointerY,
    resourceId: null
  };

  liveFlyers = visible.map(({ line, source, rect }, index) => {
    const clone = source.cloneNode(true);
    clone.classList.add("transfer-flyer", "live-transfer-flyer");
    clone.classList.remove("request-assigned");
    clone.style.position = "fixed";
    clone.style.left = `${rect.left}px`;
    clone.style.top = `${rect.top}px`;
    clone.style.width = `${rect.width}px`;
    clone.style.height = `${rect.height}px`;
    clone.style.margin = "0";
    clone.style.zIndex = "100000";
    clone.style.pointerEvents = "none";
    clone.style.transition = "opacity 120ms linear";
    document.body.appendChild(clone);

    return {
      line,
      el: clone,
      rect,
      index,
      x: 0,
      y: 0,
      vx: 0,
      vy: 0,
      offsetX: rect.left - leadRect.left,
      offsetY: rect.top - leadRect.top
    };
  });

  missing.forEach((line, missingIndex) => {
    const color = getSkillColor(requestedSkillForLine(line));
    const rect = estimateRequestLineRect(line) || {
      left: leadRect.left,
      top: leadRect.top + (visible.length + missingIndex) * (leadRect.height + 3),
      width: leadRect.width,
      height: leadRect.height
    };

    const clone = document.createElement("div");
    clone.className = "transfer-flyer live-transfer-flyer";
    clone.textContent = `${line.requestedStart}:00–${line.requestedStart + line.requestedDuration}:00`;
    clone.style.position = "fixed";
    clone.style.left = `${rect.left}px`;
    clone.style.top = `${rect.top}px`;
    clone.style.width = `${rect.width}px`;
    clone.style.height = `${rect.height}px`;
    clone.style.margin = "0";
    clone.style.zIndex = "100000";
    clone.style.pointerEvents = "none";
    clone.style.transition = "opacity 120ms linear";
    clone.style.display = "flex";
    clone.style.alignItems = "center";
    clone.style.justifyContent = "center";
    clone.style.fontSize = "10px";
    clone.style.fontWeight = "700";
    clone.style.borderRadius = "4px";
    clone.style.background = color.backgroundColor;
    clone.style.border = `1px solid ${color.borderColor}`;
    clone.style.color = color.textColor;
    document.body.appendChild(clone);

    liveFlyers.push({
      line,
      el: clone,
      rect,
      index: visible.length + missingIndex,
      x: 0,
      y: 0,
      vx: 0,
      vy: 0,
      offsetX: rect.left - leadRect.left,
      offsetY: rect.top - leadRect.top
    });
  });

  startLiveWaveLoop();
}

function moveLiveFlyers(pointerX, pointerY, resourceId = null) {
  if (!liveFlyers.length || !liveDragOrigin) return;

  livePointer = {
    x: pointerX,
    y: pointerY,
    resourceId
  };
}

function showSequenceDragTooltip(count, clientX, clientY) {
  sequenceDragTooltip.textContent =
    `${count} time slot${count === 1 ? "" : "s"} moving`;

  sequenceDragTooltip.hidden = false;
  moveSequenceDragTooltip(clientX, clientY);
}

function moveSequenceDragTooltip(clientX, clientY) {
  if (sequenceDragTooltip.hidden) return;

  const offsetX = 14;
  const offsetY = 16;
  const rect = sequenceDragTooltip.getBoundingClientRect();

  const left = Math.min(
    window.innerWidth - rect.width - 6,
    clientX + offsetX
  );

  const top = Math.min(
    window.innerHeight - rect.height - 6,
    clientY + offsetY
  );

  sequenceDragTooltip.style.left =
    `${Math.max(6, left)}px`;

  sequenceDragTooltip.style.top =
    `${Math.max(6, top)}px`;
}

function hideSequenceDragTooltip() {
  sequenceDragTooltip.hidden = true;
}

function startLiveWaveLoop() {
  if (liveWaveFrame) cancelAnimationFrame(liveWaveFrame);

  const tick = () => {
    if (!liveFlyers.length || !liveDragOrigin || !livePointer) {
      liveWaveFrame = 0;
      return;
    }

    const pointerDx = livePointer.x - liveDragOrigin.pointerX;
    const pointerDy = livePointer.y - liveDragOrigin.pointerY;

    let rowAdjust = 0;

    if (livePointer.resourceId) {
      const target = getResourceRowRect(livePointer.resourceId);

      if (target && liveFlyers[0]) {
        const lead = liveFlyers[0];
        const currentLeadTop = lead.rect.top + lead.y;
        const desiredLeadTop =
          target.top + Math.max(4, (target.height - lead.rect.height) / 2);

        rowAdjust = (desiredLeadTop - currentLeadTop) * 0.20;
      }
    }

    // Direct viewport-width scaling.
    // Reference behavior is around 1400px wide.
    // Wider screens reduce the total visible wave strength.
    const viewportWidth = Math.max(800, window.innerWidth || 1400);

    const widthFactor = Math.max(
      0.42,
      Math.min(1, 1400 / viewportWidth)
    );

    // On wider screens followers catch up more strongly,
    // preventing a long visible sequence from building a large tail amplitude.
    const followCatchUp =
      0.22 + (1 - widthFactor) * 0.16;

    const visibleCount = Math.max(1, liveFlyers.length);

    liveFlyers.forEach((item, index) => {
      let targetX;
      let targetY;
      let spring;
      let damping;

      if (index === 0) {
        // Head remains responsive and independent of screen width.
        targetX = pointerDx;
        targetY = pointerDy + rowAdjust;
        spring = 0.34;
        damping = 0.66;
      } else {
        const previous = liveFlyers[index - 1];

        // Follow predecessor, but bias toward the mouse target.
        // The bias increases on wider screens.
        targetX =
          previous.x +
          (pointerDx - previous.x) * followCatchUp;

        targetY =
          previous.y +
          (pointerDy + rowAdjust - previous.y) * followCatchUp;

        const t = index / Math.max(1, visibleCount - 1);

        // Width directly controls how much head-to-tail difference remains.
        spring =
          0.255 - t * (0.040 * widthFactor);

        damping =
          0.695 + t * (0.025 * widthFactor);
      }

      item.vx += (targetX - item.x) * spring;
      item.vy += (targetY - item.y) * spring;

      item.vx *= damping;
      item.vy *= damping;

      // Also scale the velocity ceiling with screen width.
      const maxVelocity =
        10 + 4 * widthFactor;

      item.vx = Math.max(-maxVelocity, Math.min(maxVelocity, item.vx));
      item.vy = Math.max(-maxVelocity, Math.min(maxVelocity, item.vy));

      item.x += item.vx;
      item.y += item.vy;

      item.el.style.transform =
        `translate3d(${item.x}px, ${item.y}px, 0) scale(1.008)`;

      item.el.style.opacity =
        livePointer.resourceId ? "1" : "0.97";
    });

    liveWaveFrame = requestAnimationFrame(tick);
  };

  liveWaveFrame = requestAnimationFrame(tick);
}

async function settleLiveFlyers(resourceId) {
  if (!liveFlyers.length) return;

  if (liveWaveFrame) {
    cancelAnimationFrame(liveWaveFrame);
    liveWaveFrame = 0;
  }

  const target = getResourceRowRect(resourceId);
  if (!target) {
    clearLiveFlyers();
    return;
  }

  const animations = liveFlyers.map(item => {
    const desiredTop =
      target.top + Math.max(4, (target.height - item.rect.height) / 2);
    const finalY = desiredTop - item.rect.top;

    const anim = item.el.animate(
      [
        {
          transform: `translate3d(${item.x}px, ${item.y}px, 0) scale(1.015)`,
          opacity: 1
        },
        {
          transform: `translate3d(${item.x}px, ${finalY}px, 0) scale(1)`,
          opacity: 0.97
        }
      ],
      {
        duration: 170 + Math.min(item.index * 7, 150),
        easing: "cubic-bezier(.22,.76,.22,1)",
        fill: "forwards"
      }
    );

    return anim.finished.catch(() => {});
  });

  await Promise.all(animations);
  clearLiveFlyers();
}

async function returnLiveFlyers() {
  if (!liveFlyers.length) return;

  if (liveWaveFrame) {
    cancelAnimationFrame(liveWaveFrame);
    liveWaveFrame = 0;
  }

  const animations = liveFlyers.map(item => {
    const anim = item.el.animate(
      [
        {
          transform: `translate3d(${item.x}px, ${item.y}px, 0) scale(1.015)`,
          opacity: 0.95
        },
        {
          transform: "translate3d(0,0,0) scale(1)",
          opacity: 0
        }
      ],
      {
        duration: 180 + Math.min(item.index * 8, 170),
        delay: Math.min(item.index * 5, 100),
        easing: "cubic-bezier(.2,.72,.2,1)",
        fill: "forwards"
      }
    );
    return anim.finished.catch(() => {});
  });

  await Promise.all(animations);
  clearLiveFlyers();
}

async function completeAssignmentAfterLiveDrag(lines, resourceId, mutate, after) {
  if (transferAnimating) return;
  transferAnimating = true;

  undoBtn.disabled = true;
  resetBtn.disabled = true;
  document.body.classList.add("transfer-in-progress");

  try {
    await settleLiveFlyers(resourceId);
    mutate();
    renderAll();
    after?.();
  } finally {
    document.body.classList.remove("transfer-in-progress");
    transferAnimating = false;
    resetBtn.disabled = false;
    updateUndoButton();
  }
}

function assignSequence(sequenceKey, resourceId) {
  const matching =
    sequenceLinesInScope(sequenceKey)
      .filter(line => !line.assignedResource);

  const resource = findResource(resourceId);
  if (!resource || matching.length === 0 || transferAnimating) return;

  if (sequenceIsAccepted(sequenceKey)) {
    resultStatus.textContent =
      "This sequence is accepted. Change its Day Task Lines individually.";
    returnLiveFlyers();
    return;
  }

  const row = sequenceRows.find(r => r.key === sequenceKey);

  pushUndo(
    `${row?.taskId ?? sequenceKey} / Sequence ${row?.seq ?? ""} → ${resource.label}`,
    matching,
    { sequenceKey }
  );

  const conflicts = matching.filter(
    line => !lineFitsCapacity(line, resourceId)
  ).length;

  dragStatus.textContent =
    `Assigning ${matching.length} Day Task Lines to ${resource.label}...`;

  // Whole-sequence drops are provisional (JS-only) until Accept/Reject is
  // clicked — see acceptSequenceKeys()/rejectSequenceKeys() for the only
  // points that actually persist this to Business Central.
  completeAssignmentAfterLiveDrag(
    matching,
    resourceId,
    () => {
      matching.forEach(x => x.assignedResource = resourceId);
    },
    () => {
      pendingSequences.set(sequenceKey, { resourceId });
      matching.forEach(line => {
        line.sequenceAccepted = false;
      });

      updateDecisionButtons();
      requestAnimationFrame(renderAll);

      resultStatus.textContent =
        `${matching.length} Day Task Lines provisionally assigned to ${resource.label}` +
        (conflicts ? ` · warning: ${conflicts} outside capacity` : " · all fit in capacity") +
        ` · Accept beside ${resource.label} or use Accept All`;

      dragStatus.textContent = "Provisional sequence assignment.";
    }
  );
}

function assignSelected(lines, resourceId) {
  const resource = findResource(resourceId);
  const validLines = (lines || []).filter(Boolean);

  if (!resource || validLines.length === 0 || transferAnimating) return;

  const firstLine = validLines[0];
  if (sequenceIsPending(firstLine.sequenceKey)) {
    resultStatus.textContent =
      "This sequence is still provisional. Accept it before changing individual Day Task Lines.";
    returnLiveFlyers();
    return;
  }

  // Safety rule: selected records must all belong to the same Sequence row.
  const sequenceKeys = new Set(validLines.map(line => line.sequenceKey));
  if (sequenceKeys.size !== 1) {
    dragStatus.textContent = "Selection rejected: selected time slots must belong to one Sequence row.";
    return;
  }

  const first = validLines[0];

  pushUndo(
    `${validLines.length} selected slot${validLines.length === 1 ? "" : "s"} · ` +
      `${first.taskId} / Sequence ${first.seq} → ${resource.label}`,
    validLines
  );

  const conflicts = validLines.filter(
    line => !lineFitsCapacity(line, resourceId)
  ).length;

  dragStatus.textContent =
    `Assigning ${validLines.length} selected Day Task Line${validLines.length === 1 ? "" : "s"} to ${resource.label}...`;

  // Individual/multi-slot assignment (not a whole-sequence drag) commits to
  // Business Central immediately — matches its immediate visual commit here.
  completeAssignmentAfterLiveDrag(
    validLines,
    resourceId,
    () => {
      validLines.forEach(line => {
        line.assignedResource = resourceId;
      });
    },
    () => {
      validLines.forEach(line => {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAssignDayTaskLine", [
          JSON.stringify({
            id: line.id,
            resourceId,
            startHour: line.assignedStart,
            durationHours: line.assignedDuration
          })
        ]);
      });

      resultStatus.textContent =
        `${validLines.length} selected Day Task Line${validLines.length === 1 ? "" : "s"} assigned to ${resource.label}` +
        (conflicts ? ` · ${conflicts} capacity conflict(s)` : " · all fit in capacity");

      selectedLineIds.clear();
      selectedSequenceKey = null;
      selectionAnchorId = null;
      dragStatus.textContent = "Ready";
    }
  );
}

function assignSingle(dayTaskLineId, resourceId) {
  const line = findLine(dayTaskLineId);
  const resource = findResource(resourceId);
  if (!line || !resource || transferAnimating) return;

  pushUndo(
    `${line.taskId} / Sequence ${line.seq} / ${line.date.toLocaleDateString()} → ${resource.label}`,
    [line]
  );

  const conflict = !lineFitsCapacity(line, resourceId);

  dragStatus.textContent =
    `Assigning ${line.taskId} / Seq ${line.seq} to ${resource.label}...`;

  completeAssignmentAfterLiveDrag(
    [line],
    resourceId,
    () => {
      line.assignedResource = resourceId;
    },
    () => {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAssignDayTaskLine", [
        JSON.stringify({
          id: line.id,
          resourceId,
          startHour: line.assignedStart,
          durationHours: line.assignedDuration
        })
      ]);

      resultStatus.textContent =
        `1 Day Task Line assigned: ${line.taskId} / Seq ${line.seq} → ${resource.label}` +
        (conflict ? " · capacity conflict" : "");
      dragStatus.textContent = "Ready";
    }
  );
}

/*
  Whole-sequence drag:
  DHTMLX renders the Timeline row/column structure.
  We add a small custom pointer drag to the left column's ☰ handle because
  a sequence is an application-level aggregate, not a Scheduler event.
*/
let sequenceDrag = null;
// Created inside BOOT() (not here at top level) — this script executes
// before BC's control-add-in iframe has a <body> yet; only StartupScript
// (which calls BOOT()) is guaranteed a ready DOM.
let ghost;

// Cached across an entire drag gesture (many pointermove events, potentially
// hundreds of resource rows each requiring a getBoundingClientRect() layout
// read) — rows don't move mid-drag, so recomputing this on every pointermove
// was pure layout-thrashing overhead at real BC scale. Invalidated by
// renderResources() (and drawCapacitySlotLabels(), which shares the same
// row geometry) whenever the resource rows might actually have changed.
let _resourceRowElementsCache = null;

function invalidateResourceRowElementsCache() {
  _resourceRowElementsCache = null;
}

function getResourceRowElements() {
  if (_resourceRowElementsCache) return _resourceRowElementsCache;

  const root = document.getElementById("resourceScheduler");

  // DHTMLX Timeline left-side section cells. These are the most reliable
  // visual representation of the actual resource rows.
  let rows = Array.from(root.querySelectorAll(".dhx_matrix_scell"))
    .filter(el => {
      const rect = el.getBoundingClientRect();
      return rect.height > 15 && rect.width > 20;
    });

  // Some Scheduler builds expose matrix rows instead of scale cells.
  if (rows.length < visibleResources().length) {
    rows = Array.from(root.querySelectorAll(".dhx_matrix_line"))
      .filter(el => {
        const rect = el.getBoundingClientRect();
        return rect.height > 15;
      });
  }

  // Keep only one visible row per configured resource.
  _resourceRowElementsCache = rows.slice(0, visibleResources().length);
  return _resourceRowElementsCache;
}

function resourceFromPointer(clientY, clientX = null) {
  const root = document.getElementById("resourceScheduler");
  const data = root.querySelector(".dhx_cal_data");
  if (!data) return null;

  const rootRect = root.getBoundingClientRect();
  const dataRect = data.getBoundingClientRect();

  if (
    clientY < dataRect.top ||
    clientY > dataRect.bottom ||
    (clientX !== null && (clientX < rootRect.left || clientX > rootRect.right))
  ) {
    return null;
  }

  // First use actual DHTMLX row rectangles, sorted and de-duplicated by Y.
  const candidates = getResourceRowElements()
    .map(el => ({ el, rect: el.getBoundingClientRect() }))
    .filter(item => item.rect.height > 20)
    .sort((a, b) => a.rect.top - b.rect.top);

  const uniqueRows = [];
  for (const item of candidates) {
    const previous = uniqueRows[uniqueRows.length - 1];
    if (!previous || Math.abs(previous.rect.top - item.rect.top) > 3) {
      uniqueRows.push(item);
    }
  }

  const currentResources = visibleResources();

  for (let i = 0; i < Math.min(uniqueRows.length, currentResources.length); i++) {
    const rect = uniqueRows[i].rect;
    if (clientY >= rect.top && clientY < rect.bottom) {
      return resourceIsSkillCandidate(currentResources[i].key)
        ? currentResources[i].key
        : null;
    }
  }

  // Reliable fallback: resource Timeline was configured with dy = 52.
  const rowHeight = 52;
  const y = clientY - dataRect.top + (data.scrollTop || 0);
  const index = Math.floor(y / rowHeight);

  if (index < 0 || index >= currentResources.length) return null;
  return resourceIsSkillCandidate(currentResources[index].key)
    ? currentResources[index].key
    : null;
}

function clearResourceDropHighlight() {
  document
    .querySelectorAll("#resourceScheduler .resource-drop-target, #resourceScheduler .resource-drop-invalid")
    .forEach(el => {
      el.classList.remove("resource-drop-target");
      el.classList.remove("resource-drop-invalid");
    });
}

function highlightResourceDropTarget(resourceId) {
  clearResourceDropHighlight();
  if (!resourceId) return;

  const currentResources = visibleResources();
  const index = currentResources.findIndex(r => r.key === resourceId);
  if (index < 0) return;

  let lines = [];
  if (selectedDrag?.lines?.length) {
    lines = selectedDrag.lines;
  } else if (sequenceDrag?.sequenceKey) {
    lines = sequenceLinesInScope(sequenceDrag.sequenceKey);
  }

  const check = lines.length
    ? validateCapacity(lines, resourceId)
    : { ok: true, invalid: [] };

  const rows = getResourceRowElements();
  if (rows[index]) {
    rows[index].classList.add(
      check.ok ? "resource-drop-target" : "resource-drop-invalid"
    );
  }

  dragStatus.textContent = check.ok
    ? `Drop on ${currentResources[index].label} · skill ${appliedResourceSkillFilter() ?? "all"}`
    : `Drop allowed on ${currentResources[index].label} — warning: ${check.invalid.length} slot${check.invalid.length === 1 ? "" : "s"} outside capacity`;
}

/*
  Multi time-slot selection
  -------------------------
  - Plain click selects one slot.
  - Ctrl/Cmd-click toggles slots.
  - Shift-click selects a continuous date range.
  - A selection can only contain slots from ONE Sequence row.
  - Drag any selected bar to a resource to assign the complete selected set.
  - Clicking a resource still works as a non-drag alternative.
*/
let suppressRequestClick = false;
let slotPointer = null;
let selectedDrag = null;

function lineIdFromRequestElement(element) {
  if (!element) return null;
  const cls = Array.from(element.classList)
    .find(name => name.startsWith("dtl-"));
  return cls ? cls.slice(4) : null;
}

function selectedDragGhostText(lines) {
  if (!lines.length) return "";
  const first = lines[0];
  return `${lines.length} selected · ${first.taskId} / Sequence ${first.seq}`;
}

function allSkills() {
  return [...new Set(resources.flatMap(resource => resource.skills))].sort();
}

function renderManualFilterPopover() {
  manualFilterPopover.innerHTML = "";

  pendingManualSkillFilter =
    pendingManualSkillFilter || manualSkillFilter || activeSkillFilter || null;

  const title = document.createElement("div");
  title.className = "manual-filter-title";
  title.textContent = "Choose skill filter";
  manualFilterPopover.appendChild(title);

  const options = document.createElement("div");
  options.className = "manual-filter-options";

  const refreshSelectedOption = () => {
    options.querySelectorAll(".manual-filter-option").forEach(button => {
      button.classList.toggle(
        "active",
        button.dataset.skill === pendingManualSkillFilter
      );
    });
  };

  [...allSkills(), "Assigned"].forEach(skill => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "manual-filter-option";
    button.dataset.skill = skill;
    button.textContent = skill;
    button.title =
      skill === "Assigned"
        ? "Show resources with accepted assignments for the currently selected Request skill"
        : `Select skill: ${skill}`;

    button.addEventListener("click", event => {
      event.stopPropagation();
      pendingManualSkillFilter = skill;
      refreshSelectedOption();
      applyButton.disabled = false;
    });

    options.appendChild(button);
  });

  manualFilterPopover.appendChild(options);

  const actions = document.createElement("div");
  actions.className = "manual-filter-actions";

  const applyButton = document.createElement("button");
  applyButton.type = "button";
  applyButton.className = "manual-filter-apply";
  applyButton.textContent = "Apply filter";
  applyButton.disabled = !pendingManualSkillFilter;
  applyButton.title = "Apply the selected skill filter";

  applyButton.addEventListener("click", event => {
    event.stopPropagation();
    if (!pendingManualSkillFilter) return;

    manualSkillFilter = pendingManualSkillFilter;
    manualFilterPopover.hidden = true;

    updateResourceFilterUi();
    renderResources();

    resultStatus.textContent =
      `Manual resource filter applied: ${manualSkillFilter}.`;
  });

  actions.appendChild(applyButton);
  manualFilterPopover.appendChild(actions);

  refreshSelectedOption();
}

// ═══════════════════════════════════════════════════════════════
// BC boundary: DOM construction + event wiring (BOOT), then the
// AL-driven data entry point (SetPlanningData).
// ═══════════════════════════════════════════════════════════════

const APP_MARKUP = `
  <div id="app">
    <div id="plannerSplit" class="planner-split">
      <section id="requestPane" class="pane split-pane request-pane">
        <div class="pane-title">
          <div class="request-heading-block">
            <h2>Request</h2>
            <div class="header-actions" id="planHeaderActions">
              <button id="acceptAllBtn" type="button" disabled title="Accept all provisional sequence assignments">Accept All</button>
              <button id="rejectAllBtn" type="button" disabled title="Reject all provisional sequence assignments">Reject All</button>
              <button id="undoBtn" type="button" disabled title="Undo last assignment (Ctrl+Z)">Undo</button>
              <button id="resetBtn" type="button">Reset assignments</button>
            </div>
            <div class="sequence-scope-editor sequence-scope-single-line" id="sequenceScopeEditor">
              <span class="sequence-scope-label">PLANNING HORIZON</span>
              <strong id="scopeSequenceLabel">All sequences</strong>
              <label class="scope-date-label">
                <span>Select until</span>
                <input id="sequenceEndDateInput" type="date">
              </label>
              <button id="scope30Btn" type="button">Next 30 workdays</button>
              <span id="scopeSummary" class="scope-summary">Applies to all records</span>

              <div class="request-filter-toolbar">
                <button
                  id="requestFilterBtn"
                  class="filter-icon-button"
                  type="button"
                  title="Filter Request by Job / Task"
                  aria-label="Set Request Job and Task filter">
                  <span class="filter-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="16" height="16">
                      <path d="M3 5h18l-7 8v5l-4 2v-7L3 5z"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.8"
                            stroke-linejoin="round"/>
                    </svg>
                  </span>
                  <span class="filter-button-text">Filter</span>
                  <span id="requestFilterActiveDot" class="filter-active-dot" aria-hidden="true"></span>
                </button>

                <button
                  id="clearRequestFilterBtn"
                  class="filter-icon-button filter-reset-button"
                  type="button"
                  title="Clear Request Job / Task filter"
                  aria-label="Clear Request Job and Task filter">
                  <span class="filter-icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" width="16" height="16">
                      <path d="M3 5h18l-7 8v5l-4 2v-7L3 5z"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.8"
                            stroke-linejoin="round"/>
                      <path d="M16.5 15.5l4 4m0-4l-4 4"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.8"
                            stroke-linecap="round"/>
                    </svg>
                  </span>
                  <span class="filter-button-text">Clear</span>
                </button>

                <span id="requestFilterSummary" class="request-filter-summary-pill" hidden></span>

                <div id="requestFilterPopover" class="request-filter-popover" hidden>
                  <div class="request-filter-popover-title">Filter Request</div>

                  <label class="request-filter-popover-field">
                    <span>Job</span>
                    <select id="jobFilterSelect">
                      <option value="">All</option>
                    </select>
                  </label>

                  <label class="request-filter-popover-field">
                    <span>Task</span>
                    <select id="taskFilterSelect">
                      <option value="">All</option>
                    </select>
                  </label>

                  <div class="request-filter-popover-actions">
                    <button id="applyRequestFilterBtn" type="button">Apply filter</button>
                  </div>
                </div>
              </div>

              <span class="request-toolbar-spacer" aria-hidden="true"></span>

              <button
                id="planningSetupBtn"
                type="button"
                class="planning-setup-gear"
                title="Planning setup"
                aria-label="Planning setup">
                <svg viewBox="0 0 24 24" width="17" height="17" aria-hidden="true">
                  <path d="M9.8 3.3l.5-1.3h3.4l.5 1.3 1.8.8 1.3-.6 2.4 2.4-.6 1.3.8 1.8 1.3.5v3.4l-1.3.5-.8 1.8.6 1.3-2.4 2.4-1.3-.6-1.8.8-.5 1.3h-3.4l-.5-1.3-1.8-.8-1.3.6-2.4-2.4.6-1.3-.8-1.8-1.3-.5V9.5l1.3-.5.8-1.8-.6-1.3 2.4-2.4 1.3.6 1.8-.8z"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="1.45"
                        stroke-linejoin="round"/>
                  <circle cx="12" cy="11.2" r="3.1"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="1.45"/>
                </svg>
              </button>

              <div id="planningSetupPopover" class="planning-setup-popover" hidden>
                <div class="planning-setup-title">Timeline setup</div>
                <label class="planning-setup-field planning-setup-checkbox">
                  <input id="showWeekendsInput" type="checkbox">
                  Show Saturday / Sunday
                </label>
                <label class="planning-setup-field">
                  <span>Start at</span>
                  <select id="workdayStartInput"></select>
                </label>
                <label class="planning-setup-field">
                  <span>End at</span>
                  <select id="workdayEndInput"></select>
                </label>
                <label class="planning-setup-field planning-setup-field-stacked">
                  <span>Sequence skill behavior</span>
                  <select id="sequenceSkillBehaviorInput">
                    <option value="highlight">Highlight matching sequences</option>
                    <option value="filter">Show only matching sequences</option>
                  </select>
                </label>
        <label class="setup-field">
          <span>Hierarchy density</span>
          <select id="hierarchyDensityInput">
            <option value="compact">Compact</option>
            <option value="normal">Normal</option>
          </select>
        </label>
                <div class="planning-setup-actions">
                  <button id="applyPlanningSetupBtn" type="button">Apply setup</button>
                </div>
              </div>
            </div>
          </div>
          <div class="legend">
            <span><i class="legend-chip request"></i>Requested Day Task Line</span>
            <span><i class="legend-chip capacity"></i>Capacity</span>
            <span><i class="legend-chip assigned"></i>Assignment</span>
            <span><i class="legend-chip conflict"></i>Outside capacity</span>
          </div>
          <div id="dragStatus" class="status">Ready</div>
        </div>
        <div id="requestScheduler" class="scheduler-box"></div>
      </section>

      <div
        id="paneSplitter"
        class="pane-splitter"
        role="separator"
        aria-orientation="horizontal"
        aria-label="Resize request and resource panes"
        tabindex="0">
        <span class="pane-splitter-grip" aria-hidden="true"></span>
      </div>

      <section id="resourcePane" class="pane split-pane resource-pane">
        <div class="pane-title">
          <div class="resource-heading-block resource-heading-compact">
            <div class="resource-heading-line">
              <h2>Assignment</h2>
              <div class="resource-filter-toolbar">
              <button
                id="manualFilterBtn"
                class="filter-icon-button"
                type="button"
                title="Applied filter: none"
                aria-label="Set resource skill filter">
                <span class="filter-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24" width="16" height="16">
                    <path d="M3 5h18l-7 8v5l-4 2v-7L3 5z"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="1.8"
                          stroke-linejoin="round"/>
                  </svg>
                </span>
                <span class="filter-button-text">Filter</span>
                <span id="filterActiveDot" class="filter-active-dot" aria-hidden="true"></span>
              </button>

              <button
                id="resetFilterBtn"
                class="filter-icon-button filter-reset-button"
                type="button"
                title="Reset the applied resource-skill filter"
                aria-label="Clear resource skill filter">
                <span class="filter-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24" width="16" height="16">
                    <path d="M3 5h18l-7 8v5l-4 2v-7L3 5z"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="1.8"
                          stroke-linejoin="round"/>
                    <path d="M16.5 15.5l4 4m0-4l-4 4"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="1.8"
                          stroke-linecap="round"/>
                  </svg>
                </span>
                <span class="filter-button-text">Clear</span>
              </button>

              <span id="resourceFilterSummary" class="resource-filter-summary"></span>
              </div>
              <div id="manualFilterPopover" class="manual-filter-popover" hidden></div>
            </div>
          </div>
          <div id="resultStatus" class="status">No assignments yet</div>
        </div>
        <div id="resourceScheduler" class="scheduler-box"></div>
          <div id="assignmentTimelineScrollbar" class="assignment-timeline-scrollbar" aria-label="Assignment timeline horizontal scrollbar">
            <div id="assignmentTimelineScrollbarContent" class="assignment-timeline-scrollbar-content"></div>
          </div>
      </section>
    </div>
  </div>

    <div id="sequenceDragTooltip" class="sequence-drag-tooltip" hidden></div>
    <div id="assignmentDetailTooltip" class="assignment-detail-tooltip" hidden></div>
    <div id="requestDetailTooltip" class="request-detail-tooltip" hidden></div>
    <div id="resourceSkillWarningTooltip" class="resource-skill-warning-tooltip" hidden></div>

    <div id="slotContextMenu" class="slot-context-menu" hidden></div>

    <div id="simplePopupBackdrop" class="simple-popup-backdrop" hidden>
      <div class="simple-popup" role="dialog" aria-modal="true" aria-labelledby="simplePopupText">
        <div id="simplePopupText" class="simple-popup-text">Under Construction</div>
        <button id="simplePopupCloseBtn" type="button">OK</button>
      </div>
    </div>
`;

let schedulersInitialized = false;

// Loading overlay — same mechanism as the other DHX add-ins in this project
// (e.g. poolresourceschedule/wrapper.js's _createResLoadingOverlay): shown at
// the earliest point this add-in's JS runs (well before ControlReady's
// round-trip completes, since the default 30-workday-across-all-jobs window
// can take real seconds to build), hidden once SetPlanningData finishes
// rendering. A safety timer guards against it ever getting stuck if a load
// cycle's hide call is never reached.
let _loadingOverlay = null;
let _loadingSafetyTimer = null;

function _createLoadingOverlay(host) {
  if (_loadingOverlay) return;

  const style = document.createElement("style");
  style.textContent = [
    "#req-loading-overlay {",
    "  position:absolute; inset:0; z-index:100000;",
    "  display:none; align-items:center; justify-content:center;",
    "  background:rgba(255,255,255,0.55);",
    "}",
    "#req-loading-overlay .rlo-box {",
    "  background:#fff; border:1px solid #d8d8d8; border-radius:6px;",
    "  box-shadow:0 6px 24px rgba(0,0,0,0.25);",
    "  padding:18px 26px; width:190px; text-align:center;",
    "  font:13px/1.4 'Segoe UI', Tahoma, sans-serif;",
    "}",
    "#req-loading-overlay .rlo-bar {",
    "  height:16px; border:1px solid #2f6fdb; border-radius:2px; overflow:hidden;",
    "  margin-bottom:10px; background:#fff;",
    "}",
    "#req-loading-overlay .rlo-bar-fill {",
    "  height:100%; width:200%;",
    "  background-image: repeating-linear-gradient(-55deg, #2f6fdb 0 8px, #eaf1fd 8px 16px);",
    "  animation: rlo-slide 0.9s linear infinite;",
    "}",
    "@keyframes rlo-slide { from { transform: translateX(-50%); } to { transform: translateX(0%); } }",
    "#req-loading-overlay .rlo-title { color:#2f6fdb; font-weight:700; font-size:16px; letter-spacing:1px; }",
    "#req-loading-overlay .rlo-sub { color:#8a8a8a; margin-top:2px; }"
  ].join("\n");
  document.head.appendChild(style);

  const overlay = document.createElement("div");
  overlay.id = "req-loading-overlay";
  overlay.innerHTML =
    '<div class="rlo-box">' +
      '<div class="rlo-bar"><div class="rlo-bar-fill"></div></div>' +
      '<div class="rlo-title">LOADING</div>' +
      '<div class="rlo-sub">Please wait...</div>' +
    '</div>';

  if (!host.style.position) host.style.position = "relative";
  host.appendChild(overlay);
  _loadingOverlay = overlay;
}

function _showLoading() {
  if (!_loadingOverlay) return;
  _loadingOverlay.style.display = "flex";
  if (_loadingSafetyTimer) clearTimeout(_loadingSafetyTimer);
  _loadingSafetyTimer = setTimeout(_hideLoading, 180000);
}

function _hideLoading() {
  if (_loadingOverlay) _loadingOverlay.style.display = "none";
  if (_loadingSafetyTimer) { clearTimeout(_loadingSafetyTimer); _loadingSafetyTimer = null; }
}

window.BOOT = function BOOT() {
  const host = document.getElementById("controlAddIn");
  host.style.width = "100%";
  host.style.height = "100%";
  host.style.margin = "0";
  host.style.padding = "0";
  host.innerHTML = APP_MARKUP;

  // Show immediately — earliest point this add-in's own JS runs, well before
  // ControlReady/SetPlanningData's round-trip ever completes.
  _createLoadingOverlay(host);
  _showLoading();

  dragStatus = document.getElementById("dragStatus");
  resultStatus = document.getElementById("resultStatus");
  resetBtn = document.getElementById("resetBtn");
  undoBtn = document.getElementById("undoBtn");
  acceptAllBtn = document.getElementById("acceptAllBtn");
  rejectAllBtn = document.getElementById("rejectAllBtn");
  sequenceEndDateInput = document.getElementById("sequenceEndDateInput");
  scopeSequenceLabel = document.getElementById("scopeSequenceLabel");
  scopeSummary = document.getElementById("scopeSummary");
  scope30Btn = document.getElementById("scope30Btn");
  requestFilterBtn = document.getElementById("requestFilterBtn");
  clearRequestFilterBtn = document.getElementById("clearRequestFilterBtn");
  requestFilterActiveDot = document.getElementById("requestFilterActiveDot");
  requestFilterSummary = document.getElementById("requestFilterSummary");
  requestFilterPopover = document.getElementById("requestFilterPopover");
  jobFilterSelect = document.getElementById("jobFilterSelect");
  taskFilterSelect = document.getElementById("taskFilterSelect");
  applyRequestFilterBtn = document.getElementById("applyRequestFilterBtn");
  planningSetupBtn = document.getElementById("planningSetupBtn");
  planningSetupPopover = document.getElementById("planningSetupPopover");
  showWeekendsInput = document.getElementById("showWeekendsInput");
  workdayStartInput = document.getElementById("workdayStartInput");
  workdayEndInput = document.getElementById("workdayEndInput");
  sequenceSkillBehaviorInput = document.getElementById("sequenceSkillBehaviorInput");
  hierarchyDensityInput = document.getElementById("hierarchyDensityInput");
  applyPlanningSetupBtn = document.getElementById("applyPlanningSetupBtn");
  manualFilterBtn = document.getElementById("manualFilterBtn");
  resetFilterBtn = document.getElementById("resetFilterBtn");
  resourceFilterSummary = document.getElementById("resourceFilterSummary");
  filterActiveDot = document.getElementById("filterActiveDot");
  manualFilterPopover = document.getElementById("manualFilterPopover");
  plannerSplit = document.getElementById("plannerSplit");
  requestPane = document.getElementById("requestPane");
  resourcePane = document.getElementById("resourcePane");
  paneSplitter = document.getElementById("paneSplitter");
  sequenceDragTooltip = document.getElementById("sequenceDragTooltip");
  assignmentDetailTooltip = document.getElementById("assignmentDetailTooltip");
  requestDetailTooltip = document.getElementById("requestDetailTooltip");
  assignmentTimelineScrollbar = document.getElementById("assignmentTimelineScrollbar");
  assignmentTimelineScrollbarContent = document.getElementById("assignmentTimelineScrollbarContent");
  resourceSkillWarningTooltip = document.getElementById("resourceSkillWarningTooltip");
  slotContextMenu = document.getElementById("slotContextMenu");
  simplePopupBackdrop = document.getElementById("simplePopupBackdrop");
  simplePopupText = document.getElementById("simplePopupText");
  simplePopupCloseBtn = document.getElementById("simplePopupCloseBtn");

  ghost = document.createElement("div");
  ghost.id = "sequenceGhost";
  document.body.appendChild(ghost);

  if (typeof Scheduler === "undefined") {
    console.error("DHX scheduler library (dhtmlxscheduler.js) not found. Please include it in ControlAddIn Scripts.");
    return;
  }

  document.getElementById("resourceScheduler").addEventListener("click", event => {
    const resourceTarget = event.target.closest("[data-resource-click]");
    if (!resourceTarget) return;

    event.stopPropagation();
    showSimplePopup("Under Construction");
  }, true);

  document.getElementById("requestScheduler").addEventListener("click", event => {
    const projectTarget = event.target.closest("[data-project-click]");
    if (projectTarget) {
      event.stopPropagation();
      showSimplePopup("Open project card");
      return;
    }

    const taskTarget = event.target.closest("[data-task-click]");
    if (taskTarget) {
      event.stopPropagation();
      showSimplePopup("Open task card");
      return;
    }

    const sequenceTarget = event.target.closest("[data-sequence-select]");
    if (
      sequenceTarget &&
      !event.target.closest(".seq-drag") &&
      !event.target.closest(".dhx_cal_event, .dhx_cal_event_line")
    ) {
      event.stopPropagation();

      const sequenceKey =
        sequenceTarget.dataset.sequenceSelect;

      selectedLineIds.clear();

      sequenceAllLines(sequenceKey)
        .filter(line => !line.assignedResource)
        .forEach(line => selectedLineIds.add(line.id));

      selectedSequenceKey = sequenceKey;
      selectionAnchorId = null;

      activateSkillFilter(sequenceKey, { render: false });
      activateSequenceScope(sequenceKey, { render: false });
      requestAnimationFrame(renderAll);
      refreshSelectionClasses();
    }
  }, true);

  simplePopupCloseBtn.addEventListener("click", hideSimplePopup);
  simplePopupBackdrop.addEventListener("click", event => {
    if (event.target === simplePopupBackdrop) hideSimplePopup();
  });

  document.addEventListener("click", event => {
    if (!slotContextMenu.hidden && !slotContextMenu.contains(event.target)) {
      hideSlotContextMenu();
    }
  });

  window.addEventListener("blur", hideSlotContextMenu);
  window.addEventListener("resize", hideSlotContextMenu);

  paneSplitter.addEventListener("pointerdown", beginPaneSplit);
  window.addEventListener("pointermove", movePaneSplit);
  window.addEventListener("pointerup", finishPaneSplit);
  window.addEventListener("pointercancel", finishPaneSplit);

  paneSplitter.addEventListener("keydown", event => {
    const currentHeight = requestPane.getBoundingClientRect().height;
    const step = event.shiftKey ? 60 : 24;

    if (event.key === "ArrowUp") {
      event.preventDefault();
      setRequestPaneHeight(currentHeight - step);
    } else if (event.key === "ArrowDown") {
      event.preventDefault();
      setRequestPaneHeight(currentHeight + step);
    }
  });

  window.addEventListener("resize", () => {
    fitPlannerToViewport();
  });

  document.getElementById("requestScheduler").addEventListener("click", event => {
    if (
      event.target.closest(".dhx_cal_event, .dhx_cal_event_line") ||
      event.target.closest("[data-sequence-select]") ||
      event.target.closest("[data-project-click]") ||
      event.target.closest("[data-task-click]") ||
      event.target.closest("button, input, select, a")
    ) {
      return;
    }

    const emptyTimelineArea = event.target.closest(
      ".dhx_cal_data, .dhx_matrix_cell, .dhx_matrix_line"
    );

    if (!emptyTimelineArea) return;

    clearSelection({ render: true });
  }, true);

  document.getElementById("requestScheduler").addEventListener("mousemove", event => {
    const line =
      requestLineFromPointerTarget(event.target);

    if (!line) {
      hideRequestTooltip();
      return;
    }

    requestDetailTooltip.innerHTML =
      requestTooltipHtml(line);

    requestDetailTooltip.hidden = false;

    moveRequestTooltip(
      event.clientX,
      event.clientY
    );
  }, true);

  document.getElementById("requestScheduler").addEventListener("mouseleave", () => {
    hideRequestTooltip();
  }, true);

  document.getElementById("requestScheduler").addEventListener("contextmenu", event => {
    const sequenceRow =
      event.target.closest(".seq-cell[data-sequence-select]");

    if (sequenceRow) {
      const sequenceKey =
        sequenceRow.dataset.sequenceSelect;

      selectedLineIds.clear();
      selectedSequenceKey = sequenceKey;
      selectionAnchorId = null;

      activateSkillFilter(sequenceKey, { render: true });
      activateSequenceScope(sequenceKey, { render: false });

      showSlotContextMenu(event, {
        type: "sequence",
        sequenceKey
      });
      return;
    }

    const eventElement =
      event.target.closest(".dhx_cal_event, .dhx_cal_event_line");

    if (!eventElement) return;

    const eventId =
      eventElement.getAttribute("event_id") ||
      eventElement.getAttribute("data-event-id");

    let schedulerEvent = null;
    try {
      schedulerEvent = requestScheduler.getEvent(eventId);
    } catch {
      schedulerEvent = null;
    }

    if (!schedulerEvent?.dayTaskLineId) return;

    showSlotContextMenu(event, {
      type: "request",
      lineId: schedulerEvent.dayTaskLineId
    });
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mouseover", event => {
    const warning =
      event.target.closest(".resource-skill-warning[data-resource-warning]");

    if (!warning) return;

    const resource =
      findResource(warning.dataset.resourceWarning);

    if (!resource) return;

    showResourceSkillWarningTooltip(
      resource,
      event.clientX,
      event.clientY
    );
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mousemove", event => {
    const warning =
      event.target.closest(".resource-skill-warning[data-resource-warning]");

    if (!warning) {
      if (
        !resourceSkillWarningTooltip.hidden &&
        !event.target.closest(".assignment-detail-tooltip")
      ) {
        hideResourceSkillWarningTooltip();
      }
      return;
    }

    const resource =
      findResource(warning.dataset.resourceWarning);

    if (!resource) return;

    if (resourceSkillWarningTooltip.hidden) {
      showResourceSkillWarningTooltip(
        resource,
        event.clientX,
        event.clientY
      );
      return;
    }

    moveResourceSkillWarningTooltip(
      event.clientX,
      event.clientY
    );
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mouseout", event => {
    const warning =
      event.target.closest(".resource-skill-warning[data-resource-warning]");

    if (!warning) return;

    const relatedWarning =
      event.relatedTarget?.closest?.(
        ".resource-skill-warning[data-resource-warning]"
      );

    if (relatedWarning === warning) return;

    hideResourceSkillWarningTooltip();
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mouseover", event => {
    const line = assignmentLineFromPointerTarget(event.target);
    if (!line) return;

    showAssignmentDetailTooltip(
      line,
      event.clientX,
      event.clientY
    );
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mousemove", event => {
    const line = assignmentLineFromPointerTarget(event.target);

    if (!line) {
      hideAssignmentDetailTooltip();
      return;
    }

    if (assignmentDetailTooltip.hidden) {
      showAssignmentDetailTooltip(
        line,
        event.clientX,
        event.clientY
      );
      return;
    }

    moveAssignmentDetailTooltip(
      event.clientX,
      event.clientY
    );
  }, true);

  document.getElementById("resourceScheduler").addEventListener("mouseout", event => {
    const leavingAssignment =
      event.target.closest(".dhx_cal_event, .dhx_cal_event_line");

    if (!leavingAssignment) return;

    const enteringAssignment =
      event.relatedTarget?.closest?.(".dhx_cal_event, .dhx_cal_event_line");

    if (enteringAssignment === leavingAssignment) return;

    hideAssignmentDetailTooltip();
  }, true);

  document.getElementById("resourceScheduler").addEventListener("contextmenu", event => {
    const assignmentElement =
      event.target.closest(".dhx_cal_event, .dhx_cal_event_line");

    if (assignmentElement) {
      showSlotContextMenu(event, { type: "assignment" });
      return;
    }

    const capacity =
      capacityOverlayAtPoint(
        event.clientX,
        event.clientY
      );

    if (!capacity) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    showSimplePopup("Open Edit week pattern");
  }, true);

  document.getElementById("resourceScheduler").addEventListener("pointerdown", event => {
    const handle = event.target.closest(".assignment-left-resize-handle");
    if (handle) {
      beginAcceptedLeftResize(event, handle);
      return;
    }

    // Compact rows can make the inner handle difficult to hit.
    // Treat the first 8px of an accepted assignment as the start-time resize zone.
    const eventElement = event.target.closest(".dhx_cal_event, .dhx_cal_event_line");
    if (!eventElement) return;

    const rect = eventElement.getBoundingClientRect();
    const withinLeftResizeZone =
      event.clientX >= rect.left &&
      event.clientX <= rect.left + 8;

    if (!withinLeftResizeZone) return;

    const eventId =
      eventElement.getAttribute("event_id") ||
      eventElement.getAttribute("data-event-id");

    if (!eventId) return;

    let schedulerEvent = null;
    try {
      schedulerEvent = resourceScheduler.getEvent(eventId);
    } catch {
      return;
    }

    if (!schedulerEvent?.accepted) return;

    beginAcceptedLeftResize(event, eventElement);
  }, true);

  window.addEventListener("pointermove", moveAcceptedLeftResize, true);
  window.addEventListener("pointerup", finishAcceptedLeftResize, true);
  window.addEventListener("pointercancel", finishAcceptedLeftResize, true);

  document.getElementById("resourceScheduler").addEventListener(
    "pointerdown",
    beginAssignmentPointerEdit,
    false
  );

  window.addEventListener("pointermove", moveAssignmentPointerEdit, false);
  window.addEventListener("pointerup", finishAssignmentPointerEdit, false);
  window.addEventListener("pointercancel", finishAssignmentPointerEdit, false);

  document.getElementById("requestScheduler").addEventListener("click", event => {
    const rowCell = event.target.closest(".seq-cell[data-sequence-select]");
    if (!rowCell || event.target.closest(".seq-drag")) return;

    const sequenceKey = rowCell.dataset.sequenceSelect;

    selectedLineIds.clear();
    selectedSequenceKey = sequenceKey;
    selectionAnchorId = null;

    activateSkillFilter(sequenceKey, { render: false });
    activateSequenceScope(sequenceKey, { render: false });
    requestAnimationFrame(renderAll);
  });

  document.addEventListener("pointerdown", event => {
    const handle = event.target.closest(".seq-drag");
    if (!handle) return;

    const sequenceKey = handle.dataset.sequenceKey;
    const row = sequenceRows.find(r => r.key === sequenceKey);
    if (!row || sequenceIsAccepted(sequenceKey)) return;

    selectedLineIds.clear();

    const allLines =
      sequenceLinesInScope(sequenceKey);

    const lines =
      allLines.filter(line => !line.assignedResource);

    allLines.forEach(line => {
      selectedLineIds.add(line.id);
    });

    selectedSequenceKey = sequenceKey;
    selectionAnchorId = allLines[0]?.id ?? null;

    if (!lines.length) {
      hideSequenceDragTooltip();
      showSimplePopup(
        "All Day Task Lines in this Sequence are already assigned"
      );
      return;
    }

    createLiveFlyers(
      lines,
      event.clientX,
      event.clientY
    );

    showSequenceDragTooltip(
      lines.length,
      event.clientX,
      event.clientY
    );

    refreshSelectionClasses();

    activateSkillFilter(
      sequenceKey,
      { render: false }
    );

    activateSequenceScope(
      sequenceKey,
      { render: false }
    );

    sequenceDrag = {
      pointerId: event.pointerId,
      sequenceKey,
      lineIds: lines.map(line => line.id)
    };

    // The selection/filter refresh above can replace the original handle in the DOM.
    // Capture only while it is still attached; document-level listeners keep the drag alive.
    if (handle.isConnected && Number.isInteger(event.pointerId)) {
      try {
        handle.setPointerCapture(event.pointerId);
      } catch (_error) {
        // The drag remains document-bound when capture is unavailable.
      }
    }

    ghost.style.display = "none";
    document.body.classList.add("sequence-dragging");
    dragStatus.textContent = `Dragging complete ${row.taskId} / Seq ${row.seq}...`;
    event.preventDefault();
  });

  document.addEventListener("pointermove", event => {
    if (!sequenceDrag || event.pointerId !== sequenceDrag.pointerId) return;

    moveSequenceDragTooltip(
      event.clientX,
      event.clientY
    );

    const resourceId = resourceFromPointer(event.clientY, event.clientX);
    moveLiveFlyers(event.clientX, event.clientY, resourceId);
    highlightResourceDropTarget(resourceId);
  });

  document.addEventListener("pointerup", event => {
    if (!sequenceDrag || event.pointerId !== sequenceDrag.pointerId) return;

    hideSequenceDragTooltip();

    const sequenceKey = sequenceDrag.sequenceKey;
    sequenceDrag = null;
    ghost.style.display = "none";
    document.body.classList.remove("sequence-dragging");
    clearResourceDropHighlight();

    const resourceId = resourceFromPointer(event.clientY, event.clientX);
    if (!resourceId) {
      dragStatus.textContent = "Drop on a resource row, not on the header.";
      returnLiveFlyers();
      return;
    }

    assignSequence(sequenceKey, resourceId);
  });

  document.addEventListener("pointerdown", event => {
    if (transferAnimating || sequenceDrag) return;

    const bar = event.target.closest("#requestScheduler .request-event, #requestScheduler .request-assigned");
    if (!bar) return;

    const lineId = lineIdFromRequestElement(bar);
    const line = lineId ? findLine(lineId) : null;
    if (!line) return;

    // Do NOT change selection on pointerdown. Ctrl/Shift selection is
    // finalized on pointerup. If this becomes a drag, we decide then.
    slotPointer = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      lineId: line.id,
      ctrlKey: event.ctrlKey || event.metaKey,
      shiftKey: event.shiftKey,
      dragging: false
    };
  }, true);

  document.addEventListener("pointermove", event => {
    if (!slotPointer || event.pointerId !== slotPointer.pointerId || sequenceDrag) return;

    const dx = event.clientX - slotPointer.startX;
    const dy = event.clientY - slotPointer.startY;
    const distance = Math.hypot(dx, dy);

    if (!slotPointer.dragging && distance >= 6) {
      const draggedLine = findLine(slotPointer.lineId);
      if (!draggedLine) return;

      // Starting a drag on an unselected bar means: drag this bar only.
      // Starting on a selected bar means: drag the complete current selection.
      if (!selectedLineIds.has(draggedLine.id)) {
        selectedLineIds.clear();
        selectedLineIds.add(draggedLine.id);
        selectedSequenceKey = draggedLine.sequenceKey;
        selectionAnchorId = draggedLine.id;
        refreshSelectionClasses();
      }

      activateSkillFilter(draggedLine.sequenceKey, { render: true });

      const lines = getSelectedLines();
      if (!lines.length) return;

      slotPointer.dragging = true;
      selectedDrag = {
        pointerId: event.pointerId,
        lines
      };

      createLiveFlyers(lines, event.clientX, event.clientY);
      ghost.style.display = "none";
      document.body.classList.add("sequence-dragging");
      suppressRequestClick = true;
    }

    if (!slotPointer.dragging || !selectedDrag) return;

    const resourceId = resourceFromPointer(event.clientY, event.clientX);
    moveLiveFlyers(event.clientX, event.clientY, resourceId);
    highlightResourceDropTarget(resourceId);
  }, true);

  document.addEventListener("pointerup", event => {
    if (!slotPointer || event.pointerId !== slotPointer.pointerId || sequenceDrag) return;

    const pointerState = slotPointer;
    const wasDragging = pointerState.dragging;
    slotPointer = null;

    if (!wasDragging) {
      const line = findLine(pointerState.lineId);
      if (!line) return;

      if (pointerState.shiftKey) {
        selectRange(line);
      } else if (pointerState.ctrlKey) {
        toggleSelection(line);
      } else {
        setSingleSelection(line);
      }

      dragStatus.textContent =
        `${describeSelection()}. Drag any selected slot to a resource.`;
      return;
    }

    if (!selectedDrag) return;

    const lines = selectedDrag.lines;
    selectedDrag = null;

    ghost.style.display = "none";
    document.body.classList.remove("sequence-dragging");
    clearResourceDropHighlight();

    const resourceId = resourceFromPointer(event.clientY, event.clientX);

    if (resourceId) {
      assignSelected(lines, resourceId);
    } else {
      dragStatus.textContent =
        `${describeSelection()}. Drag cancelled; selection kept.`;
      returnLiveFlyers();
    }

    // Prevent the Scheduler click generated by the same pointer gesture.
    setTimeout(() => {
      suppressRequestClick = false;
    }, 0);
  }, true);

  document.getElementById("resourceScheduler").addEventListener("click", event => {
    if (transferAnimating || selectedDrag) return;

    const lines = getSelectedLines();
    if (!lines.length) return;

    const resourceId = resourceFromPointer(event.clientY, event.clientX);
    if (!resourceId) return;

    assignSelected(lines, resourceId);
  });

  document.getElementById("resourceScheduler").addEventListener("click", event => {
    const acceptButton = event.target.closest(".resource-accept-btn");
    const rejectButton = event.target.closest(".resource-reject-btn");
    const button = acceptButton || rejectButton;

    if (!button) return;

    event.preventDefault();
    event.stopPropagation();

    const resourceId = button.dataset.resourceId;
    if (!resourceId) return;

    if (acceptButton) {
      acceptForResource(resourceId);
    } else {
      rejectForResource(resourceId);
    }
  }, true);

  requestFilterBtn.addEventListener("click", event => {
    event.stopPropagation();

    if (requestFilterPopover.hidden) {
      pendingRequestJobFilter = requestJobFilter;
      pendingRequestTaskFilter = requestTaskFilter;
      populateRequestFilters();
      requestFilterPopover.hidden = false;
    } else {
      requestFilterPopover.hidden = true;
    }
  });

  jobFilterSelect.addEventListener("change", () => {
    pendingRequestJobFilter = jobFilterSelect.value;
    pendingRequestTaskFilter = "";
    populateRequestFilters();
  });

  taskFilterSelect.addEventListener("change", () => {
    pendingRequestTaskFilter = taskFilterSelect.value;
  });

  applyRequestFilterBtn.addEventListener("click", event => {
    event.stopPropagation();
    applyRequestFilters();
  });

  clearRequestFilterBtn.addEventListener("click", event => {
    event.stopPropagation();

    requestJobFilter = "";
    requestTaskFilter = "";
    pendingRequestJobFilter = "";
    pendingRequestTaskFilter = "";

    requestFilterPopover.hidden = true;

    selectedLineIds.clear();
    selectedSequenceKey = null;
    selectionAnchorId = null;

    updateRequestFilterUi();
    renderRequest();
  });

  requestFilterPopover.addEventListener("click", event => {
    event.stopPropagation();
  });

  populatePlanningSetupInputs();
  updatePlanningSetupButtonUi();

  if (
    requestPane &&
    planningSetupBtn.parentElement !== requestPane
  ) {
    requestPane.appendChild(planningSetupBtn);
  }

  if (
    requestPane &&
    planningSetupPopover.parentElement !== requestPane
  ) {
    requestPane.appendChild(planningSetupPopover);
  }

  requestAnimationFrame(mountRequestFilterToolbar);

  planningSetupBtn.addEventListener("click", event => {
    event.stopPropagation();

    if (planningSetupPopover.hidden) {
      populatePlanningSetupInputs();
      planningSetupPopover.hidden = false;
    } else {
      planningSetupPopover.hidden = true;
    }
  });

  applyPlanningSetupBtn.addEventListener("click", event => {
    event.stopPropagation();
    applyPlanningSetup();
  });

  planningSetupPopover.addEventListener("click", event => {
    event.stopPropagation();
  });

  manualFilterBtn.addEventListener("click", event => {
    event.stopPropagation();

    if (manualFilterPopover.hidden) {
      pendingManualSkillFilter =
        manualSkillFilter || activeSkillFilter || null;
      renderManualFilterPopover();
      manualFilterPopover.hidden = false;
    } else {
      manualFilterPopover.hidden = true;
    }
  });

  resetFilterBtn.addEventListener("click", () => {
    manualSkillFilter = null;
    pendingManualSkillFilter = null;
    activeSkillFilter = null;
    activeSkillSequenceKey = null;
    manualFilterPopover.hidden = true;

    updateResourceFilterUi();
    renderResources();

    resultStatus.textContent = "Resource skill filter reset.";
  });

  document.addEventListener("click", event => {
    if (
      !manualFilterPopover.hidden &&
      !manualFilterPopover.contains(event.target) &&
      event.target !== manualFilterBtn
    ) {
      manualFilterPopover.hidden = true;
    }

    if (
      !planningSetupPopover.hidden &&
      !planningSetupPopover.contains(event.target) &&
      event.target !== planningSetupBtn
    ) {
      planningSetupPopover.hidden = true;
    }

    if (
      !requestFilterPopover.hidden &&
      !requestFilterPopover.contains(event.target) &&
      event.target !== requestFilterBtn
    ) {
      requestFilterPopover.hidden = true;
    }
  });

  sequenceEndDateInput.addEventListener("change", () => {
    const value = parseDateOnly(sequenceEndDateInput.value);

    if (!value) {
      updateSequenceScopeEditor(activeScopeSequenceKey);
      return;
    }

    setGlobalSelectionEndDate(value);
    updateSequenceScopeEditor(activeScopeSequenceKey);
    renderRequest();

    resultStatus.textContent =
      `Planning horizon changed for all records through ${getGlobalSelectionEndDate().toLocaleDateString("en-GB")}.`;
  });

  scope30Btn.addEventListener("click", () => {
    setScopeToNext30Workdays();

    resultStatus.textContent =
      `Planning horizon for all records set to the next 30 workdays through ${getGlobalSelectionEndDate().toLocaleDateString("en-GB")}.`;
  });

  acceptAllBtn.addEventListener("click", acceptAllPending);
  rejectAllBtn.addEventListener("click", rejectAllPending);
  undoBtn.addEventListener("click", undoLastAssignment);

  document.addEventListener("keydown", event => {
    const target = event.target;
    const isEditable =
      target instanceof HTMLInputElement ||
      target instanceof HTMLTextAreaElement ||
      target?.isContentEditable;

    if (!isEditable && (event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "z") {
      event.preventDefault();
      undoLastAssignment();
    }
  });

  // The source demo's Reset button called an undefined function
  // (makeDayTaskLines()) and was therefore dead code — clicking it just
  // threw. Fixed here to do what a "Reset assignments" action should
  // actually mean against a real backend: discard all unsaved client-side
  // state and reload the current period fresh from Business Central.
  resetBtn.addEventListener("click", () => {
    if (transferAnimating) return;
    _showLoading();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnRequestReset", []);
  });

  window.addEventListener("resize", syncExternalAssignmentScrollbarGeometry);

  // Native "scroll" events don't bubble, so this uses the capture phase to
  // catch a vertical scroll inside the resource row list (e.g. when there
  // are more resources than fit the viewport) — row rects shift, so the
  // getResourceRowElements() cache must not survive that.
  document.addEventListener("scroll", event => {
    if (event.target?.closest?.("#resourceScheduler")) {
      invalidateResourceRowElementsCache();
    }
  }, true);

  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
};

// Defensive JSON parser — tolerant of a trailing comma, mirrors the pattern
// already used by the other DHX add-ins in this project.
function parsePlanningDataJson(jsonText) {
  if (typeof jsonText !== "string") return jsonText;
  try {
    return JSON.parse(jsonText);
  } catch (_error) {
    try {
      return JSON.parse(jsonText.replace(/,\s*([}\]])/g, "$1"));
    } catch (error) {
      console.error("SetPlanningData: invalid JSON", error, jsonText);
      return null;
    }
  }
}

// AL-callable. Carries the full payload (resources/dayTaskLines/
// capacitySlots/skillColors/statusColors/workdays) — called once on
// ControlReady's response, and again by the Refresh ribbon action and the
// "Reset assignments" button (both just ask AL to rebuild-and-resend for
// the current default period, so all unsaved client-side state is always
// discarded here, matching a full reset's intent).
function SetPlanningData(planningDataJsonTxt) {
  const data = parsePlanningDataJson(planningDataJsonTxt);
  if (!data) return;

  workdays = (data.workdays || []).map(parseDateOnly).filter(Boolean);

  resources = (data.resources || []).map(item => ({
    key: item.key,
    label: item.label,
    skills: Array.isArray(item.skills) ? [...item.skills] : []
  }));
  rebuildResourcesByKey();

  skillColors = (data.skillColors || []).map(item => ({ ...item }));

  statusColors = data.statusColors || {
    ok: { backgroundColor: "#DDF2E5", textColor: "#26613A" }
  };

  capacitySlots = (data.capacitySlots || []).map(item => ({ ...item }));
  rebuildCapacitySlotIndex();

  dayTaskLines = (data.dayTaskLines || []).map(item => ({
    ...item,
    date: parseDateOnly(item.date),
    // `sequenceNo` is table 50610 "Day Planning"."Sequence No." (field 9), sent by AL's
    // ReqAssign_BuildDayTaskLinesJson - a real per-thread ordinal (1, 2, 3, ...) distinguishing
    // independently-created threads that share the same [Job No., Job Task No., Skill], same
    // identity/numbering as the Day Planning Sequence add-in's rows. Every label/tooltip that
    // reads `line.seq` shows this number now, not the Skill code.
    seq: item.sequenceNo,
    assignedResource: item.assignedResource || null,
    sequenceAccepted: !!item.sequenceAccepted
  }));

  rebuildRequestTree();

  // Every SetPlanningData call (initial load, Refresh, Reset) means "start
  // over" — discard any unsaved client-side selection/provisional state.
  selectedLineIds.clear();
  selectedSequenceKey = null;
  selectionAnchorId = null;
  pendingSequences.clear();
  undoStack.length = 0;
  activeSkillFilter = null;
  activeSkillSequenceKey = null;
  manualSkillFilter = null;
  pendingManualSkillFilter = null;
  activeScopeSequenceKey = null;
  globalSelectionEndDate = null;
  clearResourceDropHighlight();

  installSkillColorStyles();
  installStatusColorStyles();

  pendingRequestJobFilter = requestJobFilter;
  pendingRequestTaskFilter = requestTaskFilter;
  populateRequestFilters();
  updateRequestFilterUi();

  getGlobalSelectionEndDate();
  updateSequenceScopeEditor(null);
  updateResourceFilterUi();

  if (!schedulersInitialized) {
    schedulersInitialized = true;

    // DHTMLX computes each Timeline's internal row buffer from whatever
    // pixel height its .scheduler-box pane has AT createTimelineView() time,
    // and never recalculates it afterward - confirmed live against real BC
    // data: with 211 resources, repeated setCurrentView()/resize calls after
    // creation never grew the rendered row count past ~19, but the pane
    // still only had the CSS default (.scheduler-box { height: 360px }) at
    // the moment the schedulers were normally created here, since
    // fitPlannerToViewport() (which sets the real, viewport-derived height)
    // only ran on a later requestAnimationFrame. Sizing the panes correctly
    // first, before creation, makes DHTMLX size its own row buffer to the
    // real content area from the start.
    fitPlannerToViewport();

    requestScheduler = createRequestScheduler();
    resourceScheduler = createResourceScheduler();
    document.body.classList.add("hierarchy-density-compact");

    requestAnimationFrame(() => {
      installHorizontalTimelineSync();
    });

    requestAnimationFrame(() => {
      ensureLowerTimelineLeftShield();

      const resourceRoot =
        document.getElementById("resourceScheduler");

      const timeline =
        resourceScheduler.getView("resources");

      if (
        timeline &&
        typeof timeline.attachEvent === "function" &&
        !timeline._capacityOverlayScrollBound
      ) {
        timeline._capacityOverlayScrollBound = true;

        timeline.attachEvent("onScroll", function() {
          scheduleCapacityOverlaySync();
        });
      }

      if (
        resourceRoot &&
        !resourceRoot.dataset.capacityWheelBound
      ) {
        resourceRoot.dataset.capacityWheelBound = "1";

        resourceRoot.addEventListener(
          "wheel",
          scheduleCapacityOverlaySync,
          { passive: true }
        );
      }
    });
  }

  dragStatus.textContent = "Ready";
  resultStatus.textContent = "No assignments yet";

  renderAll();
  updateUndoButton();
  updateDecisionButtons();

  requestAnimationFrame(() => {
    requestPaneRatio = 0.50;
    fitPlannerToViewport();

    requestAnimationFrame(() => {
      fitPlannerToViewport();
    });
  });

  // True last step of every load cycle (initial ControlReady, Refresh action,
  // or the in-canvas Reset button) — always hide, even on a re-entrant call,
  // so the overlay never gets stuck.
  _hideLoading();
}
