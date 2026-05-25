report 50660 "Daytask Selection"
{
    Caption = 'Daytask Selection';
    ProcessingOnly = true;
    UsageCategory = None;
    ApplicationArea = Jobs;

    dataset
    {
        dataitem(DayTask; "Day Tasks")
        {
            RequestFilterFields = "Task Date", "Job No.", "Job Task No.", "Assigned Resource No.";
            DataItemTableView = where(Posted = const(false));

            trigger OnPreDataItem()
            begin
                DayTask.SetFilter("Assigned Resource No.", '<>%1', '');
                DayTask.SetFilter("Assigned Hours", '<>0');
                if TemplateName = '' then
                    Error(TemplateNameMissingErr);
                if BatchName = '' then
                    Error(BatchNameMissingErr);
            end;

            trigger OnAfterGetRecord()
            var
                DaytaskJnlLine: Record "Daytask Journal Line";
            begin
                // Skip if this Day Task is already in the journal
                if DaytaskJnlLine.Get(TemplateName, BatchName, DayTask."Task Date", DayTask."Day Line No.") then
                    CurrReport.Skip();

                DaytaskJnlLine.Init();
                DaytaskJnlLine."Template Name" := TemplateName;
                DaytaskJnlLine."Batch Name" := BatchName;
                DaytaskJnlLine."Daytask Date" := DayTask."Task Date";
                DaytaskJnlLine."Daytask Line No." := DayTask."Day Line No.";
                DaytaskJnlLine."Document No." := GetDocumentNo(DayTask."Task Date");
                DaytaskJnlLine."Job No." := DayTask."Job No.";
                DaytaskJnlLine."Job Task No." := DayTask."Job Task No.";
                DaytaskJnlLine."Resource No." := DayTask."Assigned Resource No.";
                DaytaskJnlLine."Hours" := DayTask."Assigned Hours";
                FillDimensions(DaytaskJnlLine, DayTask);
                DaytaskJnlLine.Insert(true);
                LinesInserted += 1;
            end;

            trigger OnPostDataItem()
            begin
                Message(LinesInsertedMsg, LinesInserted);
            end;
        }
    }

    var
        TemplateName: Code[10];
        BatchName: Code[10];
        DocNo: Code[20];
        LinesInserted: Integer;
        TemplateNameMissingErr: Label 'Template Name must be specified before running Daytask Selection.';
        BatchNameMissingErr: Label 'Batch Name must be specified before running Daytask Selection.';
        LinesInsertedMsg: Label '%1 Daytask line(s) inserted into the journal.', Comment = '%1 = number of lines inserted';

    procedure SetJournalBatch(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    begin
        TemplateName := JnlTemplateName;
        BatchName := JnlBatchName;
    end;

    local procedure GetDocumentNo(PostingDate: Date): Code[20]
    var
        JobJnlBatch: Record "Job Journal Batch";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        if DocNo <> '' then
            exit(DocNo);

        if not JobJnlBatch.Get(TemplateName, BatchName) then
            exit('');

        if JobJnlBatch."No. Series" <> '' then
            DocNo := NoSeriesMgt.GetNextNo(JobJnlBatch."No. Series", PostingDate, true)
        else
            DocNo := '';

        exit(DocNo);
    end;

    local procedure FillDimensions(var DaytaskJnlLine: Record "Daytask Journal Line"; DayTask: Record "Day Tasks")
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        Dim1Code: Code[20];
        Dim2Code: Code[20];
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, DayTask."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Job Task", DayTask."Job Task No.");
        if DayTask."Assigned Resource No." <> '' then
            DimMgt.AddDimSource(DefaultDimSource, Database::Resource, DayTask."Assigned Resource No.");
        DaytaskJnlLine."Dimension Set ID" :=
            DimMgt.GetDefaultDimID(DefaultDimSource, '', Dim1Code, Dim2Code, 0, 0);
        DaytaskJnlLine."Global Dimension 1 Code" := Dim1Code;
        DaytaskJnlLine."Global Dimension 2 Code" := Dim2Code;
    end;
}
