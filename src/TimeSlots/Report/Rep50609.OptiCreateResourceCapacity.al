report 50608 "Opti Create Resource Capacity"
{
    Caption = 'Create Resource Capacity';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.", "Resource Group No.";

            trigger OnAfterGetRecord()
            var
                CapacityDate: Date;
            begin
                CapacityDate := StartDate;

                while CapacityDate <= EndDate do begin
                    CreateCapacityForDate(Resource, CapacityDate);
                    CapacityDate := CalcDate('<1D>', CapacityDate);
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(StartDateField; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                    }

                    field(EndDateField; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                    }

                    field(WeekPatternIDField; WeekPatternID)
                    {
                        ApplicationArea = All;
                        Caption = 'Week Pattern ID';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        ValidateRequest();
        LoadWeekPatternLines();
    end;

    trigger OnPostReport()
    begin
        Message(
            CapacityCreatedMsg,
            CreatedCapacityDates,
            CreatedCapacityEntries);
    end;

    local procedure ValidateRequest()
    begin
        if StartDate = 0D then
            Error(StartDateRequiredErr);

        if EndDate = 0D then
            Error(EndDateRequiredErr);

        if EndDate < StartDate then
            Error(EndDateBeforeStartDateErr);

        if WeekPatternID = 0 then
            Error(WeekPatternRequiredErr);
    end;

    local procedure LoadWeekPatternLines()
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
    begin
        TempWeekPatternLine.Reset();
        TempWeekPatternLine.DeleteAll();

        WeekPatternLine.Reset();
        WeekPatternLine.SetRange("Week Pattern ID", WeekPatternID);

        if WeekPatternLine.FindSet() then
            repeat
                TempWeekPatternLine := WeekPatternLine;
                TempWeekPatternLine.Insert();
            until WeekPatternLine.Next() = 0;

        if TempWeekPatternLine.IsEmpty() then
            Error(WeekPatternNotFoundErr, WeekPatternID);
    end;

    local procedure CreateCapacityForDate(
        ResourceRecord: Record Resource;
        CapacityDate: Date)
    var
        ResourceCapacity: Record "Opti Resource Capacity";
        CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotHeader: Record "Opti Day Time Slots Header";
        WeekdayNo: Integer;
    begin
        WeekdayNo := Date2DWY(CapacityDate, 1);

        if not GetWeekPatternLine(WeekdayNo) then
            exit;

        if TempWeekPatternLine."Day Pattern ID" = 0 then
            exit;

        DayTimeSlotHeader.Get(
            TempWeekPatternLine."Day Pattern ID");

        if not ResourceCapacity.Get(
            ResourceRecord."No.",
            CapacityDate)
        then begin
            ResourceCapacity.Init();
            ResourceCapacity."Resource No." :=
                ResourceRecord."No.";
            ResourceCapacity."Capacity Date" :=
                CapacityDate;
            ResourceCapacity.Description :=
                ResourceRecord.Name;
            ResourceCapacity.Insert(true);

            CreatedCapacityDates += 1;
        end;

        DeleteNormalCapacityEntry(
            ResourceRecord."No.",
            CapacityDate);

        CapacityEntry.Init();
        CapacityEntry."Resource No." :=
            ResourceRecord."No.";
        CapacityEntry."Capacity Date" :=
            CapacityDate;
        CapacityEntry."Entry Type" :=
            CapacityEntry."Entry Type"::Normal;
        CapacityEntry."Day Time Slot Header ID" :=
            TempWeekPatternLine."Day Pattern ID";
        CapacityEntry.Description :=
            DayTimeSlotHeader.Description;
        CapacityEntry.Manual := false;
        CapacityEntry.Insert(true);

        CreatedCapacityEntries += 1;
    end;

    local procedure GetWeekPatternLine(WeekdayNo: Integer): Boolean
    begin
        TempWeekPatternLine.Reset();
        TempWeekPatternLine.SetRange("Weekday No.", WeekdayNo);

        exit(TempWeekPatternLine.FindFirst());
    end;

    local procedure DeleteNormalCapacityEntry(
        ResourceNo: Code[20];
        CapacityDate: Date)
    var
        CapacityEntry: Record "Opti Capacity Entry";
    begin
        CapacityEntry.Reset();
        CapacityEntry.SetRange("Resource No.", ResourceNo);
        CapacityEntry.SetRange("Capacity Date", CapacityDate);
        CapacityEntry.SetRange(
            "Entry Type",
            CapacityEntry."Entry Type"::Normal);
        CapacityEntry.DeleteAll(true);
    end;

    var
        TempWeekPatternLine: Record "Opti Week Pattern Line" temporary;
        StartDate: Date;
        EndDate: Date;
        WeekPatternID: Integer;
        CreatedCapacityDates: Integer;
        CreatedCapacityEntries: Integer;

        StartDateRequiredErr: Label 'Start Date must have a value.';
        EndDateRequiredErr: Label 'End Date must have a value.';
        EndDateBeforeStartDateErr: Label 'End Date cannot be before Start Date.';
        WeekPatternRequiredErr: Label 'Week Pattern ID must have a value.';
        WeekPatternNotFoundErr: Label 'Week Pattern %1 does not contain any weekday lines.';
        CapacityCreatedMsg: Label '%1 capacity-date records and %2 normal capacity entries were created.';
}
