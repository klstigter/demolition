page 50665 "Opti Res. Cap. Scheduler Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Resource Capacity Scheduler Setup';
    SourceTable = "Opti Res. Cap. Scheduler Setup";
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
