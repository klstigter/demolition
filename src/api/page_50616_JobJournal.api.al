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
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm;

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
                field(postResult; GetPostresult())
                {
                    Caption = 'Description';
                }
                field(unPostedDayPlanning; GetUnpostedDayPlanning())
                {
                    Caption = 'Unposted Day Planning';
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

    procedure GetPostresult(): Text
    var
        JobRegister: Record "Job Register";
        JobLedgEntry: Record "Job Ledger Entry";
        ResultJson: JsonObject;
        LinesArray: JsonArray;
        LineJson: JsonObject;
        ResultText: Text;
        DayPlanning: Record "Day Planning";
    begin
        JobRegister.Reset();
        if not JobRegister.FindLast() then
            exit('{}');

        ResultJson.Add('jobRegisterNo', JobRegister."No.");
        ResultJson.Add('fromEntryNo', JobRegister."From Entry No.");
        ResultJson.Add('toEntryNo', JobRegister."To Entry No.");
        ResultJson.Add('postedLinesCount', JobRegister."To Entry No." - JobRegister."From Entry No." + 1);
        ResultJson.Add('creationDate', Format(JobRegister."Creation Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        ResultJson.Add('userId', JobRegister."User ID");

        JobLedgEntry.SetRange("Entry No.", JobRegister."From Entry No.", JobRegister."To Entry No.");
        if JobLedgEntry.FindSet() then
            repeat
                Clear(LineJson);
                LineJson.Add('entryNo', JobLedgEntry."Entry No.");
                LineJson.Add('postingDate', Format(JobLedgEntry."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('documentNo', JobLedgEntry."Document No.");
                LineJson.Add('jobNo', JobLedgEntry."Job No.");
                LineJson.Add('jobTaskNo', JobLedgEntry."Job Task No.");
                LineJson.Add('type', Format(JobLedgEntry.Type));
                LineJson.Add('no', JobLedgEntry."No.");
                LineJson.Add('description', JobLedgEntry.Description);
                LineJson.Add('quantity', JobLedgEntry.Quantity);
                LineJson.Add('unitPrice', JobLedgEntry."Unit Price");
                LineJson.Add('totalPrice', JobLedgEntry."Total Price");
                LineJson.Add('DayPlanningDate', Format(JobLedgEntry."Opt. DayPlanning Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('DayPlanningLineNo', JobLedgEntry."Opt. DayPlanning Line No.");
                if DayPlanning.Get(
                    JobLedgEntry."Job No.",
                    JobLedgEntry."Job Task No.",
                    JobLedgEntry."Opt. DayPlanning Line No.")
                then
                    LineJson.Add('DayPlanningSystemId', DayPlanning.SystemId)
                else
                    LineJson.Add('DayPlanningSystemId', '');
                LinesArray.Add(LineJson);
            until JobLedgEntry.Next() = 0;

        ResultJson.Add('postedLines', LinesArray);
        ResultJson.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure GetUnpostedDayPlanning(): Text
    var
        JobJnlLine: Record "Job Journal Line";
        DayPlanning: Record "Day Planning";
        ResultJson: JsonObject;
        LinesArray: JsonArray;
        LineJson: JsonObject;
        ResultText: Text;
        LineCount: Integer;
    begin
        JobJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", Rec.Name);
        LineCount := JobJnlLine.Count();

        ResultJson.Add('templateName', Rec."Journal Template Name");
        ResultJson.Add('batchName', Rec.Name);
        ResultJson.Add('unpostedLineCount', LineCount);

        if JobJnlLine.FindSet() then
            repeat
                Clear(LineJson);
                LineJson.Add('lineNo', JobJnlLine."Line No.");
                LineJson.Add('postingDate', Format(JobJnlLine."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('documentNo', JobJnlLine."Document No.");
                LineJson.Add('jobNo', JobJnlLine."Job No.");
                LineJson.Add('jobTaskNo', JobJnlLine."Job Task No.");
                LineJson.Add('type', Format(JobJnlLine.Type));
                LineJson.Add('no', JobJnlLine."No.");
                LineJson.Add('description', JobJnlLine.Description);
                LineJson.Add('quantity', JobJnlLine.Quantity);
                LineJson.Add('unitOfMeasureCode', JobJnlLine."Unit of Measure Code");
                LineJson.Add('DayPlanningDate', Format(JobJnlLine."Opt. DayPlanning Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('DayPlanningLineNo', JobJnlLine."Opt. DayPlanning Line No.");
                if DayPlanning.Get(
                    JobJnlLine."Job No.",
                    JobJnlLine."Job Task No.",
                    JobJnlLine."Opt. DayPlanning Line No.")
                then
                    LineJson.Add('DayPlanningSystemId', Format(DayPlanning.SystemId, 0, 4))
                else
                    LineJson.Add('DayPlanningSystemId', '');
                LinesArray.Add(LineJson);
            until JobJnlLine.Next() = 0;

        ResultJson.Add('unpostedLines', LinesArray);
        ResultJson.WriteTo(ResultText);
        exit(ResultText);
    end;
}