page 50702 "DayPlanningPatternApi Opt"
{
    PageType = API;
    Caption = 'Day Planning Pattern API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'DayPlanningPattern';
    EntitySetName = 'DayPlanningPatterns';
    SourceTable = "Day Planning Pattern";
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
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'Project No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Project Task No.';
                }
                field(lineNo_; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(resourceNo_; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(skillsRequired; Rec.SkillsRequired)
                {
                    Caption = 'Skills Required';
                }
                field(workHourTemplate; Rec."Work-Hour Template")
                {
                    Caption = 'Work-Hour Template';
                }
                field(workOrderNo_; Rec."Work Order No.")
                {
                    Caption = 'Work Order No.';
                }
                field(startDate; Rec."Start Date")
                {
                    Caption = 'Planned Start Date';
                }
                field(startTime; Rec."Start Time")
                {
                    Caption = 'Start Time';
                }
                field(endDate; Rec."End Date")
                {
                    Caption = 'Planned End Date';
                }
                field(endTime; Rec."End Time")
                {
                    Caption = 'End Time';
                }
                field(quantityOfLines; Rec."Quantity of Lines")
                {
                    Caption = 'Quantity of Lines';
                }
                field(weekPattern; Rec."Week Pattern")
                {
                    Caption = 'Week Pattern';
                }
                field(nonWorkingMinutes; Rec."Non Working Minutes")
                {
                    Caption = 'Non Working Minutes';
                }
                field(requestedHours; Rec."Requested Hours")
                {
                    Caption = 'Requested Hours';
                }
                field(isPool; Rec."Is Pool")
                {
                    Caption = 'Is Pooled Resource';
                }
                field(poolResourceNo_; Rec."Pool Resource No.")
                {
                    Caption = 'Pool Resource No.';
                }
            }
        }
    }
}
