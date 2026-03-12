query 50602 "Unique Group in Capacity"
{
    QueryType = Normal;
    Caption = 'Unique Resource Group in Capacity';

    elements
    {
        dataitem(Res__Capacity_Entry; "Res. Capacity Entry")
        {
            filter(EntryDateFilter; "Date")
            {
            }
            column(Resource_Group_No_; "Resource Group No.")
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