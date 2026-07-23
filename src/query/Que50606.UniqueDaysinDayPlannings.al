query 50606 "Unique Days in Day Plannings"
{
    QueryType = Normal;
    Caption = 'Unique Days in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Day Planning")
        {
            filter(TaskDateFilter; "Task Date") { }
            filter(Resource_Group_No_Filter; "Resource Group No.") { }
            filter(job_Filter; "Job No.") { }
            filter(job_task_Filter; "Job Task No.") { }
            column(Job; "Job No.") { }
            column(JobTask; "Job Task No.") { }
            column(TaskDate; "Task Date") { }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
