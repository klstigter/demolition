query 50604 "Capacity Per Day Per Resource"
{
    QueryType = Normal;

    elements
    {
        dataitem(Res__Capacity_Entry; "Res. Capacity Entry")
        {
            filter(Date_Filter; Date) { }
            filter(Resource_No__Filter; "Resource No.") { }
            column(Date; Date) { }
            column(Resource_No_; "Resource No.") { }
            column(Duplicate_Id; "Duplicate Id") { }
            column(Capacity; Capacity)
            {
                Method = Sum;
            }
            column(Entry_No; "Entry No.")
            {
                Method = Max;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}