query 50609 "Unique Sequences in DayPlan"
{
    QueryType = Normal;
    Caption = 'Unique Job/Task/Skill Sequences in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Day Planning")
        {
            filter(PlanDateFilter; "Plan Date")
            {
            }
            column(Job_No_; "Job No.")
            {
            }
            column(Job_Task_No_; "Job Task No.")
            {
            }
            column(Skill; Skill)
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
