page 50694 "Opti Capacity Dates"
{
    Caption = 'Capacity Dates';
    PageType = List;
    SourceTable = "Opti Resource Capacity";
    ApplicationArea = All;
    UsageCategory = Lists;


    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }

                field("Capacity Date"; Rec."Capacity Date")
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }

            part(CapacityEntries; "Opti Capacity Entries")
            {
                ApplicationArea = All;
                SubPageLink =
                    "Resource No." = field("Resource No."),
                    "Capacity Date" = field("Capacity Date");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddCapacityEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Capacity Entry';
                Image = NewLine;
                ToolTip =
                    'Add additional capacity or an absence for the selected resource and date.';

                trigger OnAction()
                begin
                    AddManualCapacityEntry();
                end;
            }
            action(CreateResourceCapacity)
            {
                ApplicationArea = All;
                Caption = 'Create Resource Capacity';
                Image = CalculateCalendar;
                ToolTip = 'Create capacity dates and normal capacity entries for the selected resources and date range.';

                trigger OnAction()
                begin
                    Report.RunModal(
                        Report::"Opti Create Resource Capacity",
                        true,
                        false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(AddCapacityEntryPromoted; AddCapacityEntry)
            {
            }
        }
    }

    local procedure AddManualCapacityEntry()
    var
        CapacityEntry: Record "Opti Capacity Entry";
        CapacityEntryDialog: Page "Opti Capacity Entry Dialog";
        EntryType: Enum "Opti Capacity Entry Type";
        EntryDescription: Text[100];
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer;
    begin
        Rec.TestField("Resource No.");
        Rec.TestField("Capacity Date");

        if CapacityEntryDialog.RunModal() <> Action::OK then
            exit;

        CapacityEntryDialog.GetValues(
            EntryType,
            EntryDescription,
            StartTime,
            EndTime,
            RestMinutes);

        CapacityEntry.InsertManualEntry(
            Rec."Resource No.",
            Rec."Capacity Date",
            EntryType,
            EntryDescription,
            StartTime,
            EndTime,
            RestMinutes);

        CurrPage.Update(false);
    end;
}
