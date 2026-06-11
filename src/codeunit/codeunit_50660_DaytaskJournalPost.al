codeunit 50660 "DayPlanning Journal Post"
{
    // Transfers DayPlanning Journal Lines into Job Journal Lines and posts them
    // using the standard BC Job Journal posting engine.
    // The EventSubs codeunit (50603) automatically marks Day Plannings as Posted
    // after Job Ledger Entries are created with matching Opt.DayPlanningDate / Opt.DayPlanningLineNo.

    Permissions =
        tabledata "DayPlanning Journal Line" = RD,
        tabledata "Job Journal Line" = RID;

    procedure Post(TemplateName: Code[10]; BatchName: Code[10])
    var
        DayPlanningJnlLine: Record "DayPlanning Journal Line";
        JobJnlLine: Record "Job Journal Line";
    begin
        CheckLinesExist(TemplateName, BatchName);

        DayPlanningJnlLine.SetRange("Template Name", TemplateName);
        DayPlanningJnlLine.SetRange("Batch Name", BatchName);
        DayPlanningJnlLine.FindSet();

        CreateJobJournalLines(DayPlanningJnlLine, JobJnlLine);

        // Post the Job Journal Batch using the standard posting codeunit
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        JobJnlLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post Batch", JobJnlLine);

        // Clean up DayPlanning Journal Lines on success
        DayPlanningJnlLine.SetRange("Template Name", TemplateName);
        DayPlanningJnlLine.SetRange("Batch Name", BatchName);
        DayPlanningJnlLine.DeleteAll(true);
    end;

    procedure PreviewPost(TemplateName: Code[10]; BatchName: Code[10])
    var
        DayPlanningJnlLine: Record "DayPlanning Journal Line";
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

        // Step 2: Insert fresh Job Journal Lines from DayPlanning Journal Lines.
        DayPlanningJnlLine.SetRange("Template Name", TemplateName);
        DayPlanningJnlLine.SetRange("Batch Name", BatchName);
        DayPlanningJnlLine.FindSet();
        CreateJobJournalLines(DayPlanningJnlLine, JobJnlLine);

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

    local procedure CreateJobJournalLines(var DayPlanningJnlLine: Record "DayPlanning Journal Line"; var JobJnlLine: Record "Job Journal Line")
    var
        NextLineNo: Integer;
    begin
        NextLineNo := GetNextLineNo(DayPlanningJnlLine."Template Name", DayPlanningJnlLine."Batch Name");
        repeat
            JobJnlLine.Init();
            JobJnlLine."Journal Template Name" := DayPlanningJnlLine."Template Name";
            JobJnlLine."Journal Batch Name" := DayPlanningJnlLine."Batch Name";
            JobJnlLine."Line No." := NextLineNo;
            JobJnlLine."Line Type" := JobJnlLine."Line Type"::Billable;
            JobJnlLine.Validate("Posting Date", DayPlanningJnlLine."DayPlanning Date");
            JobJnlLine."Document Date" := DayPlanningJnlLine."DayPlanning Date";
            JobJnlLine."Document No." := DayPlanningJnlLine."Document No.";
            JobJnlLine.Validate("Job No.", DayPlanningJnlLine."Job No.");
            JobJnlLine.Validate("Job Task No.", DayPlanningJnlLine."Job Task No.");
            JobJnlLine.Validate(Type, JobJnlLine.Type::Resource);
            JobJnlLine.Validate("No.", DayPlanningJnlLine."Resource No.");
            JobJnlLine.Validate(Quantity, DayPlanningJnlLine."Hours");
            JobJnlLine."Shortcut Dimension 1 Code" := DayPlanningJnlLine."Global Dimension 1 Code";
            JobJnlLine."Shortcut Dimension 2 Code" := DayPlanningJnlLine."Global Dimension 2 Code";
            JobJnlLine."Dimension Set ID" := DayPlanningJnlLine."Dimension Set ID";
            // DayPlanning traceability — picked up by EventSubs (codeunit 50603) on posting
            JobJnlLine."Opt. DayPlanning Date" := DayPlanningJnlLine."DayPlanning Date";
            JobJnlLine."Opt. DayPlanning Line No." := DayPlanningJnlLine."DayPlanning Line No.";
            JobJnlLine.Insert(true);
            NextLineNo += 10000;
        until DayPlanningJnlLine.Next() = 0;
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
        DayPlanningJnlLine: Record "DayPlanning Journal Line";
        NoLinesToPostErr: Label 'There are no DayPlanning journal lines to post for template %1, batch %2.', Comment = '%1 = template name, %2 = batch name';
    begin
        DayPlanningJnlLine.SetRange("Template Name", TemplateName);
        DayPlanningJnlLine.SetRange("Batch Name", BatchName);
        if DayPlanningJnlLine.IsEmpty() then
            Error(NoLinesToPostErr, TemplateName, BatchName);
    end;
}
