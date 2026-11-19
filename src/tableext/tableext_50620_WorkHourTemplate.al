tableextension 50620 "Opti Work-Hour Template" extends "Work-Hour Template"
{
    fields
    {
        field(50600; "Opti Default Start Time"; Time)
        {
            Caption = 'Default Start Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
                var
                    DefaultStartTimeMustBeErr: Label 'Default Start Time must be earlier than Default End Time.';
            begin
                if ("Opti Default Start Time" <> 0T) and ("Opti Default End Time" <> 0T) then
                    if "Opti Default Start Time" >= "Opti Default End Time" then
                        Error(DefaultStartTimeMustBeErr);
            end;
        }

        field(50601; "Opti Default End Time"; Time)
        {
            Caption = 'Default End Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
                var
                    DefaultEndTimeMustBeErr: Label 'Default End Time must be later than Default Start Time.';
            begin
                if ("Opti Default Start Time" <> 0T) and ("Opti Default End Time" <> 0T) then
                    if "Opti Default End Time" <= "Opti Default Start Time" then
                        Error(DefaultEndTimeMustBeErr);

                CalculateNonWorkingHours();
            end;
        }

        field(50602; "Opti Non Working Minutes"; Integer)
        {
            Caption = 'Non Working Minutes';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                CalculateNonWorkingHours();
            end;
        }

        field(50603; "Opti Working Hours"; Decimal)
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
        if ("Opti Default Start Time" = 0T) or ("Opti Default End Time" = 0T) then begin
            "Opti Working Hours" := 0;
            "Opti Non Working Minutes" := 0;
            exit;
        end;

        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;

        // Calculate working minutes
        WorkingMinutes := ("Opti Default End Time" - "Opti Default Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - "Opti Non Working Minutes";

        // Convert to hours (decimal)
        "Opti Working Hours" := WorkingMinutes / 60;

    end;
}
