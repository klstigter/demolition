page 50639 "Day Task Generator"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Task Generator";
    AboutTitle = 'Create Day Tasks for Job Task';
    DataCaptionExpression = '"Job No.": ' + jobnofilter + ' - ' + '"Job Task No.": ' + JobTaskNoFilter;
    DelayedInsert = true;

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
                field("Working Hours"; Rec."Working Hours")
                {
                    ToolTip = 'Specifies the value of the Working Hours field.', Comment = '%';
                }
                field("Non Working Minutes"; Rec."Non Working Minutes")
                {
                    ToolTip = 'Specifies the value of the Non Working Minutes field.', Comment = '%';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ToolTip = 'Specifies the value of the Vendor Name field.', Comment = '%';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the value of the Vendor No. field.', Comment = '%';
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
                    DayTaskMgt: Codeunit "Day Tasks Mgt.";
                begin
                    DayTaskMgt.CreateDayTask(Rec);
                end;
            }
        }
    }


    var
        JobNoFilter: Code[20];
        JobTaskNoFilter: Code[20];

    procedure fillbuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        rec.FillBuffer(JobNo, JobTaskNo);
        JobNoFilter := JobNo;
        JobTaskNoFilter := JobTaskNo;
        rec.FilterGroup(2);
        rec.SetRange("Job No.", JobNo);
        rec.SetRange("Job Task No.", JobTaskNo);
        rec.FilterGroup(0);
    end;
}