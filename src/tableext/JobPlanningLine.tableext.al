tableextension 50600 "DDSIA Job Task" extends "Job Planning Line"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50601; "End Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50602; "End Planning Date"; Date)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                CheckOverlap();
            end;
        }
        field(50603; "Vendor No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            Caption = 'Vendor No.';
        }
        field(50604; "Vendor Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
            Caption = 'Vendor Name';
        }
        field(50605; "Planning Resource id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50520; "Ship-to Address"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Ship-to Address";
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
    //myInt: Integer;

    local procedure CheckOverlap()
    var
        DT: Date;
        DT1: DateTime;
        DT2: DateTime;
    begin
        DT := "Planning Date";
        DT1 := CreateDateTime(DT, "Start Time");
        if "End Planning Date" <> 0D then
            DT := "End Planning Date";
        DT2 := CreateDateTime(DT, "End Time");
        if DT1 > DT2 then
            error('Datetime overlaped!');
    end;
}