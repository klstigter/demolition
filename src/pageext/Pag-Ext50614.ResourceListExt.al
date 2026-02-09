pageextension 50614 "Resource List Ext." extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
        addafter("Name")
        {
            field("Day Tasks"; Rec."Day Tasks")
            {
                ApplicationArea = Jobs;
                Caption = 'Day Tasks';
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