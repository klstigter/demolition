codeunit 50660 "Daytask Journal Post"
{
    // Transfers Daytask Journal Lines into Job Journal Lines and posts them
    // using the standard BC Job Journal posting engine.
    // The EventSubs codeunit (50603) automatically marks Day Tasks as Posted
    // after Job Ledger Entries are created with matching Opt.DaytaskDate / Opt.DaytaskLineNo.

    Permissions =
        tabledata "Daytask Journal Line" = RD,
        tabledata "Job Journal Line" = RID;

    procedure Post(TemplateName: Code[10]; BatchName: Code[10])
    var
        DaytaskJnlLine: Record "Daytask Journal Line";
        JobJnlLine: Record "Job Journal Line";
    begin
        CheckLinesExist(TemplateName, BatchName);

        DaytaskJnlLine.SetRange("Template Name", TemplateName);
        DaytaskJnlLine.SetRange("Batch Name", BatchName);
        DaytaskJnlLine.FindSet();

        CreateJobJournalLines(DaytaskJnlLine, JobJnlLine);

        // Post the Job Journal Batch using the standard posting codeunit
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        JobJnlLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJnlLine);

        // Clean up Daytask Journal Lines on success
        DaytaskJnlLine.SetRange("Template Name", TemplateName);
        DaytaskJnlLine.SetRange("Batch Name", BatchName);
        DaytaskJnlLine.DeleteAll(true);
    end;

    procedure PreviewPost(TemplateName: Code[10]; BatchName: Code[10])
    var
        DaytaskJnlLine: Record "Daytask Journal Line";
        JobJnlLine: Record "Job Journal Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        JobJnlPost: Codeunit "Job Jnl.-Post";
    begin
        CheckLinesExist(TemplateName, BatchName);

        // Step 1: Delete any stale Job Journal Lines for this template/batch
        // so we start clean (avoids duplicate line numbers and stale data).
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        JobJnlLine.DeleteAll(true);

        // Step 2: Insert fresh Job Journal Lines from Daytask Journal Lines.
        DaytaskJnlLine.SetRange("Template Name", TemplateName);
        DaytaskJnlLine.SetRange("Batch Name", BatchName);
        DaytaskJnlLine.FindSet();
        CreateJobJournalLines(DaytaskJnlLine, JobJnlLine);

        // Step 3: Commit to close the write transaction before Preview.
        // GenJnlPostPreview.Preview opens a page (Form.RunModal) which is
        // not allowed inside an open write transaction.
        Commit();

        // Step 4: Preview using the bound Job Jnl.-Post instance subscriber.
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        JobJnlLine.FindFirst();
        JobJnlPost.SetHideDialog(true);
        JobJnlPost.SetSuppressCommit(true);
        BindSubscription(JobJnlPost);
        GenJnlPostPreview.Preview(JobJnlPost, JobJnlLine);
    end;

    local procedure CreateJobJournalLines(var DaytaskJnlLine: Record "Daytask Journal Line"; var JobJnlLine: Record "Job Journal Line")
    var
        NextLineNo: Integer;
    begin
        NextLineNo := GetNextLineNo(DaytaskJnlLine."Template Name", DaytaskJnlLine."Batch Name");
        repeat
            JobJnlLine.Init();
            JobJnlLine."Journal Template Name" := DaytaskJnlLine."Template Name";
            JobJnlLine."Journal Batch Name" := DaytaskJnlLine."Batch Name";
            JobJnlLine."Line No." := NextLineNo;
            JobJnlLine."Line Type" := JobJnlLine."Line Type"::Billable;
            JobJnlLine.Validate("Posting Date", DaytaskJnlLine."Daytask Date");
            JobJnlLine."Document Date" := DaytaskJnlLine."Daytask Date";
            JobJnlLine."Document No." := DaytaskJnlLine."Document No.";
            JobJnlLine.Validate("Job No.", DaytaskJnlLine."Job No.");
            JobJnlLine.Validate("Job Task No.", DaytaskJnlLine."Job Task No.");
            JobJnlLine.Validate(Type, JobJnlLine.Type::Resource);
            JobJnlLine.Validate("No.", DaytaskJnlLine."Resource No.");
            JobJnlLine.Validate(Quantity, DaytaskJnlLine."Hours");
            JobJnlLine."Shortcut Dimension 1 Code" := DaytaskJnlLine."Global Dimension 1 Code";
            JobJnlLine."Shortcut Dimension 2 Code" := DaytaskJnlLine."Global Dimension 2 Code";
            JobJnlLine."Dimension Set ID" := DaytaskJnlLine."Dimension Set ID";
            // Daytask traceability — picked up by EventSubs (codeunit 50603) on posting
            JobJnlLine."Opt. Daytask Date" := DaytaskJnlLine."Daytask Date";
            JobJnlLine."Opt. Daytask Line No." := DaytaskJnlLine."Daytask Line No.";
            JobJnlLine.Insert(true);
            NextLineNo += 10000;
        until DaytaskJnlLine.Next() = 0;
    end;

    local procedure GetNextLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        if JobJnlLine.FindLast() then
            exit(JobJnlLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure CheckLinesExist(TemplateName: Code[10]; BatchName: Code[10])
    var
        DaytaskJnlLine: Record "Daytask Journal Line";
        NoLinesToPostErr: Label 'There are no Daytask journal lines to post for template %1, batch %2.', Comment = '%1 = template name, %2 = batch name';
    begin
        DaytaskJnlLine.SetRange("Template Name", TemplateName);
        DaytaskJnlLine.SetRange("Batch Name", BatchName);
        if DaytaskJnlLine.IsEmpty() then
            Error(NoLinesToPostErr, TemplateName, BatchName);
    end;
}
