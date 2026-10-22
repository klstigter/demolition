report 50662 "Apply Demo Data Scenario"
{
    Caption = 'Apply Demo Data Scenario';
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
                    field(StartDateCtrl; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the first date of the period to delete and import.';
                    }
                    field(EndDateCtrl; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date of the period to delete and import.';
                    }
                }
                group(DataOptions)
                {
                    Caption = 'Data Options';
                    field(DataOptionCtrl; DataOption)
                    {
                        ApplicationArea = All;
                        Caption = 'Option';
                        OptionCaption = 'Delete Existing Data and replace with scenario data,Merge into existing data';
                        ToolTip = 'Specifies whether existing data is deleted first or the scenario is merged into it.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if StartDate = 0D then begin
                if Scenario."Date" <> 0D then
                    StartDate := Scenario."Date"
                else
                    StartDate := WorkDate();
                EndDate := CalcDate('<+2M-1D>', StartDate);
            end;
        end;
    }

    var
        Scenario: Record "Demo Data Scenarios Opt";
        StartDate: Date;
        EndDate: Date;
        DataOption: Option "Delete Existing Data and replace with scenario data","Merge into existing data";
        Applied: Boolean;
        ResourcesDeleted: Integer;
        ResourcesSkipped: Integer;
        DayPlanningsDeleted: Integer;
        CapacityDeleted: Integer;
        ImportedDayPlannings: Integer;
        ImportedCapacities: Integer;
        ImportErrors: Integer;
        ImportPrefixLbl: Label 'Import: ';
        ErrTable: List of [Text];
        ErrKey: List of [Text];
        ErrDesc: List of [Text];
        ErrText: List of [Text];
        TableLbl: Label 'Table';
        KeyLbl: Label 'Record key';
        DescLbl: Label 'Description';
        ErrorLbl: Label 'Error message';
        SheetNameLbl: Label 'Delete errors';
        ExcelMsg: Label '%1 delete error(s) occurred. An Excel file with the details was downloaded.';
        PeriodErr: Label 'Start Date and End Date must be filled in and Start Date must not be after End Date.';
        ConfirmDeleteLbl: Label 'This will DELETE existing resources, day plannings and capacity (day plannings and capacity within the period) before importing the scenario. This cannot be undone.\\Continue?';
        NoXmlErr: Label 'The scenario has no XML demo data.';
        DoneMsg: Label 'Demo data scenario applied.\Resources deleted: %1 (skipped, could not be deleted: %2)\Day plannings deleted: %3\Capacity entries deleted: %4\Day plannings imported: %5\Capacity entries imported: %6\Delete errors: %7\Import errors: %8';

    procedure SetScenario(EntryNo: Integer)
    begin
        Scenario.Get(EntryNo);
    end;

    procedure WasApplied(): Boolean
    begin
        exit(Applied);
    end;

    trigger OnPreReport()
    var
        DemoDataXmlPort: XmlPort DemoData;
        InStr: InStream;
        ImpTables: List of [Text];
        ImpKeys: List of [Text];
        ImpTexts: List of [Text];
        i: Integer;
    begin
        Applied := false;
        if (StartDate = 0D) or (EndDate = 0D) or (StartDate > EndDate) then
            Error(PeriodErr);
        if not Scenario.HasXml() then
            Error(NoXmlErr);

        if DataOption = DataOption::"Delete Existing Data and replace with scenario data" then begin
            if not Confirm(ConfirmDeleteLbl, false) then
                exit;
            DeleteExistingData();
        end;

        Scenario.GetXmlStream(InStr);
        DemoDataXmlPort.SetSource(InStr);
        DemoDataXmlPort.SetOptions(StartDate, EndDate);
        DemoDataXmlPort.Import();
        ImportedDayPlannings := DemoDataXmlPort.GetImportedDayPlannings();
        ImportedCapacities := DemoDataXmlPort.GetImportedCapacities();
        DemoDataXmlPort.GetImportErrors(ImpTables, ImpKeys, ImpTexts);
        for i := 1 to ImpTables.Count() do
            AddError(ImportPrefixLbl + ImpTables.Get(i), ImpKeys.Get(i), '', ImpTexts.Get(i));
        ImportErrors := ImpTables.Count();

        Applied := true;
        Message(DoneMsg, ResourcesDeleted, ResourcesSkipped, DayPlanningsDeleted, CapacityDeleted, ImportedDayPlannings, ImportedCapacities, ErrTable.Count() - ImportErrors, ImportErrors);
        if ErrTable.Count() > 0 then
            if GuiAllowed() then begin
                DownloadErrorsExcel();
                Message(ExcelMsg, ErrTable.Count());
            end;
    end;

    local procedure DeleteExistingData()
    var
        DayPlanning: Record "Day Planning";
        ResCapacity: Record "Res. Capacity Entry";
        Resource: Record Resource;
        RecRef: RecordRef;
    begin
        // DeleteAll(false) bypasses Day Planning's OnDelete, which blocks on Assigned/Realized Hours <> 0.
        DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        RecRef.GetTable(DayPlanning);
        DayPlanningsDeleted := DeleteSet(RecRef, '');
        RecRef.Close();

        ResCapacity.SetRange(Date, StartDate, EndDate);
        RecRef.GetTable(ResCapacity);
        CapacityDeleted := DeleteSet(RecRef, '');
        RecRef.Close();

        Resource.SetLoadFields("No.", Name);
        if Resource.FindSet() then
            repeat
                if DeleteResourceWithDependents(Resource."No.", Resource.Name) then
                    ResourcesDeleted += 1
                else
                    ResourcesSkipped += 1;
            until Resource.Next() = 0;
    end;

    local procedure DeleteResourceWithDependents(ResNo: Code[20]; ResName: Text): Boolean
    var
        DayPlanning: Record "Day Planning";
        ResCapacity: Record "Res. Capacity Entry";
        ResourceSkill: Record "Resource Skill";
        ResUoM: Record "Resource Unit of Measure";
        DefaultDim: Record "Default Dimension";
        Resource: Record Resource;
        RecRef: RecordRef;
        Dummy: Integer;
    begin
        DayPlanning.SetRange("Requested Resource No.", ResNo);
        RecRef.GetTable(DayPlanning);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();
        DayPlanning.Reset();
        DayPlanning.SetRange("Assigned Resource No.", ResNo);
        RecRef.GetTable(DayPlanning);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();

        ResCapacity.SetRange("Resource No.", ResNo);
        RecRef.GetTable(ResCapacity);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();

        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("No.", ResNo);
        RecRef.GetTable(ResourceSkill);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();

        ResUoM.SetRange("Resource No.", ResNo);
        RecRef.GetTable(ResUoM);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();

        DefaultDim.SetRange("Table ID", Database::Resource);
        DefaultDim.SetRange("No.", ResNo);
        RecRef.GetTable(DefaultDim);
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();

        DeleteRefTableByCode(201, ResNo, ResName); // Resource Price
        DeleteRefTableByCode(203, ResNo, ResName); // Resource Cost

        if not Resource.Get(ResNo) then
            exit(true);
        if TryDeleteResource(Resource) then
            exit(true);
        AddError(Resource.TableCaption(), ResNo, ResName, GetLastErrorText());
        exit(false);
    end;

    // Deletes all records in RecRef's current filter. Tries a bulk DeleteAll first; if that fails,
    // falls back to record by record so one failing record never stops the run. Returns number deleted.
    local procedure DeleteSet(var RecRef: RecordRef; Desc: Text): Integer
    var
        CountBefore: Integer;
    begin
        CountBefore := RecRef.Count();
        if CountBefore = 0 then
            exit(0);
        if not TryDeleteAll(RecRef) then
            if RecRef.FindSet() then
                repeat
                    if not TryDeleteCurrent(RecRef) then
                        AddError(RecRef.Caption(), Format(RecRef.RecordId()), Desc, GetLastErrorText());
                until RecRef.Next() = 0;
        exit(CountBefore - RecRef.Count());
    end;

    [TryFunction]
    local procedure TryDeleteAll(var RecRef: RecordRef)
    begin
        RecRef.DeleteAll(false);
    end;

    [TryFunction]
    local procedure TryDeleteCurrent(var RecRef: RecordRef)
    begin
        RecRef.Delete(false);
    end;

    [TryFunction]
    local procedure TryDeleteResource(var Resource: Record Resource)
    begin
        Resource.Delete(true);
    end;

    [TryFunction]
    local procedure TryOpenFilterTable(var RecRef: RecordRef; TableNo: Integer; ResNo: Code[20])
    var
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(2); // Code
        FieldRef.SetRange(ResNo);
    end;

    local procedure DeleteRefTableByCode(TableNo: Integer; ResNo: Code[20]; ResName: Text)
    var
        RecRef: RecordRef;
        Dummy: Integer;
    begin
        // Resource Price / Resource Cost may not exist in every BC version: a failure to open is ignored.
        if not TryOpenFilterTable(RecRef, TableNo, ResNo) then
            exit;
        Dummy := DeleteSet(RecRef, ResNo + ' ' + ResName);
        RecRef.Close();
    end;

    local procedure AddError(TableName: Text; RecordKey: Text; Desc: Text; ErrorText: Text)
    begin
        ErrTable.Add(TableName);
        ErrKey.Add(RecordKey);
        ErrDesc.Add(Desc);
        ErrText.Add(ErrorText);
    end;

    local procedure DownloadErrorsExcel()
    var
        ExcelBuf: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        i: Integer;
        FileName: Text;
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(TableLbl, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(KeyLbl, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(DescLbl, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(ErrorLbl, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
        for i := 1 to ErrTable.Count() do begin
            ExcelBuf.NewRow();
            ExcelBuf.AddColumn(ErrTable.Get(i), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(ErrKey.Get(i), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(ErrDesc.Get(i), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(ErrText.Get(i), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        end;
        ExcelBuf.CreateNewBook(SheetNameLbl);
        ExcelBuf.WriteSheet('', CompanyName(), UserId());
        ExcelBuf.CloseBook();
        TempBlob.CreateOutStream(OutStr);
        ExcelBuf.SaveToStream(OutStr, true);
        TempBlob.CreateInStream(InStr);
        FileName := 'DemoData_DeleteErrors_' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
