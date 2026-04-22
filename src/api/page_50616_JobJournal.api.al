page 50616 "JobJournal Opt"
{
    PageType = API;
    Caption = 'Job Journal API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'JobJournal';
    EntitySetName = 'JobJournals';
    SourceTable = "Job Journal Batch";
    SourceTableTemporary = true; // Temp: we only route lines to the real batch; the batch record itself is not created via this API
    ODataKeyFields = "Journal Template Name", Name;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(templateName; Rec."Journal Template Name")
                {
                    Caption = 'Journal Template Name';
                }
                field(batchName; Rec.Name)
                {
                    Caption = 'Name';
                }
            }
            part(jobJournalLines; "Job Journal Line API Opt.")
            {
                EntityName = 'JobJournalLine';
                EntitySetName = 'JobJournalLines';
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field(Name);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(post)
            {
                Caption = 'Post';
                // Invoke via OData bound action after submitting all lines:
                // POST .../JobJournals(templateName='X',batchName='Y')/Microsoft.NAV.post
                // Runs Job Jnl.-Post Batch once for ALL lines in the batch →
                // creates ONE register entry (same as native BC batch-post behaviour).

                trigger OnAction()
                begin
                    PostBatchInline(Rec."Journal Template Name", Rec.Name);
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobJournalBatch: Record "Job Journal Batch";
    begin
        // Validate the referenced batch exists before accepting any journal lines
        if not JobJournalBatch.Get(Rec."Journal Template Name", Rec.Name) then
            Error('Journal Batch ''%1 / %2'' does not exist. Create the batch in Business Central first.', Rec."Journal Template Name", Rec.Name);

        // Copy real batch data into the temp Rec so SubPageLink fields are correct
        Rec.TransferFields(JobJournalBatch, false);
        exit(true); // insert into temp table so the nested part can resolve its SubPageLink
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure PostBatchInline(TemplateName: Code[10]; BatchName: Code[10])
    // CommitBehavior::Ignore suppresses any explicit COMMIT calls inside
    // Job Jnl.-Post Batch so the entire operation commits atomically when
    // the OData HTTP response is finalised.
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
    begin
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        if not JobJnlLine.FindFirst() then
            Error('No journal lines found for template ''%1'' / batch ''%2''.', TemplateName, BatchName);
        JobJnlPostBatch.Run(JobJnlLine);
    end;
}