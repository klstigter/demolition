query 50608 "Unique Resource Joined"
{
    QueryType = Normal;
    Caption = 'Unique Resource in Capacity (Joined)';

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

            dataitem(Resource; Resource)
            {
                DataItemLink = "No." = Res__Capacity_Entry."Resource No.";
                SqlJoinType = InnerJoin;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}
