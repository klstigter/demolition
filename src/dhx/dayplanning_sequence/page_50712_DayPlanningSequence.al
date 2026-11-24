/// <summary>
/// Standalone (opened on its own, e.g. from the Gantt "Open Sequences" action) copy of page 50711
/// "Day Planning Sequence Part", additionally showing the read-only Project No./Project Task No.
/// context above the DHTMLX sequence timeline. Same add-in, triggers and SetContext contract.
/// </summary>
page 50712 "Day Planning Sequence"
{
    PageType = Card;
    UsageCategory = None;
    ApplicationArea = All;
    Caption = 'Day Planning Sequence';

    layout
    {
        area(Content)
        {
            // group(General)
            // {
            //     Caption = 'General';
            //     field(ProjectNo; JobNo)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Project No.';
            //         Editable = false;
            //         ToolTip = 'Specifies the project (job) the sequences belong to.';
            //     }
            //     field(ProjectTaskNo; JobTaskNo)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Project Task No.';
            //         Editable = false;
            //         ToolTip = 'Specifies the project task the sequences belong to.';
            //     }
            // }
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
                    LatestDate: Date;
                begin
                    ControlIsReady := true;
                    CurrPage.DhxSequence.SetShowContext(true);
                    CurrPage.DhxSequence.SetNewSequenceResourceContext(ResourceContextNo);
                    if (JobNo = '') or (JobTaskNo = '') then
                        exit;

                    DayPlanningSequenceMgt.BuildSectionsAndEventsJson(JobFilter, JobTaskFilter, SkillFilter, ResourceFilter, PeriodFrom, PeriodTo, SectionsJsonTxt, EventsJsonTxt, EarliestDate, LatestDate);
                    DataSpanFrom := EarliestDate;
                    DataSpanTo := LatestDate;
                    SkillsJsonTxt := DayPlanningSequenceMgt.BuildSkillsJson();
                    TemplatesJsonTxt := DayPlanningSequenceMgt.BuildTemplatesJson();

                    PushFilterInfo(); // before Init: the add-in sizes the span from the period end
                    CurrPage.DhxSequence.SetHighlightedSections(HighlightKeysJson);
                    CurrPage.DhxSequence.Init(SectionsJsonTxt, SkillsJsonTxt, TemplatesJsonTxt, EarliestDate, TimelineEndDate(EarliestDate, LatestDate));
                    CurrPage.DhxSequence.LoadData(EventsJsonTxt);
                    PushHolidaysData(EarliestDate, LatestDate);
                    CurrPage.DhxSequence.SetDayOffColors(VisualDefaultSettings.GetWeekendColor(), VisualDefaultSettings.GetHolidayColor());
                    // Hover/tooltip popup background/font colour - codeunit 50609's
                    // GetTooltipBackgroundColor/GetTooltipFontColor.
                    CurrPage.DhxSequence.SetTooltipColors(VisualDefaultSettings.GetTooltipBackgroundColor(), VisualDefaultSettings.GetTooltipFontColor());
                    PushFilterInfo();
                    if HasNewSequenceDefaults then
                        CurrPage.DhxSequence.SetNewSequenceDefaults(DefaultSkillCode, DefaultTemplateCode)
                    else
                        PushNewSequenceDefaults();
                    if OpenNewSequenceOnStart then
                        CurrPage.DhxSequence.OpenNewSequence(JobNo, JobTaskNo);
                end;

                /// <summary>
                /// Filter icon clicked: opens report 50610 prefilled with the active filters; on OK
                /// stores them and refreshes the timeline.
                /// </summary>
                trigger OnFilterIconClick()
                var
                    FilterDlg: Report "Day Planning Sequence Filter";
                    NewJobFilter: Text;
                    NewJobTaskFilter: Text;
                    NewSkillFilter: Text;
                    NewResourceFilter: Text;
                    NewPeriodFrom: Date;
                    NewPeriodTo: Date;
                begin
                    FilterDlg.SetFilter(JobFilter, JobTaskFilter, SkillFilter, ResourceFilter, PeriodFrom, PeriodTo);
                    FilterDlg.RunModal();
                    if not FilterDlg.IsConfirmed() then
                        exit;
                    FilterDlg.GetFilter(NewJobFilter, NewJobTaskFilter, NewSkillFilter, NewResourceFilter, NewPeriodFrom, NewPeriodTo);
                    DayPlanningSequenceMgt.SetOnlySections('');
                    JobFilter := NewJobFilter;
                    JobTaskFilter := NewJobTaskFilter;
                    SkillFilter := NewSkillFilter;
                    ResourceFilter := NewResourceFilter;
                    PeriodFrom := NewPeriodFrom;
                    PeriodTo := NewPeriodTo;
                    RefreshTimeline();
                end;

                /// <summary>
                /// Clears all four filters and the period so the timeline shows every Day Planning line that has a Skill.
                /// </summary>
                trigger OnClearFilter()
                begin
                    DayPlanningSequenceMgt.SetOnlySections('');
                    JobFilter := '';
                    JobTaskFilter := '';
                    SkillFilter := '';
                    ResourceFilter := '';
                    PeriodFrom := 0D;
                    PeriodTo := 0D;
                    RefreshTimeline();
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
                    NewSequenceNo: Integer;
                    NewSequenceResourceNo: Code[20];
                    InView: Boolean;
                    NotInViewQst: Label 'The Day Planning will be created, but it will not be shown in the current view because it does not match the displayed filter.\%1\Continue?';
                begin
                    PayloadJObj.ReadFrom(payloadJson);
                    if PayloadJObj.Get('skill', JToken) then
                        SkillCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(SkillCode));
                    if PayloadJObj.Get('template', JToken) then
                        TemplateCode := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(TemplateCode));
                    if PayloadJObj.Get('excludedWeekdays', JToken) then
                        ExcludedWeekdaysCsv := JToken.AsValue().AsText();
                    if PayloadJObj.Get('resourceNo', JToken) then
                        NewSequenceResourceNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(NewSequenceResourceNo));
                    if PayloadJObj.Get('startDate', JToken) then
                        StartDate := ParseIsoDate(JToken.AsValue().AsText());
                    if PayloadJObj.Get('endDate', JToken) then
                        EndDate := ParseIsoDate(JToken.AsValue().AsText());
                    if (SkillCode = '') or (StartDate = 0D) or (EndDate = 0D) then
                        exit;
                    // Project/Task chosen in the dialog (assist-edit) win over the page context
                    if PayloadJObj.Get('jobNo', JToken) then
                        if JToken.AsValue().AsText() <> '' then
                            JobNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(JobNo));
                    if PayloadJObj.Get('jobTaskNo', JToken) then
                        if JToken.AsValue().AsText() <> '' then
                            JobTaskNo := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(JobTaskNo));

                    // The new sequence is only visible when it matches what this page currently displays.
                    InView := MatchesDisplayedFilter(JobNo, JobTaskNo, SkillCode, StartDate, EndDate, NewSequenceResourceNo);
                    if not InView then
                        if not Confirm(NotInViewQst, false, CurrentFilterText()) then begin
                            RefreshTimeline(); // closes the dialog's busy state
                            exit;
                        end;

                    NewSequenceNo := DayPlanningSequenceMgt.GenerateSequence(JobNo, JobTaskNo, SkillCode, TemplateCode, StartDate, EndDate, ExcludedWeekdaysCsv, WorkOrderNo);
                    if InView then
                        DayPlanningSequenceMgt.AddOnlySection(JobNo, JobTaskNo, SkillCode, NewSequenceNo); // keep it visible when the view is restricted to marker rows
                    if NewSequenceResourceNo <> '' then
                        DayPlanningSequenceMgt.SetRequestedResourceOnSequence(JobNo, JobTaskNo, SkillCode, NewSequenceNo, NewSequenceResourceNo);
                    RefreshTimeline();
                    // A new sequence can widen the parent Job Task's PlannedStartDate/PlannedEndDate
                    // (see codeunit 50695's ExtendJobTaskPlannedPeriod) via a separate Record variable,
                    // not through the host card's own bound Rec - so the host's header fields
                    // (Planned Start/End Date, Duration) would otherwise stay stale until the card is
                    // reopened. CurrPage.Update(false) here reloads the whole open card (this Part's
                    // host), not just this Part, the same way any other page-bound field refresh works.
                    CurrPage.Update(false);
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

                    DayPlanningSequenceMgt.RegenerateSequence(JobNo, JobTaskNo, SkillCode, SequenceNo, TemplateCode, StartDate, EndDate, ExcludedWeekdaysCsv, WorkOrderNo);
                    RefreshTimeline();
                    // See the matching comment in OnCreateSequence above - a regenerated sequence can
                    // likewise widen the parent Job Task's planned period, so the host card needs the
                    // same refresh.
                    CurrPage.Update(false);
                end;

                trigger OnExecuteSequence(PayloadJson: Text)
                begin
                    DayPlanningSequenceMgt.ExecuteSequenceSelection(PayloadJson, '', '');
                    RefreshTimeline();
                    CurrPage.DhxSequence.SequenceExecuted();
                end;

                /// <summary>
                /// "New sequence" Project No./Task No. assist-edit. Project: Job list limited to the Job
                /// filter (if any). Task: Job Task list of the Project No. in the dialog, limited to the
                /// Job Task filter (if any). Picking a different Project clears the Task.
                /// </summary>
                trigger OnLookupNewSequenceContext(isTask: Boolean; projectNo: Text)
                var
                    Job: Record Job;
                    JobTask: Record "Job Task";
                    JobList: Page "Job List";
                    JobTaskList: Page "Job Task List";
                begin
                    if not isTask then begin
                        if JobFilter <> '' then
                            Job.SetFilter("No.", JobFilter);
                        JobList.SetTableView(Job);
                        JobList.LookupMode(true);
                        if JobList.RunModal() = Action::LookupOK then begin
                            JobList.GetRecord(Job);
                            if Job."No." = projectNo then
                                exit;
                            CurrPage.DhxSequence.SetNewSequenceContext(Job."No.", '');
                        end;
                    end else begin
                        JobTask.SetRange("Job No.", projectNo);
                        if JobTaskFilter <> '' then
                            JobTask.SetFilter("Job Task No.", JobTaskFilter);
                        JobTaskList.SetTableView(JobTask);
                        JobTaskList.LookupMode(true);
                        if JobTaskList.RunModal() = Action::LookupOK then begin
                            JobTaskList.GetRecord(JobTask);
                            CurrPage.DhxSequence.SetNewSequenceContext(JobTask."Job No.", JobTask."Job Task No.");
                        end;
                    end;
                end;

                trigger OnLookupNewSequenceResource()
                var
                    Resource: Record Resource;
                    ResourceList: Page "Resource List";
                begin
                    Resource.SetRange(Blocked, false);
                    ResourceList.SetTableView(Resource);
                    ResourceList.LookupMode(true);
                    if ResourceList.RunModal() = Action::LookupOK then begin
                        ResourceList.GetRecord(Resource);
                        CurrPage.DhxSequence.SetNewSequenceResource(Resource."No.");
                    end;
                end;

                trigger OnLookupSequenceResource()
                var
                    Resource: Record Resource;
                    ResourceList: Page "Resource List";
                begin
                    Resource.SetRange(Blocked, false);
                    ResourceList.SetTableView(Resource);
                    ResourceList.LookupMode(true);
                    if ResourceList.RunModal() = Action::LookupOK then begin
                        ResourceList.GetRecord(Resource);
                        CurrPage.DhxSequence.SetSequenceResource(Resource."No.");
                    end;
                end;

                trigger OnEventChanged(eventId: Text; eventData: Text)
                begin
                    DayPlanningSequenceMgt.UpdateEventFromJson(eventId, eventData);
                    RefreshTimeline();
                end;

                trigger OnEventCreated(eventData: Text)
                begin
                    DayPlanningSequenceMgt.CreateEventFromJson(JobNo, JobTaskNo, WorkOrderNo, eventData);
                    RefreshTimeline();
                    CurrPage.Update(false); // may widen the host Job Task's planned period
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

                trigger OnBarOpenResource(eventId: Text)
                begin
                    DayPlanningSequenceMgt.OpenResourceByEventId(eventId);
                end;

                trigger OnBarOpenCapacity(eventId: Text)
                begin
                    DayPlanningSequenceMgt.OpenCapacityByEventId(eventId);
                end;

                trigger OnOpenProject(jobNo: Text)
                var
                    Job: Record Job;
                begin
                    if Job.Get(CopyStr(jobNo, 1, MaxStrLen(Job."No."))) then
                        Page.Run(Page::"Job Card", Job);
                end;

                trigger OnOpenProjectTask(jobNo: Text; jobTaskNo: Text)
                var
                    GanttBCPageHandler: Codeunit "Gantt BC Page Handler";
                begin
                    GanttBCPageHandler.OpenJobTaskCard(CopyStr(jobNo, 1, 20), CopyStr(jobTaskNo, 1, 20));
                end;
            }
        }
    }

    var
        DayPlanningSequenceMgt: Codeunit "Day Planning Sequence Mgt.";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        WorkOrderNo: Code[20];
        JobFilter: Text;
        JobTaskFilter: Text;
        SkillFilter: Text;
        ResourceFilter: Text;
        PeriodFrom: Date;
        PeriodTo: Date;
        ControlIsReady: Boolean;
        HighlightKeysJson: Text;
        DefaultSkillCode: Text;
        DefaultTemplateCode: Text;
        HasNewSequenceDefaults: Boolean;
        OpenNewSequenceOnStart: Boolean;
        ResourceContextNo: Code[20];
        ResourceContextDate: Date;
        DataSpanFrom: Date;
        DataSpanTo: Date;

    /// <summary>The filter currently applied to the view, same lines as the filter icon's tooltip (for the "will not be shown" confirmation).</summary>
    local procedure CurrentFilterText(): Text
    var
        ShownJobFilter: Text;
        ShownJobTaskFilter: Text;
        ShownSkillFilter: Text;
        ShownResourceFilter: Text;
        ShownDate: Text;
        Result: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        GetShownFilters(ShownJobFilter, ShownJobTaskFilter, ShownSkillFilter, ShownResourceFilter, ShownDate);
        if ShownJobFilter <> '' then
            Result += Lf + 'Job = ' + ShownJobFilter;
        if ShownJobTaskFilter <> '' then
            Result += Lf + 'Task = ' + ShownJobTaskFilter;
        if ShownSkillFilter <> '' then
            Result += Lf + 'Skill = ' + ShownSkillFilter;
        if ShownResourceFilter <> '' then
            Result += Lf + 'Resource = ' + ShownResourceFilter;
        if (PeriodFrom <> 0D) or (PeriodTo <> 0D) then
            Result += Lf + 'Period = ' + FormatIsoDate(PeriodFrom) + ' to ' + FormatIsoDate(PeriodTo)
        else
            if (Result <> '') and (DataSpanFrom <> 0D) and (DataSpanTo <> 0D) then
                Result += Lf + FormatIsoDate(DataSpanFrom) + ' to ' + FormatIsoDate(DataSpanTo); // same span line as the filter tooltip
        exit(CopyStr(Result, 2));
    end;

    /// <summary>
    /// Filter texts as shown to the user (tooltip + confirmation). Explicit filters win. When the view is limited to the rows of a
    /// resource marker, its context is only the marker's Resource and date (Gantt resource panel cell), else the Job/Task/Skill of the limited rows.
    /// </summary>
    local procedure GetShownFilters(var ShownJobFilter: Text; var ShownJobTaskFilter: Text; var ShownSkillFilter: Text; var ShownResourceFilter: Text; var ShownDate: Text)
    begin
        ShownResourceFilter := ResourceFilter;
        if DayPlanningSequenceMgt.HasOnlySections() then
            if ResourceContextNo <> '' then begin
                if ShownResourceFilter = '' then
                    ShownResourceFilter := ResourceContextNo;
                if ResourceContextDate <> 0D then
                    ShownDate := FormatIsoDate(ResourceContextDate);
            end else
                DayPlanningSequenceMgt.GetOnlyScopeFilters(ShownJobFilter, ShownJobTaskFilter, ShownSkillFilter);
        if JobFilter <> '' then
            ShownJobFilter := JobFilter;
        if JobTaskFilter <> '' then
            ShownJobTaskFilter := JobTaskFilter;
        if SkillFilter <> '' then
            ShownSkillFilter := SkillFilter;
    end;

    /// <summary>True when a sequence of this Job/Task/Skill would appear in the current view (no "only these rows" restriction, and it fits the Job/Task/Skill filters).</summary>
    local procedure MatchesDisplayedFilter(NewJobNo: Code[20]; NewJobTaskNo: Code[20]; NewSkillCode: Code[10]; NewStartDate: Date; NewEndDate: Date; NewResourceNo: Code[20]): Boolean
    var
        TempDayPlanning: Record "Day Planning" temporary;
    begin
        if DayPlanningSequenceMgt.HasOnlySections() then
            if ResourceContextNo <> '' then begin
                // Marker context = resource + the displayed date range (same as the filter info): in view when it is for that
                // resource and its Start..End overlaps the displayed range.
                if NewResourceNo <> ResourceContextNo then
                    exit(false);
                if (DataSpanFrom = 0D) or (DataSpanTo = 0D) then
                    exit(true);
                exit((NewStartDate <= DataSpanTo) and (NewEndDate >= DataSpanFrom));
            end else
                if not DayPlanningSequenceMgt.IsInOnlyScope(NewJobNo, NewJobTaskNo, NewSkillCode) then
                    exit(false);
        TempDayPlanning."Plan Date" := Today();
        TempDayPlanning."Day Line No." := 1;
        TempDayPlanning."Job No." := NewJobNo;
        TempDayPlanning."Job Task No." := NewJobTaskNo;
        TempDayPlanning.Skill := NewSkillCode;
        TempDayPlanning.Insert();
        if JobFilter <> '' then
            TempDayPlanning.SetFilter("Job No.", JobFilter);
        if JobTaskFilter <> '' then
            TempDayPlanning.SetFilter("Job Task No.", JobTaskFilter);
        if SkillFilter <> '' then
            TempDayPlanning.SetFilter(Skill, SkillFilter);
        exit(not TempDayPlanning.IsEmpty());
    end;

    /// <summary>
    /// Same defaults as part 50711: Skill = Daily Optimizer Setup."Default Skill"; Work-Hour Template =
    /// Job Task."Work Hour Template", else Daily Optimizer Setup."Work hour Template".
    /// </summary>
    local procedure PushNewSequenceDefaults()
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        JobTask: Record "Job Task";
        TemplateCode: Code[20];
    begin
        if DailyOptimizerSetup.Get() then;
        if JobTask.Get(JobNo, JobTaskNo) then
            TemplateCode := JobTask."Work Hour Template";
        if TemplateCode = '' then
            TemplateCode := DailyOptimizerSetup."Work hour Template";
        CurrPage.DhxSequence.SetNewSequenceDefaults(DailyOptimizerSetup."Default Skill", TemplateCode);
    end;

    /// <summary>
    /// Resource context (e.g. "Open Sequences" from a resource marker): sequences created on this page get this
    /// resource as Requested Resource. Call before RunModal.
    /// </summary>
    procedure SetResourceContext(NewResourceNo: Code[20]; NewContextDate: Date)
    begin
        ResourceContextNo := NewResourceNo;
        ResourceContextDate := NewContextDate;
    end;

    /// <summary>
    /// Opens the "New sequence" dialog as soon as the page is ready (Job/Task from SetContext). Call before RunModal.
    /// </summary>
    procedure SetOpenNewSequenceOnStart()
    begin
        OpenNewSequenceOnStart := true;
    end;

    /// <summary>
    /// Optional "New sequence" dialog defaults, pushed to the add-in in ControlReady. Call before RunModal.
    /// When never called, nothing is pushed (behaviour unchanged).
    /// </summary>
    procedure SetSequenceDefaults(SkillCode: Text; TemplateCode: Text)
    begin
        DefaultSkillCode := SkillCode;
        DefaultTemplateCode := TemplateCode;
        HasNewSequenceDefaults := true;
        if ControlIsReady then
            CurrPage.DhxSequence.SetNewSequenceDefaults(DefaultSkillCode, DefaultTemplateCode);
    end;

    /// <summary>
    /// Section keys (rows) to shade light yellow - the sequence rows holding the Day Planning lines
    /// the page was opened for. Call BEFORE SetContext, like SetPeriod.
    /// </summary>
    procedure SetHighlightedSections(SectionKeys: JsonArray)
    begin
        SectionKeys.WriteTo(HighlightKeysJson);
    end;

    /// <summary>
    /// Shows ONLY the sequence rows given to SetHighlightedSections (call after it). The filter
    /// icon / clear (red x) lifts the restriction again.
    /// </summary>
    procedure SetShowHighlightedOnly()
    begin
        DayPlanningSequenceMgt.SetOnlySections(HighlightKeysJson);
        HighlightKeysJson := '[]'; // every shown row is a related one - no yellow shading needed
    end;

    /// <summary>
    /// Pushes Job No./Job Task No. context from the host card page, plus an optional Work Order
    /// No. to stamp onto newly-created/regenerated lines (table 50610 field 55). Blank is valid
    /// and expected when hosted from the Job Task card (page_50618_JobTaskCard_Project.al) - a
    /// task can span multiple work orders there, so there's no single value to pass. When hosted
    /// from the Workorder Card (Pag50662.WorkorderCard.al) the real Rec."Work Order No." is
    /// passed, so lines created/regenerated here also show up on that card's "Day Plannings"
    /// fasttab (page 50676), which filters on "Work Order No.". On first load (before ControlReady
    /// has fired) this just stores the context - ControlReady itself reads it to build the initial
    /// payload, same call-order precedent as page 50638's own SetContext. On a re-entry (context
    /// changing on an already-live control), it also pushes fresh data immediately via
    /// RefreshTimeline.
    /// </summary>
    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20]; NewWorkOrderNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        WorkOrderNo := NewWorkOrderNo;
        JobFilter := NewJobNo;
        JobTaskFilter := NewJobTaskNo;
        SkillFilter := '';
        ResourceFilter := '';
        if ControlIsReady then
            RefreshTimeline();
    end;

    /// <summary>
    /// Overrides the Job/Job Task/Skill filters SetContext just set (single task) with a wider scope,
    /// e.g. the Gantt resource panel's filter. Blank args clear that filter. Call AFTER SetContext, before
    /// the page is run (the control isn't ready yet, so no refresh is needed here).
    /// </summary>
    procedure SetScopeFilters(NewJobFilter: Text; NewJobTaskFilter: Text; NewSkillFilter: Text)
    begin
        // Blank means "no restriction" (must clear what SetContext set to the single task)
        JobFilter := NewJobFilter;
        JobTaskFilter := NewJobTaskFilter;
        SkillFilter := NewSkillFilter;
        if ControlIsReady then
            RefreshTimeline();
    end;

    // Preserve the calling contract. The Gantt period does not filter this overview.
    procedure SetPeriod(NewFrom: Date; NewTo: Date)
    begin
    end;

    local procedure TimelineEndDate(EarliestDate: Date; LatestDate: Date): Date
    var
        LastVisibleDate: Date;
    begin
        if (EarliestDate = 0D) or (LatestDate = 0D) then
            exit(LatestDate);

        LastVisibleDate := CalcDate('<+12M>', EarliestDate) - 1;
        // The existing wrapper adds seven display days unless the user sets a Period To.
        if PeriodTo = 0D then
            LastVisibleDate -= 7;
        if LatestDate > LastVisibleDate then
            exit(LastVisibleDate);
        exit(LatestDate);
    end;

    local procedure RefreshTimeline()
    var
        SectionsJsonTxt: Text;
        EventsJsonTxt: Text;
        EarliestDate: Date;
        LatestDate: Date;
    begin
        if not ControlIsReady then
            exit;
        if (JobNo = '') or (JobTaskNo = '') then
            exit;

        DayPlanningSequenceMgt.BuildSectionsAndEventsJson(JobFilter, JobTaskFilter, SkillFilter, ResourceFilter, PeriodFrom, PeriodTo, SectionsJsonTxt, EventsJsonTxt, EarliestDate, LatestDate);
                    DataSpanFrom := EarliestDate;
                    DataSpanTo := LatestDate;
        PushFilterInfo(); // before RefreshTimeline: the add-in sizes the span from the period end
        CurrPage.DhxSequence.SetHighlightedSections(HighlightKeysJson);
        CurrPage.DhxSequence.RefreshTimeline(SectionsJsonTxt, EventsJsonTxt, EarliestDate, TimelineEndDate(EarliestDate, LatestDate));
        PushHolidaysData(EarliestDate, LatestDate);
    end;

    local procedure PushFilterInfo()
    var
        ShownJobFilter: Text;
        ShownJobTaskFilter: Text;
        ShownSkillFilter: Text;
        ShownResourceFilter: Text;
        ShownDate: Text;
        ShownPeriodFrom: Text;
        ShownPeriodTo: Text;
    begin
        GetShownFilters(ShownJobFilter, ShownJobTaskFilter, ShownSkillFilter, ShownResourceFilter, ShownDate);
        ShownPeriodFrom := FormatIsoDate(PeriodFrom);
        ShownPeriodTo := FormatIsoDate(PeriodTo);
        CurrPage.DhxSequence.SetFilterInfo(ShownJobFilter, ShownJobTaskFilter, ShownSkillFilter, ShownResourceFilter, ShownPeriodFrom, ShownPeriodTo);
    end;

    local procedure FormatIsoDate(D: Date): Text
    begin
        if D = 0D then
            exit('');
        exit(Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    /// <summary>
    /// Same day-off/holiday shading as the Gantt add-in (src/dhx/ganttdemo2): reuses
    /// Codeunit "GanttChartDataHandler".GetHolidaysAsJson (already generic - Base Calendar driven,
    /// not Gantt-specific) so both add-ins render identical colors from the identical source data,
    /// instead of re-deriving calendar-exception logic here. Windowed to [AnchorDate, EndDate] -
    /// EndDate is now the caller's actual latest Plan Date (see codeunit 50695's LatestDate),
    /// matching whatever span this timeline itself dynamically renders, rather than the old
    /// hard-coded +31D window (that fixed window was exactly the same cutoff bug this whole
    /// dynamic-span change fixes). Falls back to AnchorDate+31D only when EndDate is blank (e.g.
    /// no data yet), same as the old default. AnchorDate itself falls back to Today() when there's
    /// no data yet (EarliestDate = 0D), same fallback Init/RefreshTimeline already apply to the
    /// scheduler's own anchor.
    /// </summary>
    local procedure PushHolidaysData(AnchorDate: Date; EndDate: Date)
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        HolidaysJsonTxt: Text;
    begin
        if AnchorDate = 0D then
            AnchorDate := Today();
        if EndDate = 0D then
            EndDate := CalcDate('<+31D>', AnchorDate);
        HolidaysJsonTxt := GanttChartDataHandler.GetHolidaysAsJson(AnchorDate, EndDate);
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
