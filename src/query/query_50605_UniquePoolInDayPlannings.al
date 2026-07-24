query 50605 "Unique Pool in Day Plannings"
{
    QueryType = Normal;
    Caption = 'Unique Pool in Day Plannings';

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
            column(PoolResNo; "Assigned Pool Resource No.")
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
