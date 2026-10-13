page 50730 "JobTaskBatch Header Opt"
{
    // Deep-insert header for creating MULTIPLE Job Tasks in one POST.
    // The header is never persisted (temporary Name/Value Buffer);
    // each nested line in 'jobTaskRecords' inserts a real Job Task record.
    PageType = API;
    Caption = 'Job Task Batch API';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'jobTaskBatch';
    EntitySetName = 'jobTaskBatches';
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
            }
            part(jobTasks; "JobTaskBatch Line Opt")
            {
                EntityName = 'jobTaskRecord';
                EntitySetName = 'jobTaskRecords';
                SubPageLink = "Sell-to Contact" = field(Name);
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        // BC binds the first nested line once before the header insert (phantom insert) - lines skip while pending
        GlobalSessionVar.SetHeaderInsertPending(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        GlobalSessionVar.SetHeaderInsertPending(false);
        exit(true); // insert into the temp table only, so the nested part can resolve its SubPageLink
    end;
}
