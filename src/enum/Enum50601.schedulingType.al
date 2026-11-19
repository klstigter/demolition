enum 50601 "Opti schedulingType"
{
    Caption = 'schedulingType';
    Extensible = true;

    value(0; " ")
    {
        Caption = '';
    }
    value(1; FixedDuration)
    {
        Caption = 'Fixed Duration';
    }
    value(2; FixedWork)
    {
        Caption = 'Fixed Work';
    }
}