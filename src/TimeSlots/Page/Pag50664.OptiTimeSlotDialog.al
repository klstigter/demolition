page 50664 "Opti Time Slot Dialog"
{
    PageType = StandardDialog;
    SourceTable = "Opti Time Slot Buffer";
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
                field("Rest Minutes"; Rec."Rest Minutes")
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
        Rec."Entry No." := 1;
        Rec."Start Time" := 080000T;
        Rec."End Time" := 170000T;
        Rec."Rest Minutes" := 60;
        Rec.Recalculate();
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        if CloseAction <> Action::OK then
            exit(true);

        Rec.ValidateInput();

        TimeSlotID :=
            TimeSlot.GetOrCreateTimeSlot(
                Rec."Start Time",
                Rec."End Time",
                Rec."Rest Minutes");

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