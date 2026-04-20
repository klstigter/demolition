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
    SourceTableTemporary = true; // set temp due to record is persistent in Job Journal batch
    DelayedInsert = true;

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
            part(jobJournalLines; "Job Journal Line Listpart Opt.")
            {
                EntityName = 'JobJournalLine';
                EntitySetName = 'JobJournalLines';
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field(Name);

            }
        }
    }
}