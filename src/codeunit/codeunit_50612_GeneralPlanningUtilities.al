codeunit 50612 "General Planning Utilities"
{
    /// <summary>
    /// Converts a Date to Integer in YYYYMMDD format
    /// </summary>
    /// <param name="InputDate">The date to convert</param>
    /// <returns>Integer in YYYYMMDD format (e.g., 20251222 for December 22, 2025)</returns>
    procedure DateToInteger(InputDate: Date): Integer
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputDate = 0D then
            exit(0);

        Year := Date2DMY(InputDate, 3);
        Month := Date2DMY(InputDate, 2);
        Day := Date2DMY(InputDate, 1);

        exit((Year * 10000) + (Month * 100) + Day);
    end;

    /// <summary>
    /// Converts an Integer in YYYYMMDD format back to Date
    /// </summary>
    /// <param name="InputInteger">Integer in YYYYMMDD format</param>
    /// <returns>Date value</returns>
    procedure IntegerToDate(InputInteger: Integer): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputInteger = 0 then
            exit(0D);

        Year := InputInteger div 10000;
        Month := (InputInteger mod 10000) div 100;
        Day := InputInteger mod 100;

        exit(DMY2Date(Day, Month, Year));
    end;


    procedure MapConstraintTypeToDhtmlx(ConstraintType: Enum "Gantt Constraint Type"): text
    begin
        case ConstraintType of
            ConstraintType::"none":
                exit('asap');

            ConstraintType::"Must Start On":
                exit('mso');

            ConstraintType::"Must Finish On":
                exit('mfo');

            ConstraintType::"Start No Earlier Than":
                exit('snet');

            ConstraintType::"Start No Later Than":
                exit('snlt');

            ConstraintType::"Finish No Earlier Than":
                exit('fnet');

            ConstraintType::"Finish No Later Than":
                exit('fnlt');

            else
                exit('');
        end;
    end;
    /*
        procedure MapConstraintTypeToDhtmlx(ConstraintType: Enum "Gantt Constraint Type"): Text
        begin
            case ConstraintType of
                ConstraintType::"Must Start On":
                    exit('must_start_on');

                ConstraintType::"Must Finish On":
                    exit('must_finish_on');

                ConstraintType::"Start No Earlier Than":
                    exit('start_no_earlier_than');

                ConstraintType::"Start No Later Than":
                    exit('start_no_later_than');

                ConstraintType::"Finish No Earlier Than":
                    exit('finish_no_earlier_than');

                ConstraintType::"Finish No Later Than":
                    exit('finish_no_later_than');

                else
                    exit('');
            end;
        end;
        */

    procedure DayTaskFulFillment(pDayTask: Record "Day Tasks";
                                 var RequestedHours: Decimal;
                                 var Capacity: Decimal): Boolean
    var
        Resource: Record Resource;
        DayTask: Record "Day Tasks";
        ResourceNo: Code[20];
        WorkingMinutes: Decimal;
        CapacityIsUsed: boolean;
    begin
        if pDayTask.Type <> pDayTask.Type::Resource then
            exit;
        ResourceNo := pDayTask."No.";
        if pDayTask."No." = '' then
            exit;
        WorkingMinutes := GetWorkingMinutes(pDayTask);
        // Find Day Task with complete start and end time and same resource and day no
        DayTask.SetRange("Task Date", pDayTask."task Date");
        DayTask.SetRange("No.", ResourceNo);
        DayTask.SetFilter("Day Line No.", '<>%1', pDayTask."Day Line No.");
        DayTask.SetFilter("Start Time", '<>%1', 0T);
        DayTask.SetFilter("End Time", '<>%1', 0T);
        if DayTask.FindFirst() then
            repeat
                WorkingMinutes += GetWorkingMinutes(DayTask);
            until DayTask.Next() = 0;

        RequestedHours += WorkingMinutes / 60;
        // Find Capacity Entry per Daytask Date and Resource No.
        pDayTask.CalcFields(Capacity);
        Capacity := pDayTask.Capacity;

        CapacityIsUsed := RequestedHours >= Capacity;
        exit(CapacityIsUsed);
    end;

    local procedure GetWorkingMinutes(DayTask: Record "Day Tasks"): Decimal
    var
        WorkingMinutes: Decimal;
    begin
        WorkingMinutes := (DayTask."End Time" - DayTask."Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - DayTask."Non Working Minutes";
        exit(WorkingMinutes);
    end;

}


