page 50633 "Job Planning Line Day Tasks"
{
    Caption = 'Day Tasks';
    PageType = ListPart;
    SourceTable = "Day Tasks";
    Editable = true;
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Visible = false;
                }
                field("Start Planning Date"; Rec."Task Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the planning date for this day.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the start time for this day.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the end time for this day.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description.';
                }

                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of planning line.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the resource, item, or G/L account.';
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code.';
                }
                field(Skill; Rec.Skill)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the skill level required.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the quantity for this day.';
                }
                field("Worked Hours"; Rec."Worked Hours")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the actual worked hours for this day task.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the unit of measure code.';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the vendor number.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the vendor name.';
                    Visible = false;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the depth.';
                }
                field("Do Not Change"; Rec."Manual Modified")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Indicates whether the record was manually modified, and not is changed automatically by a process.';
                    Editable = True;
                    trigger OnValidate()
                    begin
                        SetDoNotChangedOff := true;
                    end;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(RefreshDayTasks)
            {
                ApplicationArea = Jobs;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the day tasks list.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if SetDoNotChangedOff then begin
            SetDoNotChangedOff := false;
            rec."Manual Modified" := false
        end else
            rec."Manual Modified" := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if SetDoNotChangedOff then begin
            SetDoNotChangedOff := false;
            rec."Manual Modified" := false
        end else
            rec."Manual Modified" := true;
        exit(true);
    end;

    var
        SetDoNotChangedOff: Boolean;

    procedure SetFilterOnDayTasks(StartDate: Date; EndDate: Date)
    begin
        if (StartDate <> 0D) and (EndDate <> 0D) then
            Rec.SetRange("Task Date", StartDate, EndDate);
    end;
}
