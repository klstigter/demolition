page 50670 "Opti Date Lookup Dialog"
{
    PageType = List;
    SourceTable = Date;
    Caption = 'Select Date';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Dates)
            {
                field("Period Start"; Rec."Period Start")
                {
                    ToolTip = 'Specifies the value of the Period Start field.';
                    ApplicationArea = All;
                    Caption = 'Date';
                }
            }
        }
    }

}