page 50639 "Day Planning Pattern"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Planning Pattern";
    AboutTitle = 'Create Day Plannings for Job Task';
    DataCaptionExpression = '"Job No.": ' + jobnofilter + ' - ' + '"Job Task No.": ' + JobTaskNoFilter;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {

                field("Job No."; Rec."Job No.")
                {
                    ToolTip = 'Specifies the value of the Project No. field.', Comment = '%';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ToolTip = 'Specifies the value of the Project Task No. field.', Comment = '%';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.', Comment = '%';
                    Visible = false;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ToolTip = 'Specifies the value of the Resource No. field.', Comment = '%';
                }
                field(SkillsRequired; Rec.SkillsRequired)
                {
                    ToolTip = 'Specifies the value of the Skills Required field.', Comment = '%';
                }
                field("Work-Hour Template"; Rec."Work-Hour Template")
                {
                    ToolTip = 'Specifies the value of the Work-Hour Template field.', Comment = '%';
                }
                field("Quantity of Lines"; Rec."Quantity of Lines")
                {
                    ToolTip = 'Specifies the value of the Quantity of Lines field.', Comment = '%';
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ToolTip = 'Specifies the value of the Work Order No. field.', Comment = '%';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ToolTip = 'Specifies the value of the Planned Start Date field.', Comment = '%';
                }
                field("End Date"; Rec."End Date")
                {
                    ToolTip = 'Specifies the value of the Planned End Date field.', Comment = '%';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ToolTip = 'Specifies the value of the Start Time field.', Comment = '%';
                }
                field("End Time"; Rec."End Time")
                {
                    ToolTip = 'Specifies the value of the End Time field.', Comment = '%';
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ToolTip = 'Specifies the value of the Requested Hours field.', Comment = '%';
                }
                field("Non Working Minutes"; Rec."Non Working Minutes")
                {
                    ToolTip = 'Specifies the value of the Non Working Minutes field.', Comment = '%';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the value of the Vendor No. field.', Comment = '%';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ToolTip = 'Specifies the value of the Vendor Name field.', Comment = '%';
                }
                field("Day 1"; Rec."Day 1")
                {
                    ToolTip = 'Specifies the value of the Day 1 field.', Comment = '%';
                }
                field("Day 2"; Rec."Day 2")
                {
                    ToolTip = 'Specifies the value of the Day 2 field.', Comment = '%';
                }
                field("Day 3"; Rec."Day 3")
                {
                    ToolTip = 'Specifies the value of the Day 3 field.', Comment = '%';
                }
                field("Day 4"; Rec."Day 4")
                {
                    ToolTip = 'Specifies the value of the Day 4 field.', Comment = '%';
                }
                field("Day 5"; Rec."Day 5")
                {
                    ToolTip = 'Specifies the value of the Day 5 field.', Comment = '%';
                }
                field("Day 6"; Rec."Day 6")
                {
                    ToolTip = 'Specifies the value of the Day 6 field.', Comment = '%';
                }
                field("Day 7"; Rec."Day 7")
                {
                    ToolTip = 'Specifies the value of the Day 7 field.', Comment = '%';
                }

            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(Create)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Image = New;

                trigger OnAction()

                var
                    DayPlanningMgt: Codeunit "Day Plannings Mgt.";
                begin
                    DayPlanningMgt.CreateDayPlanning(Rec);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        WorkHourTemplate: Record "Work-Hour Template";
        WorkOrder: Record "Work Order";
    begin
        DailyOptimizerSetup.Get();
        Rec."Work-Hour Template" := DailyOptimizerSetup."Work hour Template";
        Rec.SkillsRequired := DailyOptimizerSetup."Default Skill";
        Rec."Quantity of Lines" := 1;
        if Rec."Work-Hour Template" <> '' then begin
            WorkHourTemplate.Get(Rec."Work-Hour Template");
            Rec."Start Time" := WorkHourTemplate."Default Start Time";
            Rec."End Time" := WorkHourTemplate."Default End Time";
            Rec."Non Working Minutes" := WorkHourTemplate."Non Working Minutes";
        end;
        if WorkOrderNoFilter <> '' then begin
            WorkOrder.SetFilter("Work Order No.", WorkOrderNoFilter);
            if WorkOrder.FindFirst() then begin
                Rec."Work Order No." := WorkOrder."Work Order No.";
                Rec."Start Date" := WorkOrder."Date Window Start";
                Rec."End Date" := WorkOrder."Date Window End";
            end;
        end;
        if (rec."Start Date" <> 0D) and (rec."End Date" <> 0D) then
            Rec.Validate("End Time");
    end;

    var
        JobNoFilter: Code[20];
        JobTaskNoFilter: Code[20];
        WorkOrderNoFilter: Code[20];

    procedure fillbuffer(JobNo: Code[20]; JobTaskNo: Code[20]; WorkOrderNo: Code[20])
    begin
        rec.FillBuffer(JobNo, JobTaskNo);
        JobNoFilter := JobNo;
        JobTaskNoFilter := JobTaskNo;
        WorkOrderNoFilter := WorkOrderNo;
        rec.FilterGroup(2);
        rec.SetRange("Job No.", JobNo);
        rec.SetRange("Job Task No.", JobTaskNo);
        rec.SetRange("Work Order No.", WorkOrderNo);
        rec.FilterGroup(0);
    end;
}