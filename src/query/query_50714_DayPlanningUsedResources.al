query 50714 "Day Planning Used Resources"
{
    // Distinct (Assigned Resource No., Requested Resource No.) combinations of "Day Planning",
    // used by codeunit 50613 GetResourcesAsJson(AnchorDate, JobNo, JobTaskNo) so pass 1 no longer
    // has to FindSet() every matching Day Planning row. No aggregation -> grouped by both columns.
    QueryType = Normal;
    Caption = 'Day Planning Used Resources';

    elements
    {
        dataitem(Day_Planning; "Day Planning")
        {
            filter(JobNoFilter; "Job No.") { }
            filter(JobTaskNoFilter; "Job Task No.") { }
            filter(PlanDateFilter; "Plan Date") { }

            column(AssignedResourceNo; "Assigned Resource No.") { }
            column(RequestedResourceNo; "Requested Resource No.") { }
        }
    }
}
