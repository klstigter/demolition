table 50600 "Planning Integration Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Planning API Url"; Text[200])
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                ErrLbl: Label 'Please do not specify slash char (/) in the last url string';
            begin
                if ("Planning API Url" <> '') and (StrLen("Planning API Url") >= 9) then begin
                    if CopyStr("Planning API Url", StrLen("Planning API Url"), 1) = '/' then
                        Error(ErrLbl);
                end
            end;
        }
        field(11; "Planning API Key"; Text[200])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Log Incoming Api Request"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Gen. Prod. Posting Group"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Product Posting Group";
            Caption = 'Default Gen. Prod. Posting Group';
        }
        field(40; "Default Unit of Measure Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
        }
        field(50; "Default Vacant Text"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Standard Text";
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
    //myInt: Integer;

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