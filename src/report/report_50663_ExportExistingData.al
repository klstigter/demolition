report 50663 "Export Existing Data"
{
    Caption = 'Export Existing Data';
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Period)
                {
                    Caption = 'Period';
                    InstructionalText = 'Limits the exported Day Plannings and capacity entries. Leave both dates empty to export all data.';
                    field(StartDateCtrl; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the first date of the period to export. Leave empty for no lower limit.';
                    }
                    field(EndDateCtrl; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date of the period to export. Leave empty for no upper limit.';
                    }
                }
            }
        }
    }

    var
        StartDate: Date;
        EndDate: Date;
        PeriodErr: Label 'Start Date must not be after End Date.';

    trigger OnPreReport()
    var
        DemoDataXmlPort: XmlPort DemoData;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
    begin
        if (StartDate <> 0D) and (EndDate <> 0D) and (StartDate > EndDate) then
            Error(PeriodErr);

        TempBlob.CreateOutStream(OutStr);
        DemoDataXmlPort.SetDestination(OutStr);
        DemoDataXmlPort.SetExportPeriod(StartDate, EndDate);
        DemoDataXmlPort.Export();
        TempBlob.CreateInStream(InStr);
        FileName := 'DemoData.xml';
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
