page 50709 "Job Task Planning Part"
{
    PageType = CardPart;
    SourceTable = "Job Task";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Planning)
            {
                ShowCaption = false;

                group(Duration)
                {
                    field("Project Manager"; Rec."Project Manager")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Manager';
                        ToolTip = 'Specifies the project manager for the project task. The project manager is based on the project manager on the related project planning line.';
                    }
                    field("Work Hour Template"; Rec."Work Hour Template")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the work hour template for the project task. The work hour template is based on the work hour template on the related project planning line.';
                    }
                    field("Planned Start Date"; Rec.PlannedStartDate)
                    {
                        ApplicationArea = All;
                        Editable = false; //use assist edit to change the value
                        ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';

                        trigger OnAssistEdit()
                        var
                            PlannedDateUpdater: Report "Job Task Planned Date Updater";
                        begin
                            PlannedDateUpdater.SetPlannedDates(Rec);
                            PlannedDateUpdater.RunModal();
                        end;
                    }
                    field("Planned End Date"; Rec.PlannedEndDate)
                    {
                        ApplicationArea = All;
                        Editable = false; //use assist edit to change the value
                        ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
                    }
                    field(DurationTask; Rec.Duration)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the duration of the project task in days.';
                        importance = Promoted;
                    }
                }

                group(ProgressAndConstraint)
                {
                    Caption = 'In Progress / Constraint';

                    field("Estimated Hours"; Rec."Estimated Hours")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Estimated Hours field.', Comment = '%';
                        importance = Promoted;
                    }

                    field(Progress; Rec.Progress)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the progress percentage (0-100) for this job task.';
                        importance = Promoted;
                    }
                    field("Total Worked Hours"; Rec."Total Assigned Hours")
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies the total worked hours from all related day plannings.';
                        importance = Promoted;
                    }
                    field("Constraint Type"; Rec."Constraint Type")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the constraint of the project task.';
                    }
                    field("Constraint Date"; Rec."Constraint Date")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the constraint date of the project task.';
                    }
                }
            }
        }
    }
}
