report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rim;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        MakeFreeCapacityExternalMandatoryData();
    end;

    local procedure MakeFreeCapacityExternalMandatoryData()
    var
        Res: Record Resource;
        Vend: Record Vendor;
        ResCap: Record "Res. Capacity Entry";
        ResCapCheck: Record "Res. Capacity Entry";
        TestDate: Date;
        EntryNo: Integer;
        NeedsModify: Boolean;
        ResNo: Code[20];
    begin
        // Throwaway manual-testing data: manufactures a resource that is both External and
        // Mandatory Schedulling, with Res. Capacity Entry rows for the currently-displayed
        // week (2026-09-14..2026-09-18), so the new "Free Capacity - External (Mandatory)"
        // chart segment on page 50692 has something to render. See codeunit 50662
        // CalcCapacitySplit for the classification this feeds.
        ResNo := 'EXTMND-TEST';

        if not Res.Get(ResNo) then begin
            if not Vend.FindFirst() then
                exit; // nothing sane to link Vendor No. to - test-data-only code, skip gracefully

            Res.Init();
            Res."No." := ResNo;
            Res.Name := 'External Mandatory Test Resource';
            Res.Type := Res.Type::Person;
            Res.Insert();

            Res."Vendor No." := Vend."No.";
            Res."Is External" := true;
            Res."Mandatory Schedulling" := true;
            Res.Modify();
        end else begin
            NeedsModify := false;
            if not Res."Is External" then begin
                if Res."Vendor No." = '' then begin
                    if not Vend.FindFirst() then
                        exit;
                    Res."Vendor No." := Vend."No.";
                end;
                Res."Is External" := true;
                NeedsModify := true;
            end;
            if not Res."Mandatory Schedulling" then begin
                Res."Mandatory Schedulling" := true;
                NeedsModify := true;
            end;
            if NeedsModify then
                Res.Modify();
        end;

        ResCap.Reset();
        if ResCap.FindLast() then
            EntryNo := ResCap."Entry No." + 1
        else
            EntryNo := 1;

        for TestDate := 20260914D to 20260918D do begin
            ResCapCheck.SetRange("Resource No.", ResNo);
            ResCapCheck.SetRange(Date, TestDate);
            if ResCapCheck.IsEmpty() then begin
                ResCap.Init();
                ResCap."Entry No." := EntryNo;
                ResCap."Resource No." := ResNo;
                ResCap.Date := TestDate;
                ResCap.Capacity := 8;
                ResCap."Resource Group No." := Res."Resource Group No.";
                ResCap.Insert();
                EntryNo += 1;
            end;
        end;
    end;
}
