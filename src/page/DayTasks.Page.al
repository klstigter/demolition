page 50630 "Day Tasks"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Tasks";
    Caption = 'Day Tasks';
    //Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number.';
                }
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job planning line number.';
                }
                field("Start Planning Date"; Rec."Start Planning Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning date for this day.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day.';
                }
                field("Non Working Hours"; Rec."Non Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of non-working hours in a 24-hour period for this day task.';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of working hours for this day task, calculated automatically based on start and end times.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = true;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of planning line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the resource, item, or G/L account.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity for this day.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor name.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code.';
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the depth.';
                }
                field(IsBoor; Rec.IsBoor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is a boor line.';
                }
                field("Worked Hours"; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the actual worked hours for this day task.';
                    Editable = true;
                }


            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(pLanningLines)
            {
                ApplicationArea = All;
                Caption = 'Planning Lines';
                ToolTip = 'Navigate to the Planning Lines page.';
                Image = AbsenceCalendar;

                trigger OnAction()
                var
                    jobplanningLine: Record "Job Planning Line";
                begin
                    jobplanningLine."Job No." := Rec."Job No.";
                    jobplanningLine."Line No." := Rec."Job Planning Line No.";
                    jobplanningLine."Line No." := jobplanningLine."Line No.";
                    if jobplanningLine.find('=<>') then;
                    Page.Run(Page::"Job Planning Line (Project)", jobplanningLine);
                end;
            }
            action(UnpackJobPlanningLines)
            {
                ApplicationArea = All;
                Caption = 'Unpack Job Planning Lines';
                ToolTip = 'Unpacks job planning lines into daily records.';
                Image = SplitLines;
                Visible = false;

                trigger OnAction()
                var
                    JobDayPlanningMgt: Codeunit "Day Tasks Mgt.";
                begin
                    JobDayPlanningMgt.UnpackAllJobPlanningLines();
                    CurrPage.Update(false);
                end;
            }
            action(RefreshDayPlanning)
            {
                ApplicationArea = All;
                Caption = 'Refresh Day Planning';
                ToolTip = 'Refreshes the day planning lines.';
                Image = Refresh;
                Visible = false;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
