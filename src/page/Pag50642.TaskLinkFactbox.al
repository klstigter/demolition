page 50642 "Opti Task Link Factbox"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "Opti BCG Gantt Task Link";
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
                    ToolTip = 'Specifies the value of the Target Task No. field.';
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        JobTask: Record "Job Task";
                        JobTaskLookupPage: Page "Opti Job Task List - Project";
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
                    ToolTip = 'Specifies the value of the Link Type field.';
                    ApplicationArea = All;
                }
                field("Constraint Type"; Rec."Constraint Type")
                {
                    ToolTip = 'Specifies the value of the Constraint Type field.';
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