report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = r,
                  tabledata "Res. Capacity Entry" = rimd;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        CreateDemoDataCU: Codeunit "Create Demo Data";
        LogEntry: Record "Demo Data Log Entry";
        CalendarCode: Code[10];
        CountBefore: Integer;
        CountAfter: Integer;
        CapacityDeleted: Integer;
    begin
        CapacityDeleted := DeleteUnmatchedResourceCapacity();
        Message('Finished. %1 Res. Capacity Entry record(s) with no matching Day Planning demand for the same resource/date were deleted.', CapacityDeleted);
    end;

    // Deletes every "Res. Capacity Entry" row that has no matching Day Planning demand for the
    // same resource on the same date. A capacity entry survives only if "Day Planning" has at
    // least one row with "Assigned Resource No." = the capacity entry's "Resource No." AND
    // "Plan Date" = the capacity entry's Date - otherwise it is deleted. No date range: applies
    // across all dates.
    //
    // The aggregate Capacity total (1,183,823) was still far above Requested Hours (low
    // hundred-thousands) after the earlier blanket Jan-May date-range deletion, because that
    // approach deleted/kept whole date ranges regardless of whether any given resource actually
    // had demand on any given day. This replaces that with a precise per-(resource, date) match
    // against actual Day Planning demand instead.
    //
    // Implementation: build the full set of distinct "Assigned Resource No."|"Plan Date" keys
    // from Day Planning in one pass (same key-building pattern as gResDaySlotUsed in codeunit
    // 50602 "Create Demo Data" / the old per-skill resource-date key in codeunit 50662 "Skill
    // Capacity Analysis Mgt."), then make a single pass over Res. Capacity Entry deleting any
    // row whose "Resource No."|Date key isn't in that set. Two linear passes plus dictionary
    // lookups is far cheaper than a nested Day Planning lookup per capacity row.
    local procedure DeleteUnmatchedResourceCapacity(): Integer
    var
        DayPlanning: Record "Day Planning";
        ResCap: Record "Res. Capacity Entry";
        DemandKeys: Dictionary of [Text, Boolean];
        ResourceDateKey: Text;
        n: Integer;
    begin
        DayPlanning.SetCurrentKey("Assigned Resource No.", "Plan Date");
        DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        if DayPlanning.FindSet() then
            repeat
                ResourceDateKey := StrSubstNo('%1|%2', DayPlanning."Assigned Resource No.", Format(DayPlanning."Plan Date", 0, 9));
                if not DemandKeys.ContainsKey(ResourceDateKey) then
                    DemandKeys.Add(ResourceDateKey, true);
            until DayPlanning.Next() = 0;

        if ResCap.FindSet(true) then
            repeat
                ResourceDateKey := StrSubstNo('%1|%2', ResCap."Resource No.", Format(ResCap.Date, 0, 9));
                if not DemandKeys.ContainsKey(ResourceDateKey) then begin
                    ResCap.Delete();
                    n += 1;
                end;
            until ResCap.Next() = 0;

        exit(n);
    end;
}
