page 50623 "Job Journal Line API Opt."
{
    // Dedicated PageType = API subpage for Job Journal Lines.
    // Must be PageType = API (not ListPart) so BC does not auto-initialize
    // a blank UI row when processing the nested collection — that blank row
    // was the root cause of the double-insert of the first record.
    // Reference: native BC APIV2 - JournalLines (page 30049).
    PageType = API;
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'JobJournalLine';
    EntitySetName = 'JobJournalLines';
    SourceTable = "Job Journal Line";
    // DelayedInsert = true is mandatory for PageType = API (AL0505).
    // Single-call posting pattern:
    //   Set "triggerPost": true on the LAST line in the JSON array.
    //   OnInsertRecord inserts every line, then — only when triggerPost = true —
    //   calls Job Jnl.-Post Batch ONCE for the whole batch, producing ONE register
    //   (identical to native BC batch-post behaviour).
    //   All other lines are simply inserted without posting.
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(lineType; Rec."Line Type")
                {
                    Caption = 'Line Type';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(externalDocumentNo; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                }
                field(jobNo; Rec."Job No.")
                {
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Job Task No.';
                }
                field(DayPlanningSystemId; DayPlanningSystemId)
                {
                    Caption = 'DayPlanning System Id';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    Caption = 'Unit Cost';
                }
                field(unitCostLCY; Rec."Unit Cost (LCY)")
                {
                    Caption = 'Unit Cost (LCY)';
                }
                field(totalCost; Rec."Total Cost")
                {
                    Caption = 'Total Cost';
                }
                field(totalCostLCY; Rec."Total Cost (LCY)")
                {
                    Caption = 'Total Cost (LCY)';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(lineAmount; Rec."Line Amount")
                {
                    Caption = 'Line Amount';
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    Caption = 'Line Discount Amount';
                }
                field(lineDiscountPercentage; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    Caption = 'Gen. Bus. Posting Group';
                }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    Caption = 'Gen. Prod. Posting Group';
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    Caption = 'Work Type Code';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(triggerPost; TriggerPost)
                {
                    // Set to true ONLY on the last line in the array.
                    // When true, OnInsertRecord posts the entire batch in one run
                    // so all lines share a single Job Register entry.
                    Caption = 'Trigger Post';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Prevent unfiltered access — caller must supply a Journal Batch Id or SystemId filter.
        // When used as a nested subpage, BC injects the SubPageLink filter automatically.
        if (Rec.GetFilter(SystemId) = '') and
           (Rec.GetFilter("Journal Template Name") = '') and
           (Rec.GetFilter("Journal Batch Name") = '')
        then
            Error('You must specify a Journal Template Name and Batch Name filter to access journal lines.');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TempLine: Record "Job Journal Line" temporary;
        ExistingLine: Record "Job Journal Line";
        DayPlanning: Record "Day Planning";
        NextLineNo: Integer;
        GuidVar: Guid;
        ModifyRec: Boolean;
        ErrLbl: Label 'The specified Day Planning (System Id = %1) has already been posted and cannot be referenced in a Job Journal Line.';
    begin
        // Step 1: snapshot ALL incoming API data FIRST, before Rec is touched
        TempLine.Copy(Rec);

        Evaluate(GuidVar, DayPlanningSystemId);
        DayPlanning.GetBySystemId(GuidVar);
        if DayPlanning.Posted then
            Error(ErrLbl, DayPlanningSystemId);

        // Check if a line for the same DayPlanning already exists in this batch
        ExistingLine.Reset();
        ExistingLine.SetRange("Journal Template Name", TempLine."Journal Template Name");
        ExistingLine.SetRange("Journal Batch Name", TempLine."Journal Batch Name");
        ExistingLine.SetRange("Opt. DayPlanning Date", DayPlanning."Task Date");
        ExistingLine.SetRange("Opt. DayPlanning Line No.", DayPlanning."Day Line No.");
        if ExistingLine.FindFirst() then begin
            // Modify path: load existing PK into Rec; payload comes from TempLine (incoming)
            ModifyRec := true;
            Rec := ExistingLine;
        end else begin
            // Insert path: clear stale framework values and rebuild PK
            ModifyRec := false;
            Clear(Rec);
            Rec."Journal Template Name" := TempLine."Journal Template Name";
            Rec."Journal Batch Name" := TempLine."Journal Batch Name";

            if TempLine."Line No." <> 0 then
                NextLineNo := TempLine."Line No."
            else begin
                ExistingLine.Reset();
                ExistingLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                ExistingLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                if ExistingLine.FindLast() then
                    NextLineNo := ExistingLine."Line No." + 10000
                else
                    NextLineNo := 10000;
            end;
            Rec."Line No." := NextLineNo;
        end;

        // Apply incoming payload — TempLine always holds the API-submitted values
        Rec."Line Type" := TempLine."Line Type";
        Rec."Posting Date" := TempLine."Posting Date";
        Rec."Document Date" := TempLine."Document Date";
        Rec."Document No." := TempLine."Document No.";
        Rec."External Document No." := TempLine."External Document No.";

        Rec."Opt. DayPlanning Date" := DayPlanning."Task Date";
        Rec."Opt. DayPlanning Line No." := DayPlanning."Day Line No.";
        Rec."Job No." := DayPlanning."Job No.";
        Rec."Job Task No." := DayPlanning."Job Task No.";

        Rec.Type := TempLine.Type;
        Rec."No." := TempLine."No.";
        Rec.Description := TempLine.Description;
        Rec."Description 2" := TempLine."Description 2";
        Rec.Quantity := TempLine.Quantity;
        Rec."Unit of Measure Code" := TempLine."Unit of Measure Code";
        Rec."Unit Cost" := TempLine."Unit Cost";
        Rec."Unit Price" := TempLine."Unit Price";
        Rec."Work Type Code" := TempLine."Work Type Code";
        Rec."Location Code" := TempLine."Location Code";
        Rec."Shortcut Dimension 1 Code" := TempLine."Shortcut Dimension 1 Code";
        Rec."Shortcut Dimension 2 Code" := TempLine."Shortcut Dimension 2 Code";
        Rec."Gen. Bus. Posting Group" := TempLine."Gen. Bus. Posting Group";
        Rec."Gen. Prod. Posting Group" := TempLine."Gen. Prod. Posting Group";

        // Validation
        Rec.TestField("Posting Date");
        Rec.TestField("Document No.");
        Rec.TestField("Opt. DayPlanning Date");
        Rec.TestField("Opt. DayPlanning Line No.");
        Rec.TestField("Job No.");
        Rec.TestField("Job Task No.");
        Rec.TestField(Quantity);
        Rec.TestField("Unit of Measure Code");

        if ModifyRec then
            Rec.Modify()
        else
            Rec.Insert(true);

        // If this is the last line, post the entire batch in one run
        if TriggerPost then
            PostBatchInline(Rec."Journal Template Name", Rec."Journal Batch Name");

        // BC must NOT insert again
        exit(false);
    end;

    var
        DayPlanningSystemId: Text[50];
        TriggerPost: Boolean;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure PostBatchInline(TemplateName: Code[10]; BatchName: Code[10])
    // CommitBehavior::Ignore suppresses any COMMIT calls inside Job Jnl.-Post Batch.
    // All posted ledger entries and journal line deletions accumulate in the current
    // transaction and are committed atomically when the HTTP response is sent.
    // Called only ONCE (on the last line), so all lines share a single Job Register entry.
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostBatch: Codeunit "Job Jnl.-Post Batch";
    begin
        JobJnlLine.SetRange("Journal Template Name", TemplateName);
        JobJnlLine.SetRange("Journal Batch Name", BatchName);
        if JobJnlLine.FindFirst() then
            JobJnlPostBatch.Run(JobJnlLine);
    end;
}
