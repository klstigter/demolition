report 50609 "Opti Res Capacity To Excel"
{
    Caption = 'Resource Capacity To Excel';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    UseRequestPage = true;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                AddResourceCapacityRows(Resource);
            end;
        }
    }

    trigger OnPreReport()
    begin
        AddHeader();
    end;

    trigger OnPostReport()
    begin
        ExportExcel();
    end;

    local procedure AddHeader()
    begin
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Resource No.', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Resource Name', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Year', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Week', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Date', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Date);
        ExcelBuffer.AddColumn('Start time', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Time);
        ExcelBuffer.AddColumn('End time', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Time);
        ExcelBuffer.AddColumn('Non working minutes', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Number);
        ExcelBuffer.AddColumn('Total capacity per time slot', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Number);
    end;

    local procedure AddResourceCapacityRows(var Res: Record Resource)
    var
        SlotMinutes: Decimal;
        CapacityMinutes: Decimal;
        NonWorkingMinutes: Decimal;
        YearNo: Integer;
        WeekNo: Integer;
    begin
        ResCapacityEntry.Reset();
        ResCapacityEntry.SetRange("Resource No.", Res."No.");
        if Res.GetFilter("Date Filter") <> '' then
            ResCapacityEntry.SetFilter(Date, Res.GetFilter("Date Filter"));

        if ResCapacityEntry.FindSet() then
            repeat
                YearNo := Date2DMY(ResCapacityEntry.Date, 3);
                WeekNo := Date2DWY(ResCapacityEntry.Date, 2);

                SlotMinutes := GetSlotMinutes(ResCapacityEntry."Start Time", ResCapacityEntry."End Time");
                CapacityMinutes := Round(ResCapacityEntry.Capacity * 60, 0.00001, '=');
                NonWorkingMinutes := SlotMinutes - CapacityMinutes;
                if NonWorkingMinutes < 0 then
                    NonWorkingMinutes := 0;

                ExcelBuffer.NewRow();
                ExcelBuffer.AddColumn(Res."No.", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(Res.Name, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(YearNo, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(WeekNo, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(ResCapacityEntry.Date, false, '', false, false, false, 'yyyy-mm-dd', ExcelBuffer."Cell Type"::Date);
                ExcelBuffer.AddColumn(ResCapacityEntry."Start Time", false, '', false, false, false, 'hh:mm', ExcelBuffer."Cell Type"::Time);
                ExcelBuffer.AddColumn(ResCapacityEntry."End Time", false, '', false, false, false, 'hh:mm', ExcelBuffer."Cell Type"::Time);
                ExcelBuffer.AddColumn(NonWorkingMinutes, false, '', false, false, false, '0.00', ExcelBuffer."Cell Type"::Number);
                ExcelBuffer.AddColumn(ResCapacityEntry.Capacity, false, '', false, false, false, '0.00000', ExcelBuffer."Cell Type"::Number);
            until ResCapacityEntry.Next() = 0;
    end;

    local procedure GetSlotMinutes(StartTime: Time; EndTime: Time): Decimal
    var
        Dur: Duration;
    begin
        Dur := EndTime - StartTime;
        if Dur < 0 then
            Dur += 24 * 60 * 60 * 1000; // across midnight

        exit(Round(Dur / 60000, 0.00001, '='));
    end;

    local procedure ExportExcel()
    begin
        ExcelBuffer.CreateNewBook('Resource Capacity');
        ExcelBuffer.WriteSheet('Capacity', CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.SetFriendlyFilename('resource_capacity_timeslots');
        ExcelBuffer.OpenExcel();
    end;

    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        ExcelBuffer: Record "Excel Buffer" temporary;
}