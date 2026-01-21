page 50626 "Job Planning Line Info FactBox"
{
    Caption = 'Job Planning Line Information';
    PageType = CardPart;
    SourceTable = "Job Planning Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                    Caption = 'Job No.';

                    trigger OnDrillDown()
                    var
                        Job: Record Job;
                    begin
                        if Job.Get(Rec."Job No.") then
                            Page.Run(Page::"Job Card", Job);
                    end;
                }
                field(JobDescription; JobDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Job Description';
                    ToolTip = 'Specifies the description of the job.';
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
                    begin
                        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
                            Page.Run(Page::"Job Task Card", JobTask);
                    end;
                }
                field(JobTaskDescription; JobTaskDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Job Task Description';
                    ToolTip = 'Specifies the description of the job task.';
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning line number.';
                    Caption = 'Planning Line No.';
                }
            }
            group(Planning)
            {
                Caption = 'Planning';

                field("Start Planning Date"; Rec."Start Planning Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start planning date.';
                }
                field("End Planning Date"; Rec."End Planning Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end planning date.';
                }
                field("Total Day Taks"; Rec."Total Day Taks")
                {
                    ApplicationArea = All;
                    ToolTip = 'The total number of day tasks created for this planning line.';
                }
                field("Total Worked Hours"; Rec."Total Worked Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'The total number of worked hours recorded for this planning line.';
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
    begin
        Clear(JobDescription);
        Clear(JobTaskDescription);

        if Job.Get(Rec."Job No.") then
            JobDescription := Job.Description;

        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            JobTaskDescription := JobTask.Description;
    end;
}
