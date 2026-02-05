query 50605 "Unique Pool in Day Tasks"
{
    QueryType = Normal;
    Caption = 'Unique Pool in Day Tasks';

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
            column(PoolResNo; "Pool Resource No.")
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
