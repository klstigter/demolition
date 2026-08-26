page 50706 "DHX Scheduler - TimeLine"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Resource Scheduler - Timeline';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; DHXResourceCapacityScheduleAddin)
            {
                ApplicationArea = All;

                #region Init and Load Data on Control Ready

                trigger ControlReady()
                var
                    ResSchedSetup: Record "Resource Scheduler Setup";
                    DailyOptimizerSetup: Record "Daily Optimizer Setup";
                    SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
                    TreeJsonTxt: Text;
                    ColorsJsonTxt: Text;
                    AssignedColorHex: Text;
                    CapacityColorHex: Text;
                    ExternalBorderColorHex: Text;
                    CapacityBorderColorHex: Text;
                    HasSetup: Boolean;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Capacity data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);

                    DHXDataHandler.GetWeekPeriodDates(Today(), AnchorDate, DummyEndDate);
                    if IsResourceGroupMode() then
                        TreeJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildTreeJson(ResourceFilter, SkillFilter)
                    else
                        TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, AnchorDate, DummyEndDate);

                    HasSetup := ResSchedSetup.Get(UserId);
                    if HasSetup and (ResSchedSetup."Timeline Hour Step" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourStep(ResSchedSetup."Timeline Hour Step");
                    if HasSetup and (ResSchedSetup."Timeline End Hour" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourRange(ResSchedSetup."Timeline Start Hour", ResSchedSetup."Timeline End Hour");

                    if GuiAllowed() then
                        Window.Update(1, 'Rendering...');
                    CurrPage.DhxScheduler.Init(TreeJsonTxt, AnchorDate);
                    // Envelope/Assigned/Height/Capacity colors now come from the company-wide
                    // "Daily Optimizer Setup" singleton (table 50605), not the per-user "Resource
                    // Scheduler Setup" - the old flat "Requested Color" field is gone entirely
                    // (requested segments are now colored per-skill - see codeunit "DHX Data
                    // Handler"'s ResolveRequestedColor, wired into each event's own
                    // "requested_color" JSON field, CSS "--dp-color-requested" is the fallback
                    // default). "Capacity Border Color" is back as a real setup field (table
                    // 50605 field 67) and is now sent as "capacityBorder" below - wrapper.js
                    // already supported this key (it just had nothing feeding it before), applying
                    // it to the "--cap-color-border" CSS variable that the Capacity event's border
                    // already reads.
                    // Boolean-context Get() - a bare "DailyOptimizerSetup.Get();" statement
                    // throws a runtime error if the singleton row doesn't exist yet (it's only
                    // ever created lazily, the first time someone opens page 50654's OnOpenPage -
                    // there's no install-time seeding), unlike this same call used in an "if"
                    // condition, which just leaves DailyOptimizerSetup blank/Init()'d on a miss -
                    // exactly what's wanted here since every field read below already tolerates
                    // blank (SetBarColors' per-key guards, GetCapacitySegmentColors' own fallback).
                    if DailyOptimizerSetup.Get() then;
                    // Assigned/Capacity colors are resolved via GetCapacitySegmentColors (one
                    // call resolves both) so this page always matches the Daily/Weekly bar-chart
                    // tiles' defaults (#548235/#2E75B6), instead of silently falling back to
                    // wrapper.js's own (previously mismatched) CSS defaults whenever "Daily
                    // Optimizer Setup" is entirely blank. SetBarColors is now always called
                    // unconditionally - every property write inside it is individually guarded
                    // against blank values, so sending blanks for Envelope/EnvelopeBorder/Heights
                    // when the setup record doesn't exist is a safe no-op per key.
                    SkillCapacityAnalysisMgt.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
                    CapacityBorderColorHex := SkillCapacityAnalysisMgt.GetCapacityBorderColor();
                    ColorsJsonTxt := StrSubstNo('{"envelope":"%1","envelopeBorder":"%2","assigned":"%3","assignedHeight":%4,"requestedHeight":%5,"capacity":"%6","capacityBorder":"%7"}',
                        DailyOptimizerSetup."Envelope Color",
                        DailyOptimizerSetup."Envelope Border Color",
                        AssignedColorHex,
                        DailyOptimizerSetup."Assigned High (%)",
                        DailyOptimizerSetup."Requested High (%)",
                        CapacityColorHex,
                        CapacityBorderColorHex);
                    CurrPage.DhxScheduler.SetBarColors(ColorsJsonTxt);
                    PushResourceFilterInfo();
                    CurrPage.Update(false);

                    if GuiAllowed() then
                        Window.Close();
                end;

                trigger OnAfterInit()
                var
                    startDate: Date;
                    endDate: Date;
                    CapacityJsonTxt: Text;
                    EventsJsonTxt: Text;
                begin
                    DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                    if IsResourceGroupMode() then begin
                        CapacityJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                        EventsJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
                    end else begin
                        CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                        EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
                    end;
                    CurrPage.DhxScheduler.LoadCapacity(CapacityJsonTxt);
                    CurrPage.DhxScheduler.LoadData(EventsJsonTxt);
                end;

                #endregion Init and Load Data on Control Ready

                #region Section double click / Event double click

                trigger OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text)
                begin
                    // Skill (folder) rows have key "SKILL|..." and Resource Group (folder) rows
                    // have key "GROUP|..." - only Resource leaf rows (composite "<Resource No.>|
                    // <Skill Code>" or "<Resource No.>|<Resource Group No.>") open the Resource
                    // Card; a folder row double-click is a no-op. Extract the plain Resource No.
                    // before lookup.
                    if not (sectionId.StartsWith('SKILL|') or sectionId.StartsWith('GROUP|')) then
                        DHXDataHandler.SkillResScheduler_OpenResourceCard(DHXDataHandler.SkillResScheduler_ExtractResourceNo(sectionId));
                end;

                trigger OnEventDblClick(eventId: Text; eventData: Text)
                begin
                    if eventId.StartsWith('CAP|') then
                        DHXDataHandler.SkillResScheduler_OpenCapacityByEventId(eventId)
                    else
                        DHXDataHandler.SkillResScheduler_OpenDayPlanningByEventId(eventId);
                end;

                #endregion Section double click / Event double click

                #region Timeline Navigate

                trigger OnTimelineNavigate(NavigateJson: Text)
                var
                    TreeJsonTxt: Text;
                    CapacityJsonTxt: Text;
                    EventsJsonTxt: Text;
                    startDate: Date;
                    endDate: Date;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Capacity data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);

                    DHXDataHandler.GetStartEndDatesFromTimeLineJSon(NavigateJson, startDate, endDate);
                    if startDate <> 0D then begin
                        AnchorDate := startDate;
                        if IsResourceGroupMode() then begin
                            TreeJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildTreeJson(ResourceFilter, SkillFilter);
                            CapacityJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                            EventsJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
                        end else begin
                            TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, startDate, endDate);
                            CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                            EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
                        end;

                        if GuiAllowed() then
                            Window.Update(1, 'Rendering...');
                        CurrPage.DhxScheduler.RefreshTimeline(TreeJsonTxt, EventsJsonTxt, CapacityJsonTxt, startDate);
                        PushResourceFilterInfo();
                    end;

                    if GuiAllowed() then
                        Window.Close();
                end;

                #endregion Timeline Navigate

                #region Diagnostics

                trigger OnEventsNotMatch(EventIdsJsonTxt: Text)
                begin
                    Message(EventIdsJsonTxt);
                end;

                trigger OnGetAllEvents(EventIdsJsonTxt: Text)
                begin
                    Message('All Events: %1', EventIdsJsonTxt);
                end;

                trigger OnGetAllSections(SectionIdsJsonTxt: Text)
                begin
                    Message('All Sections: %1', SectionIdsJsonTxt);
                end;

                #endregion Diagnostics

                #region Context Menu

                trigger OnEventContextMenu(eventId: Text; action: Text; payloadJson: Text)
                begin
                    case action of
                        'OpenDayPlanning':
                            if not eventId.StartsWith('CAP|') then
                                DHXDataHandler.SkillResScheduler_OpenDayPlanningByEventId(eventId);
                        'OpenCapacity':
                            if eventId.StartsWith('CAP|') then
                                DHXDataHandler.SkillResScheduler_OpenCapacityByEventId(eventId);
                        'OpenTask':
                            if not eventId.StartsWith('CAP|') then
                                DHXDataHandler.SkillResScheduler_OpenTaskByEventId(eventId);
                        'OpenResource':
                            if not eventId.StartsWith('CAP|') then
                                DHXDataHandler.SkillResScheduler_OpenResourceByEventId(eventId);
                    end;
                end;

                trigger OnSectionContextMenu(sectionId: Text; action: Text; payloadJson: Text)
                var
                    ResNo: Code[20];
                    startDate: Date;
                    endDate: Date;
                begin
                    if sectionId.StartsWith('SKILL|') or sectionId.StartsWith('GROUP|') then
                        exit; // no per-skill/per-group actions yet
                    // Resource leaf rows are the composite "<Resource No.>|<Skill Code>" (or
                    // "<Resource No.>|<Resource Group No.>") key; these actions all operate on
                    // the plain Resource No. regardless of which tree grouping mode is active.
                    ResNo := DHXDataHandler.SkillResScheduler_ExtractResourceNo(sectionId);
                    case action of
                        'OpenResourceCard':
                            DHXDataHandler.SkillResScheduler_OpenResourceCard(ResNo);
                        'OpenResourceSkills':
                            DHXDataHandler.SkillResScheduler_OpenResourceSkills(ResNo);
                        'OpenDayPlannings':
                            begin
                                DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                                DHXDataHandler.SkillResScheduler_OpenDayPlanningsForResource(ResNo, startDate, endDate);
                            end;
                        'OpenTask':
                            begin
                                DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                                DHXDataHandler.SkillResScheduler_OpenTasksForResource(ResNo, startDate, endDate);
                            end;
                        'ShowCapacity':
                            begin
                                DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                                DHXDataHandler.SkillResScheduler_ShowCapacityForResource(ResNo, startDate, endDate);
                            end;
                    end;
                end;

                #endregion Context Menu

                #region Resource/Skill Filter Toolbar

                trigger OnFilterIconClick()
                var
                    FilterDlg: Report "Resource Scheduler Filter";
                    NewResNoFilter: Text;
                    NewResNameFilter: Text;
                    NewSkillFilter: Text;
                    NewJobFilter: Text;
                    NewJobTaskFilter: Text;
                begin
                    FilterDlg.SetFilter(ResourceFilter, ResourceNameFilter, SkillFilter);
                    FilterDlg.EnableJobFilter();
                    FilterDlg.SetJobFilter(JobFilter, JobTaskFilter);
                    FilterDlg.RunModal();
                    if FilterDlg.IsConfirmed() then begin
                        FilterDlg.GetFilter(NewResNoFilter, NewResNameFilter, NewSkillFilter);
                        // "Resource Scheduler Filter" collects a Resource No./Name/Skill triple; only
                        // Resource No. and Skill feed this add-in's tree/event filtering today (see
                        // SkillResScheduler_* procedures) - ResourceNameFilter is kept for the toolbar
                        // tooltip text only, matching pool's own ResourceNameFilter usage.
                        ResourceFilter := NewResNoFilter;
                        ResourceNameFilter := NewResNameFilter;
                        SkillFilter := NewSkillFilter;
                        FilterDlg.GetJobFilter(NewJobFilter, NewJobTaskFilter);
                        JobFilter := NewJobFilter;
                        JobTaskFilter := NewJobTaskFilter;
                        // Narrowing by Job typically leaves most resources with zero matching Day
                        // Planning bars - force "Hide no event resources" on so the tree isn't mostly
                        // empty rows. Only forced ON when a job filter becomes active; clearing the
                        // job filter (here or via OnClearResourceFilter) does NOT force it back off -
                        // that stays a manual user toggle via the existing Hide/Show actions.
                        if (JobFilter <> '') or (JobTaskFilter <> '') then begin
                            HideNoEventResourcesFlag := true;
                            CurrPage.DhxScheduler.SetHideNoEventResources(true);
                        end;
                        RefreshSchedule();
                    end;
                end;

                trigger OnClearResourceFilter()
                begin
                    ResourceFilter := '';
                    ResourceNameFilter := '';
                    SkillFilter := '';
                    JobFilter := '';
                    JobTaskFilter := '';
                    RefreshSchedule();
                end;

                #endregion Resource/Skill Filter Toolbar
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TodayAct)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Position;
                trigger OnAction()
                begin
                    AnchorDate := Today();
                    RefreshSchedule();
                end;
            }
            action(PreviousAct)
            {
                Caption = 'Previous';
                ApplicationArea = All;
                Image = PreviousSet;
                trigger OnAction()
                begin
                    AnchorDate := CalcDate('<-1W>', AnchorDate);
                    RefreshSchedule();
                end;
            }
            action(NextAct)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Image = NextSet;
                trigger OnAction()
                begin
                    AnchorDate := CalcDate('<1W>', AnchorDate);
                    RefreshSchedule();
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshSchedule();
                end;
            }
            action(DateLookup)
            {
                Caption = 'Go to Date';
                ApplicationArea = All;
                Image = GoTo;
                trigger OnAction()
                var
                    DateRec: Record Date;
                    DateSelectorPage: Page "Date Lookup";
                    SelectedDate: Date;
                begin
                    DateSelectorPage.LookupMode := true;
                    if DateSelectorPage.RunModal() = Action::LookupOK then begin
                        DateSelectorPage.GetRecord(DateRec);
                        SelectedDate := DateRec."Period Start";
                        AnchorDate := SelectedDate;
                        RefreshSchedule();
                    end;
                end;
            }

            action(ExecEventsNotMatch)
            {
                Caption = 'Get Events Not Matching Sections';
                ApplicationArea = All;
                Image = "Event";
                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.get_events_not_match_with_section();
                end;
            }
            action(ExecGetAllEvents)
            {
                Caption = 'Get All Events';
                ApplicationArea = All;
                Image = Task;
                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.getAllEvents();
                end;
            }
            action(ExecGetAllSections)
            {
                Caption = 'Get All Sections';
                ApplicationArea = All;
                Image = Resource;
                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.getAllSections();
                end;
            }

            group(CapacityGroup)
            {
                Caption = 'Capacity';
                action(ShowCapacityAct)
                {
                    ApplicationArea = All;
                    Caption = 'Show Capacity';
                    Image = AddWatch;
                    Visible = not ShowCapacityFlag;
                    trigger OnAction()
                    begin
                        ShowCapacityFlag := true;
                        CurrPage.DhxScheduler.SetShowCapacity(true);
                    end;
                }
                action(HideCapacityAct)
                {
                    ApplicationArea = All;
                    Caption = 'Hide Capacity';
                    Image = RemoveContacts;
                    Visible = ShowCapacityFlag;
                    trigger OnAction()
                    begin
                        ShowCapacityFlag := false;
                        CurrPage.DhxScheduler.SetShowCapacity(false);
                    end;
                }
            }
            group(DayPlanningGroup)
            {
                Caption = 'Day Plannings';
                action(ShowDayPlanningAct)
                {
                    ApplicationArea = All;
                    Caption = 'Show Day Planning';
                    Image = AddWatch;
                    Visible = not ShowDayPlanningFlag;
                    trigger OnAction()
                    begin
                        ShowDayPlanningFlag := true;
                        CurrPage.DhxScheduler.SetShowDayPlanning(true);
                    end;
                }
                action(HideDayPlanningAct)
                {
                    ApplicationArea = All;
                    Caption = 'Hide Day Planning';
                    Image = RemoveContacts;
                    Visible = ShowDayPlanningFlag;
                    trigger OnAction()
                    begin
                        ShowDayPlanningFlag := false;
                        CurrPage.DhxScheduler.SetShowDayPlanning(false);
                    end;
                }
            }
            group(NoEventResourcesGroup)
            {
                Caption = 'No Event Resources';
                action(HideNoEventResourcesAct)
                {
                    ApplicationArea = All;
                    Caption = 'Hide no event resources';
                    Image = FilterLines;
                    Visible = not HideNoEventResourcesFlag;
                    trigger OnAction()
                    begin
                        HideNoEventResourcesFlag := true;
                        CurrPage.DhxScheduler.SetHideNoEventResources(true);
                    end;
                }
                action(ShowNoEventResourcesAct)
                {
                    ApplicationArea = All;
                    Caption = 'Show no event resources';
                    Image = ClearFilter;
                    Visible = HideNoEventResourcesFlag;
                    trigger OnAction()
                    begin
                        HideNoEventResourcesFlag := false;
                        CurrPage.DhxScheduler.SetHideNoEventResources(false);
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Date Navigation';

                actionref("Prev_promoted"; PreviousAct) { }
                actionref("Today_promoted"; TodayAct) { }
                actionref("Next_promoted"; NextAct) { }
                actionref("Refresh_promoted"; Refresh) { }
                actionref("DateLookup_promoted"; DateLookup) { }
                actionref("ShowCapacity_promoted"; ShowCapacityAct) { }
                actionref("HideCapacity_promoted"; HideCapacityAct) { }
                actionref("ShowDayPlanning_promoted"; ShowDayPlanningAct) { }
                actionref("HideDayPlanning_promoted"; HideDayPlanningAct) { }
                actionref("HideNoEventResources_promoted"; HideNoEventResourcesAct) { }
                actionref("ShowNoEventResources_promoted"; ShowNoEventResourcesAct) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowCapacityFlag := true;
        ShowDayPlanningFlag := true;
    end;

    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        AnchorDate: Date;
        DummyEndDate: Date;
        ResourceFilter: Text;
        ResourceNameFilter: Text;
        SkillFilter: Text;
        JobFilter: Text;
        JobTaskFilter: Text;
        ShowCapacityFlag: Boolean;
        ShowDayPlanningFlag: Boolean;
        HideNoEventResourcesFlag: Boolean;

    /// <summary>
    /// External entry point for opening this page pre-filtered by Skill (left resource panel
    /// filtered to resources carrying the given Skill Code, rather than to a specific resource).
    /// Used by the Task Scheduler's right-click context menu action "Open Res. Scheduler
    /// (Assigned) - Timeline" (see codeunit "DHX Data Handler".OpenResSchedulerTimeline).
    /// Respects whichever grouping mode "Daily Optimizer Setup"."Resource Scheduler - List Type"
    /// currently selects - both the SkillResScheduler_ (By Skill) and ResGroupResScheduler_ (By
    /// Resource Group) builder families accept a SkillFilter parameter, so the Skill restriction
    /// applies either way; only the grouping (by Skill branch vs. by Resource Group branch)
    /// differs.
    /// </summary>
    procedure OpenSkillFiltered(SkillCodeVal: Code[20])
    begin
        SkillFilter := SkillCodeVal;
        ResourceFilter := '';
    end;

    local procedure RefreshSchedule()
    var
        TreeJsonTxt: Text;
        CapacityJsonTxt: Text;
        EventsJsonTxt: Text;
        startDate: Date;
        endDate: Date;
        Window: Dialog;
        LoadingLbl: Label 'Loading Capacity data...\n#1######################';
    begin
        if GuiAllowed() then
            Window.Open(LoadingLbl);

        DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
        if IsResourceGroupMode() then begin
            TreeJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildTreeJson(ResourceFilter, SkillFilter);
            CapacityJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
            EventsJsonTxt := DHXDataHandler.ResGroupResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
        end else begin
            TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, startDate, endDate);
            CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
            EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);
        end;

        if GuiAllowed() then
            Window.Update(1, 'Rendering...');
        CurrPage.DhxScheduler.RefreshTimeline(TreeJsonTxt, EventsJsonTxt, CapacityJsonTxt, startDate);
        PushResourceFilterInfo();
        CurrPage.Update(false);

        if GuiAllowed() then
            Window.Close();
    end;

    local procedure PushResourceFilterInfo()
    var
        startDate: Date;
        endDate: Date;
        ResNameLbl: Text;
    begin
        DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
        ResNameLbl := GetResourceName(ResourceFilter);
        if ResourceNameFilter <> '' then
            ResNameLbl += StrSubstNo(' (name filter: %1)', ResourceNameFilter);
        if SkillFilter <> '' then
            ResNameLbl += StrSubstNo(' (skill filter: %1)', SkillFilter);
        if (JobFilter <> '') or (JobTaskFilter <> '') then
            ResNameLbl += StrSubstNo(' (job filter: %1 %2)', JobFilter, JobTaskFilter);
        CurrPage.DhxScheduler.SetResourceFilterInfo(
            ResourceFilter,
            ResNameLbl,
            Format(startDate, 0, '<Year4>-<Month,2>-<Day,2>'),
            Format(endDate, 0, '<Year4>-<Month,2>-<Day,2>'),
            SkillFilter);
    end;

    /// <summary>
    /// True when "Daily Optimizer Setup"."Resource Scheduler - List Type" = "By Resource Group",
    /// the switch that makes the left-panel tree group by "Resource Group" (table 72, via each
    /// Resource's own "Resource Group No." field - see codeunit "DHX Data Handler"'s
    /// "ResGroupResScheduler_" procedure family) instead of the default Skill grouping
    /// ("SkillResScheduler_" family). Rec.Get() with no key value reads the setup singleton
    /// (blank "Primary Key"), same pattern used elsewhere in this app (e.g. table "Day Planning"
    /// OnInsert, codeunit "Day Planning Mgt."); false (Skill grouping) when the setup record
    /// does not exist yet.
    /// </summary>
    local procedure IsResourceGroupMode(): Boolean
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if not DailyOptimizerSetup.Get() then
            exit(false);
        exit(DailyOptimizerSetup."Resource Scheduler - List Type" = DailyOptimizerSetup."Resource Scheduler - List Type"::"By Resource Group");
    end;

    local procedure GetResourceName(pResourceNo: Text): Text
    var
        ResRec: Record Resource;
    begin
        if pResourceNo = '' then
            exit('');
        if StrLen(pResourceNo) > MaxStrLen(ResRec."No.") then
            exit('');
        if ResRec.Get(CopyStr(pResourceNo, 1, MaxStrLen(ResRec."No."))) then
            exit(ResRec.Name);
        exit('');
    end;
}
