page 50605 "JobTaskApi Opt"
{
    PageType = API;
    Caption = 'Job Task API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobTask';
    EntitySetName = 'jobTasks';
    SourceTable = "Job Task";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Task No.';
                }
                field(taskType; Rec."Job Task Type")
                {
                    Caption = 'Task Type';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(plannedStartDate; Rec.PlannedStartDate)
                {
                    Caption = 'Planned Start Date';
                }
                field(plannedEndDate; Rec.PlannedEndDate)
                {
                    Caption = 'Planned End Date';
                }
                field(address; Rec."Sell-to Address")
                {
                    Caption = 'Sell-to Address';
                }
                field(address2; Rec."Sell-to Address 2")
                {
                    Caption = 'Sell-to Address 2';
                }
                field(city; Rec."Sell-to City")
                {
                    Caption = 'Sell-to City';
                }
                field(county; Rec."Sell-to County")
                {
                    Caption = 'Sell-to County';
                }
                field(regionCode; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Sell-to Country/Region Code';
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Modified At';
                }
            }
        }
    }
}