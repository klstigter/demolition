report 50606 "Job Planning Line Usage Detail"
{
    // Day-Planning-to-Invoice (Release 1): given one or more Job Planning Lines, shows the
    // posted usage (Job Ledger Entry) rows behind each one, via the "Job Ledger Invoice
    // Link" traceability table, plus a per-Resource hours summary per planning line.
    //
    // Unlike this project's other reports (all ProcessingOnly = true batch jobs), this one
    // is deliberately NOT ProcessingOnly - it exists to display data, not process it - so it
    // relies on BC's auto-generated layout since no RDLC/Word layout is defined. Keep it
    // simple per the Release 1 design doc.
    Caption = 'Job Planning Line Usage Detail';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(JobPlanningLine; "Job Planning Line")
        {
            RequestFilterFields = "Job No.", "Job Task No.", "Line No.";
            DataItemTableView = sorting("Job No.", "Job Task No.", "Line No.");

            column(JobNo_JPL; "Job No.")
            {
            }
            column(JobTaskNo_JPL; "Job Task No.")
            {
            }
            column(LineNo_JPL; "Line No.")
            {
            }
            column(ResourceNo_JPL; "No.")
            {
            }
            column(Description_JPL; Description)
            {
            }
            column(Quantity_JPL; Quantity)
            {
            }

            dataitem(JobLedgerInvoiceLink; "Job Ledger Invoice Link")
            {
                DataItemLink = "Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Invoice Job Planning Line No." = field("Line No.");
                DataItemTableView = sorting("Job No.", "Job Task No.", "Invoice Job Planning Line No.");

                column(JobLedgerEntryNo; "Job Ledger Entry No.")
                {
                }
                column(SkillCode_Link; "Skill Code")
                {
                }
                column(PostingDate_Entry; JobLedgerEntry."Posting Date")
                {
                }
                column(ResourceNo_Entry; JobLedgerEntry."No.")
                {
                }
                column(ResourceName_Entry; ResourceName)
                {
                }
                column(Description_Entry; JobLedgerEntry.Description)
                {
                }
                column(Quantity_Entry; JobLedgerEntry.Quantity)
                {
                }
                column(UOM_Entry; JobLedgerEntry."Unit of Measure Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not JobLedgerEntry.Get("Job Ledger Entry No.") then
                        CurrReport.Skip();

                    ResourceName := '';
                    if Resource.Get(JobLedgerEntry."No.") then
                        ResourceName := Resource.Name;

                    AddToResourceSummary(JobLedgerEntry."No.", ResourceName, JobLedgerEntry.Quantity);
                end;
            }

            dataitem(ResourceSummaryLoop; "Integer")
            {
                DataItemTableView = sorting(Number);

                column(SummaryResourceNo; SummaryResourceNo)
                {
                }
                column(SummaryResourceName; SummaryResourceName)
                {
                }
                column(SummaryHours; SummaryHours)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ResourceSummaryKeys.Count());
                    if ResourceSummaryKeys.Count() = 0 then
                        CurrReport.Break();
                end;

                trigger OnAfterGetRecord()
                begin
                    SummaryResourceNo := ResourceSummaryKeys.Get(Number);
                    SummaryHours := ResourceSummaryHours.Get(SummaryResourceNo);
                    SummaryResourceName := ResourceSummaryNames.Get(SummaryResourceNo);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // Reset per Job Planning Line, before its child dataitems (which populate
                // the summary) run for this record - NOT in OnPreDataItem, which would
                // only fire once for the whole report.
                ClearResourceSummary();
            end;
        }
    }

    var
        JobLedgerEntry: Record "Job Ledger Entry";
        Resource: Record Resource;
        ResourceName: Text[100];
        ResourceSummaryKeys: List of [Code[20]];
        ResourceSummaryHours: Dictionary of [Code[20], Decimal];
        ResourceSummaryNames: Dictionary of [Code[20], Text[100]];
        SummaryResourceNo: Code[20];
        SummaryResourceName: Text[100];
        SummaryHours: Decimal;

    local procedure ClearResourceSummary()
    begin
        Clear(ResourceSummaryKeys);
        Clear(ResourceSummaryHours);
        Clear(ResourceSummaryNames);
    end;

    local procedure AddToResourceSummary(ResNo: Code[20]; ResName: Text[100]; Hours: Decimal)
    begin
        if not ResourceSummaryHours.ContainsKey(ResNo) then begin
            ResourceSummaryHours.Add(ResNo, 0);
            ResourceSummaryNames.Add(ResNo, ResName);
            ResourceSummaryKeys.Add(ResNo);
        end;
        ResourceSummaryHours.Set(ResNo, ResourceSummaryHours.Get(ResNo) + Hours);
    end;
}
