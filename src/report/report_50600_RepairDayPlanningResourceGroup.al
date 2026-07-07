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
        n := RepairDayPlanningPoolResourceNo();
        n += RepairForemanTree();
        n += RepairResourceMandatorySchedulling();
        n += RepairDayPlanningVendorNo();
        n += RepairDemoResourceCapacity();
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

    var
    //myInt: Integer;
}