report 50601 "Opti Job Task Plan. Date Upd."
{
    UsageCategory = None;
    ApplicationArea = Jobs;
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'Project Task Planned Date Updater';

    // dataset
    // {
    //     dataitem(DataItemName; SourceTableName)
    //     {
    //         column(ColumnName; SourceFieldName)
    //         {

    //         }
    //     }
    // }

    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                group(UpdatePlannedPeriod)
                {
                    ShowCaption = false;

                    field(PlannedStartDate; PlannedStartDate)
                    {
                        ToolTip = 'Specifies the value of the Planned Start Date field.';
                        Caption = 'Planned Start Date';
                        trigger OnValidate()
                        var
                            ChangedFrom: Option "Planned Start Date","Planned End Date",Duration;
                        begin
                            PlannedDateCheck(ChangedFrom::"Planned Start Date");
                        end;
                    }
                    field(PlannedEndDate; PlannedEndDate)
                    {
                        ToolTip = 'Specifies the value of the Planned End Date field.';
                        Caption = 'Planned End Date';
                        trigger OnValidate()
                        var
                            ChangedFrom: Option "Planned Start Date","Planned End Date",Duration;
                        begin
                            PlannedDateCheck(ChangedFrom::"Planned End Date");
                        end;
                    }
                    field(Duration; Duration)
                    {
                        ToolTip = 'Specifies the value of the Duration field.';
                        Caption = 'Duration (days)';
                        trigger OnValidate()
                        var
                            ChangedFrom: Option "Planned Start Date","Planned End Date",Duration;
                        begin
                            PlannedDateCheck(ChangedFrom::Duration);
                        end;
                    }
                }
            }
        }

        // actions
        // {
        //     area(processing)
        //     {
        //         action(LayoutName)
        //         {

        //         }
        //     }
        // }
    }

    // rendering
    // {
    //     layout(LayoutName)
    //     {
    //         Type = Excel;
    //         LayoutFile = 'mySpreadsheet.xlsx';
    //     }
    // }

    trigger OnPostReport()
    var
        DayPlanningPeriodSyncMgt: Codeunit "Opti DayPlan. Period Sync Mgt.";
    begin
        // popup page editor:
        if (ProjectTask."Opti VisualBarStartDate" <> PlannedStartDate) or (ProjectTask."Opti VisualBarEndDate" <> PlannedEndDate) then
            if DayPlanningPeriodSyncMgt.ShowPreview(ProjectTask,
                                                ProjectTask."Job No.",
                                                ProjectTask."Job Task No.",
                                                ProjectTask."Opti VisualBarStartDate",
                                                ProjectTask."Opti VisualBarEndDate",
                                                PlannedStartDate,
                                                PlannedEndDate) then begin

                // Apply Changes in the preview already modified the Job Task in the database;
                // re-read it so Modify() doesn't hit a stale-record error.
                ProjectTask.Get(ProjectTask."Job No.", ProjectTask."Job Task No.");
                ProjectTask."Opti VisualBarStartDate" := PlannedStartDate;
                ProjectTask."Opti VisualBarEndDate" := PlannedEndDate;
                ProjectTask."Opti Duration" := Duration;
                ProjectTask.Modify();
            end;
    end;

    var
        ProjectTask: Record "Job Task";
        PlannedStartDate: Date;
        PlannedEndDate: Date;
        Duration: Integer;

    procedure SetPlannedDates(var JobTask: Record "Job Task")
    begin
        ProjectTask := JobTask;
        PlannedStartDate := JobTask."Opti VisualBarStartDate";
        PlannedEndDate := JobTask."Opti VisualBarEndDate";
        Duration := JobTask."Opti Duration";
    end;

    local procedure PlannedDateCheck(ChangedFrom: Option "Planned Start Date","Planned End Date",Duration)
    var
        durationTxt: Text;
        durationLbl: Label '<%1D>', Comment = '%1 = value';
        Err01Lbl: Label 'Planned Start Date cannot be later than Planned End Date.';
    begin
        case ChangedFrom of
            ChangedFrom::"Planned Start Date",
            ChangedFrom::"Planned End Date":
                begin
                    if PlannedEndDate <> 0D then
                        if PlannedStartDate > PlannedEndDate then
                            Error(Err01Lbl);
                    if (PlannedEndDate <> 0D) and (PlannedStartDate <> 0D) then
                        Duration := PlannedEndDate - PlannedStartDate + 1;
                end;
            ChangedFrom::Duration:
                begin
                    if (PlannedStartDate <> 0D) and (Duration >= 1) then begin
                        if Duration = 1 then
                            PlannedEndDate := PlannedStartDate
                        else begin
                            durationTxt := StrSubstNo(durationLbl, Duration - 1);
                            PlannedEndDate := CalcDate(durationTxt, PlannedStartDate);
                        end;
                    end else
                        Duration := 0;
                end;
        end;
    end;
}