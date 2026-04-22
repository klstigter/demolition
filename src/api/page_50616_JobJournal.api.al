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

                trigger OnAction()
                var
                    JobJnlLine: Record "Job Journal Line";
                    JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
                begin
                    // Locate lines for the referenced batch in the real (non-temp) table
                    JobJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    JobJnlLine.SetRange("Journal Batch Name", Rec.Name);
                    if not JobJnlLine.FindFirst() then
                        Error('No journal lines found for template ''%1'' / batch ''%2''.', Rec."Journal Template Name", Rec.Name);

                    // Post all lines in the batch
                    JobJnlPostBatch.Run(JobJnlLine);
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
}