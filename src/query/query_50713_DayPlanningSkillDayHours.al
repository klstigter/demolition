query 50713 "Day Planning Skill Day Hours"
{
    // Capacity Planning Dashboard (page 50724) Section 4 perf fix (2026-09-11) - SQL-side
    // replacement for the old per-line company-wide "Day Planning" scan (codeunit 50604's
    // CPO_ScanOtherWorkOrderGroups + CPO_BuildOtherWorkOrderLinesForGroups, which the dashboard used
    // to reuse from src/dhx/capacity_planning_overview, paginated via a background task because
    // building per-line JSON - description lookups, time formatting - for every Day Planning row
    // company-wide could be slow/large). This query groups by Skill + Plan Date only (no Job/Task/
    // Sequence dimension - the dashboard's own Section 4 tree is now a flat Skill-only list, see
    // capacityPlanningDashboard.js's buildCentralSections override) and sums Requested/Assigned
    // Hours in the database instead of AL looping every row and building per-line JSON, so the
    // result set is always tiny (distinct skills x days in the visible window), never paginated.
    //
    // Deliberately NOT reused by page 50722 "Capacity Planning Overview" - that page's own Section 4
    // still needs full per-line/Job/Task/Sequence detail for its drilldown tree, which this
    // aggregated query cannot provide; it keeps using its own existing (untouched) builders.
    QueryType = Normal;
    Caption = 'Day Planning Skill Day Hours';

    elements
    {
        dataitem(Day_Planning; "Day Planning")
        {
            filter(PlanDateFilter; "Plan Date") { }
            filter(SkillFilter; Skill) { }

            column(Skill; Skill) { }
            column(PlanDate; "Plan Date") { }
            column(RequestedHours; "Requested Hours")
            {
                Method = Sum;
            }
            column(AssignedHours; "Assigned Hours")
            {
                Method = Sum;
            }
        }
    }
}
