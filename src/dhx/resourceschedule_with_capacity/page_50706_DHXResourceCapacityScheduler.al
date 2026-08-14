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
                    TreeJsonTxt: Text;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Capacity data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);

                    DHXDataHandler.GetWeekPeriodDates(Today(), AnchorDate, DummyEndDate);
                    TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter);

                    if GuiAllowed() then
                        Window.Update(1, 'Rendering...');
                    CurrPage.DhxScheduler.Init(TreeJsonTxt, AnchorDate);
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
                    CurrPage.DhxScheduler.LoadData(DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, startDate, endDate));
                end;

                #endregion Init and Load Data on Control Ready

                #region Section double click / Event double click

                trigger OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text)
                begin
                    // Skill (folder) rows have key "SKILL|..." - only Resource leaf rows (plain
                    // Resource "No.") open the Resource Card; a Skill row double-click is a no-op.
                    if not sectionId.StartsWith('SKILL|') then
                        DHXDataHandler.SkillResScheduler_OpenResourceCard(sectionId);
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
                        TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter);
                        CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
                        EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, startDate, endDate);

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
                    end;
                end;

                trigger OnSectionContextMenu(sectionId: Text; action: Text; payloadJson: Text)
                var
                    startDate: Date;
                    endDate: Date;
                begin
                    if sectionId.StartsWith('SKILL|') then
                        exit; // no per-skill actions yet
                    case action of
                        'OpenResourceCard':
                            DHXDataHandler.SkillResScheduler_OpenResourceCard(sectionId);
                        'OpenResourceSkills':
                            DHXDataHandler.SkillResScheduler_OpenResourceSkills(sectionId);
                        'OpenDayPlannings':
                            begin
                                DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                                DHXDataHandler.SkillResScheduler_OpenDayPlanningsForResource(sectionId, startDate, endDate);
                            end;
                        'ShowCapacity':
                            begin
                                DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
                                DHXDataHandler.SkillResScheduler_ShowCapacityForResource(sectionId, startDate, endDate);
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
                begin
                    FilterDlg.SetFilter(ResourceFilter, ResourceNameFilter, SkillFilter);
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
                        RefreshSchedule();
                    end;
                end;

                trigger OnClearResourceFilter()
                begin
                    ResourceFilter := '';
                    ResourceNameFilter := '';
                    SkillFilter := '';
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
        TreeJsonTxt := DHXDataHandler.SkillResScheduler_BuildTreeJson(ResourceFilter, SkillFilter);
        CapacityJsonTxt := DHXDataHandler.SkillResScheduler_BuildCapacityJson(ResourceFilter, SkillFilter, startDate, endDate);
        EventsJsonTxt := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson(ResourceFilter, SkillFilter, startDate, endDate);

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
