report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
                  tabledata Resource = rimd,
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
        n: Integer;
    begin
        //<< create code here
        n := RepairDayPlanningPoolResourceNo();
        n += RepairForemanTree();
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

                if DayPlanning."Pool Resource No." <> NewPoolResNo then begin
                    DayPlanning."Pool Resource No." := NewPoolResNo;
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

    var
    //myInt: Integer;
}