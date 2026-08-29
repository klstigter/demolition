page 50664 "Opti Time Slot"
{
    PageType = StandardDialog;
    SourceTable = "Opti Time Slot";
    SourceTableTemporary = true;
    Caption = 'Edit Time Slot';

    layout
    {
        area(Content)
        {
            group(TimeSlot)
            {
                Caption = 'Time Slot';

                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the time slot starts.';

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the time slot ends.';

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }
                field("Rest Minutes"; Rec."Idle Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rest duration in minutes.';

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculated working hours.';
                }
                field("Time Slot Hash"; Rec."Time Slot Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculated time-slot hash.';
                    Visible = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."Time Slot No." := 1;
        Rec."Start Time" := 080000T;
        Rec."End Time" := 170000T;
        Rec."Idle Time" := 60;
        Rec.Recalculate();
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        rec.ValidateInput();

        TimeSlotID :=
            TimeSlot.GetOrCreateTimeSlotID(
                Rec."Start Time",
                Rec."End Time",
                Rec."Idle Time");

        exit(true);
    end;



    procedure GetTimeSlotID(): Integer
    begin
        exit(TimeSlotID);
    end;

    local procedure Recalculate()
    begin
        if (Rec."Start Time" = 0T) or
           (Rec."End Time" = 0T)
        then
            exit;

        Rec.Recalculate();
        CurrPage.Update(false);
    end;

    var
        TimeSlotID: Integer;

}