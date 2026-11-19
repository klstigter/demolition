report 50607 "Opti Prepare Proj. Plan. Lines"
{
    Caption = 'Prepare Project Planning Lines for Invoicing';
    ProcessingOnly = true;
    UsageCategory = None;
    ApplicationArea = All;
    Permissions = tabledata "Opti Day Planning" = r;

    dataset
    {
        dataitem(DayPlanning; "Opti Day Planning")
        {
            RequestFilterFields = "Job No.", "Job Task No.", "Skill", "Assigned Resource No.";
            DataItemTableView = where(Posted = const(true));

            trigger OnPreDataItem()
            var
                JobInvoicePrepMgt: Codeunit "Opti Job Plan. Line Prep. Mgt.";
                LinesCreated: Integer;
                ProcessedCount: Integer;
                AlreadyLinkedCount: Integer;
                NotPostedCount: Integer;
                SkippedOtherCount: Integer;
            begin
                LinesCreated := JobInvoicePrepMgt.PrepareJobPlanningLinesForSelection(DayPlanning, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount);
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
