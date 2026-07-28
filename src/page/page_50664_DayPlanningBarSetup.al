page 50664 "Day Planning Bar Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Day Planning Bar Setup';
    SourceTable = "Day Planning Bar Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Colors)
            {
                Caption = 'Day Planning Bar Colors';

                field("Envelope Color"; Rec."Envelope Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Background color of the full Day Planning bar (visible where neither the Assigned nor Requested strip covers it). Enter a hex color, e.g. #1B3A6B.';
                }
                field("Envelope Border Color"; Rec."Envelope Border Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Border color of the full Day Planning bar. Enter a hex color, e.g. #14294D.';
                }
                field("Assigned Color"; Rec."Assigned Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Color of the Assigned time-range strip on the Day Planning bar. Enter a hex color, e.g. #7FB3FA.';
                }
                field("Requested Color"; Rec."Requested Color")
                {
                    ApplicationArea = All;
                    ToolTip = 'Color of the Requested time-range strip on the Day Planning bar. Enter a hex color, e.g. #6FCF97.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get('') then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
