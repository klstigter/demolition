table 50614 "Job Ledger Invoice Link"
{
    // Day-Planning-to-Invoice (Release 1) traceability table.
    // One row per posted Job Ledger Entry (resource usage) that has been rolled into a
    // billable Job Planning Line by codeunit 50607 "Job Invoice Prep. Mgt.".
    //
    // Key design: the Primary Key on "Job Ledger Entry No." alone is what prevents
    // double-invoicing - a usage entry can only ever be linked to one invoice planning
    // line, ever. Do not weaken this (e.g. do not add a composite key that would allow a
    // second row for the same Job Ledger Entry No.). The "SummaryLookup" key exists purely
    // for reverse lookup from (Job No., Job Task No., Invoice Job Planning Line No.) back
    // to its linked usage entries (e.g. report 50606's DataItemLink) - it carries no
    // uniqueness guarantee of its own.
    DataClassification = CustomerContent;
    Caption = 'Job Ledger Invoice Link';

    fields
    {
        field(1; "Job Ledger Entry No."; Integer)
        {
            Caption = 'Job Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Ledger Entry";
            Editable = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
            TableRelation = Job;
            Editable = false;
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Editable = false;
        }
        field(4; "Invoice Job Planning Line No."; Integer)
        {
            Caption = 'Invoice Job Planning Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Skill Code"; Code[20])
        {
            // Optional, for reporting only - the Skill Code that this specific usage entry
            // originated from (via its Day Planning row). Kept per-entry, not per invoice
            // line, because two different Skills can share the same Invoice Resource No.
            Caption = 'Skill Code';
            DataClassification = CustomerContent;
            TableRelation = "Skill Code";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Job Ledger Entry No.")
        {
            Clustered = true;
        }
        key(SummaryLookup; "Job No.", "Job Task No.", "Invoice Job Planning Line No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", "Invoice Job Planning Line No.")
        {
        }
    }
}
