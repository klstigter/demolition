table 50704 "Demo Data Scenarios Opt"
{
    Caption = 'Demo Data Scenarios';
    DataClassification = CustomerContent;
    LookupPageId = "Demo Data Scenarios";
    DrillDownPageId = "Demo Data Scenarios";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec.Description = '' then
                    Error(DescriptionRequiredErr);
                if Rec."Date" = 0D then
                    Rec."Date" := Today();
            end;
        }
        field(30; "XML Demo Data"; Blob)
        {
            Caption = 'XML Demo Data';
            DataClassification = CustomerContent;
        }
        field(40; Applied; DateTime)
        {
            Caption = 'Applied';
            DataClassification = CustomerContent;
        }
        field(50; "Applied Type"; Option)
        {
            Caption = 'Applied Type';
            DataClassification = CustomerContent;
            OptionMembers = " ","Delete Existing Data and replace with scenario data","Merge into existing data";
            OptionCaption = ' ,Delete Existing Data and replace with scenario data,Merge into existing data';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    var
        DescriptionRequiredErr: Label 'Description must be filled in.';

    trigger OnInsert()
    var
        Scenario: Record "Demo Data Scenarios Opt";
    begin
        Rec.TestField(Description);
        if Rec."Date" = 0D then
            Rec."Date" := Today();
        if Rec."Entry No." = 0 then
            if Scenario.FindLast() then
                Rec."Entry No." := Scenario."Entry No." + 1
            else
                Rec."Entry No." := 1;
    end;

    trigger OnModify()
    begin
        Rec.TestField(Description);
    end;

    procedure HasXml(): Boolean
    begin
        Rec.CalcFields("XML Demo Data");
        exit(Rec."XML Demo Data".HasValue());
    end;

    procedure SetXmlFromStream(var InStr: InStream)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."XML Demo Data");
        Rec."XML Demo Data".CreateOutStream(OutStr, TextEncoding::UTF8);
        CopyStream(OutStr, InStr);
    end;

    procedure GetXmlStream(var InStr: InStream)
    begin
        Rec.CalcFields("XML Demo Data");
        Rec."XML Demo Data".CreateInStream(InStr, TextEncoding::UTF8);
    end;
}
