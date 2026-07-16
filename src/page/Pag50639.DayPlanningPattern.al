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
                field("Resource Category"; Rec."Resource Category")
                {
                    ToolTip = 'Specifies the category of resource.', Comment = '%';
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
                field("Week Pattern"; Rec."Week Pattern")
                {
                    ToolTip = 'Specifies which weekdays are active, derived automatically from the "Work-Hour Template" field''s weekday hours.', Comment = '%';
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
        WorkOrder: Record "Work Order";
    begin
        DailyOptimizerSetup.Get();
        Rec.Validate("Work-Hour Template", DailyOptimizerSetup."Work hour Template");
        Rec.SkillsRequired := DailyOptimizerSetup."Default Skill";
        Rec."Quantity of Lines" := 1;
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
        //rec.FillBuffer(JobNo, JobTaskNo);
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