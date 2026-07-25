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
    begin
        TestField("Resource No.");
        TestField("Capacity Date");

        if "Line No." = 0 then
            "Line No." := GetNextLineNo("Resource No.", "Capacity Date");
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
}
