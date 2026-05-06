table 50604 "Daytask Order Intake Opt."
{
    DataClassification = CustomerContent;
    Caption = 'Daytask Order Intake';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Daytask Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Daytask Date';
        }
        field(11; "Daytask Start"; Time)
        {
            DataClassification = CustomerContent;
            Caption = 'Daytask Start';
        }
        field(12; "Daytask End"; Time)
        {
            DataClassification = CustomerContent;
            Caption = 'Daytask End';
        }
        field(13; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(20; "Resource No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Resource;
            Caption = 'Resource No.';
        }
        field(21; "Resource Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Resource.Name where("No." = field("Resource No.")));
            editable = false;
            Caption = 'Resource Name';
        }
        field(30; Skill; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Skill Code";
            Caption = 'Skill';
        }
        field(40; Status; Enum "Daytask Order Intake Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Status';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Daytask Date")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}