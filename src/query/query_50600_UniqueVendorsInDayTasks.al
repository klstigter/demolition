query 50600 "Unique Vendors in Day Tasks"
{
    QueryType = Normal;
    Caption = 'Unique Vendors in Day Tasks';

    elements
    {
        dataitem(Day_Tasks; "Day Tasks")
        {
            filter(TaskDateFilter; "Task Date")
            {
            }
            filter(Resource_Group_No_Filter; "Resource Group No.")
            {
            }
            column(VendorNo; "Vendor No.")
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
