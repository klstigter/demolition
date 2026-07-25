page 50683 "Opti Week Pattern Dialog"
{
    PageType = StandardDialog;
    SourceTable = "Opti Week Pattern Buffer";
    SourceTableTemporary = true;
    Caption = 'Edit Week Pattern';

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
                field("Rest Minutes"; Rec."Rest Minutes")
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Entry No." := GetNextEntryNo();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::OK then
            exit(true);

        CurrPage.SaveRecord();

        ValidateLines();

        exit(true);
    end;

    procedure SetCapacityPatternID(NewCapacityPatternID: Integer)
    begin
        CapacityPatternID := NewCapacityPatternID;
    end;

    procedure GetCapacityPatternID(): Integer
    begin
        exit(CapacityPatternID);
    end;

    procedure LoadBuffer(
        var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary)
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
    end;

    procedure GetBuffer(
        var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary)
    begin
        TempWeekPatternBuffer.Reset();
        TempWeekPatternBuffer.DeleteAll();

        Rec.Reset();

        if Rec.FindSet() then
            repeat
                TempWeekPatternBuffer.Init();
                TempWeekPatternBuffer.TransferFields(Rec, true);
                TempWeekPatternBuffer.Insert();
            until Rec.Next() = 0;
    end;

    local procedure ValidateLines()
    var
        TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary;
    begin
        TempWeekPatternBuffer.Copy(Rec, true);
        TempWeekPatternBuffer.Reset();

        if TempWeekPatternBuffer.IsEmpty() then
            Error(NoLinesErr);

        if TempWeekPatternBuffer.FindSet() then
            repeat
                TempWeekPatternBuffer.ValidateInput();
            until TempWeekPatternBuffer.Next() = 0;
    end;

    local procedure GetNextEntryNo(): Integer
    var
        TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary;
    begin
        TempWeekPatternBuffer.Copy(Rec, true);
        TempWeekPatternBuffer.Reset();

        if TempWeekPatternBuffer.FindLast() then
            exit(TempWeekPatternBuffer."Entry No." + 10000);

        exit(10000);
    end;

    var
        CapacityPatternID: Integer;
        NoLinesErr: Label 'Enter at least one time slot before closing the page.';
}