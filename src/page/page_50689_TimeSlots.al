page 50661 "Time Slots"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Time Slot";
    Caption = 'Time Slots';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Integer"; Rec."Integer")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sequence number.';
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day of the week.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number within Integer and Day No.';
                    Editable = false;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time.';
                }
                field("Non Working Minutes"; Rec."Non Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the break time in minutes.';
                }
                field(Hours; Rec.Hours)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the net hours (Start-End minus Non Working Minutes).';
                    Editable = false;
                }
            }
        }
    }


    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (xRec."Integer" <> 0) then
            Rec."Integer" := xRec."Integer"
        else
            Rec."Integer" := 1;

        Rec."Day No." := xRec."Day No.";
    end;
}
