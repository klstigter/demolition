table 50608 "Order Intake Line Opt."
{
    DataClassification = CustomerContent;
    Caption = 'Order Intake Line';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
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
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
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