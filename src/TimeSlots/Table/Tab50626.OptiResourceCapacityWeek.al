table 50626 "Opti Resource Capacity Week"
{
    Caption = 'Resource Capacity Week';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";
        }

        field(2; "Week Start Date"; Date)
        {
            Caption = 'Week Start Date';
        }

        field(3; "Week End Date"; Date)
        {
            Caption = 'Week End Date';
            Editable = false;
        }
        field(4; "Week No."; Integer)
        {
            Caption = 'Week No.';
            Editable = false;
        }

        field(5; "Week Year"; Integer)
        {
            Caption = 'Week Year';
            Editable = false;
        }

        field(10; "Monday Date"; Date)
        {
            Caption = 'Monday Date';
            Editable = false;
        }

        field(11; "Tuesday Date"; Date)
        {
            Caption = 'Tuesday Date';
            Editable = false;
        }

        field(12; "Wednesday Date"; Date)
        {
            Caption = 'Wednesday Date';
            Editable = false;
        }

        field(13; "Thursday Date"; Date)
        {
            Caption = 'Thursday Date';
            Editable = false;
        }

        field(14; "Friday Date"; Date)
        {
            Caption = 'Friday Date';
            Editable = false;
        }

        field(15; "Saturday Date"; Date)
        {
            Caption = 'Saturday Date';
            Editable = false;
        }

        field(16; "Sunday Date"; Date)
        {
            Caption = 'Sunday Date';
            Editable = false;
        }

        field(20; "Monday Capacity"; Decimal)
        {
            Caption = 'Monday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Monday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(21; "Tuesday Capacity"; Decimal)
        {
            Caption = 'Tuesday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Tuesday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(22; "Wednesday Capacity"; Decimal)
        {
            Caption = 'Wednesday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Wednesday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(23; "Thursday Capacity"; Decimal)
        {
            Caption = 'Thursday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Thursday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(24; "Friday Capacity"; Decimal)
        {
            Caption = 'Friday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Friday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(25; "Saturday Capacity"; Decimal)
        {
            Caption = 'Saturday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Saturday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(26; "Sunday Capacity"; Decimal)
        {
            Caption = 'Sunday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Sunday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }


    }

    keys
    {
        key(PK; "Resource No.", "Week Start Date")
        {
            Clustered = true;
        }

    }

    trigger OnInsert()
    begin
        SetWeekDates();
    end;

    trigger OnModify()
    begin
        SetWeekDates();
    end;

    procedure SetWeekDates()
    begin
        TestField("Week Start Date");

        "Monday Date" := "Week Start Date";
        "Tuesday Date" := CalcDate('<1D>', "Week Start Date");
        "Wednesday Date" := CalcDate('<2D>', "Week Start Date");
        "Thursday Date" := CalcDate('<3D>', "Week Start Date");
        "Friday Date" := CalcDate('<4D>', "Week Start Date");
        "Saturday Date" := CalcDate('<5D>', "Week Start Date");
        "Sunday Date" := CalcDate('<6D>', "Week Start Date");
        "Week End Date" := "Sunday Date";

        "Week No." := Date2DWY("Week Start Date", 2);
        "Week Year" := Date2DWY("Week Start Date", 3);
    end;
}
