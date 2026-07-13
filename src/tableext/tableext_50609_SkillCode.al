tableextension 50609 "Opt. Skill Code" extends "Skill Code"
{
    // Day-Planning-to-Invoice (Release 1): the Resource that billable Job Planning Lines
    // should be created against when summarizing posted usage for this Skill.
    // Invoice preparation (codeunit 50607) hard-stops if this is blank for a Skill
    // that is actually in use on posted, unlinked Job Ledger Entries.
    fields
    {
        field(50609; "Invoice Resource No."; Code[20])
        {
            Caption = 'Invoice Resource No.';
            DataClassification = CustomerContent;
            TableRelation = Resource."No.";
            ToolTip = 'Specifies the resource that billable planning lines for this skill are created against when preparing invoice lines from posted Day Planning usage.';
        }
    }
}
