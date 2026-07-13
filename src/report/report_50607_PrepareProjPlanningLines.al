report 50607 "Prepare Proj. Planning Lines"
{
    Caption = 'Prepare Project Planning Lines for Invoicing';
    ProcessingOnly = true;
    UsageCategory = None;
    ApplicationArea = All;
    Permissions = tabledata "Day Planning" = r;

    dataset
    {
        dataitem(DayPlanning; "Day Planning")
        {
            RequestFilterFields = "Job No.", "Job Task No.", "Skill", "Assigned Resource No.";
            DataItemTableView = where(Posted = const(true));

            trigger OnPreDataItem()
            var
                JobInvoicePrepMgt: Codeunit "Job Invoice Prep. Mgt.";
                LinesCreated: Integer;
                ProcessedCount: Integer;
                AlreadyLinkedCount: Integer;
                NotPostedCount: Integer;
                SkippedOtherCount: Integer;
            begin
                LinesCreated := JobInvoicePrepMgt.PrepareInvoiceLinesForSelection(DayPlanning, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount);
                Message(JobInvoicePrepMgt.FormatResultMessage(LinesCreated, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount));
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        Caption = 'Prepare Project Planning Lines for Invoicing';

        layout
        {
            area(content)
            {
            }
        }
    }
}
