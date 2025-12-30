enum 50602 "Gantt Constraint Type"
{
    Extensible = true;

    value(0; None) { }
    value(1; "Must Start On") { }        // MSO
    value(2; "Must Finish On") { }       // MFO
    value(3; "Start No Earlier Than") { }// SNET
    value(4; "Start No Later Than") { }  // SNLT
    value(5; "Finish No Earlier Than") { }
    value(6; "Finish No Later Than") { } // FNLT (RDD)
}
