/// <summary>
/// Defines the scheduling mode used when generating pre-DayPlanning planning lines
/// from an Order Intake document.
/// </summary>
enum 50608 "Pre DayPlanning Scheduling Mode"
{
    Extensible = true;
    Caption = 'Scheduling Mode';

    /// <summary>Single fixed calendar date.</summary>
    value(0; FixedDate)
    {
        Caption = 'Fixed Date';
    }

    /// <summary>Generate lines for every selected weekday within a date range.</summary>
    value(1; DateRange)
    {
        Caption = 'Date Range';
    }

    /// <summary>Generate lines according to a recurring pattern (Daily/Weekly/Monthly)
    /// with an interval multiplier within a date range.</summary>
    value(2; Recurring)
    {
        Caption = 'Recurring';
    }
}
