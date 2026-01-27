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
                    Style = Favorable;      // green
                    StyleExpr = Rec.Fulfilled;
                }
                field(DayLineNo; Rec.DayLineNo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day task.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number.';
                    Visible = false;
                }
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job planning line number.';
                    Visible = false;
                }
                field("Start Planning Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning date for this day.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Non Working Hours"; Rec."Non Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of non-working hours in a 24-hour period for this day task.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of working hours for this day task, calculated automatically based on start and end times.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Remaining Hours"; Rec."Remaining Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the remaining hours needed to fulfill the capacity for this day task.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Fulfilled; Rec.Fulfilled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the day task has fulfilled the required capacity.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of planning line.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the resource, item, or G/L account.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(skill; Rec.skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill associated with the resource.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity available for this day task.';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity for this day.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor name.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the depth.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field(IsBoor; Rec.IsBoor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is a boor line.';
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }
                field("Worked Hours"; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the actual worked hours for this day task.';
                    Editable = true;
                    Style = Favorable;
                    StyleExpr = Rec.Fulfilled;
                }


            }
        }
        area(FactBoxes)
        {
            part(DayTaskInfo; "Day Task Information FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Day No." = field("Day No."),
                              DayLineNo = field(DayLineNo);
            }
            part(ResourceSkills; "Resource Skills FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                SubPageLink = Type = const(Resource), "No." = field("No.");
            }
            part(ResourceCapacity; "Res. Capacity FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Capacity';
                SubPageLink = "Resource No." = field("No."),
                              Date = field("Task Date");
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
                Image = Split;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DayTaskRec: Record "Day Tasks";
        ResourceNo: Code[20];
        DayNo: Integer;
        DayLineNo: Integer;
    begin
        if Rec.GetFilter("Day No.") <> '' then
            DayNo := Rec.GetRangeMax("Day No.");

        // Get the DayLineNo from the SubPageLink filter (FilterGroup 4)
        if DayNo = 0 then begin
            Rec.FilterGroup(4);
            if Rec.GetFilter("Day No.") <> '' then
                DayNo := Rec.GetRangeMax("Day No.");
            Rec.FilterGroup(0);
        end;

        if DayNo <> 0 then begin
            DayLineNo := 10000;
            DayTaskRec.SetRange("Day No.", DayNo);
            if DayTaskRec.FindLast() then begin
                DayLineNo := DayTaskRec.DayLineNo + 10000;
                Rec.SetRange(DayLineNo); //remove filter
            end;
        end;
        Rec."Day No." := DayNo;
        Rec.DayLineNo := DayLineNo;
    end;

}
