page 50652 "BCG Gantt Task Link List"
{
    PageType = List;
    SourceTable = "BCG Gantt Task Link";
    Caption = 'Gantt Task Links';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project number.';
                }
                field("Source Task No."; Rec."Source Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source task number.';
                }
                field("Source Task Description"; Rec."Source Task Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Displays the description of the source task.';
                }
                field("Target Task No."; Rec."Target Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the target task number.';
                }
                field("Target Task Description"; Rec."Target Task Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Displays the description of the target task.';
                }
                field("Link Type"; Rec."Link Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of link between tasks.';
                }
                field("Lag (Days)"; Rec."Lag (Days)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lag in days for the link.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Delete)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the selected task link.';

                trigger OnAction()
                begin
                    if Confirm('Do you want to delete the selected link?', false) then
                        Rec.Delete(true);
                end;
            }
        }
    }
}
