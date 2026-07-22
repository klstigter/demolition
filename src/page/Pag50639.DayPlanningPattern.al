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
                field(SkillsRequired; Rec.SkillsRequired)
                {
                    ToolTip = 'Specifies the value of the Skills Required field.', Comment = '%';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ToolTip = 'Specifies the value of the Resource No. field.', Comment = '%';
                }
                field("Quantity of Lines"; Rec."Quantity of Lines")
                {
                    ToolTip = 'Specifies the value of the Quantity of Lines field.', Comment = '%';
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ToolTip = 'Specifies the value of the Work Order No. field.', Comment = '%';
                }
                field("Work-Hour Template"; Rec."Work-Hour Template")
                {
                    ToolTip = 'Specifies the value of the Work-Hour Template field.', Comment = '%';
                }
                field("Time Slot No."; Rec."Time Slot No.")
                {
                    ToolTip = 'Specifies the time slot set used for this pattern line.';
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
                field("Week Pattern"; Rec."Week Pattern")
                {
                    ToolTip = 'Shows 7 day values from the selected Time Slot in the format day1|day2|day3|day4|day5|day6|day7. A dash means no value for that day.';
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

    trigger OnAfterGetRecord()
    var
        TimeSlot: Record "Time Slot";
    begin
        if rec."Time Slot No." <> 0 then
            rec."Week Pattern" := TimeSlot.GetWorkingHours(rec."Time Slot No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        WorkOrder: Record "Work Order";
    begin
        if xRec.SkillsRequired = '' then begin // first new record

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
        end else begin
            rec."Job No." := xRec."Job No.";
            rec."Job Task No." := xRec."Job Task No.";
            Rec."Work Order No." := xRec."Work Order No.";

            rec.SkillsRequired := xRec.SkillsRequired;
            rec."Work-Hour Template" := xRec."Work-Hour Template";
            rec."Quantity of Lines" := xRec."Quantity of Lines";
            Rec."Start Date" := xRec."Start Date";
            Rec."End Date" := xRec."End Date";
            rec."Start Time" := xRec."Start Time";
            rec."End Time" := xRec."End Time";
            rec."Requested Hours" := xRec."Requested Hours";
            rec."Non Working Minutes" := xRec."Non Working Minutes";
            rec."Time Slot No." := xRec."Time Slot No.";
        end;
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