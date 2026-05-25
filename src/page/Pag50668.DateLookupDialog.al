page 50668 "Date Lookup Dialog"
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
                    ApplicationArea = All;
                    Caption = 'Date';
                }
            }
        }
    }

}