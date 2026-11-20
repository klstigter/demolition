page 50642 "Task Link Factbox"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "BCG Gantt Task Link";
    Editable = false;
    Caption = 'Task Links';
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Target Task No."; Rec."Target Task No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        JobTask: Record "Job Task";
                        JobTaskLookupPage: Page "Job Task List - Project";
                    begin
                        JobTask.setrange("Job No.", Rec."Job No.");
                        JobTask.SetRange("Job Task No.", Rec."Target Task No.");
                        if JobTask.FindFirst() then;
                        JobTask.SetRange("Job Task No.");
                        JobTaskLookupPage.SetRecord(JobTask);
                        JobTaskLookupPage.SetTableView(JobTask);
                        JobTaskLookupPage.Run();
                    end;

                }
                field("Link Type"; Rec."Link Type")
                {
                    ApplicationArea = All;
                }
                field("Constraint Type"; Rec."Constraint Type")
                {
                    ApplicationArea = All;
                }

            }
        }

    }

    actions
    {
        area(Processing)
        {

        }
    }
}