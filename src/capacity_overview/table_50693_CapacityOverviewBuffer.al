table 50693 "Capacity Overview Buffer"
{
    TableType = Temporary;
    Caption = 'Capacity Overview Buffer';
    DataClassification = ToBeClassified;

    /// <summary>
    /// One row per matrix line (Total Capacity, Total Request, Assigned Hours, Capacity,
    /// Request Plan (not assigned), Surplus - see codeunit 50694). Rows are fixed and contiguous,
    /// ordered by "Line No.". "Total Column" is the aggregate ("Total") column that precedes the
    /// per-skill columns. "Column 1".."Column 20" are generic per-skill columns - column N holds
    /// the value for the N-th entry in the ordered Skill Code list built by codeunit 50694. The
    /// column count is capped at 20 skills; captions for whichever columns are in use are assigned
    /// at runtime on the matrix subpage (page 50696) via CaptionClass = '3,' + a per-column
    /// caption variable, since the header text (e.g. "DELIVER2") is only known once the Skill
    /// Code list is read - see that page for details.
    ///
    /// BlankZero = true / Editable = false on the value fields is intentional and row-independent:
    /// per spec, the "Total Capacity" and "Surplus" rows never populate the per-skill columns
    /// (codeunit 50694 leaves them at 0 for both) - Total Capacity's real per-skill split IS
    /// calculated (CalcCapacityPerSkill) but only feeds the "Capacity" (Free Capacity) row's own
    /// calculation, not this row's displayed columns. BlankZero makes those cells render blank
    /// instead of "0" without needing any per-row conditional formatting.
    ///
    /// "Style" carries the row's StyleExpr token (e.g. 'Standard', 'Strong') set by codeunit
    /// 50694's InsertRow/InsertDifferenceRow, and is read by page 50696's value field controls
    /// (StyleExpr = Rec.Style) to bold the "Capacity" (Free Capacity) row - the row label
    /// (Description) itself is deliberately not styled.
    /// </summary>

    fields
    {
        field(1; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Line No.';
        }
        field(2; Description; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Description';
            Editable = false;
        }
        field(3; "Total Column"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Total';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(4; "Style"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Style';
        }
        field(10; "Column 1"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 1';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(11; "Column 2"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 2';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(12; "Column 3"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 3';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(13; "Column 4"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 4';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(14; "Column 5"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 5';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(15; "Column 6"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 6';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(16; "Column 7"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 7';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(17; "Column 8"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 8';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(18; "Column 9"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 9';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(19; "Column 10"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 10';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(20; "Column 11"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 11';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(21; "Column 12"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 12';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(22; "Column 13"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 13';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(23; "Column 14"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 14';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(24; "Column 15"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 15';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(25; "Column 16"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 16';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(26; "Column 17"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 17';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(27; "Column 18"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 18';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(28; "Column 19"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 19';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
        field(29; "Column 20"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Column 20';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
