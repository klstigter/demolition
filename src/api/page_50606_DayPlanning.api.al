page 50606 "DayPlanningApi Opt"
{
    PageType = API;
    Caption = 'Day Planning API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'DayPlanning';
    EntitySetName = 'DayPlannings';
    SourceTable = "Day Planning";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

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
                field(taskDate; Rec."Plan Date")
                {
                    Caption = 'Work Date';
                }
                field(dayLineNo_; Rec."Day Line No.")
                {
                    Caption = 'Day Line No.';
                }
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Task No.';
                }
                field(requestedResourceNo; Rec."Requested Resource No.")
                {
                    Caption = 'No.';
                }
                field(assignedResourceNo; Rec."Assigned Resource No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(planStatus; Rec."Plan Status")
                {
                    ApplicationArea = All;
                }
                field(startTimeRequested; Rec."Start Time Requested")
                {
                    Caption = 'Start Time Assigned';
                }
                field(endTimeRequested; Rec."End Time Requested")
                {
                    Caption = 'End Time Assigned';
                }
                field(nonWorkingMinutesRequested; Rec."Non Working Minutes Requested") { }
                field(startTimeAssigned; Rec."Start Time Assigned")
                {
                    Caption = 'Start Time Assigned';
                }
                field(endTimeAssigned; Rec."End Time Assigned")
                {
                    Caption = 'End Time Assigned';
                }
                field(nonWorkingMinutesAssigned; Rec."Non Working Minutes Assigned") { }
                field(startTimeRealized; Rec."Start Time Realized")
                {
                    Caption = 'Start Time Assigned';
                }
                field(endTimeRealized; Rec."End Time Realized")
                {
                    Caption = 'End Time Assigned';
                }
                field(requestedHours; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                }
                field(assignedHours; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                }
                field(realizedHours; Rec."Realized Hours")
                {
                    ApplicationArea = All;
                }
                field(workedHours; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                }
                field(dataOwner; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field(teamLeader; Rec."Team Leader")
                {
                    ApplicationArea = All;
                }
                field(leader; Rec.Leader)
                {
                    ApplicationArea = All;
                }
                field(workOrderNo; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field(skill; Rec."Skill")
                {
                    Caption = 'Skill';
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