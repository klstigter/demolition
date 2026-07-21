page 50624 "Day Planning Info FactBox"
{
    PageType = CardPart;
    SourceTable = "Day Planning";
    Caption = 'Day Planning Information';

    layout
    {
        area(Content)
        {
            group(DayPlanningDetails)
            {
                Caption = 'Day Planning Details';
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field("Task Date"; Rec."Work Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Task Date';
                }
                field("Plan Status"; Rec."Plan Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the plan status of the day planning.';
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day planning.';
                    Caption = 'Day Line No.';
                }
                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field("Pattern Line No."; Rec."Pattern Line No.")
                {
                    ApplicationArea = All;
                }
            }
            group(JobInformation)
            {
                Caption = 'Job Information';
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                    Caption = 'Job No.';

                    trigger OnDrillDown()
                    var
                        Job: Record Job;
                        JobCard: Page "Opti Job Card";
                    begin
                        Job.Get(Rec."Job No.");
                        JobCard.SetRecord(Job);
                        JobCard.RunModal();
                    end;
                }
                field(JobDescription; JobDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job description.';
                    Caption = 'Job Description';
                    Editable = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number.';
                    Caption = 'Job Task No.';

                    trigger OnDrillDown()
                    var
                        JobTask: Record "Job Task";
                        JobCard: Page "Job Task Card";
                    begin
                        JobTask.Get(Rec."Job No.", Rec."Job Task No.");
                        JobCard.SetRecord(JobTask);
                        JobCard.RunModal();
                    end;
                }
                field(JobTaskDescription; JobTaskDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task description.';
                    Caption = 'Job Task Description';
                    Editable = false;
                }
            }
            group(Requested)
            {
                Caption = 'Request';
                field("Pool Resource No."; Rec."Requested Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                }

                field("Resource No."; Rec."Requested Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the request number.';
                    Caption = 'Request No.';
                }
                field("Start Time"; Rec."Start Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                }
                field("End Time"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                }
                field("Non Working Minutes"; Rec."Non Working Minutes Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Non Working Minutes Requested field.', Comment = '%';
                }

                field("Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the requested hours for this day task.';
                }
                field("Total Hours"; Rec."Total Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total Requested Hours field.', Comment = '%';
                }
            }

        }
    }

    var
        JobDescription: Text[100];
        JobTaskDescription: Text[100];

    trigger OnAfterGetRecord()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Task";
    begin
        // Get Job Description
        JobDescription := '';
        if Job.Get(Rec."Job No.") then
            JobDescription := Job.Description;

        // Get Job Task Description
        JobTaskDescription := '';
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            JobTaskDescription := JobTask.Description;

    end;
}
