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
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
            TableRelation = Job;
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(4; "Invoice Job Planning Line No."; Integer)
        {
            Caption = 'Invoice Job Planning Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Skill Code"; Code[20])
        {
            // Optional, for reporting only - the Skill Code that this specific usage entry
            // originated from (via its Day Planning row). Kept per-entry, not per invoice
            // line, because two different Skills can share the same Invoice Resource No.
            Caption = 'Skill Code';
            DataClassification = CustomerContent;
            TableRelation = "Skill Code";
        }
        field(20; "Invoice Job Ledger Entry No."; Integer)
        {
            // Closes the traceability loop: when the Job Planning Line named by "Invoice
            // Job Planning Line No." is transferred to a Sales Invoice and that invoice is
            // posted, standard BC creates a new Job Ledger Entry (Entry Type = Sale). Set
            // by UpdateJobLedgerInvoiceLinkOnAfterPostSalesDoc in codeunit 50603, which
            // subscribes to codeunit "Sales-Post"'s OnAfterPostSalesDoc (fires once
            // everything from that posting run - the Posted Sales Invoice AND the
            // Job-related Sale entry - exists). Resolved via: Posted Sales Invoice Line's
            // "Job Contract Entry No." -> matching Job Planning Line (same field) -> Job
            // Ledger Entry filtered by Entry Type = Sale, Document No., Posting Date. NOT
            // sourced from table 1022 "Job Planning Line Invoice" - that table's own "Job
            // Ledger Entry No." was found unreliable (its owning row can be deleted and
            // re-inserted by native posting logic after the value is written, losing it).
            Caption = 'Invoice Job Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Job Ledger Entry";
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
