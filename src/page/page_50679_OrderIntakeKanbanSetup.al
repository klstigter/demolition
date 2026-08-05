page 50707 "Order Intake Kanban Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Order Intake Kanban Setup';
    SourceTable = "Order Intake Kanban Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Vacant Field"; Rec."Vacant Field")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vacant field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        rec.EnsureUserRecord();
    end;
}