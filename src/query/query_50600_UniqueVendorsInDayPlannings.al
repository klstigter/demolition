query 50600 "Unique Vend in Day Plannings"
{
    QueryType = Normal;
    Caption = 'Unique Vendors in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Day Planning")
        {
            filter(TaskDateFilter; "Plan Date")
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
