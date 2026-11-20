enum 50617 "Job Task Constraint Type"
{
    Extensible = true;

    value(0; ASAP)
    {
        Caption = 'As Soon As Possible';
    }
    value(1; ALAP)
    {
        Caption = 'As Late As Possible';
    }
    value(2; SNET)
    {
        Caption = 'Start No Earlier Than';
    }
    value(3; SNLT)
    {
        Caption = 'Start No Later Than';
    }
    value(4; FNET)
    {
        Caption = 'Finish No Earlier Than';
    }
    value(5; FNLT)
    {
        Caption = 'Finish No Later Than';
    }
    value(6; MSO)
    {
        Caption = 'Must Start On';
    }
    value(7; MFO)
    {
        Caption = 'Must Finish On';
    }
}
