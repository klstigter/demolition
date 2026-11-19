pageextension 50613 "Opti Res. Capacity Entries" extends "Res. Capacity Entries"
{
    layout
    {
        // Add changes to page layout here
        addafter(Capacity)
        {
            field("Opti Duplicate Id"; Rec."Opti Duplicate Id")
            {
                ToolTip = 'Specifies the value of the Duplicate Id field.';
                ApplicationArea = Jobs;
                Caption = 'Duplicate Id';
            }
            field("Opti Start Time"; Rec."Opti Start Time")
            {
                ToolTip = 'Specifies the value of the Start Time field.';
                ApplicationArea = Jobs;
                Caption = 'Start Time';
            }
            field("Opti End Time"; Rec."Opti End Time")
            {
                ToolTip = 'Specifies the value of the End Time field.';
                ApplicationArea = Jobs;
                Caption = 'End Time';
            }
            field("Opti Requested Hours"; Rec."Opti Requested Hours")
            {
                ToolTip = 'Specifies the value of the Requested Hours field.';
                ApplicationArea = Jobs;
                Caption = 'Requested Hours';
            }
            field("Opti Assigned Hours"; Rec."Opti Assigned Hours")
            {
                ToolTip = 'Specifies the value of the Assigned Hours field.';
                ApplicationArea = Jobs;
                Caption = 'Assigned Hours';
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