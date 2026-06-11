table 50660 "DayPlanning Journal Line"
{
    Caption = 'DayPlanning Journal Line';
    DataClassification = CustomerContent;
    LookupPageId = "DayPlanning Journal";
    DrillDownPageId = "DayPlanning Journal";

    fields
    {
        field(1; "Template Name"; Code[10])
        {
            Caption = 'Template Name';
            TableRelation = "Job Journal Template";
            DataClassification = CustomerContent;
        }
        field(2; "Batch Name"; Code[10])
        {
            Caption = 'Batch Name';
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Template Name"));
            DataClassification = CustomerContent;
        }
        field(3; "DayPlanning Date"; Date)
        {
            Caption = 'DayPlanning Date';
            DataClassification = CustomerContent;
        }
        field(4; "DayPlanning Line No."; Integer)
        {
            Caption = 'DayPlanning Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(10; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
            DataClassification = CustomerContent;
        }
        field(11; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            DataClassification = CustomerContent;
        }
        field(20; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
            DataClassification = CustomerContent;
        }
        field(21; "Hours"; Decimal)
        {
            Caption = 'Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(30; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(31; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(32; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID(
                    "Dimension Set ID",
                    "Global Dimension 1 Code",
                    "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(PK; "Template Name", "Batch Name", "DayPlanning Date", "DayPlanning Line No.")
        {
            Clustered = true;
        }
        key(JobDateKey; "Job No.", "Job Task No.", "DayPlanning Date")
        {
        }
    }

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
            DimMgt.EditDimensionSet(
                "Dimension Set ID",
                StrSubstNo('%1 %2 %3', "Template Name", "Batch Name", "DayPlanning Date"));
        if OldDimSetID <> "Dimension Set ID" then begin
            DimMgt.UpdateGlobalDimFromDimSetID(
                "Dimension Set ID",
                "Global Dimension 1 Code",
                "Global Dimension 2 Code");
        end;
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;
}
