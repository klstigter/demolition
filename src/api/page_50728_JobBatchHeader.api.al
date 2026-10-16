page 50728 "JobBatch Header Opt"
{
    // Deep-insert header for creating MULTIPLE Jobs in one POST. 
    //The header is never persisted
    // (temporary Name/Value Buffer); each nested line in 'jobRecords' inserts a real Job record.
    PageType = API;
    Caption = 'Job Batch API';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobBatch';
    EntitySetName = 'jobBatches';
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;
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
                field(id; Rec.ID)
                {
                    Caption = 'Id';
                }
                field(batchName; Rec.Name)
                {
                    Caption = 'Batch Name';
                }
                field(postResult; GetPostresult())
                {
                    Caption = 'Description';
                }
            }
            part(jobs; "JobBatch Line Opt")
            {
                EntityName = 'jobRecord';
                EntitySetName = 'jobRecords';
                SubPageLink = "Description 2" = field(Name);
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        // BC binds the first nested line once before the header insert (phantom insert) - lines skip while pending
        GlobalSessionVar.SetHeaderInsertPending(true);
        GlobalSessionVar.ResetPostResults();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        GlobalSessionVar.SetHeaderInsertPending(false);
        exit(true); // insert into the temp table only, so the nested part can resolve its SubPageLink
    end;

    local procedure GetPostresult(): Text
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        exit(GlobalSessionVar.GetPostResultsText('Jobs'));
    end;
}
