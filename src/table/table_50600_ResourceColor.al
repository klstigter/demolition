table 50600 "Planning Color Opt."
{
    DataClassification = ToBeClassified;
    Caption = 'Planning Color';
    LookupPageId = "Planning Color opt";
    DrillDownPageId = "Planning Color opt";

    fields
    {
        field(1; "No."; Code[20]) // Resource No. or Task No. depending on Type
        {
            DataClassification = ToBeClassified;
        }
        field(2; Type; enum "Planning Color Opt.")
        {
            DataClassification = ToBeClassified;
        }
        field(3; "No. 2"; Code[20]) // Job No. if Type=Task, empty if Type=Resource
        {
            DataClassification = ToBeClassified;
        }
        field(4; "No. 3"; Code[20]) // Vacant for now, can be used for future filtering (e.g., by Resource Group or Task Group)
        {
            DataClassification = ToBeClassified;
        }

        field(10; "Day Task"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Capacity"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Task"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; Type, "No.", "No. 2", "No. 3")
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