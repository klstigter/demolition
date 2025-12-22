tableextension 50620 "Work-Hour Template Ext" extends "Work-Hour Template"
{
    fields
    {
        field(50600; "Default Start Time"; Time)
        {
            Caption = 'Default Start Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Default Start Time" <> 0T) and ("Default End Time" <> 0T) then
                    if "Default Start Time" >= "Default End Time" then
                        Error('Default Start Time must be earlier than Default End Time.');
            end;
        }

        field(50601; "Default End Time"; Time)
        {
            Caption = 'Default End Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Default Start Time" <> 0T) and ("Default End Time" <> 0T) then
                    if "Default End Time" <= "Default Start Time" then
                        Error('Default End Time must be later than Default Start Time.');

                CalculateNonWorkingHours();
            end;
        }

        field(50602; "Non Working Minutes"; Integer)
        {
            Caption = 'Non Working Hours';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                CalculateNonWorkingHours();
            end;
        }

        field(50603; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            Editable = false;

        }
    }

    local procedure CalculateNonWorkingHours()
    var
        TotalMinutes: Integer;
        WorkingMinutes: Integer;
    begin
        // If either time is not set, clear both hours fields
        if ("Default Start Time" = 0T) or ("Default End Time" = 0T) then begin
            "Working Hours" := 0;
            "Non Working Minutes" := 0;
            exit;
        end;

        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;

        // Calculate working minutes
        WorkingMinutes := ("Default End Time" - "Default Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - "Non Working Minutes";

        // Convert to hours (decimal)
        "Working Hours" := WorkingMinutes / 60;

    end;
}
