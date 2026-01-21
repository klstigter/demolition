pageextension 50613 "Res. Capacity Entries Opt" extends "Res. Capacity Entries"
{
    layout
    {
        // Add changes to page layout here
        addafter(Capacity)
        {
            field("Start Time"; Rec."Start Time")
            {
                ApplicationArea = Jobs;
                Caption = 'Start Time';
            }
            field("End Time"; Rec."End Time")
            {
                ApplicationArea = Jobs;
                Caption = 'End Time';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}