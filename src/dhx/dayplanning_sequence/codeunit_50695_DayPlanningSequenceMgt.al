/// <summary>
/// Business logic for "Day Planning Sequence" (control add-in page 50711): assigns/repairs the
/// small-ordinal "Sequence No." field on table 50610 "Day Planning" (row/thread identity =
/// (Job No., Job Task No., Skill, Sequence No.)), and generates/regenerates a whole thread of Day
/// Planning lines across a date range in one batch. Also hosts the JS-event-driven single-bar
/// CRUD helpers for the add-in (drag/resize/delete), mirroring codeunit 50604 "DHX Data
/// Handler"'s event-id convention: "|"-delimited text, here "JobNo|JobTaskNo|DayLineNo".
/// </summary>
codeunit 50695 "Day Planning Sequence Mgt."
{
    /// <summary>
    /// Ensures DayPlanning."Sequence No." is a small ordinal (1, 2, 3, ...) that no OTHER Day
    /// Planning line for the same [Job No., Job Task No., Skill, Plan Date] already holds. Called
    /// from table 50610's OnInsert/OnModify whenever Skill is non-blank - safe to call repeatedly
    /// (idempotent no-op when the current value has no conflict), and never Inserts/Modifies any
    /// record itself (only mutates Rec's own in-memory field), so it cannot recurse.
    /// Deliberately a no-op while "Plan Date" is still 0D (e.g. a page-level Insert that fires
    /// before the user has filled in a date yet) - assigning a real row/thread identity before
    /// there's a date to group by would just be a throwaway number that gets recomputed anyway
    /// the moment Plan Date is set and the record is Modify()'d. Matches the confirmed contract:
    /// "Sequence No." must be non-zero whenever Skill &lt;&gt; '' AND "Plan Date" &lt;&gt; 0D - see
    /// test/DayPlanningSequenceNo.Test.Codeunit.al.
    /// </summary>
    procedure CalcSequence(var DayPlanning: Record "Day Planning")
    var
        OtherDayPlanning: Record "Day Planning";
        Candidate: Integer;
    begin
        if DayPlanning.Skill = '' then
            exit;
        if DayPlanning."Plan Date" = 0D then
            exit;

        OtherDayPlanning.SetRange("Job No.", DayPlanning."Job No.");
        OtherDayPlanning.SetRange("Job Task No.", DayPlanning."Job Task No.");
        OtherDayPlanning.SetRange(Skill, DayPlanning.Skill);
        OtherDayPlanning.SetRange("Plan Date", DayPlanning."Plan Date");
        OtherDayPlanning.SetFilter("Day Line No.", '<>%1', DayPlanning."Day Line No.");

        if DayPlanning."Sequence No." <> 0 then begin
            OtherDayPlanning.SetRange("Sequence No.", DayPlanning."Sequence No.");
            if OtherDayPlanning.IsEmpty() then
                exit; // current value has no conflict, keep it
            OtherDayPlanning.SetRange("Sequence No."); // clear filter, fall through to reassignment
        end;

        Candidate := 1;
        OtherDayPlanning.SetRange("Sequence No.", Candidate);
        while not OtherDayPlanning.IsEmpty() do begin
            Candidate += 1;
            OtherDayPlanning.SetRange("Sequence No.", Candidate);
        end;
        DayPlanning."Sequence No." := Candidate;
    end;

    /// <summary>
    /// Batch-creates a brand new "sequence" thread: picks the lowest free Sequence No. across the
    /// WHOLE [StartDate, EndDate] range for [Job No., Job Task No., Skill] (so every date in the
    /// batch shares the same row/thread number), then inserts one Day Planning line per surviving
    /// calendar date (excluded weekdays and inactive Work-Hour-Template/calendar days are
    /// skipped). Returns the assigned Sequence No.
    /// </summary>
    procedure GenerateSequence(JobNo: Code[20]; JobTaskNo: Code[20]; SkillCode: Code[10]; WorkHourTemplateCode: Code[20]; StartDate: Date; EndDate: Date; ExcludedWeekdaysCsv: Text; WorkOrderNo: Code[20]): Integer
    var
        WorkHourTemplate: Record "Work-Hour Template";
        DayPlanningMgt: Codeunit "Day Plannings Mgt.";
        SequenceNo: Integer;
        d: Date;
        ActualMinDate: Date;
        ActualMaxDate: Date;
    begin
        SequenceNo := FindFreeSequenceNoForRange(JobNo, JobTaskNo, SkillCode, StartDate, EndDate);

        if WorkHourTemplateCode <> '' then
            WorkHourTemplate.Get(WorkHourTemplateCode);

        d := StartDate;
        while d <= EndDate do begin
            if not IsWeekdayExcluded(ExcludedWeekdaysCsv, Date2DWY(d, 1)) then
                if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, d) then begin
                    InsertSequenceLine(JobNo, JobTaskNo, SkillCode, SequenceNo, WorkHourTemplate, d, WorkOrderNo);
                    if ActualMinDate = 0D then
                        ActualMinDate := d;
                    ActualMaxDate := d;
                end;
            d := CalcDate('<+1D>', d);
        end;

        ExtendJobTaskPlannedPeriod(JobNo, JobTaskNo, ActualMinDate, ActualMaxDate);
        exit(SequenceNo);
    end;

    /// <summary>
    /// Regenerates an EXISTING sequence thread in place: deletes every current Day Planning line
    /// for [Job No., Job Task No., Skill, Sequence No.] (respecting the table's OnDelete guard -
    /// TestField("Assigned Hours",0)/TestField("Realized Hours",0) - so a line with
    /// assigned/realized hours makes this error out rather than silently skip), then re-runs the
    /// same date-iteration/insert logic as GenerateSequence but FORCES the same Sequence No. for
    /// row continuity. Since step 1 already cleared every prior occupant of that number for this
    /// Job/Task/Skill, CalcSequence (fired from Day Planning's own OnInsert) will find no conflict
    /// and keep it - unless a different, unrelated generation batch already occupies that exact
    /// number on one particular overlapping date, in which case CalcSequence bumps just that one
    /// date's line to a different free number. That is correct, intentional behavior per spec.
    /// </summary>
    procedure RegenerateSequence(JobNo: Code[20]; JobTaskNo: Code[20]; SkillCode: Code[10]; SequenceNo: Integer; WorkHourTemplateCode: Code[20]; StartDate: Date; EndDate: Date; ExcludedWeekdaysCsv: Text; WorkOrderNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
        WorkHourTemplate: Record "Work-Hour Template";
        DayPlanningMgt: Codeunit "Day Plannings Mgt.";
        d: Date;
        ActualMinDate: Date;
        ActualMaxDate: Date;
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange(Skill, SkillCode);
        DayPlanning.SetRange("Sequence No.", SequenceNo);
        if DayPlanning.FindSet(true) then
            repeat
                DayPlanning.Delete(true);
            until DayPlanning.Next() = 0;

        if WorkHourTemplateCode <> '' then
            WorkHourTemplate.Get(WorkHourTemplateCode);

        d := StartDate;
        while d <= EndDate do begin
            if not IsWeekdayExcluded(ExcludedWeekdaysCsv, Date2DWY(d, 1)) then
                if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, d) then begin
                    InsertSequenceLine(JobNo, JobTaskNo, SkillCode, SequenceNo, WorkHourTemplate, d, WorkOrderNo);
                    if ActualMinDate = 0D then
                        ActualMinDate := d;
                    ActualMaxDate := d;
                end;
            d := CalcDate('<+1D>', d);
        end;

        ExtendJobTaskPlannedPeriod(JobNo, JobTaskNo, ActualMinDate, ActualMaxDate);
    end;

    local procedure InsertSequenceLine(JobNo: Code[20]; JobTaskNo: Code[20]; SkillCode: Code[10]; SequenceNo: Integer; WorkHourTemplate: Record "Work-Hour Template"; PlanDate: Date; WorkOrderNo: Code[20])
    var
        NewDayPlanning: Record "Day Planning";
        DefaultStartTimeTok: Time;
        DefaultEndTimeTok: Time;
    begin
        NewDayPlanning.Init();
        NewDayPlanning."Job No." := JobNo;
        NewDayPlanning."Job Task No." := JobTaskNo;
        NewDayPlanning.Skill := SkillCode;
        NewDayPlanning."Plan Date" := PlanDate;
        NewDayPlanning."Sequence No." := SequenceNo;
        NewDayPlanning."Work Order No." := WorkOrderNo;
        NewDayPlanning."Day Line No." := NewDayPlanning.GetNextDayLineNo(PlanDate, JobNo, JobTaskNo);

        if (WorkHourTemplate."Default Start Time" <> 0T) and (WorkHourTemplate."Default End Time" <> 0T) then begin
            DefaultStartTimeTok := WorkHourTemplate."Default Start Time";
            DefaultEndTimeTok := WorkHourTemplate."Default End Time";
        end else begin
            DefaultStartTimeTok := 070000T;
            DefaultEndTimeTok := 160000T;
        end;

        NewDayPlanning."Start Time Requested" := DefaultStartTimeTok;
        NewDayPlanning."End Time Requested" := DefaultEndTimeTok;
        NewDayPlanning."Non Working Minutes Requested" := WorkHourTemplate."Non Working Minutes";
        // "Requested Hours" is NOT simply (End-Start-NonWorking): table 50610's own
        // CalculateRequestedWorkingHours() routes through
        // "General Planning Utilities".DayPlanningFulFillment, which exits early (leaving the
        // hours at 0) whenever "Requested Resource No." is blank - and a sequence-generated line
        // deliberately has no resource yet (Skill only, resource gets assigned later via
        // drag/drop, same as the demo app). So Requested Hours is computed directly here instead
        // of via Validate(), mirroring the sanctioned override codeunit 50610's own
        // CreateDayPlanning already uses for pattern-generated lines
        // (`DayPlannings."Requested Hours" := DayPlanningPattern."Requested Hours";`, bypassing
        // the same resource-dependent path) rather than an ad-hoc new calc.
        NewDayPlanning."Requested Hours" :=
            ((DefaultEndTimeTok - DefaultStartTimeTok) div 60000 - WorkHourTemplate."Non Working Minutes") / 60;
        NewDayPlanning.Insert(true); // fires OnInsert -> CalcSequence(Rec) as a no-op safety check
    end;

    /// <summary>
    /// Widens the parent Job Task's PlannedStartDate/PlannedEndDate (tableext 50605) so a newly
    /// generated/regenerated sequence is never left dangling outside the task's displayed planned
    /// window. Unlike codeunit 50617 "DayPlanning Period Sync Mgt."'s own
    /// ExtendJobTaskEndDateIfNeeded - which only ever pushes the END date forward, because that
    /// flow already has an explicit "old period" (OldStart/OldEnd) it is diffing the reschedule
    /// against - this one is symmetric in both directions: the sequence add-in has no prior "old
    /// period" to anchor to, so a brand new sequence can legitimately start EARLIER than the
    /// task's current Planned Start Date just as easily as it can run later than its Planned End
    /// Date. Direct field assignment + explicit CalculateDuration() (never Validate()) deliberately
    /// mirrors ExtendJobTaskEndDateIfNeeded's own pattern, so tableext 50605's
    /// PlannedStartDate/PlannedEndDate OnValidate triggers - which are deliberately NOT wired to
    /// any Day-Planning-sync flow, per that tableext's own doc comments - do not unexpectedly fire.
    /// </summary>
    local procedure ExtendJobTaskPlannedPeriod(JobNo: Code[20]; JobTaskNo: Code[20]; RangeStart: Date; RangeEnd: Date)
    var
        JobTask: Record "Job Task";
        Changed: Boolean;
    begin
        if (RangeStart = 0D) or (RangeEnd = 0D) then
            exit;
        if not JobTask.Get(JobNo, JobTaskNo) then
            exit;

        if (JobTask.PlannedStartDate = 0D) or (RangeStart < JobTask.PlannedStartDate) then begin
            JobTask.PlannedStartDate := RangeStart;
            Changed := true;
        end;
        if (JobTask.PlannedEndDate = 0D) or (RangeEnd > JobTask.PlannedEndDate) then begin
            JobTask.PlannedEndDate := RangeEnd;
            Changed := true;
        end;

        if Changed then begin
            JobTask.CalculateDuration();
            JobTask.Modify(true);
            OnAfterExtendJobTaskPlannedPeriod(JobNo, JobTaskNo);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExtendJobTaskPlannedPeriod(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
    end;

    /// <summary>
    /// Lowest candidate Sequence No. (starting at 1) with zero existing Day Planning rows anywhere
    /// in [Job No., Job Task No., Skill, Sequence No.=candidate, Plan Date between
    /// StartDate..EndDate] - used to pick ONE number for a whole new generation batch up front.
    /// </summary>
    local procedure FindFreeSequenceNoForRange(JobNo: Code[20]; JobTaskNo: Code[20]; SkillCode: Code[10]; StartDate: Date; EndDate: Date): Integer
    var
        DayPlanning: Record "Day Planning";
        Candidate: Integer;
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange(Skill, SkillCode);
        DayPlanning.SetRange("Plan Date", StartDate, EndDate);

        Candidate := 1;
        DayPlanning.SetRange("Sequence No.", Candidate);
        while not DayPlanning.IsEmpty() do begin
            Candidate += 1;
            DayPlanning.SetRange("Sequence No.", Candidate);
        end;
        exit(Candidate);
    end;

    /// <summary>
    /// ExcludedWeekdaysCsv is a comma-separated list of ISO weekday numbers (1=Monday..7=Sunday,
    /// matching Date2DWY(D,1)), e.g. "6,7" to exclude Saturday/Sunday. Blank = nothing excluded.
    /// </summary>
    local procedure IsWeekdayExcluded(ExcludedWeekdaysCsv: Text; WeekdayNo: Integer): Boolean
    var
        Parts: List of [Text];
        PartTxt: Text;
        ParsedWeekdayNo: Integer;
    begin
        if ExcludedWeekdaysCsv = '' then
            exit(false);

        Parts := ExcludedWeekdaysCsv.Split(',');
        foreach PartTxt in Parts do
            if Evaluate(ParsedWeekdayNo, PartTxt.Trim()) then
                if ParsedWeekdayNo = WeekdayNo then
                    exit(true);
        exit(false);
    end;

    #region JS event-id convention ("JobNo|JobTaskNo|DayLineNo") - mirrors codeunit 50604's "|"-split convention

    procedure BuildEventId(JobNo: Code[20]; JobTaskNo: Code[20]; DayLineNo: Integer): Text
    begin
        exit(StrSubstNo('%1|%2|%3', JobNo, JobTaskNo, DayLineNo));
    end;

    local procedure ParseEventId(EventId: Text; var JobNo: Code[20]; var JobTaskNo: Code[20]; var DayLineNo: Integer)
    var
        Parts: List of [Text];
    begin
        Parts := EventId.Split('|');
        JobNo := CopyStr(Parts.Get(1), 1, MaxStrLen(JobNo));
        JobTaskNo := CopyStr(Parts.Get(2), 1, MaxStrLen(JobTaskNo));
        Evaluate(DayLineNo, Parts.Get(3));
    end;

    /// <summary>
    /// Row/thread key = (Job No., Job Task No., Skill, Sequence No.), same "|"-delimited scheme.
    /// </summary>
    procedure BuildSectionId(JobNo: Code[20]; JobTaskNo: Code[20]; SkillCode: Code[10]; SequenceNo: Integer): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4', JobNo, JobTaskNo, SkillCode, SequenceNo));
    end;

    local procedure ParseSectionId(SectionId: Text; var JobNo: Code[20]; var JobTaskNo: Code[20]; var SkillCode: Code[10]; var SequenceNo: Integer)
    var
        Parts: List of [Text];
    begin
        Parts := SectionId.Split('|');
        JobNo := CopyStr(Parts.Get(1), 1, MaxStrLen(JobNo));
        JobTaskNo := CopyStr(Parts.Get(2), 1, MaxStrLen(JobTaskNo));
        SkillCode := CopyStr(Parts.Get(3), 1, MaxStrLen(SkillCode));
        Evaluate(SequenceNo, Parts.Get(4));
    end;

    #endregion JS event-id convention

    #region Single-bar CRUD (drag/resize/delete) - scoped strictly to the eventId's own record

    /// <summary>
    /// Applies a drag/resize/move from the timeline back onto the single Day Planning line the
    /// eventId identifies. EventDataJson carries the new section_id (row the bar was dropped on -
    /// may move the line to a different Skill/Sequence No.) and the new start_date/end_date
    /// (drives Plan Date + Start/End Time Requested). Skill/Plan Date changes let CalcSequence
    /// re-fire naturally via the table's own OnModify trigger - not called directly here.
    /// </summary>
    procedure UpdateEventFromJson(EventId: Text; EventDataJson: Text)
    var
        DayPlanning: Record "Day Planning";
        DHXDataHandler: Codeunit "DHX Data Handler";
        EventJObj: JsonObject;
        JToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
        NewSectionId: Text;
        NewSkillCode: Code[10];
        NewSequenceNo: Integer;
        UtcDateTime: DateTime;
        LocalDateTime: DateTime;
    begin
        ParseEventId(EventId, JobNo, JobTaskNo, DayLineNo);
        if not DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            exit;

        EventJObj.ReadFrom(EventDataJson);

        if EventJObj.Get('section_id', JToken) then begin
            NewSectionId := JToken.AsValue().AsText();
            ParseSectionId(NewSectionId, JobNo, JobTaskNo, NewSkillCode, NewSequenceNo);
            DayPlanning.Validate(Skill, NewSkillCode);
            DayPlanning."Sequence No." := NewSequenceNo;
        end;

        // JS Date objects serialize via JSON.stringify to ISO-8601 UTC text (e.g.
        // "2026-08-28T07:00:00.000Z") - same shape codeunit 50604's OnEventChanged_Project
        // parses, and the same ConvertToUserTimeZone conversion is reused here rather than
        // re-deriving timezone-offset logic.
        if EventJObj.Get('start_date', JToken) then
            if Evaluate(UtcDateTime, JToken.AsValue().AsText()) then begin
                LocalDateTime := DHXDataHandler.ConvertToUserTimeZone(UtcDateTime);
                DayPlanning.Validate("Plan Date", DT2Date(LocalDateTime));
                DayPlanning."Start Time Requested" := DT2Time(LocalDateTime);
            end;

        if EventJObj.Get('end_date', JToken) then
            if Evaluate(UtcDateTime, JToken.AsValue().AsText()) then begin
                LocalDateTime := DHXDataHandler.ConvertToUserTimeZone(UtcDateTime);
                DayPlanning."End Time Requested" := DT2Time(LocalDateTime);
            end;

        DayPlanning.CalculateWorkingHours();
        DayPlanning.Modify(true);
    end;

    /// <summary>
    /// Deletes the single Day Planning line identified by eventId. Respects the table's OnDelete
    /// guard as-is (errors if Assigned/Realized Hours are non-zero) - not suppressed here.
    /// </summary>
    procedure DeleteEventById(EventId: Text)
    var
        DayPlanning: Record "Day Planning";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
    begin
        ParseEventId(EventId, JobNo, JobTaskNo, DayLineNo);
        if DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            DayPlanning.Delete(true);
    end;

    /// <summary>
    /// Opens the existing "Day Planning Card Opt" (page 50668) for the single record eventId
    /// identifies - reused as-is, per spec, rather than building a new card for this add-in.
    /// </summary>
    procedure OpenDayPlanningCardByEventId(EventId: Text)
    var
        DayPlanning: Record "Day Planning";
        DayPlanningCard: Page "Day Planning Card Opt";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
    begin
        ParseEventId(EventId, JobNo, JobTaskNo, DayLineNo);
        if not DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            exit;
        DayPlanningCard.SetRecord(DayPlanning);
        DayPlanningCard.RunModal();
    end;

    #endregion Single-bar CRUD

    #region JSON assembly for the add-in (sections/events/skills/templates)

    /// <summary>
    /// Builds the timeline's row (section) list and bar (event) list for [JobNo, JobTaskNo],
    /// grouped into (Job No., Job Task No., Skill, Sequence No.) rows per spec. EarliestDate is
    /// the earliest Plan Date found (0D if none), used by the add-in to pick an initial scroll
    /// position. LatestDate is the latest Plan Date found (0D if none), used together with
    /// EarliestDate by the add-in to size the timeline's horizontal span dynamically to the
    /// actual data range, instead of a fixed window that can silently cut off real data.
    /// </summary>
    procedure BuildSectionsAndEventsJson(JobNo: Code[20]; JobTaskNo: Code[20]; var SectionsJson: Text; var EventsJson: Text; var EarliestDate: Date; var LatestDate: Date)
    var
        DayPlanning: Record "Day Planning";
        SkillCodeRec: Record "Skill Code";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        SectionsArray: JsonArray;
        EventsArray: JsonArray;
        SectionObj: JsonObject;
        EventObj: JsonObject;
        SeenSectionKeys: List of [Text];
        MinDateBySection: Dictionary of [Text, Date];
        MaxDateBySection: Dictionary of [Text, Date];
        SectionKey: Text;
        LoopSectionKey: Text;
        SkillDescription: Text[100];
        BarColorHex: Text;
        RowJobNo: Code[20];
        RowJobTaskNo: Code[20];
        RowSkillCode: Code[10];
        RowSequenceNo: Integer;
        PaletteIndex: Integer;
    begin
        EarliestDate := 0D;
        LatestDate := 0D;

        // Ascending Plan Date order, so MinDateBySection is fixed on each section's first sighting
        // and MaxDateBySection is simply overwritten every time (last write = latest date) - one
        // pass, no separate aggregate query needed for the Modify-panel Start/End Date prefill.
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetFilter(Skill, '<>%1', '');
        DayPlanning.SetCurrentKey("Job No.", "Job Task No.", "Plan Date", "Day Line No.");
        if DayPlanning.FindSet() then
            repeat
                if (EarliestDate = 0D) or (DayPlanning."Plan Date" < EarliestDate) then
                    EarliestDate := DayPlanning."Plan Date";
                if DayPlanning."Plan Date" > LatestDate then
                    LatestDate := DayPlanning."Plan Date";

                SectionKey := BuildSectionId(DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning.Skill, DayPlanning."Sequence No.");
                if not SeenSectionKeys.Contains(SectionKey) then begin
                    SeenSectionKeys.Add(SectionKey);
                    MinDateBySection.Add(SectionKey, DayPlanning."Plan Date");
                end;
                MaxDateBySection.Set(SectionKey, DayPlanning."Plan Date");

                Clear(EventObj);
                EventObj.Add('id', BuildEventId(DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Day Line No."));
                EventObj.Add('section_id', SectionKey);
                EventObj.Add('start_date', FormatEventDateTime(DayPlanning."Plan Date", DayPlanning."Start Time Requested"));
                EventObj.Add('end_date', FormatEventDateTime(DayPlanning."Plan Date", DayPlanning."End Time Requested"));
                EventObj.Add('text', FormatEventBarText(DayPlanning));
                EventObj.Add('skill', DayPlanning.Skill);
                EventsArray.Add(EventObj);
            until DayPlanning.Next() = 0;

        foreach LoopSectionKey in SeenSectionKeys do begin
            ParseSectionId(LoopSectionKey, RowJobNo, RowJobTaskNo, RowSkillCode, RowSequenceNo);

            if SkillCodeRec.Get(RowSkillCode) then
                SkillDescription := SkillCodeRec.Description
            else
                SkillDescription := RowSkillCode;

            BarColorHex := VisualDefaultSettings.GetSkillBarColor(RowSkillCode, PaletteIndex);

            Clear(SectionObj);
            SectionObj.Add('key', LoopSectionKey);
            SectionObj.Add('jobNo', RowJobNo);
            SectionObj.Add('jobTaskNo', RowJobTaskNo);
            SectionObj.Add('skill', RowSkillCode);
            SectionObj.Add('skillDescription', SkillDescription);
            SectionObj.Add('sequenceNo', RowSequenceNo);
            SectionObj.Add('color', BarColorHex);
            SectionObj.Add('fontColor', VisualDefaultSettings.GetSkillFontColor(RowSkillCode));
            SectionObj.Add('borderColor', VisualDefaultSettings.GetSkillBorderColor(RowSkillCode, PaletteIndex));
            PaletteIndex += 1;
            SectionObj.Add('label', StrSubstNo('%1 - Seq %2', SkillDescription, RowSequenceNo));
            SectionObj.Add('minDate', Format(MinDateBySection.Get(LoopSectionKey), 0, '<Year4>-<Month,2>-<Day,2>'));
            SectionObj.Add('maxDate', Format(MaxDateBySection.Get(LoopSectionKey), 0, '<Year4>-<Month,2>-<Day,2>'));
            SectionsArray.Add(SectionObj);
        end;

        SectionsArray.WriteTo(SectionsJson);
        EventsArray.WriteTo(EventsJson);
    end;

    procedure BuildSkillsJson(): Text
    var
        SkillCodeRec: Record "Skill Code";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        SkillsArray: JsonArray;
        SkillObj: JsonObject;
        PaletteIndex: Integer;
        ResultTxt: Text;
    begin
        if SkillCodeRec.FindSet() then
            repeat
                Clear(SkillObj);
                SkillObj.Add('code', SkillCodeRec.Code);
                SkillObj.Add('description', SkillCodeRec.Description);
                SkillObj.Add('color', VisualDefaultSettings.GetSkillBarColor(SkillCodeRec.Code, PaletteIndex));
                SkillsArray.Add(SkillObj);
                PaletteIndex += 1;
            until SkillCodeRec.Next() = 0;
        SkillsArray.WriteTo(ResultTxt);
        exit(ResultTxt);
    end;

    /// <summary>
    /// One entry per Work-Hour Template, including which ISO weekdays (1=Mon..7=Sun) are active
    /// per Codeunit "Day Plannings Mgt.".GetActiveWeekdaysText, so the add-in's "Exclude days"
    /// toggles can enable/disable the right days for whichever template the user picks.
    /// </summary>
    procedure BuildTemplatesJson(): Text
    var
        WorkHourTemplate: Record "Work-Hour Template";
        DayPlanningMgt: Codeunit "Day Plannings Mgt.";
        TemplatesArray: JsonArray;
        TemplateObj: JsonObject;
        ResultTxt: Text;
    begin
        if WorkHourTemplate.FindSet() then
            repeat
                Clear(TemplateObj);
                TemplateObj.Add('code', WorkHourTemplate.Code);
                TemplateObj.Add('description', WorkHourTemplate.Description);
                TemplateObj.Add('activeWeekdays', DayPlanningMgt.GetActiveWeekdaysText(WorkHourTemplate.Code));
                TemplatesArray.Add(TemplateObj);
            until WorkHourTemplate.Next() = 0;
        TemplatesArray.WriteTo(ResultTxt);
        exit(ResultTxt);
    end;

    local procedure FormatEventDateTime(PlanDate: Date; PlanTime: Time): Text
    begin
        exit(Format(PlanDate, 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(PlanTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure FormatEventBarText(DayPlanning: Record "Day Planning"): Text
    begin
        exit(StrSubstNo('%1-%2 . %3h',
            Format(DayPlanning."Start Time Requested", 0, '<Hours24,2>:<Minutes,2>'),
            Format(DayPlanning."End Time Requested", 0, '<Hours24,2>:<Minutes,2>'),
            DayPlanning."Requested Hours"));
    end;

    #endregion JSON assembly
}
