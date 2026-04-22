page 50645 "Res. Asgmt. Day Tasks"
{
    PageType = ListPart;
    SourceTable = "Day Tasks";
    Caption = 'Daytasks';
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(ActiveFilters)
            {
                Caption = 'Applied Filters';
                Visible = FilterDescription <> '';

                field(FilterDescriptionField; FilterDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Filters';
                    Editable = false;
                    ToolTip = 'Shows the filters currently applied to the day tasks list.';
                    Style = StrongAccent;
                    MultiLine = true;
                }
            }
            repeater(DayTaskLines)
            {
                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of the day task.';
                }
                field("Day Line No."; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day task.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource, item, or G/L account number.';
                }
                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field(Skill; Rec.Skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill associated with the resource.';
                }
                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the assigned hours for this day task.';
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the requested hours for this day task.';
                    Editable = false;
                }
                field("Total Assigned Hours"; Rec."Total Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total assigned hours across all tasks for the same resource on the same date.';
                    Editable = false;
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity of the resource on this date.';
                    Editable = false;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                }
                field("Non Working Minutes"; Rec."Non Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the non-working minutes within the task period.';
                }
                field("Capacity Fully Utilized"; Rec."Capacity Fully Utilized")
                {
                    ApplicationArea = All;
                    Caption = 'Fulfilled';
                    ToolTip = 'Indicates whether the resource capacity is fully utilized for this day task.';
                    Editable = false;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
                }
                field("Pool Resource No."; Rec."Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                }
                field("Pool Resource Name"; Rec."Pool Resource Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource name.';
                    Editable = false;
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
                    Editable = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project number.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project task number.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the day task.';
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day task.';
                }
                field(Leader; Rec.Leader)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day task.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DayTaskRec: Record "Day Tasks";
        NewDate: Date;
        NextLineNo: Integer;
    begin
        Rec.Type := Rec.Type::Resource;

        // Inherit date from current filter if set
        Rec.FilterGroup(2);
        if Rec.GetFilter("Task Date") <> '' then
            NewDate := Rec.GetRangeMin("Task Date")
        else
            NewDate := Today;
        Rec.FilterGroup(0);
        Rec."Task Date" := NewDate;

        // Inherit Job No. from filter if set
        Rec.FilterGroup(2);
        if Rec.GetFilter("Job No.") <> '' then
            Rec."Job No." := Rec.GetRangeMin("Job No.");
        Rec.FilterGroup(0);

        NextLineNo := 10000;
        DayTaskRec.SetRange("Task Date", NewDate);
        if DayTaskRec.FindLast() then
            NextLineNo := DayTaskRec."Day Line No." + 10000;
        Rec."Day Line No." := NextLineNo;
    end;

    var
        FilterDescription: Text;

    procedure SetFilters(JobNo: Code[20]; DateFrom: Date; DateTo: Date; ForceToSpecificDate: Date)
    begin
        Rec.FilterGroup(2);
        if JobNo <> '' then
            Rec.SetRange("Job No.", JobNo)
        else
            Rec.SetRange("Job No.");

        Rec.SetRange("Task Date");
        if ForceToSpecificDate <> 0D then
            Rec.SetRange("Task Date", ForceToSpecificDate)
        else if (DateFrom <> 0D) and (DateTo <> 0D) then
            Rec.SetRange("Task Date", DateFrom, DateTo)
        else if DateFrom <> 0D then
            Rec.SetFilter("Task Date", '%1..', DateFrom)
        else if DateTo <> 0D then
            Rec.SetRange("Task Date", 0D, DateTo);

        Rec.FilterGroup(0);

        BuildFilterDescription(JobNo, DateFrom, DateTo, ForceToSpecificDate);
        CurrPage.Update(false);
    end;

    procedure GoToFirst()
    begin
        if Rec.FindFirst() then
            CurrPage.Update(false);
    end;

    local procedure BuildFilterDescription(JobNo: Code[20]; DateFrom: Date; DateTo: Date; ForceToSpecificDate: Date)
    var
        Parts: Text;
    begin
        Parts := '';
        if JobNo <> '' then
            Parts += 'Project: ' + JobNo;

        if ForceToSpecificDate <> 0D then begin
            if Parts <> '' then Parts += '  |  ';
            Parts += 'Specific Date: ' + Format(ForceToSpecificDate);
        end else begin
            if (DateFrom <> 0D) and (DateTo <> 0D) then begin
                if Parts <> '' then Parts += '  |  ';
                Parts += 'Date: ' + Format(DateFrom) + ' .. ' + Format(DateTo);
            end else if DateFrom <> 0D then begin
                if Parts <> '' then Parts += '  |  ';
                Parts += 'Date: ' + Format(DateFrom) + '..';
            end else if DateTo <> 0D then begin
                if Parts <> '' then Parts += '  |  ';
                Parts += 'Date: ..' + Format(DateTo);
            end;
        end;
        FilterDescription := Parts;
    end;
}
