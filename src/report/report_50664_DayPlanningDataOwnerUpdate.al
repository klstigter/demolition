/// <summary>
/// Batch report that sets "Data Owner" on the filtered Day Planning rows. Bypasses the OnModify
/// lock on non-Planner rows by assigning directly and calling Modify(false).
/// </summary>
report 50664 "Day Planning Data Owner Update"
{
    Caption = 'Day Planning Data Owner Update';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;
    Permissions = tabledata "Day Planning" = rm;

    dataset
    {
        dataitem(DayPlanning; "Day Planning")
        {
            RequestFilterFields = "Job No.", "Job Task No.", "Day Line No.", Skill, "Requested Resource No.", "Assigned Resource No.", "Data Owner";

            trigger OnPreDataItem()
            begin
                if DayPlanning.GetFilters() = '' then
                    Error(SetFilterErr);
                UpdatedCount := 0;
            end;

            trigger OnAfterGetRecord()
            begin
                if DayPlanning."Data Owner" <> NewDataOwner then begin
                    DayPlanning."Data Owner" := NewDataOwner;
                    DayPlanning.Modify(false);
                    UpdatedCount += 1;
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewDataOwnerField; NewDataOwner)
                    {
                        ApplicationArea = All;
                        Caption = 'Change Data Owner to';
                        ToolTip = 'Specifies the Data Owner that will be set on all Day Planning records matching the filter.';
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    begin
        Message(UpdatedMsg, UpdatedCount);
    end;

    var
        NewDataOwner: Enum "Data Owner Opt.";
        UpdatedCount: Integer;
        SetFilterErr: Label 'Set a filter on Day Planning before running this report.';
        UpdatedMsg: Label '%1 Day Planning record(s) updated.', Comment = '%1 = number of records';
}
