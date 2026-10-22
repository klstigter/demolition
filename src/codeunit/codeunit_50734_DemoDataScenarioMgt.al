codeunit 50734 "Demo Data Scenario Mgt."
{
    Access = Public;

    procedure GetHardcodedDayPlannings(var DP: Record "Day Planning" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        Res: Record Resource;
        JobTask: Record "Job Task";
        Content: Text;
        Lines: List of [Text];
        Parts: List of [Text];
        Line: Text;
        LineNo: Integer;
        DayLineNo: Integer;
        SeqNo: Integer;
        NonWorkMin: Integer;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ReqResNo: Code[20];
        AsgResNo: Code[20];
        TaskKey: Text;
        TaskCache: Dictionary of [Text, Boolean];
        ResCache: Dictionary of [Code[20], Boolean];
        VendorCache: Dictionary of [Code[20], Code[20]];
        GrpCache: Dictionary of [Code[20], Code[20]];
        TaskOk: Boolean;
        ReqHours: Decimal;
        AsgHours: Decimal;
    begin
        // Loads src/data/DemoDayPlannings.csv (20 columns, see header row). Lines whose Job Task or
        // Requested/Assigned Resource do not exist, or whose PK already exists, are skipped silently.
        // Fills DP (caller's temporary record) only - no DB writes, no logging, no commit.
        DP.Reset();
        DP.DeleteAll();
        Content := NavApp.GetResourceAsText('DemoDayPlannings.csv', TextEncoding::UTF8);
        Lines := Content.Split(TypeHelper.LFSeparator());
        foreach Line in Lines do begin
            LineNo += 1;
            Line := Line.TrimEnd();
            if (LineNo > 1) and (Line <> '') then begin
                Parts := Line.Split(',');
                if Parts.Count() >= 20 then begin
                    JobNo := CopyStr(Parts.Get(1).Trim(), 1, MaxStrLen(JobNo));
                    JobTaskNo := CopyStr(Parts.Get(2).Trim(), 1, MaxStrLen(JobTaskNo));
                    ReqResNo := CopyStr(Parts.Get(9).Trim(), 1, MaxStrLen(ReqResNo));
                    AsgResNo := CopyStr(Parts.Get(15).Trim(), 1, MaxStrLen(AsgResNo));

                    TaskKey := JobNo + '|' + JobTaskNo;
                    if not TaskCache.Get(TaskKey, TaskOk) then begin
                        JobTask.SetLoadFields("Job No.", "Job Task No.");
                        TaskOk := JobTask.Get(JobNo, JobTaskNo);
                        TaskCache.Add(TaskKey, TaskOk);
                    end;

                    if TaskOk and CacheResource(Res, ReqResNo, ResCache, VendorCache, GrpCache) and
                       CacheResource(Res, AsgResNo, ResCache, VendorCache, GrpCache)
                    then begin
                        Evaluate(DayLineNo, Parts.Get(3).Trim());
                        begin
                            DP.Init();
                            DP."Job No." := JobNo;
                            DP."Job Task No." := JobTaskNo;
                            DP."Day Line No." := DayLineNo;
                            DP."Plan Date" := ParseCsvDate(Parts.Get(4).Trim());
                            Evaluate(DP."Plan Status", Parts.Get(5).Trim());
                            DP.Skill := CopyStr(Parts.Get(6).Trim(), 1, MaxStrLen(DP.Skill));
                            if Evaluate(SeqNo, Parts.Get(7).Trim()) then
                                DP."Sequence No." := SeqNo;
                            DP.Description := CopyStr(Parts.Get(8).Trim(), 1, MaxStrLen(DP.Description));
                            DP."Requested Resource No." := ReqResNo;
                            DP."Requested Pool Resource No." := CopyStr(Parts.Get(10).Trim(), 1, MaxStrLen(DP."Requested Pool Resource No."));
                            DP."Start Time Requested" := ParseCsvTime(Parts.Get(11).Trim());
                            DP."End Time Requested" := ParseCsvTime(Parts.Get(12).Trim());
                            if Evaluate(NonWorkMin, Parts.Get(13).Trim()) then
                                DP."Non Working Minutes Requested" := NonWorkMin;
                            if Evaluate(ReqHours, Parts.Get(14).Trim()) then
                                DP."Requested Hours" := ReqHours;
                            DP."Assigned Resource No." := AsgResNo;
                            DP."Assigned Pool Resource No." := CopyStr(Parts.Get(16).Trim(), 1, MaxStrLen(DP."Assigned Pool Resource No."));
                            DP."Start Time Assigned" := ParseCsvTime(Parts.Get(17).Trim());
                            DP."End Time Assigned" := ParseCsvTime(Parts.Get(18).Trim());
                            if Evaluate(NonWorkMin, Parts.Get(19).Trim()) then
                                DP."Non Working Minutes Assigned" := NonWorkMin;
                            if Evaluate(AsgHours, Parts.Get(20).Trim()) then
                                DP."Assigned Hours" := AsgHours;
                            DP."Data Owner" := "Data Owner Opt."::"Planner";
                            if AsgResNo <> '' then begin
                                DP."Resource Group No." := GrpCache.Get(AsgResNo);
                                DP."Vendor No." := VendorCache.Get(AsgResNo);
                            end else
                                if ReqResNo <> '' then begin
                                    DP."Resource Group No." := GrpCache.Get(ReqResNo);
                                    DP."Vendor No." := VendorCache.Get(ReqResNo);
                                end;
                            DP.AssignedCheck();
                            DP.Assigned := DP."Assigned Resource No." <> '';
                            DP.Insert(false);
                        end;
                    end;
                end;
            end;
        end;
    end;

    procedure GetHardcodedCapacities(var TempCap: Record "Res. Capacity Entry" temporary)
    var
        TempDP: Record "Day Planning" temporary;
        Res: Record Resource;
        HoursByKey: Dictionary of [Text, Decimal];
        KeyList: List of [Text];
        GrpCache: Dictionary of [Code[20], Code[20]];
        ResNo: Code[20];
        KeyTxt: Text;
        Hours: Decimal;
        Cap: Decimal;
        EntryNo: Integer;
        StartT: Time;
    begin
        // Fills TempCap only (no DB writes). Capacity is derived from the hardcoded Day Planning rows
        // so the two stay consistent: per (resource, date) = 110% of the sum of max(Requested,
        // Assigned hours) of its lines, rounded up to 0.5 h. The resource is the Assigned Resource,
        // otherwise the Requested Resource. No entries for resources/dates without day planning.
        TempCap.Reset();
        TempCap.DeleteAll();
        GetHardcodedDayPlannings(TempDP);
        if TempDP.FindSet() then
            repeat
                if TempDP."Assigned Resource No." <> '' then
                    ResNo := TempDP."Assigned Resource No."
                else
                    ResNo := TempDP."Requested Resource No.";
                if ResNo <> '' then begin
                    KeyTxt := ResNo + '|' + Format(TempDP."Plan Date", 0, 9);
                    Hours := TempDP."Requested Hours";
                    if TempDP."Assigned Hours" > Hours then
                        Hours := TempDP."Assigned Hours";
                    if HoursByKey.ContainsKey(KeyTxt) then
                        HoursByKey.Set(KeyTxt, HoursByKey.Get(KeyTxt) + Hours)
                    else begin
                        HoursByKey.Add(KeyTxt, Hours);
                        KeyList.Add(KeyTxt);
                    end;
                end;
            until TempDP.Next() = 0;

        Res.SetLoadFields("No.", "Resource Group No.");
        foreach KeyTxt in KeyList do begin
            Cap := Round(HoursByKey.Get(KeyTxt) * 1.1, 0.5, '>');
            if Cap > 0 then begin
                ResNo := CopyStr(KeyTxt, 1, StrPos(KeyTxt, '|') - 1);
                if not GrpCache.ContainsKey(ResNo) then begin
                    if Res.Get(ResNo) then
                        GrpCache.Add(ResNo, Res."Resource Group No.")
                    else
                        GrpCache.Add(ResNo, '');
                end;
                EntryNo += 1;
                TempCap.Init();
                TempCap."Entry No." := EntryNo;
                TempCap."Resource No." := ResNo;
                Evaluate(TempCap.Date, CopyStr(KeyTxt, StrPos(KeyTxt, '|') + 1), 9);
                StartT := 070000T;
                TempCap."Start Time" := StartT;
                if Cap * 3600000 > 16 * 3600000 then
                    TempCap."End Time" := 235900T
                else
                    TempCap."End Time" := StartT + Cap * 3600000;
                TempCap.Capacity := Cap;
                TempCap."Resource Group No." := GrpCache.Get(ResNo);
                TempCap.Insert(false);
            end;
        end;
    end;

    local procedure CacheResource(var Res: Record Resource; ResNo: Code[20]; var ResCache: Dictionary of [Code[20], Boolean]; var VendorCache: Dictionary of [Code[20], Code[20]]; var GrpCache: Dictionary of [Code[20], Code[20]]): Boolean
    var
        Found: Boolean;
    begin
        if ResNo = '' then
            exit(true);
        if ResCache.Get(ResNo, Found) then
            exit(Found);
        Res.SetLoadFields("No.", "Resource Group No.", "Vendor No.");
        Found := Res.Get(ResNo);
        ResCache.Add(ResNo, Found);
        if Found then begin
            VendorCache.Add(ResNo, Res."Vendor No.");
            GrpCache.Add(ResNo, Res."Resource Group No.");
        end;
        exit(Found);
    end;

    local procedure ParseCsvDate(Txt: Text): Date
    var
        YearInt: Integer;
        MonthInt: Integer;
        DayInt: Integer;
    begin
        if StrLen(Txt) < 10 then
            exit(0D);
        Evaluate(YearInt, CopyStr(Txt, 1, 4));
        Evaluate(MonthInt, CopyStr(Txt, 6, 2));
        Evaluate(DayInt, CopyStr(Txt, 9, 2));
        exit(DMY2Date(DayInt, MonthInt, YearInt));
    end;

    local procedure ParseCsvTime(Txt: Text): Time
    var
        H: Integer;
        M: Integer;
        S: Integer;
    begin
        if StrLen(Txt) < 8 then
            exit(0T);
        Evaluate(H, CopyStr(Txt, 1, 2));
        Evaluate(M, CopyStr(Txt, 4, 2));
        Evaluate(S, CopyStr(Txt, 7, 2));
        exit(000000T + ((H * 3600) + (M * 60) + S) * 1000);
    end;
}
