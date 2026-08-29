page 50695 "Opti Capacity Entry Dialog"
{
    Caption = 'Add Capacity Entry';
    PageType = StandardDialog;
    SourceTable = "Opti Time Slot";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(EntryType; EntryType)
                {
                    ApplicationArea = All;
                    Caption = 'Entry Type';
                }

                field(Description; EntryDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }

                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }

                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }

                field("Rest Minutes"; Rec."Idle Time")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Recalculate();
                    end;
                }

                field("Working Minutes"; Rec."Working Minutes")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.FindFirst() then begin
            Rec.Init();
            Rec."Time Slot No." := 1;
            Rec.Insert();
        end;

        EntryType := EntryType::Normal;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            rec.ValidateInput();
            Rec.Recalculate();
            Rec.Modify();
        end;

        exit(true);
    end;

    procedure GetValues(
        var NewEntryType: Enum "Opti Capacity Entry Type";
        var NewDescription: Text[100];
        var StartTime: Time;
        var EndTime: Time;
        var RestMinutes: Integer)
    begin
        NewEntryType := EntryType;
        NewDescription := EntryDescription;
        StartTime := Rec."Start Time";
        EndTime := Rec."End Time";
        RestMinutes := Rec."Idle Time";
    end;

    local procedure Recalculate()
    begin
        if (Rec."Start Time" = 0T) or (Rec."End Time" = 0T) then
            exit;

        Rec.Recalculate();
        Rec.Modify();
        CurrPage.Update(false);
    end;

    var
        EntryType: Enum "Opti Capacity Entry Type";
        EntryDescription: Text[100];
}
