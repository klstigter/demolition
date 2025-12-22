table 50610 "Day Tasks"
{
    DataClassification = ToBeClassified;
    Caption = 'Day Tasks';

    fields
    {
        field(1; "Day No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Day No.';
        }
        field(2; DayLineNo; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Day Line No.';
        }
        field(3; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Job;
            Caption = 'Job No.';
        }
        field(4; "Job Task No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Caption = 'Job Task No.';
        }
        field(5; "Job Planning Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."));
            Caption = 'Job Planning Line No.';
        }

        field(10; "Start Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planning Date';
        }
        field(11; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Time';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(12; "End Time"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time';

            trigger OnValidate()
            begin
                CalculateWorkingHours();
            end;
        }
        field(20; Type; Enum "Job Planning Line Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Type';
        }
        field(21; "No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource
            else if (Type = const(Item)) Item
            else if (Type = const("G/L Account")) "G/L Account";
        }
        field(22; Description; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }
        field(30; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(31; "Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit of Measure Code';
        }
        field(40; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            Caption = 'Vendor No.';
        }
        field(41; "Vendor Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
            Caption = 'Vendor Name';
        }
        field(50; "Work Type Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Work Type";
            Caption = 'Work Type Code';
        }
        field(60; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Depth';
        }
        field(61; IsBoor; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Boor';
        }
        field(70; "Worked Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Worked Hours';
            DecimalPlaces = 0 : 2;
        }
        field(80; "Working Hours"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(81; "Non Working Hours"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Non Working Hours';
            DecimalPlaces = 0 : 2;
        }

        field(90; "Do Not Change"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Do Not Change automatically by process';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Day No.", DayLineNo, "Job No.", "Job Task No.", "Job Planning Line No.")
        {
            Clustered = true;
        }
        key(DateKey; "Start Planning Date", "Start Time")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Start Planning Date", Description)
        {
        }
    }

    procedure CalculateWorkingHours()
    var
        TotalMinutes: Integer;
        WorkingMinutes: Integer;
        NonWorkingMinutes: Integer;
    begin
        // If either time is not set, clear both hours fields
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            "Working Hours" := 0;
            "Non Working Hours" := 0;
            exit;
        end;

        // Validate that End Time is after Start Time
        if "End Time" <= "Start Time" then begin
            "Working Hours" := 0;
            "Non Working Hours" := 24;
            exit;
        end;

        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;

        // Calculate working minutes
        WorkingMinutes := ("End Time" - "Start Time") div 60000;

        // Calculate non-working minutes
        NonWorkingMinutes := TotalMinutes - WorkingMinutes;

        // Convert to hours (decimal)
        "Working Hours" := WorkingMinutes / 60;
        "Non Working Hours" := NonWorkingMinutes / 60;
    end;
}
