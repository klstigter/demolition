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
}
