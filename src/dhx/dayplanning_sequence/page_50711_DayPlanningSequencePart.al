/// <summary>
/// FastTab part hosting the "Day Planning Sequence" DHTMLX timeline add-in - one row per
/// (Job No., Job Task No., Skill, Sequence No.) "sequence" thread of table 50610 "Day Planning"
/// lines. No SourceTable (matches page 50707/50708's CardPart-hosting-a-usercontrol-directly
/// convention in this repo - see those pages' own doc comments for why PageType = Card is not
/// usable inside a part()). Context (Job No./Job Task No.) is pushed in via SetContext, the same
/// pattern page 50638 "Resource Week View Part" already uses, called from the host card's own
/// OnAfterGetCurrRecord.
/// </summary>
page 50711 "Day Planning Sequence Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Day Planning Sequence';

    layout
    {
        area(Content)
        {
            usercontrol(DhxSequence; DHXDayPlanningSequenceAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                var
                    SectionsJsonTxt: Text;
                    EventsJsonTxt: Text;
                    SkillsJsonTxt: Text;
                    TemplatesJsonTxt: Text;
                    EarliestDate: Date;
                begin
                    ControlIsReady := true;
                    if (JobNo = '') or (JobTaskNo = '') then
                        exit;

                    DayPlanningSequenceMgt.BuildSectionsAndEventsJson(JobNo, JobTaskNo, SectionsJsonTxt, EventsJsonTxt, EarliestDate);
                    SkillsJsonTxt := DayPlanningSequenceMgt.BuildSkillsJson();
                    TemplatesJsonTxt := DayPlanningSequenceMgt.BuildTemplatesJson();

                    CurrPage.DhxSequence.Init(SectionsJsonTxt, SkillsJsonTxt, TemplatesJsonTxt, EarliestDate);
                    CurrPage.DhxSequence.LoadData(EventsJsonTxt);
                    PushHolidaysData(EarliestDate);
                    CurrPage.DhxSequence.SetDayOffColors(VisualDefaultSettings.GetWeekendColor(), VisualDefaultSettings.GetHolidayColor());
                end;

                /// <summary>
                /// "New sequence" - payloadJson: {skill, template, excludedWeekdays (CSV "1,6,7"),
                /// startDate ("yyyy-MM-dd"), endDate}. Always a full RefreshTimeline afterward, per
                /// this app's "regenerate, don't patch" convention for anything that changes row
                /// structure (matches src/dhx/projectschedule's OnDragCreateDayPlanning/OnFilterIconClick).
                /// </summary>
                trigger OnCreateSequence(payloadJson: Text)
                var
                    PayloadJObj: JsonObject;
                    JToken: JsonToken;
                    SkillCode: Code[10];
                    TemplateCode: Code[20];
                    ExcludedWeekdaysCsv: Text;
                    StartDate: Date;
                    EndDate: Date;
                begin
                    PayloadJObj.ReadFrom(payloadJson);
                    if PayloadJObj.Get('skill', JToken) then
                        SkillCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(SkillCode));
                    if PayloadJObj.Get('template', JToken) then
                        TemplateCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TemplateCode));
                    if PayloadJObj.Get('excludedWeekdays', JToken) then
                        ExcludedWeekdaysCsv := JToken.AsValue().AsText();
                    if PayloadJObj.Get('startDate', JToken) then
                        StartDate := ParseIsoDate(JToken.AsValue().AsText());
                    if PayloadJObj.Get('endDate', JToken) then
                        EndDate := ParseIsoDate(JToken.AsValue().AsText());

                    if (SkillCode = '') or (StartDate = 0D) or (EndDate = 0D) then
                        exit;

                    DayPlanningSequenceMgt.GenerateSequence(JobNo, JobTaskNo, SkillCode, TemplateCode, StartDate, EndDate, ExcludedWeekdaysCsv);
                    RefreshTimeline();
                end;

                /// <summary>
                /// "Modify sequence" - payloadJson adds sequenceNo to OnCreateSequence's shape.
                /// </summary>
                trigger OnModifySequence(payloadJson: Text)
                var
                    PayloadJObj: JsonObject;
                    JToken: JsonToken;
                    SkillCode: Code[10];
                    TemplateCode: Code[20];
                    ExcludedWeekdaysCsv: Text;
                    StartDate: Date;
                    EndDate: Date;
                    SequenceNo: Integer;
                begin
                    PayloadJObj.ReadFrom(payloadJson);
                    if PayloadJObj.Get('skill', JToken) then
                        SkillCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(SkillCode));
                    if PayloadJObj.Get('sequenceNo', JToken) then
                        SequenceNo := JToken.AsValue().AsInteger();
                    if PayloadJObj.Get('template', JToken) then
                        TemplateCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TemplateCode));
                    if PayloadJObj.Get('excludedWeekdays', JToken) then
                        ExcludedWeekdaysCsv := JToken.AsValue().AsText();
                    if PayloadJObj.Get('startDate', JToken) then
                        StartDate := ParseIsoDate(JToken.AsValue().AsText());
                    if PayloadJObj.Get('endDate', JToken) then
                        EndDate := ParseIsoDate(JToken.AsValue().AsText());

                    if (SkillCode = '') or (SequenceNo = 0) or (StartDate = 0D) or (EndDate = 0D) then
                        exit;

                    DayPlanningSequenceMgt.RegenerateSequence(JobNo, JobTaskNo, SkillCode, SequenceNo, TemplateCode, StartDate, EndDate, ExcludedWeekdaysCsv);
                    RefreshTimeline();
                end;

                trigger OnEventChanged(eventId: Text; eventData: Text)
                begin
                    DayPlanningSequenceMgt.UpdateEventFromJson(eventId, eventData);
                    RefreshTimeline();
                end;

                trigger OnEventDeleted(eventId: Text)
                begin
                    DayPlanningSequenceMgt.DeleteEventById(eventId);
                    RefreshTimeline();
                end;

                trigger OnEventDblClick(eventId: Text; eventData: Text)
                begin
                    DayPlanningSequenceMgt.OpenDayPlanningCardByEventId(eventId);
                    RefreshTimeline();
                end;
            }
        }
    }

    var
        DayPlanningSequenceMgt: Codeunit "Day Planning Sequence Mgt.";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ControlIsReady: Boolean;

    /// <summary>
    /// Pushes Job No./Job Task No. context from the host card page. On first load (before
    /// ControlReady has fired) this just stores the context - ControlReady itself reads it to
    /// build the initial payload, same call-order precedent as page 50638's own SetContext. On a
    /// re-entry (context changing on an already-live control), it also pushes fresh data
    /// immediately via RefreshTimeline.
    /// </summary>
    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        if ControlIsReady then
            RefreshTimeline();
    end;

    local procedure RefreshTimeline()
    var
        SectionsJsonTxt: Text;
        EventsJsonTxt: Text;
        EarliestDate: Date;
    begin
        if not ControlIsReady then
            exit;
        if (JobNo = '') or (JobTaskNo = '') then
            exit;

        DayPlanningSequenceMgt.BuildSectionsAndEventsJson(JobNo, JobTaskNo, SectionsJsonTxt, EventsJsonTxt, EarliestDate);
        CurrPage.DhxSequence.RefreshTimeline(SectionsJsonTxt, EventsJsonTxt, EarliestDate);
        PushHolidaysData(EarliestDate);
    end;

    /// <summary>
    /// Same day-off/holiday shading as the Gantt add-in (src/dhx/ganttdemo2): reuses
    /// Codeunit "GanttChartDataHandler".GetHolidaysAsJson (already generic - Base Calendar driven,
    /// not Gantt-specific) so both add-ins render identical colors from the identical source data,
    /// instead of re-deriving calendar-exception logic here. Windowed to [AnchorDate,
    /// AnchorDate+31D] to match this timeline's own visible span (x_size: 12*31 two-hour cells =
    /// 31 days) - AnchorDate falls back to Today() when there's no data yet (EarliestDate = 0D),
    /// same fallback Init/RefreshTimeline already apply to the scheduler's own anchor.
    /// </summary>
    local procedure PushHolidaysData(AnchorDate: Date)
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        HolidaysJsonTxt: Text;
    begin
        if AnchorDate = 0D then
            AnchorDate := Today();
        HolidaysJsonTxt := GanttChartDataHandler.GetHolidaysAsJson(AnchorDate, CalcDate('<+31D>', AnchorDate));
        CurrPage.DhxSequence.LoadHolidaysData(HolidaysJsonTxt);
    end;

    /// <summary>
    /// Parses a "yyyy-MM-dd" text (the format an HTML &lt;input type="date"&gt; always serializes
    /// to, regardless of the browser's display locale) into a Date, without relying on Evaluate's
    /// session-region-dependent text parsing. Returns 0D for anything that doesn't parse cleanly.
    /// </summary>
    local procedure ParseIsoDate(IsoDateTxt: Text): Date
    var
        Parts: List of [Text];
        YearNo: Integer;
        MonthNo: Integer;
        DayNo: Integer;
    begin
        if IsoDateTxt = '' then
            exit(0D);
        Parts := IsoDateTxt.Split('-');
        if Parts.Count() <> 3 then
            exit(0D);
        if not Evaluate(YearNo, Parts.Get(1)) then
            exit(0D);
        if not Evaluate(MonthNo, Parts.Get(2)) then
            exit(0D);
        if not Evaluate(DayNo, Parts.Get(3)) then
            exit(0D);
        exit(DMY2Date(DayNo, MonthNo, YearNo));
    end;
}
