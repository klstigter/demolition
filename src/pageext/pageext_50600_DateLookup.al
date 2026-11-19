pageextension 50600 "Opti DateLookupOptimizer" extends "Date Lookup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Period Name")
        {
            field("Opti Period Start"; Rec."Period Start")
            {
                ToolTip = 'Specifies the value of the Period Start field.';
                ApplicationArea = All;
                Caption = 'Date';
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Period Type", Rec."Period Type"::Day);
        SetToDate(Today);
    end;

    var
        myInt: Integer;

    local procedure SetToDate(Date: Date)
    var
        GetPos: Text;
    begin
        Rec.SetRange("Period Start", Date);
        Rec.FindFirst();
        GetPos := Rec.GetPosition();
        Rec.SetRange("Period Start");
        Rec.SetPosition(GetPos);
    end;
}