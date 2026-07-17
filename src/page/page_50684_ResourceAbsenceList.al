page 50684 "Resource Absence List"
{
    Caption = 'Resource Absence List';
    PageType = List;
    SourceTable = "Res. Capacity Entry";
    SourceTableView = where(Type = const(Absence));
    CardPageId = "Resource Absence Card";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of the absence.';
                }
                field(Hours; HoursValue)
                {
                    ApplicationArea = All;
                    Caption = 'Hours';
                    ToolTip = 'Specifies the number of absence hours.';
                }
                field("Absence Reason Code"; Rec."Absence Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for the absence.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource this absence entry applies to.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HoursValue := -Rec.Capacity;
    end;

    var
        HoursValue: Decimal;
}
