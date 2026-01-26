page 50620 "Gantt Demo DHX 2"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Gantt Demo';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            // controladdin syntax: controladdin(<ControlId>; <ControlAddInName>)
            usercontrol(DHXGanttControl2; "DHX Gantt Control 2")
            {
                ApplicationArea = All;
                // Height/Width can be adjusted if needed
                trigger OnAfterInit()
                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);

                end;

                trigger ControlReady()

                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);
                    LoadPageData();
                end;

                trigger onTaskDblClick(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    PossibleChanges: Boolean;
                    newEventData: Text;
                    EventIDList: List of [Text];
                    JobNo: Code[20];
                    TaskNo: Code[20];
                begin
                    EventIDList := eventId.Split('|');
                    JobNo := EventIDList.Get(1);
                    TaskNo := EventIDList.Get(2);
                    PageHandler.OpenJobTaskCard(JobNo, TaskNo);
                    // Get the latest data after possible changes in day tasks
                    if PossibleChanges then begin
                        if DHXDataHandler.GetEventDataFromEventId(eventId, newEventData) then
                            CurrPage.DHXGanttControl2.RefreshEventData(newEventData); //update event ID
                    end;
                end;

                trigger OnJobTaskUpdated(eventData: Text)
                var
                    GantUpdatedata: Codeunit "Gantt Update Data";
                begin
                    GantUpdatedata.UpdateJobTaskFromJson(eventData);
                    // Now update Job Task + regenerate Day Tasks
                end;

                trigger OpenResourceLoadDay(ResourceId: Text; workDate: Text)
                var
                    DayTask: Record "Day Tasks";
                    WorkDt: Date;
                    PlType: enum "Job Planning Line Type";
                    Tp: array[2] of text;
                begin
                    Evaluate(WorkDt, workDate); // expects YYYY-MM-DD
                    tp[1] := CopyStr(ResourceId, 1, 4);
                    tp[2] := CopyStr(ResourceId, 5);
                    PlType := PlType::Resource;
                    DayTask.SetRange("Day No.", general.DateToInteger(WorkDt));
                    DayTask.setrange(Type, PlType);
                    if tp[1] = 'RES-' then
                        DayTask.SetRange("No.", tp[2]);
                    if tp[1] = 'VEN-' then
                        DayTask.SetRange("Vendor No.", tp[2]);
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetJsonTasks)
            {
                Caption = 'Get JSON Tasks Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                begin
                    JsonTxt := GanttChartDataHandler.GetJobTasksAsJson(AnchorDate);
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GetJsonResources)
            {
                Caption = 'Get JSON Resources Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                begin
                    JsonTxt := GanttChartDataHandler.GetResourcesAsJson();
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GetJsonDayTasks)
            {
                Caption = 'Get JSON Day Tasks Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                begin
                    JsonTxt := GanttChartDataHandler.GetDayTasksAsJson(Setup."From Date", setup."Job No. Filter", '');
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GanttSettings)
            {
                Caption = 'Gantt Settings';
                Image = Setup;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Gantt Chart Setup");
                    setup.get(UserId);
                    CurrPage.DHXGanttControl2.SetColumnVisibility(
                     Setup."Show Start Date",
                     Setup."Show Duration",
                     Setup."Show Constraint Type",
                     Setup."Show Constraint Date",
                     Setup."Show Task Type");
                    CurrPage.DHXGanttControl2.LoadProject(Setup."From Date", Setup."To Date");
                    CurrPage.Update(false); // reapply settings after close
                end;
            }
            action(Undo)
            {
                ApplicationArea = All;
                Caption = 'Undo';
                Image = Undo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.Undo();
                end;
            }

            action(Redo)
            {
                ApplicationArea = All;
                Caption = 'Redo';
                Image = Redo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.Redo();
                end;
            }
            action("AddMarker")
            {
                ApplicationArea = All;
                Caption = 'Add Marker';
                Image = Add;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.AddMarker('2024-06-15', 'New Marker');
                end;
            }
            action("RefreshData")
            {
                ApplicationArea = All;
                Caption = 'Refresh Data';
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshGantt();
                end;
            }
        }

        area(Navigation)
        {
            action(DayTaks)
            {
                Caption = 'Day Tasks';
                ApplicationArea = All;
                image = AbsenceCalendar;

                trigger OnAction()
                begin
                    page.RunModal(Page::"Day Tasks");
                end;
            }

            action(TodayAct)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Position;
                Visible = ShowPreviousNext;
                trigger OnAction()
                begin
                    AnchorDate := Today();
                    RefreshGantt();
                end;
            }
            action(PreviousAct)
            {
                Caption = 'Previous';
                ApplicationArea = All;
                Image = PreviousSet;
                Visible = ShowPreviousNext;
                trigger OnAction()
                begin
                    Case Setup."Date Range Type" of
                        Setup."Date Range Type"::Weekly:
                            AnchorDate := CalcDate('<-1W>', AnchorDate);
                        Setup."Date Range Type"::Monthly:
                            AnchorDate := CalcDate('<-1M>', AnchorDate);
                        Setup."Date Range Type"::Yearly:
                            AnchorDate := CalcDate('<-1Y>', AnchorDate);
                    End;
                    RefreshGantt();
                end;
            }
            action(NextAct)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Image = NextSet;
                Visible = ShowPreviousNext;
                trigger OnAction()
                begin
                    Case Setup."Date Range Type" of
                        Setup."Date Range Type"::Weekly:
                            AnchorDate := CalcDate('<1W>', AnchorDate);
                        Setup."Date Range Type"::Monthly:
                            AnchorDate := CalcDate('<1M>', AnchorDate);
                        Setup."Date Range Type"::Yearly:
                            AnchorDate := CalcDate('<1Y>', AnchorDate);
                    End;
                    RefreshGantt();
                end;
            }
        }


        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(GanttSettings_ref; GanttSettings) { }
                actionref("UodoPromoted"; Undo) { }
                actionref("RedoPromoted"; Redo) { }
                actionref("AddMarkerPromoted"; AddMarker) { }
                actionref("RefreshDataPromoted"; RefreshData) { }
                actionref("Prev_filter"; PreviousAct) { }
                actionref("Today_filter"; Todayact) { }
                actionref("Next_filter"; Nextact) { }
            }
            group(Category_Category4)
            {
                Caption = 'Export';
                actionref(GetJsonTasks_ref; GetJsonTasks) { }
                actionref(GetJsonResources_ref; GetJsonResources) { }
                actionref(GetJsonDayTasks_ref; GetJsonDayTasks) { }
            }
            group(Category_Category5)
            {
                Caption = 'Related';
                actionref(DayTaks_ref; DayTaks) { }

            }

        }
    }

    trigger OnOpenPage()
    begin
        Setup.Get(UserId);
        AnchorDate := Today();
        ShowPreviousNext := not (Setup."Date Range Type" = Setup."Date Range Type"::"Date Range");
    end;

    var
        AnchorDate: Date;
        ToggleAutoScheduling: Boolean;
        PageHandler: Codeunit "Gantt BC Page Handler";
        general: Codeunit "General Planning Utilities";
        Setup: Record "Gantt Chart Setup";
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        ShowPreviousNext: Boolean;

    procedure RefreshGantt()
    begin
        CurrPage.DHXGanttControl2.ClearData();
        Setup.Get(UserId);
        LoadPageData();
    end;

    procedure OnJobTaskUpdated(TaskJson: Text)
    var
        JobTask: Record "Job Task";
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        StartDateTxt: Text;
        EndDateTxt: Text;
        DurationTxt: Text;
        ConstraintDateTxt: Text;
        SchedulingTypeTxt: Text;
        Description: Text[100];
        StartDate: Date;
        EndDate: Date;
        Duration: Integer;
        ConstraintDate: Date;
    begin
        // Parse the JSON
        if not JsonObj.ReadFrom(TaskJson) then
            Error('Invalid JSON format');

        // Extract BC bindings
        if JsonObj.Get('id', JsonToken) then
            JobNo := JsonToken.AsValue().AsCode()
        else
            Error('id. missing in JSON');

        // Extract and update Description
        if JsonObj.Get('text', JsonToken) then begin
            Description := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(JobTask.Description));
            if JobTask.Description <> Description then
                JobTask.Description := Description;
        end;

        // Extract and update Start Date (format: dd-MM-yyyy)
        if JsonObj.Get('start_date', JsonToken) then begin
            StartDateTxt := JsonToken.AsValue().AsText();
            if StartDateTxt <> '' then begin
                StartDate := ParseDate(StartDateTxt);
                if JobTask.PlannedStartDate <> StartDate then
                    JobTask.PlannedStartDate := StartDate;
            end;
        end;

        // Extract and update Start Date (format: dd-MM-yyyy)
        if JsonObj.Get('end_date', JsonToken) then begin
            EndDateTxt := JsonToken.AsValue().AsText();
            if EndDateTxt <> '' then begin
                EndDate := ParseDate(EndDateTxt);
                if JobTask.PlannedEndDate <> EndDate then
                    JobTask.PlannedEndDate := EndDate;
            end;
        end;

        // Extract and update Duration
        if JsonObj.Get('duration', JsonToken) then begin
            Duration := JsonToken.AsValue().AsInteger();
            if (JobTask.PlannedStartDate <> 0D) and (Duration > 0) then begin
                JobTask.PlannedEndDate := JobTask.PlannedStartDate + Duration;
            end;
        end;

        // Extract and update Scheduling Type
        if JsonObj.Get('schedulingType', JsonToken) then begin
            SchedulingTypeTxt := JsonToken.AsValue().AsText();
            case SchedulingTypeTxt of
                'fixed_duration':
                    JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedDuration;
                'fixed_units':
                    JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedUnits;
                'fixed_work':
                    JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedWork;
            end;
        end;

        // Extract constraint date if needed
        if JsonObj.Get('constraint_date', JsonToken) then begin
            ConstraintDateTxt := JsonToken.AsValue().AsText();
            if ConstraintDateTxt <> '' then
                ConstraintDate := ParseDate(ConstraintDateTxt);
            // Add logic to handle constraint date if you have a field for it
        end;

        // Save the changes
        JobTask.Modify(true);
    end;

    local procedure ParseDate(DateText: Text) ParsedDate: Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        DayTxt: Text;
        MonthTxt: Text;
        YearTxt: Text;
        DashPos1: Integer;
        DashPos2: Integer;
    begin
        if DateText = '' then
            exit(0D);

        // Parse format: dd-MM-yyyy
        DashPos1 := StrPos(DateText, '-');
        if DashPos1 = 0 then
            exit(0D);

        DayTxt := CopyStr(DateText, 1, DashPos1 - 1);
        DateText := CopyStr(DateText, DashPos1 + 1);

        DashPos2 := StrPos(DateText, '-');
        if DashPos2 = 0 then
            exit(0D);

        MonthTxt := CopyStr(DateText, 1, DashPos2 - 1);
        YearTxt := CopyStr(DateText, DashPos2 + 1);

        Evaluate(Day, DayTxt);
        Evaluate(Month, MonthTxt);
        Evaluate(Year, YearTxt);

        ParsedDate := DMY2Date(Day, Month, Year);
    end;

    local procedure LoadPageData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        StartDate: Date;
        EndDate: Date;
        JsonTxtTasks: Text;
        JsonTxtResource: Text;
        JsonTxtDayTasks: Text;
    begin
        CurrPage.DHXGanttControl2.SetColumnVisibility(
                        Setup."Show Start Date",
                        Setup."Show Duration",
                        Setup."Show Constraint Type",
                        Setup."Show Constraint Date",
                        Setup."Show Task Type"
                    );
        if setup."Load Job Tasks" then
            JsonTxtTasks := GanttChartDataHandler.GetJobTasksAsJson(AnchorDate);
        if setup."Load Resources" then
            JsonTxtResource := GanttChartDataHandler.GetResourcesAsJson();
        if setup."Load Day Tasks" then
            JsonTxtDayTasks := GanttChartDataHandler.GetDayTasksAsJson(AnchorDate, setup."Job No. Filter");

        GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
        CurrPage.DHXGanttControl2.LoadProject(StartDate, EndDate);
        if setup."Load Job Tasks" then
            CurrPage.DHXGanttControl2.LoadProjectData(JsonTxtTasks);
        if setup."Load Resources" then
            CurrPage.DHXGanttControl2.LoadResourcesData(JsonTxtResource);
        if setup."Load Day Tasks" then
            CurrPage.DHXGanttControl2.LoadDayTasksData(JsonTxtDayTasks);

    end;
}