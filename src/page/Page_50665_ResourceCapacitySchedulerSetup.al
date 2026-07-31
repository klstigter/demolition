page 50705 "Res. Capacity Scheduler Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Resource Capacity Scheduler Setup';
    SourceTable = "Res. Capacity Scheduler Setup";
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
