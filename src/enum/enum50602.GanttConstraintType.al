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

/*
var constraintTypeEditor =
 { type: "select", map_to: 
    "constraint_type", options: [ 
        { key: "asap", label: gantt.locale.labels.asap }, 
        { key: "alap", label: gantt.locale.labels.alap }, 
        { key: "snet", label: gantt.locale.labels.snet }, 
        { key: "snlt", label: gantt.locale.labels.snlt }, 
        { key: "fnet", label: gantt.locale.labels.fnet }, 
        { key: "fnlt", label: gantt.locale.labels.fnlt }, 
        { key: "mso", label: gantt.locale.labels.mso }, 
        { key: "mfo", label: gantt.locale.labels.mfo } 
        ] }; 
    var constraintDateEditor = { type: "date", map_to: "constraint_date", min: new Date(2023, 0, 1), max: new Date(2025, 0, 1) };
*/
