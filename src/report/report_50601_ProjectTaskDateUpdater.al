report 50601 "Job Task Planned Date Updater"
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
        DayTaskPeriodSyncMgt: Codeunit "DayTask Period Sync Mgt.";
    begin
        // popup page editor:
        if (ProjectTask.PlannedStartDate <> PlannedStartDate) or (ProjectTask.PlannedEndDate <> PlannedEndDate) then
            if DayTaskPeriodSyncMgt.ShowPreview(ProjectTask,
                                                ProjectTask."Job No.",
                                                ProjectTask."Job Task No.",
                                                ProjectTask.PlannedStartDate,
                                                ProjectTask.PlannedEndDate,
                                                PlannedStartDate,
                                                PlannedEndDate) then begin

                ProjectTask.PlannedStartDate := PlannedStartDate;
                ProjectTask.PlannedEndDate := PlannedEndDate;
                ProjectTask.Duration := Duration;
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
        PlannedStartDate := JobTask.PlannedStartDate;
        PlannedEndDate := JobTask.PlannedEndDate;
        Duration := JobTask.Duration;
    end;

    local procedure PlannedDateCheck(ChangedFrom: Option "Planned Start Date","Planned End Date",Duration)
    var
        durationTxt: Text;
        durationLbl: Label '<%1D>';
        ErrLbl01: Label 'Planned Start Date cannot be later than Planned End Date.';
    begin
        case ChangedFrom of
            ChangedFrom::"Planned Start Date",
            ChangedFrom::"Planned End Date":
                begin
                    if PlannedStartDate > PlannedEndDate then
                        Error(ErrLbl01);
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