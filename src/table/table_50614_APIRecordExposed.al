// API Integeration for Exposing API Pages
table 50614 "API Record Exposed Opti"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "API Page No."; Integer)
        {
            DataClassification = ToBeClassified;
            tableRelation = "Page Metadata" where(PageType = const(API));
            blankzero = true;
            NotBlank = true;

            trigger OnValidate()
            var
                PageMetadata: Record "Page Metadata";
            begin
                Rec."Table ID" := 0;
                if Rec."API Page No." <> 0 then begin
                    if not PageMetadata.Get("API Page No.") then
                        Error('The API page %1 does not exist.', Rec."API Page No.");
                    Rec."Table ID" := PageMetadata.SourceTable;
                end;
            end;
        }
        field(2; "Table ID"; Integer)
        {
            DataClassification = ToBeClassified;
            editable = false;
        }
        field(10; "API Page Name"; Text[100])
        {
            fieldClass = FlowField;
            CalcFormula = Lookup("Page Metadata".Name WHERE(ID = FIELD("API Page No.")));
            Editable = false;
        }
        field(20; "Table Name"; Text[100])
        {
            fieldClass = FlowField;
            CalcFormula = Lookup("Table Metadata".Name WHERE(ID = FIELD("Table ID")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "API Page No.")
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