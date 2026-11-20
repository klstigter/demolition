// =============================================
// 60003 Table "Date Span Node" (used as TEMP table)
// =============================================
table 60003 "Date Span Node"
{
    Caption = 'Date Span Node';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Node ID"; Code[20]) { Caption = 'Node ID'; }
        field(2; "Parent ID"; Code[20]) { Caption = 'Parent ID'; }
        field(3; Level; Enum "Date Span Level") { Caption = 'Level'; }
        field(4; "Start Date"; Date) { Caption = 'Start Date'; }
        field(5; "End Date"; Date) { Caption = 'End Date'; }
        field(6; Lock; Enum "Date Span Lock") { Caption = 'Lock'; }
        field(7; Caption; Text[100]) { Caption = 'Caption'; }
    }

    keys
    {
        key(PK; "Node ID") { Clustered = true; }
        key(Parent; "Parent ID") { }
        key(LevelKey; Level) { }
    }
}