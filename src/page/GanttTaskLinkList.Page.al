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
                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project number.';
                }
                field("Source Task No."; Rec."Source Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source task number.';
                }
                field("Target Task No."; Rec."Target Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the target task number.';
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
                field("Link Id"; Rec."Link Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for the link.';
                    Visible = false;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the link was created.';
                }
                field("Modified At"; Rec."Modified At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the link was last modified.';
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
