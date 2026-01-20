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
                }
                field(JobTaskDescription; JobTaskDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task description.';
                    Caption = 'Job Task Description';
                    Editable = false;
                }
            }
            group(JobPlanningLineInformation)
            {
                Caption = 'Job Planning Line Information';
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job planning line number.';
                    Caption = 'Job Planning Line No.';
                }
                field(JobPlanningLineDescription; JobPlanningLineDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job planning line description.';
                    Caption = 'Job Planning Line Description';
                    Editable = false;
                }
            }
        }
    }

    var
        JobDescription: Text[100];
        JobTaskDescription: Text[100];
        JobPlanningLineDescription: Text[100];

    trigger OnAfterGetRecord()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Get Job Description
        JobDescription := '';
        if Job.Get(Rec."Job No.") then
            JobDescription := Job.Description;

        // Get Job Task Description
        JobTaskDescription := '';
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            JobTaskDescription := JobTask.Description;

        // Get Job Planning Line Description
        JobPlanningLineDescription := '';
        if JobPlanningLine.Get(Rec."Job No.", Rec."Job Task No.", Rec."Job Planning Line No.") then
            JobPlanningLineDescription := JobPlanningLine.Description;
    end;
}
