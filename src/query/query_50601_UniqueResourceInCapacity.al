query 50601 "Unique Resource in Capacity"
{
    QueryType = Normal;
    Caption = 'Unique Resource in Capacity';

    elements
    {
        dataitem(Res__Capacity_Entry; "Res. Capacity Entry")
        {
            filter(EntryDateFilter; "Date")
            {
            }
            filter(Resource_Group_No_; "Resource Group No.")
            {
            }
            column(Resource_No_; "Resource No.")
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}