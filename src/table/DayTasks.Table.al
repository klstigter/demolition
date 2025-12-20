table 50610 "Day Tasks"
{
    DataClassification = ToBeClassified;
    Caption = 'Day Tasks';

    fields
    {
        field(1; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Job;
            Caption = 'Job No.';
        }
        field(2; "Job Task No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Caption = 'Job Task No.';
        }
        field(3; "Job Planning Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."));
            Caption = 'Job Planning Line No.';
        }
        field(4; "Day No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Day No.';
        }
        field(10; "Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planning Date';
        }
        field(11; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Time';
        }
        field(12; "End Time"; Time)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Time';
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
    }

    keys
    {
        key(PK; "Day No.", "Job No.", "Job Task No.", "Job Planning Line No.")
        {
            Clustered = true;
        }
        key(DateKey; "Planning Date", "Start Time")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Planning Date", Description)
        {
        }
    }
}
