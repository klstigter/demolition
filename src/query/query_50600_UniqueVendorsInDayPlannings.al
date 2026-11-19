query 50600 "Opti Uniq. Vend in Day Plans"
{
    QueryType = Normal;
    Caption = 'Unique Vendors in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Opti Day Planning")
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
