page 50689 "Opti Week Pattern Dialog Sub"
{
    PageType = ListPart;
    SourceTable = "Opti Week Pattern Dialog";
    SourceTableTemporary = true;
    Caption = 'Edit Week Pattern';
    editable = False;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Weekday No."; Rec."Weekday No.")
                {
                    ApplicationArea = All;
                    Caption = 'Weekday';
                    ToolTip = 'Specifies the weekday for this time slot.';
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                    Caption = 'Day';
                    Editable = false;
                    ToolTip = 'Specifies the name of the weekday.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the time slot starts.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the time slot ends.';
                }
                field("Rest Minutes"; Rec."Idle Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rest duration in minutes.';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the calculated working hours.';
                }
            }
        }
    }

    procedure LoadDataSet(
        var TempWeekPatternBuffer: Record "Opti Week Pattern Dialog" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempWeekPatternBuffer.Reset();

        if TempWeekPatternBuffer.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(TempWeekPatternBuffer, true);
                Rec.Insert();
            until TempWeekPatternBuffer.Next() = 0;

        Rec.Reset();

        if Rec.FindFirst() then;
        currPage.Update(false);
    end;


    var
        WeekPatternCode: Code[20];
        NoLinesErr: Label 'Enter at least one time slot before closing the page.';
}