codeunit 60032 "Job Jnl Post Skill Fields Test"
{
    // Posting a Job Journal Line must carry Skill, "Invoice Resource No." and
    // "Approved Project Manager" into the Job Ledger Entry and (Resource lines) the Res. Ledger Entry.
    // Event subscriber under test: codeunit 50603 CopyDayPlanningFieldsOnBeforeJobLedgEntryInsert.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TemplateName: Code[10];
        BatchName: Code[10];
        SelectBatchName: Code[10];
        TestJobNo: Code[20];
        TestSkill: Code[10];
        TestSkillInvoiceRes: Code[20];
        TestResourceNo: Code[20];
        TestInvoiceResNo: Code[20];
        TestPM: Code[50];

    local procedure Initialize()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        InvResource: Record Resource;
        ResUoM: Record "Resource Unit of Measure";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPostingGroup: Record "Job Posting Group";
        SkillCode: Record "Skill Code";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        TemplateName := 'JSKTST';
        BatchName := 'JSKTST';
        SelectBatchName := 'JSKSEL';
        TestJobNo := 'JSKTST-JOB';
        TestSkill := 'JSKTSTSK';
        TestPM := 'PM.TEST.USER';

        if IsInitialized then
            exit;

        Resource.SetRange(Blocked, false);
        Resource.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Resource.SetFilter("Base Unit of Measure", '<>%1', '');
        Resource.FindSet();
        repeat
            if ResUoM.Get(Resource."No.", Resource."Base Unit of Measure") then
                TestResourceNo := Resource."No.";
        until (Resource.Next() = 0) or (TestResourceNo <> '');
        if TestResourceNo = '' then
            Error('No resource with a Resource Unit of Measure for its base unit exists in this company.');

        // A different resource to act as the Skill's invoice resource (any code is valid; it is a plain Code[20])
        InvResource.SetFilter("No.", '<>%1', TestResourceNo);
        InvResource.FindFirst();
        TestSkillInvoiceRes := InvResource."No.";
        TestInvoiceResNo := InvResource."No.";

        if not SkillCode.Get(TestSkill) then begin
            SkillCode.Init();
            SkillCode.Code := TestSkill;
            SkillCode.Description := 'Job Jnl Post Test Skill';
            SkillCode.Insert();
        end;
        SkillCode."Invoice Resource No." := TestSkillInvoiceRes;
        SkillCode.Modify();

        if not Job.Get(TestJobNo) then begin
            Customer.SetRange(Blocked, Customer.Blocked::" ");
            Customer.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
            Customer.FindFirst();
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Job Jnl Post Skill Fields Test';
            Job.Insert();
            Job.Validate("Bill-to Customer No.", Customer."No.");
            if JobPostingGroup.FindFirst() then
                Job."Job Posting Group" := JobPostingGroup.Code;
            Job.Status := Job.Status::Open;
            Job.Modify();
        end;

        if not JobTask.Get(TestJobNo, 'T1') then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := 'T1';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;

        SourceCodeSetup.Get();
        if not JobJnlTemplate.Get(TemplateName) then begin
            JobJnlTemplate.Init();
            JobJnlTemplate.Name := TemplateName;
            JobJnlTemplate.Description := 'Skill fields test';
            JobJnlTemplate."Source Code" := SourceCodeSetup."Job Journal";
            JobJnlTemplate.Insert();
        end;
        if not JobJnlBatch.Get(TemplateName, BatchName) then begin
            JobJnlBatch.Init();
            JobJnlBatch."Journal Template Name" := TemplateName;
            JobJnlBatch.Name := BatchName;
            JobJnlBatch.Insert();
        end;

        IsInitialized := true;
        Commit();
    end;

    local procedure ClearJournals(DocNo: Code[20]; DPBatch: Code[10])
    var
        JobJnlLine: Record "Job Journal Line";
        DPJnlLine: Record "DayPlanning Journal Line";
    begin
        // Scoped: only this test's own leftover lines (never other tests' persisted results)
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        JobJnlLine.SetRange("Document No.", DocNo);
        JobJnlLine.DeleteAll();
        DPJnlLine.SetRange("Template Name", TemplateName);
        DPJnlLine.SetRange("Batch Name", DPBatch);
        DPJnlLine.DeleteAll();
    end;

    local procedure AssertAreEqual(Expected: Variant; Actual: Variant; ErrMsg: Text)
    begin
        if Format(Expected) <> Format(Actual) then
            Error('%1 Expected: %2, Actual: %3', ErrMsg, Format(Expected), Format(Actual));
    end;

    local procedure AssertLedgerEntries(DocNo: Code[20]; ExpSkill: Code[10]; ExpInvRes: Code[20]; ExpPM: Code[50])
    var
        JobLedgEntry: Record "Job Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
    begin
        JobLedgEntry.SetRange("Job No.", TestJobNo);
        JobLedgEntry.SetRange("Document No.", DocNo);
        JobLedgEntry.FindLast();
        AssertAreEqual(ExpSkill, JobLedgEntry.Skill, 'Job Ledger Entry Skill.');
        AssertAreEqual(ExpInvRes, JobLedgEntry."Invoice Resource No.", 'Job Ledger Entry Invoice Resource No.');
        AssertAreEqual(ExpPM, JobLedgEntry."Approved Project Manager", 'Job Ledger Entry Approved Project Manager.');

        if JobLedgEntry."Ledger Entry No." = 0 then
            Error('Job Ledger Entry has no Ledger Entry No. (Res. Ledger Entry link).');
        ResLedgEntry.Get(JobLedgEntry."Ledger Entry No.");
        AssertAreEqual(ExpSkill, ResLedgEntry.Skill, 'Res. Ledger Entry Skill.');
        AssertAreEqual(ExpInvRes, ResLedgEntry."Invoice Resource No.", 'Res. Ledger Entry Invoice Resource No.');
        AssertAreEqual(ExpPM, ResLedgEntry."Approved Project Manager", 'Res. Ledger Entry Approved Project Manager.');
    end;

    [Test]
    procedure GivenJobJnlLineWithThreeFields_WhenPosted_ThenCarriedToJobAndResLedgerEntries()
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        DocNo: Code[20];
    begin
        Initialize();
        DocNo := 'JSK-DIRECT';
        ClearJournals(DocNo, 'JSKDIR');

        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := TemplateName;
        JobJnlLine."Journal Batch Name" := BatchName;
        JobJnlLine."Line No." := 10000;
        JobJnlLine."Line Type" := JobJnlLine."Line Type"::Billable;
        JobJnlLine.Validate("Posting Date", WorkDate());
        JobJnlLine."Document No." := DocNo;
        JobJnlLine.Validate("Job No.", TestJobNo);
        JobJnlLine.Validate("Job Task No.", 'T1');
        JobJnlLine.Validate(Type, JobJnlLine.Type::Resource);
        JobJnlLine.Validate("No.", TestResourceNo);
        JobJnlLine.Validate(Quantity, 2);
        JobJnlLine.Skill := TestSkill;
        JobJnlLine."Invoice Resource No." := 'DIRECTINV';
        JobJnlLine."Approved Project Manager" := TestPM;
        JobJnlLine."Source Code" := GetSourceCode();
        JobJnlLine.Insert();

        JobJnlPostLine.RunWithCheck(JobJnlLine);

        AssertLedgerEntries(DocNo, TestSkill, 'DIRECTINV', TestPM);
    end;

    [Test]
    procedure GivenDayPlanningJnlLine_WhenPostedViaDayPlanningJournalPost_ThenSkillsInvoiceResourceAndPMReachLedgers()
    var
        DPJnlLine: Record "DayPlanning Journal Line";
        DPJnlPost: Codeunit "DayPlanning Journal Post";
        DimMgt: Codeunit DimensionManagement;
        DimSources: List of [Dictionary of [Integer, Code[20]]];
        Dim1: Code[20];
        Dim2: Code[20];
        DocNo: Code[20];
    begin
        Initialize();
        DocNo := 'JSK-DPJNL';
        ClearJournals(DocNo, BatchName);

        DPJnlLine.Init();
        DPJnlLine."Template Name" := TemplateName;
        DPJnlLine."Batch Name" := BatchName;
        DPJnlLine."DayPlanning Date" := WorkDate();
        DPJnlLine."DayPlanning Line No." := 990001;
        DPJnlLine."Document No." := DocNo;
        DPJnlLine."Job No." := TestJobNo;
        DPJnlLine."Job Task No." := 'T1';
        DPJnlLine."Resource No." := TestResourceNo;
        DPJnlLine.Hours := 3;
        DPJnlLine.Skill := TestSkill;
        DPJnlLine."Invoice Resource No." := 'WILLBEOVERWRITTEN';
        DPJnlLine."Approved Project Manager" := TestPM;
        // Same default-dimension derivation as report 50660 FillDimensions (environment may require dimensions)
        DimMgt.AddDimSource(DimSources, Database::Job, TestJobNo);
        DimMgt.AddDimSource(DimSources, Database::"Job Task", 'T1');
        DimMgt.AddDimSource(DimSources, Database::Resource, TestResourceNo);
        DPJnlLine."Dimension Set ID" := DimMgt.GetDefaultDimID(DimSources, '', Dim1, Dim2, 0, 0);
        DPJnlLine."Global Dimension 1 Code" := Dim1;
        DPJnlLine."Global Dimension 2 Code" := Dim2;
        DPJnlLine.Insert();

        DPJnlPost.Post(TemplateName, BatchName);

        // Invoice Resource No. must be the Skill Code's, not the one on the DayPlanning journal line
        AssertLedgerEntries(DocNo, TestSkill, TestSkillInvoiceRes, TestPM);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure GivenDayPlanningWithApprovedPM_WhenSelectionReportRuns_ThenPMCopiedToDayPlanningJnlLine()
    var
        DayPlanning: Record "Day Planning";
        DPJnlLine: Record "DayPlanning Journal Line";
        DPSelection: Report "DayPlanning Selection";
        LineNo: Integer;
    begin
        Initialize();
        ClearJournals('JSK-SELECT', SelectBatchName);

        // Only this test's own previous-run Day Planning record
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", 'T1');
        DayPlanning.SetRange("Day Line No.", 990002);
        DayPlanning.DeleteAll();
        DayPlanning.Reset();

        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := 'T1';
        DayPlanning."Day Line No." := 990002;
        DayPlanning."Plan Date" := WorkDate();
        DayPlanning.Skill := TestSkill;
        DayPlanning."Assigned Resource No." := TestResourceNo;
        DayPlanning."Assigned Hours" := 4;
        DayPlanning."Realized Hours" := 4;
        DayPlanning."Approved Project Manager" := TestPM;
        DayPlanning.Insert();
        LineNo := DayPlanning."Day Line No.";

        DayPlanning.SetRange("Job No.", TestJobNo);
        DPSelection.SetTableView(DayPlanning);
        DPSelection.SetJournalBatch(TemplateName, SelectBatchName);
        DPSelection.UseRequestPage(false);
        DPSelection.RunModal();

        DPJnlLine.Get(TemplateName, SelectBatchName, WorkDate(), LineNo);
        AssertAreEqual(TestSkill, DPJnlLine.Skill, 'DayPlanning Journal Line Skill.');
        AssertAreEqual(TestSkillInvoiceRes, DPJnlLine."Invoice Resource No.", 'DayPlanning Journal Line Invoice Resource No. (from Skill Code).');
        AssertAreEqual(TestPM, DPJnlLine."Approved Project Manager", 'DayPlanning Journal Line Approved Project Manager (from Day Planning).');

        // Persist Day Planning + DayPlanning Journal Line for inspection
        Commit();
    end;

    [MessageHandler]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;

    local procedure GetSourceCode(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup."Job Journal");
    end;
}
