table 50627 "Opti Capacity Entry"
{
    Caption = 'Capacity Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = "Opti Resource Capacity"."Resource No.";
        }

        field(2; "Capacity Date"; Date)
        {
            Caption = 'Capacity Date';
        }

        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }

        field(10; "Entry Type"; Enum "Opti Capacity Entry Type")
        {
            Caption = 'Entry Type';
        }

        field(20; "Day Time Slot Header ID"; Integer)
        {
            Caption = 'Day Time Slot Header ID';
            TableRelation =
                "Opti Day Time Slots Header"."Day Time Slot Header ID";
        }

        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(40; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "Opti Day Time Slots Header"."Total Working Minutes"
                where(
                    "Day Time Slot Header ID" =
                    field("Day Time Slot Header ID")
                )
            );
            Editable = false;
        }

        field(50; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "Opti Day Time Slots Header"."Total Working Hours"
                where(
                    "Day Time Slot Header ID" =
                    field("Day Time Slot Header ID")
                )
            );
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(60; Manual; Boolean)
        {
            Caption = 'Manual';
            Editable = false;
        }
        field(70; "Capacity Minutes"; Integer)
        {
            Caption = 'Capacity Minutes';
            Editable = false;
        }

        field(80; "Capacity Hours"; Decimal)
        {
            Caption = 'Capacity Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(90; "Source Week Pattern ID"; Integer)
        {
            Caption = 'Source Week Pattern ID';
            TableRelation = "Opti Week Pattern Header"."Week Pattern ID";
            Editable = false;
        }
        field(100; "Source Week Pattern Hash"; Text[64])
        {
            Caption = 'Source Week Pattern Hash';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Resource No.", "Capacity Date", "Line No.")
        {
            Clustered = true;
        }

        key(ResourceDate; "Resource No.", "Capacity Date")
        {
        }
    }

    trigger OnInsert()
    var
        CapacityWeek: Record "Opti Resource Capacity Week";
    begin
        TestField("Resource No.");
        TestField("Capacity Date");

        if "Line No." = 0 then
            "Line No." := GetNextLineNo("Resource No.", "Capacity Date");

        UpdateCapacityAmounts();

        CapacityWeek.EnsureCapacityWeek("Resource No.", "Capacity Date");
        CapacityWeek.RecalculateWeekHashForDate("Resource No.", "Capacity Date");
    end;

    trigger OnModify()
    var
        CapacityWeek: Record "Opti Resource Capacity Week";
    begin
        TestField("Resource No.");
        TestField("Capacity Date");

        UpdateCapacityAmounts();
        CapacityWeek.EnsureCapacityWeek("Resource No.", "Capacity Date");

        if ("Resource No." <> xRec."Resource No.") or
           ("Capacity Date" <> xRec."Capacity Date")
        then begin
            // Recalculate the old week before the move is finalized.
            CapacityWeek.RecalculateWeekHashForDateExcluding(
                xRec."Resource No.",
                xRec."Capacity Date",
                xRec.SystemId);

            // Recalculate the new/current week with the updated values.
            CapacityWeek.RecalculateWeekHashForDate("Resource No.", "Capacity Date");

            CapacityWeek.DeleteIfEmpty(xRec."Resource No.", xRec."Capacity Date", xRec.SystemId);
        end else
            CapacityWeek.RecalculateWeekHashForDate("Resource No.", "Capacity Date");
    end;

    trigger OnDelete()
    var
        CapacityWeek: Record "Opti Resource Capacity Week";
    begin
        // Exclude the row being deleted from the old week's hash calculation.
        CapacityWeek.RecalculateWeekHashForDateExcluding(
            "Resource No.",
            "Capacity Date",
            SystemId);

        CapacityWeek.DeleteIfEmpty("Resource No.", "Capacity Date", SystemId);
    end;

    procedure InsertManualEntry(
        ResourceNo: Code[20];
        CapacityDate: Date;
        EntryType: Enum "Opti Capacity Entry Type";
        EntryDescription: Text[100];
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer)
    var
        TimeSlot: Record "Opti Time Slot";
        DayTimeSlotHeaderID: Integer;
        TimeSlotID: Integer;
    begin
        TimeSlotID :=
            TimeSlot.GetOrCreateTimeSlot(
                StartTime,
                EndTime,
                RestMinutes);

        DayTimeSlotHeaderID :=
            GetOrCreateSingleSlotHeader(TimeSlotID);

        Init();
        "Resource No." := ResourceNo;
        "Capacity Date" := CapacityDate;
        "Entry Type" := EntryType;
        "Day Time Slot Header ID" := DayTimeSlotHeaderID;
        Description := EntryDescription;
        Manual := true;
        Insert(true);
    end;

    procedure GetNextLineNo(
        ResourceNo: Code[20];
        CapacityDate: Date): Integer
    var
        CapacityEntry: Record "Opti Capacity Entry";
    begin
        CapacityEntry.Reset();
        CapacityEntry.SetRange("Resource No.", ResourceNo);
        CapacityEntry.SetRange("Capacity Date", CapacityDate);

        if CapacityEntry.FindLast() then
            exit(CapacityEntry."Line No." + 10000);

        exit(10000);
    end;

    local procedure GetOrCreateSingleSlotHeader(
        TimeSlotID: Integer): Integer
    var
        DayTimeSlotHeader: Record "Opti Day Time Slots Header";
        DayTimeSlotLine: Record "Opti Day TimeSlot Line";
    begin
        DayTimeSlotLine.Reset();
        DayTimeSlotLine.SetRange("Time Slot ID", TimeSlotID);

        if DayTimeSlotLine.FindSet() then
            repeat
                if DayTimeSlotHeader.Get(
                    DayTimeSlotLine."Day Time Slot Header ID")
                then
                    if DayTimeSlotHeader."No. of Time Slots" = 1 then
                        exit(
                            DayTimeSlotHeader."Day Time Slot Header ID");
            until DayTimeSlotLine.Next() = 0;

        DayTimeSlotHeader.Init();
        DayTimeSlotHeader.Insert(true);

        DayTimeSlotLine.Init();
        DayTimeSlotLine."Day Time Slot Header ID" :=
            DayTimeSlotHeader."Day Time Slot Header ID";
        DayTimeSlotLine."Time Slot ID" := TimeSlotID;
        DayTimeSlotLine.Insert(true);

        DayTimeSlotHeader.RecalculatePattern();

        exit(DayTimeSlotHeader."Day Time Slot Header ID");
    end;

    procedure UpdateCapacityAmounts()
    begin
        CalcFields("Working Minutes", "Working Hours");

        case "Entry Type" of
            "Entry Type"::Normal,
            "Entry Type"::Additional:
                begin
                    "Capacity Minutes" := "Working Minutes";
                    "Capacity Hours" := "Working Hours";
                end;

            "Entry Type"::Absence:
                begin
                    "Capacity Minutes" := -"Working Minutes";
                    "Capacity Hours" := -"Working Hours";
                end;
        end;
    end;
}
