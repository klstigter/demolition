report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
                  tabledata Resource = rimd,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata "Work-Hour Template" = r;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        n: Integer;
    begin
        //<< create code here
        // n := RepairDayPlanningPoolResourceNo();
        // n += RepairForemanTree();
        // n += RepairResourceMandatorySchedulling();
        // n += RepairDayPlanningVendorNo();
        // n += RepairDemoResourceCapacity();
        //>>

        //<< new repair function here:
        // n += RepairDemoResourceUniqueNames();
        // n += RepairDayPlanningResourceName();
        // n += RepairDemoResourceCapacityRegenerate();
        //>>
        Message('Finished. %1 record(s) repaired.', n);
    end;

    local procedure RepairDayPlanningPoolResourceNo(): Integer
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        ResourceNo: Code[20];
        NewPoolResNo: Code[20];
        n: Integer;
    begin
        // Assigned Resource No. is more dominant than Requested Resource No.: if it is filled,
        // the Pool Resource No. follows it; otherwise it follows Requested Resource No.
        if DayPlanning.FindSet(true) then
            repeat
                if DayPlanning."Assigned Resource No." <> '' then
                    ResourceNo := DayPlanning."Assigned Resource No."
                else
                    ResourceNo := DayPlanning."Requested Resource No.";

                if ResourceNo = '' then
                    NewPoolResNo := ''
                else
                    if Resource.Get(ResourceNo) then
                        NewPoolResNo := Resource."Pool Resource No."
                    else
                        NewPoolResNo := '';

                if DayPlanning."Assigned Pool Resource No." <> NewPoolResNo then begin
                    DayPlanning."Assigned Pool Resource No." := NewPoolResNo;
                    DayPlanning.Modify();
                    n += 1;
                end;
            until DayPlanning.Next() = 0;
        exit(n);
    end;

    local procedure RepairForemanTree(): Integer
    var
        Pool: Record Resource;
        Member: Record Resource;
        ForemanNo: Code[20];
        n: Integer;
    begin
        // A Pool resource ("Is Pool" = true) is a vendor/grouping placeholder, not a real
        // worker, so it must never be the foreman. Re-point the hierarchy at the first real
        // (non-pool) member of that pool instead, and follow through to any Resource whose
        // "Default Foreman" and any "Day Planning"."Team Leader" still reference the pool.
        Pool.SetRange("Is Pool", true);
        if Pool.FindSet(true) then
            repeat
                if Pool."Is Foreman" then begin
                    Pool."Is Foreman" := false;
                    Pool.Modify();
                    n += 1;
                end;

                Member.Reset();
                Member.SetRange("Pool Resource No.", Pool."No.");
                Member.SetRange("Is Pool", false);
                Member.SetFilter("No.", '<>%1', Pool."No.");
                if Member.FindFirst() then begin
                    ForemanNo := Member."No.";

                    if not Member."Is Foreman" then begin
                        Member."Is Foreman" := true;
                        Member.Modify();
                        n += 1;
                    end;

                    Member.SetFilter("No.", '<>%1&<>%2', Pool."No.", ForemanNo);
                    if Member.FindSet(true) then
                        repeat
                            if Member."Default Foreman" <> ForemanNo then begin
                                Member."Default Foreman" := ForemanNo;
                                Member.Modify();
                                n += 1;
                            end;
                        until Member.Next() = 0;

                    n += RepairDayPlanningTeamLeader(Pool."No.", ForemanNo);
                end;
            until Pool.Next() = 0;
        exit(n);
    end;

    local procedure RepairDayPlanningTeamLeader(OldLeaderNo: Code[20]; NewLeaderNo: Code[20]): Integer
    var
        DayPlanning: Record "Day Planning";
        n: Integer;
    begin
        DayPlanning.SetRange("Team Leader", OldLeaderNo);
        if DayPlanning.FindSet(true) then
            repeat
                DayPlanning."Team Leader" := NewLeaderNo;
                DayPlanning.Modify();
                n += 1;
            until DayPlanning.Next() = 0;
        exit(n);
    end;

    local procedure RepairResourceMandatorySchedulling(): Integer
    var
        Resource: Record Resource;
        NewValue: Boolean;
        n: Integer;
    begin
        // Adapt existing resource data (created before this randomization existed) to the same
        // ~60% true / 40% false split demo data creation now uses, for resources that qualify
        // (not Pool, not External).
        Resource.SetRange("Is Pool", false);
        Resource.SetRange("Is External", false);
        if Resource.FindSet(true) then
            repeat
                NewValue := (Random(100) <= 60);
                if Resource."Mandatory Schedulling" <> NewValue then begin
                    Resource."Mandatory Schedulling" := NewValue;
                    Resource.Modify();
                    n += 1;
                end;
            until Resource.Next() = 0;
        exit(n);
    end;

    local procedure RepairDayPlanningVendorNo(): Integer
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        ResourceNo: Code[20];
        NewVendorNo: Code[20];
        n: Integer;
    begin
        // Assigned Resource No. is more dominant than Requested Resource No.
        if DayPlanning.FindSet(true) then
            repeat
                if DayPlanning."Assigned Resource No." <> '' then
                    ResourceNo := DayPlanning."Assigned Resource No."
                else
                    ResourceNo := DayPlanning."Requested Resource No.";

                if ResourceNo = '' then
                    NewVendorNo := ''
                else
                    if Resource.Get(ResourceNo) then
                        NewVendorNo := Resource."Vendor No."
                    else
                        NewVendorNo := '';

                if DayPlanning."Vendor No." <> NewVendorNo then begin
                    DayPlanning."Vendor No." := NewVendorNo;
                    DayPlanning.Modify();
                    n += 1;
                end;
            until DayPlanning.Next() = 0;
        exit(n);
    end;

    local procedure RepairDemoResourceCapacity(): Integer
    var
        Res: Record Resource;
        ResCap: Record "Res. Capacity Entry";
        WorkHourTemplate: Record "Work-Hour Template";
        StartDate: Date;
        EndDate: Date;
        DT: Date;
        EntryNo: Integer;
        n: Integer;
    begin
        // Pool leaders (DRP*) and members (DRM*) are the resources actually used for Day
        // Planning assignment; backfill capacity for any of them still missing it, using the
        // same date window demo data creation uses (start of last week through +110 weeks).
        StartDate := CalcDate('<WD1-1W>', Today());
        EndDate := CalcDate('+110W', StartDate);

        Res.SetFilter("No.", 'DRP*|DRM*');
        if Res.FindSet() then
            repeat
                if not WorkHourTemplate.Get(Res."Work Hour Template") then
                    Clear(WorkHourTemplate);

                ResCap.Reset();
                if ResCap.FindLast() then
                    EntryNo := ResCap."Entry No." + 1
                else
                    EntryNo := 1;

                for DT := StartDate to EndDate do
                    if IsWorkingDay(DT, WorkHourTemplate) then begin
                        Res.SetRange("Date Filter", DT);
                        Res.CalcFields(Capacity);
                        if Res.Capacity = 0 then begin
                            ResCap.Init();
                            ResCap."Entry No." := EntryNo;
                            ResCap."Resource No." := Res."No.";
                            ResCap.Date := DT;
                            ResCap.Capacity := 8;
                            ResCap."Resource Group No." := Res."Resource Group No.";
                            ResCap."Start Time" := 080000T;
                            ResCap."End Time" := 160000T;
                            ResCap.Insert();
                            EntryNo += 1;
                            n += 1;
                        end;
                    end;
                Commit();
            until Res.Next() = 0;
        exit(n);
    end;

    local procedure IsWorkingDay(DT: Date; var WorkHourTemplate: Record "Work-Hour Template"): Boolean
    begin
        case Date2DWY(DT, 1) of
            1:
                exit(WorkHourTemplate.Monday <> 0);
            2:
                exit(WorkHourTemplate.Tuesday <> 0);
            3:
                exit(WorkHourTemplate.Wednesday <> 0);
            4:
                exit(WorkHourTemplate.Thursday <> 0);
            5:
                exit(WorkHourTemplate.Friday <> 0);
            6:
                exit(WorkHourTemplate.Saturday <> 0);
            7:
                exit(WorkHourTemplate.Sunday <> 0);
            else
                exit(false);
        end;
    end;

    local procedure RepairDemoResourceUniqueNames(): Integer
    var
        Resource: Record Resource;
        CreateDemoData: Codeunit "Create Demo Data";
        NewName: Text[100];
        SequenceNo: Integer;
        n: Integer;
    begin
        // Old (pre-fix) demo data generator only had a 20 first names x 20 last names = 400
        // combination pool, so the ~34,725 existing DRP*/DRM*/DRE* resources are full of
        // duplicate names (e.g. many different "No." values all named "Jennifer Martinez").
        // Reassign every demo resource a unique name from the same collision-free permutation
        // the generator now uses, via the reusable GetUniqueDemoResourceName() on codeunit 50602 -
        // only the Name field is touched, nothing else about the resource is changed.
        Resource.SetFilter("No.", 'DRP*|DRM*|DRE*');
        if Resource.FindSet(true) then
            repeat
                NewName := CreateDemoData.GetUniqueDemoResourceName(SequenceNo);
                SequenceNo += 1;
                if Resource.Name <> NewName then begin
                    Resource.Validate(Name, NewName);
                    Resource.Modify();
                    n += 1;
                end;
                // Commit periodically so this ~34,725-record run doesn't hold one long
                // transaction/lock for its whole duration (same pattern as RepairDemoResourceCapacity).
                if SequenceNo mod 1000 = 0 then
                    Commit();
            until Resource.Next() = 0;
        exit(n);
    end;

    local procedure RepairDayPlanningResourceName(): Integer
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        ResourceNo: Code[20];
        n: Integer;
        RecCount: Integer;
    begin
        // Description is a plain stored field (not a FlowField, unlike "Vendor Name" and "Pool
        // Resource Name" on this table), set from Resource.Name inside the OnValidate triggers for
        // "Assigned Resource No."/"Requested Resource No.". It goes stale on existing Day Planning
        // records once Resource.Name is repaired (see RepairDemoResourceUniqueNames), so re-copy it
        // here. Assigned Resource No. is more dominant than Requested Resource No. - same dominance
        // rule as RepairDayPlanningPoolResourceNo/RepairDayPlanningVendorNo above.
        if DayPlanning.FindSet(true) then
            repeat
                if DayPlanning."Assigned Resource No." <> '' then
                    ResourceNo := DayPlanning."Assigned Resource No."
                else
                    ResourceNo := DayPlanning."Requested Resource No.";

                if (ResourceNo <> '') and Resource.Get(ResourceNo) then
                    if DayPlanning.Description <> Resource.Name then begin
                        DayPlanning.Description := Resource.Name;
                        DayPlanning.Modify();
                        n += 1;
                    end;

                // Commit periodically so this run doesn't hold one long transaction/lock for its
                // whole duration (same pattern as RepairDemoResourceCapacity).
                RecCount += 1;
                if RecCount mod 1000 = 0 then
                    Commit();
            until DayPlanning.Next() = 0;
        exit(n);
    end;

    local procedure RepairDemoResourceCapacityRegenerate(): Integer
    var
        Res: Record Resource;
        ResCap: Record "Res. Capacity Entry";
        CreateDemoData: Codeunit "Create Demo Data";
        StartDate: Date;
        EndDate: Date;
        DT: Date;
        EntryNo: Integer;
        n: Integer;
    begin
        // Fix 1 (randomized 8-24h daily capacity, see GetRandomDailyCapacity on codeunit 50602)
        // only affects newly-created capacity going forward. Existing NL_Test data was generated
        // by older/buggier runs and can have multiple Res. Capacity Entry rows per resource+date
        // with inconsistent values (e.g. Resource Capacity Matrix shows a correct-looking summed
        // total for a date, while the scheduler renders a separate ~5-minute event for that same
        // resource/date from a leftover bad row) - no display-side fix can repair genuinely bad
        // stored data, so this wipes and regenerates capacity for every demo pool resource using
        // the exact same date window and working-day/randomization logic the generator uses.
        //
        // Scope matches CreateDemoResourceCapacity: pool leaders (DRP*) and members (DRM*) only -
        // external resources (DRE*) are vendor-linked and are not capacity-planned.
        //
        // NOTE (operational): at ~34,000 DRP/DRM resources x up to ~550 working days each across
        // the 110-week window, this is on the order of ~15-19 million individual delete+insert
        // operations. Running this as a single interactive report execution is very likely NOT
        // practical - see the accompanying report to the user/coordinator on chunking this before
        // running it for real (e.g. via a scheduled Job Queue entry instead of an interactive
        // report, or by narrowing this procedure's resource/date scope across multiple runs).
        CreateDemoData.GetDemoDateWindow(StartDate, EndDate);

        ResCap.Reset();
        if ResCap.FindLast() then
            EntryNo := ResCap."Entry No." + 1
        else
            EntryNo := 1;

        Res.SetFilter("No.", 'DRP*|DRM*');
        if Res.FindSet() then
            repeat
                ResCap.Reset();
                ResCap.SetRange("Resource No.", Res."No.");
                ResCap.DeleteAll(false);

                for DT := StartDate to EndDate do
                    if CreateDemoData.IsDemoWorkingDay(DT) then begin
                        ResCap.Init();
                        ResCap."Entry No." := EntryNo;
                        ResCap."Resource No." := Res."No.";
                        ResCap.Date := DT;
                        ResCap.Capacity := CreateDemoData.GetRandomDailyCapacity(ResCap."Start Time", ResCap."End Time");
                        ResCap."Resource Group No." := Res."Resource Group No.";
                        ResCap.Insert();
                        EntryNo += 1;
                        n += 1;
                    end;

                // Commit after each resource (~up to 550 rows) so this doesn't hold one enormous
                // transaction/lock across ~34,000 resources - same per-resource pattern as
                // RepairDemoResourceCapacity above.
                Commit();
            until Res.Next() = 0;
        exit(n);
    end;

    var
    //myInt: Integer;
}