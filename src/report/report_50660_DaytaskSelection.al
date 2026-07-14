report 50660 "DayPlanning Selection"
{
    Caption = 'DayPlanning Selection';
    ProcessingOnly = true;
    UsageCategory = None;
    ApplicationArea = Jobs;

    dataset
    {
        dataitem(DayPlanning; "Day Planning")
        {
            RequestFilterFields = "Task Date", "Job No.", "Job Task No.", "Assigned Resource No.";
            DataItemTableView = where(Posted = const(false));

            trigger OnPreDataItem()
            begin
                DayPlanning.SetRange(Posted, false);
                DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
                DayPlanning.SetFilter("Realized Hours", '<>0');
                if TemplateName = '' then
                    Error(TemplateNameMissingErr);
                if BatchName = '' then
                    Error(BatchNameMissingErr);
            end;

            trigger OnAfterGetRecord()
            var
                DayPlanningJnlLine: Record "DayPlanning Journal Line";
            begin
                // Skip if this Day Planning is already in the journal
                if DayPlanningJnlLine.Get(TemplateName, BatchName, DayPlanning."Task Date", DayPlanning."Day Line No.") then
                    CurrReport.Skip();

                DayPlanningJnlLine.Init();
                DayPlanningJnlLine."Template Name" := TemplateName;
                DayPlanningJnlLine."Batch Name" := BatchName;
                DayPlanningJnlLine."DayPlanning Date" := DayPlanning."Task Date";
                DayPlanningJnlLine."DayPlanning Line No." := DayPlanning."Day Line No.";
                DayPlanningJnlLine."Document No." := GetDocumentNo(DayPlanning."Task Date");
                DayPlanningJnlLine."Job No." := DayPlanning."Job No.";
                DayPlanningJnlLine."Job Task No." := DayPlanning."Job Task No.";
                DayPlanningJnlLine."Resource No." := DayPlanning."Assigned Resource No.";
                DayPlanningJnlLine."Hours" := DayPlanning."Assigned Hours";
                DayPlanningJnlLine.Skill := DayPlanning."Skill";
                FillDimensions(DayPlanningJnlLine, DayPlanning);
                DayPlanningJnlLine.Insert(true);
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
        TemplateNameMissingErr: Label 'Template Name must be specified before running DayPlanning Selection.';
        BatchNameMissingErr: Label 'Batch Name must be specified before running DayPlanning Selection.';
        LinesInsertedMsg: Label '%1 DayPlanning line(s) inserted into the journal.', Comment = '%1 = number of lines inserted';

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

    local procedure FillDimensions(var DayPlanningJnlLine: Record "DayPlanning Journal Line"; DayPlanning: Record "Day Planning")
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        Dim1Code: Code[20];
        Dim2Code: Code[20];
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, DayPlanning."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Job Task", DayPlanning."Job Task No.");
        if DayPlanning."Assigned Resource No." <> '' then
            DimMgt.AddDimSource(DefaultDimSource, Database::Resource, DayPlanning."Assigned Resource No.");
        DayPlanningJnlLine."Dimension Set ID" :=
            DimMgt.GetDefaultDimID(DefaultDimSource, '', Dim1Code, Dim2Code, 0, 0);
        DayPlanningJnlLine."Global Dimension 1 Code" := Dim1Code;
        DayPlanningJnlLine."Global Dimension 2 Code" := Dim2Code;
    end;
}
