enum 50627 "Opti Planner Status"
{
    Caption = 'Planner Status';
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(10; Submitted) { Caption = 'Submitted'; }
    value(20; Pending) { Caption = 'Pending'; }
    value(30; Rejected) { Caption = 'Rejected'; }
}
