table 50622 "Skill Req. vs Capacity Buffer"
{
    TableType = Temporary;
    Caption = 'Skill Requested vs Capacity Buffer';
    DataClassification = ToBeClassified;

    fields
    {

        field(1; "Bar Type"; Enum "Day Capacity Chart Bar Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Bar Type';
        }
        field(2; "No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skill Code';

        }
        field(3; "Week Day No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Week Day No.';
        }
        field(4; "Segment"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Segment';
        }
        field(10; "Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Requested Hours';
            DecimalPlaces = 0 : 2;
        }
        // Added 2026-09-22 so page 50661's factbox can show the same Capacity/Assigned breakdown
        // as the "C"/"R" bar pair on the Daily chart (src/dhx/barchart_daily) - see codeunit
        // 50608's BuildSkillBuffer for how these are populated (GetSkillCapacityAssignedFreeSplit/
        // BuildSkillAssignedUnassignedSplit, the same per-skill-resource-set figures the chart's
        // own "C"/"R" bars are built from).
        field(11; "Capacity Assigned"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Capacity Assigned';
            DecimalPlaces = 0 : 2;
        }
        field(12; "Capacity Free"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Capacity Free';
            DecimalPlaces = 0 : 2;
        }
        field(13; "Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Assigned Hours';
            DecimalPlaces = 0 : 2;
        }
    }

    keys
    {
        key(PK; "Bar Type", "No.", "Week Day No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Week Day No.", "Requested Hours")
        {
        }

    }
}
