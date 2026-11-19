query 50606 "Opti Uniq. Days in Day Plans"
{
    QueryType = Normal;
    Caption = 'Unique Days in Day Plannings';

    elements
    {
        dataitem(Day_Tasks; "Opti Day Planning")
        {
            filter(TaskDateFilter; "Plan Date") { }
            filter(Resource_Group_No_Filter; "Resource Group No.") { }
            filter(job_Filter; "Job No.") { }
            filter(job_task_Filter; "Job Task No.") { }
            column(Job; "Job No.") { }
            column(JobTask; "Job Task No.") { }
            column(TaskDate; "Plan Date") { }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}
