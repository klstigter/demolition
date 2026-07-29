/// <summary>
/// In-memory (temporary) buffer used by page 50681 "Task Scheduler Filter" to
/// collect a Job No. / Job Task No. pair from the user before it is applied as
/// the active filter on page 50621 "DHX Scheduler (Project)". One record per
/// dialog session — mirrors the shape of table 50609 "Pre DayPlanning Request Buf."
/// </summary>
table 50622 "Task Scheduler Filter Buffer"
{
    TableType = Temporary;
    Caption = 'Task Scheduler Filter Buffer';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>Surrogate PK. Always 1 — one buffer record per dialog session.</summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(10; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
            TableRelation = Job;
        }
        field(20; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
