/// <summary>
/// Defines the recurrence pattern used when Scheduling Mode = Recurring
/// in the pre-Daytask generation dialog.
/// </summary>
enum 50609 "Pre Daytask Recurrence"
{
    Extensible = true;
    Caption = 'Recurrence Type';

    /// <summary>Generate an occurrence every N calendar days.</summary>
    value(0; Daily)
    {
        Caption = 'Daily';
    }

    /// <summary>Generate occurrences on selected weekdays of every N-th week.</summary>
    value(1; Weekly)
    {
        Caption = 'Weekly';
    }

    /// <summary>Generate occurrences on selected weekdays of every N-th month.</summary>
    value(2; Monthly)
    {
        Caption = 'Monthly';
    }
}
