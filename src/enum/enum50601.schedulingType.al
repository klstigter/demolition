enum 50601 schedulingType
{
    Extensible = true;

    value(0; FixedDuration)
    {
        Caption = 'Fixed Duration';
    }
    value(1; FixedUnits)
    {
        Caption = 'Fixed Units';
    }
    value(2; FixedWork)
    {
        Caption = 'Fixed Work';
    }
}