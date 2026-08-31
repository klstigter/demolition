query 50712 "Day Planning By Job Task"
{
    // Single-pass replacement for the per-Job-Task Record.FindSet() loop that used to live in
    // codeunit 50613's GetDayPlanningsByJobTaskAsJson/GetResourcesByJobTaskAsJson (N+1 round
    // trips against the huge "Day Planning" table - one FindSet() per marked Job Task). Callers
    // filter on JobNoFilter/JobTaskNoFilter (each an AL '|' OR-list built from the requested
    // "JobNo|JobTaskNo" keys) plus PlanDateFilter, then post-filter each returned row against the
    // exact key set in AL (List.Contains) to stay correct even if a Job No./Job Task No. pairing
    // wouldn't otherwise be implied by the two independent OR-lists.
    QueryType = Normal;
    Caption = 'Day Planning By Job Task';

    elements
    {
        dataitem(Day_Planning; "Day Planning")
        {
            filter(JobNoFilter; "Job No.") { }
            filter(JobTaskNoFilter; "Job Task No.") { }
            filter(PlanDateFilter; "Plan Date") { }

            column(SystemId; SystemId) { }
            column(JobNo; "Job No.") { }
            column(JobTaskNo; "Job Task No.") { }
            column(PlanDate; "Plan Date") { }
            column(DayLineNo; "Day Line No.") { }
            column(StartTimeAssigned; "Start Time Assigned") { }
            column(EndTimeAssigned; "End Time Assigned") { }
            column(StartTimeRequested; "Start Time Requested") { }
            column(EndTimeRequested; "End Time Requested") { }
            column(AssignedHours; "Assigned Hours") { }
            column(RequestedHours; "Requested Hours") { }
            column(NonWorkingMinutesAssigned; "Non Working Minutes Assigned") { }
            column(NonWorkingMinutesRequested; "Non Working Minutes Requested") { }
            column(AssignedResourceNo; "Assigned Resource No.") { }
            column(RequestedResourceNo; "Requested Resource No.") { }
            column(VendorNo; "Vendor No.") { }
            column(PlanStatus; "Plan Status") { }
            column(WorkOrderNo; "Work Order No.") { }
        }
    }
}
