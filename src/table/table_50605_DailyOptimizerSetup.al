table 50605 "Daily Optimizer Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Work hour Template"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Hour Template';
            TableRelation = "Work-Hour Template";
        }
        field(15; "Base Calendar"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Base Calendar';
            TableRelation = "Base Calendar";
        }
        field(20; "Order Intake Nos"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Order Intake Nos';
            TableRelation = "No. Series";
        }
        field(21; "Work Order Nos"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Order Nos';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
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