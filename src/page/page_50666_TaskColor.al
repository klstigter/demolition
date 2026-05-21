page 50666 "Task Color Opt."
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Planning Color Opt.";
    SourceTableView = sorting("No.", "No. 2") where(Type = const(Task));
    Caption = 'Task Color';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Type"; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    Caption = 'Job No.';
                    ApplicationArea = All;
                    TableRelation = "Job";
                }
                field("No. 2"; Rec."No. 2")
                {
                    Caption = 'Job Task No.';
                    ApplicationArea = All;
                    TableRelation = "Job Task" where("Job No." = field("No."));
                }
                field("Task"; Rec."Task")
                {
                    ApplicationArea = All;
                }
            }
        }
        // area(Factboxes)
        // {

        // }
    }

    // actions
    // {
    //     area(Processing)
    //     {

    //     }
    // }

}