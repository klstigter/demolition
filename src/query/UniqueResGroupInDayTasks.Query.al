query 50603 "Unique ResGroup in Day Tasks"
{
    QueryType = Normal;
    Caption = 'Unique Resource Groups in Day Tasks';

    elements
    {
        dataitem(Day_Tasks; "Day Tasks")
        {
            filter(TaskDateFilter; "Task Date")
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
}
