page 50624 "Day Task Information FactBox"
{
    PageType = CardPart;
    SourceTable = "Day Tasks";
    Caption = 'Day Task Information';

    layout
    {
        area(Content)
        {
            group(DayTaskDetails)
            {
                Caption = 'Day Task Details';
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field(DayLineNo; Rec.DayLineNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day task.';
                    Caption = 'Day Line No.';
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
                        JobCard: Page "Job Card";
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
            }
            group(JobTaskInformation)
            {
                Caption = 'Job Task Information';
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
