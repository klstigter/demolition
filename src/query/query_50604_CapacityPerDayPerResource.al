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

            // Joined so callers can read Pool Resource No. straight off this query instead of
            // a per-row Resource.Get() in AL (was the dominant cost in the Resource Capacity
            // Scheduler's weekly load - hundreds of capacity-entry rows each doing a separate
            // full-table Get()). Safe as a plain (non-aggregated) column: Pool Resource No. is
            // functionally dependent on Resource No., which is already part of the group-by key
            // via the parent's own Resource_No_ column, so this can't fragment/duplicate groups.
            dataitem(Resource; Resource)
            {
                DataItemLink = "No." = Res__Capacity_Entry."Resource No.";
                SqlJoinType = LeftOuterJoin;

                column(Pool_Resource_No_; "Pool Resource No.")
                {
                }
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}