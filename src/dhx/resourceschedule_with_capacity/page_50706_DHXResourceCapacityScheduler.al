page 50706 "DHX Scheduler (Res+Capacity)"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Resource Scheduler (New)';

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
                    TreeJsonTxt: Text;
                    ColorsJsonTxt: Text;
                    HasSetup: Boolean;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Capacity data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);

                    DHXDataHandler.GetWeekPeriodDates(Today(), AnchorDate, DummyEndDate);
                    TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, AnchorDate, DummyEndDate);

                    HasSetup := ResSchedSetup.Get(UserId);
                    if HasSetup and (ResSchedSetup."Timeline Hour Step" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourStep(ResSchedSetup."Timeline Hour Step");
                    if HasSetup and (ResSchedSetup."Timeline End Hour" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourRange(ResSchedSetup."Timeline Start Hour", ResSchedSetup."Timeline End Hour");

                    if GuiAllowed() then
                        Window.Update(1, 'Rendering...');
                    CurrPage.DhxScheduler.Init(TreeJsonTxt, AnchorDate);
                    if HasSetup then
                        if (ResSchedSetup."Envelope Color" <> '') or
                           (ResSchedSetup."Envelope Border Color" <> '') or
                           (ResSchedSetup."Assigned Color" <> '') or
                           (ResSchedSetup."Requested Color" <> '') or
                           (ResSchedSetup."Assigned High (%)" > 0) or
                           (ResSchedSetup."Requested High (%)" > 0) or
                           (ResSchedSetup."Capacity Color" <> '') or
                           (ResSchedSetup."Capacity Border Color" <> '')
                        then begin
                            ColorsJsonTxt := StrSubstNo('{"envelope":"%1","envelopeBorder":"%2","assigned":"%3","requested":"%4","assignedHeight":%5,"requestedHeight":%6,"capacity":"%7","capacityBorder":"%8"}',
                                ResSchedSetup."Envelope Color",
                                ResSchedSetup."Envelope Border Color",
                                ResSchedSetup."Assigned Color",
                                ResSchedSetup."Requested Color",
                                ResSchedSetup."Assigned High (%)",
                                ResSchedSetup."Requested High (%)",
                                ResSchedSetup."Capacity Color",
                                ResSchedSetup."Capacity Border Color");
                            CurrPage.DhxScheduler.SetBarColors(ColorsJsonTxt);
                        end;
                    PushResourceFilterInfo();
                    CurrPage.Update(false);

                    if GuiAllowed() then
                        Window.Close();
                end;

                trigger OnAfterInit()
                var
                    startDate: Date;
                    endDate: Date;
                begin
                    DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                    CurrPage.DhxScheduler.LoadCapacity(DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate));
                    CurrPage.DhxScheduler.LoadData(DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate));
                end;

                #endregion Init and Load Data on Control Ready

                #region Section double click / Event double click

                trigger OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text)
                begin
                    // Skill (folder) rows have key "SKILL|..." - only Resource leaf rows
                    // (composite "<Resource No.>|<Skill Code>") open the Resource Card; a Skill
                    // row double-click is a no-op. Extract the plain Resource No. before lookup.
                    if not sectionId.StartsWith('SKILL|') then
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
                        TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, startDate, endDate);
                        CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                        EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);

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
                    if sectionId.StartsWith('SKILL|') then
                        exit; // no per-skill actions yet
                    // Resource leaf rows are the composite "<Resource No.>|<Skill Code>" key;
                    // these actions all operate on the plain Resource No. across every skill.
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
        TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter, startDate, endDate);
        CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
        EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, JobFilter, JobTaskFilter, startDate, endDate);

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
