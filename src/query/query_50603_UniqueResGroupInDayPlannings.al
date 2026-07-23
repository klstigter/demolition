query 50603 "Unique ResGrp in DayPlannings"
{
    QueryType = Normal;
    Caption = 'Unique Resource Groups in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Day Planning")
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
