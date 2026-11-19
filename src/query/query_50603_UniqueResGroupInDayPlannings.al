query 50603 "Opti Uniq. ResGrp in DayPlans"
{
    QueryType = Normal;
    Caption = 'Unique Resource Groups in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Opti Day Planning")
        {
            filter(TaskDateFilter; "Plan Date")
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
