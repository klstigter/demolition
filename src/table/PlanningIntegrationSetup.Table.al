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