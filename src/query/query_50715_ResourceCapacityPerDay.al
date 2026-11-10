query 50715 "Resource Capacity Per Day"
{
    // Summed "Res. Capacity Entry".Capacity per Resource No. + Date, used by codeunit 50613 to send
    // the Gantt resource panel the real daily capacity of the listed resources (cell colour).
    QueryType = Normal;
    Caption = 'Resource Capacity Per Day';

    elements
    {
        dataitem(Res__Capacity_Entry; "Res. Capacity Entry")
        {
            filter(ResourceNoFilter; "Resource No.") { }
            filter(DateFilter; Date) { }

            column(ResourceNo; "Resource No.") { }
            column(CapacityDate; Date) { }
            column(Capacity; Capacity)
            {
                Method = Sum;
            }
        }
    }
}
