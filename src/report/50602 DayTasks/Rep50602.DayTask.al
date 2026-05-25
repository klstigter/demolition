report 50602 DayTask
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = DayTaskReport;

    dataset
    {
        dataitem(DayTask; "Day Tasks")
        {
            dataitemtableview = sorting("Job No.", "Job Task No.", "Task Date") where("plan status" = const(Inprocess));

            column(JobNo; JobDescription)
            {
                Caption = 'Job No.';
            }
            column(JobTaskNo; JobTaskDescription)
            {
                Caption = 'Job Task No.';
            }
            column(LineNo; DayTask."Day Line No.")
            {
                Caption = 'Job Line No.';
            }
            column(TaskDate; DayTask."Task Date")
            {
                Caption = 'Task Date';
            }
            dataitem(Integer; "Integer")
            {
                dataitemtableview = sorting(Number) where(Number = const(1));
                dataitem(DayTask2; "Day Tasks")

                {
                    DataItemLinkReference = DayTask;
                    DataItemLink = "Job No." = field("Job No.")
                    , "Job Task No." = field("Job Task No.")
                    , "Task Date" = field("Task Date");

                    column(ResourceNo;
                    DayTask2."Assigned Resource No.")
                    {
                        Caption = 'Resource No.';
                    }
                    column(IsPool; resource."Is Pool")
                    {
                        Caption = 'Is Pool';
                    }
                    column(PoolResourceName; resource."pool Resource no.")
                    {
                        Caption = 'Resource Name';
                    }
                    column(IsForeman; resource."Is Foreman")
                    {
                        Caption = 'Is Foreman';
                    }

                    column(AssignedHours; DayTask2."Assigned Hours")
                    {
                        Caption = 'Assigned Hours';
                    }


                    trigger OnPreDataItem()
                    begin
                        TEMPresource.Reset();
                        TEMPresource.DeleteAll();
                    end;

                    trigger OnAfterGetRecord()
                    var
                        DoInsert: Boolean;

                    begin
                        // Populate the temporary table with necessary fields from related tables
                        if resource.Get(DayTask2."Assigned Resource No.") then begin
                            if not TEMPresource.Get(dayTask2."Assigned Resource No.") then begin
                                TEMPresource.Init();
                                TEMPresource."No." := dayTask2."Assigned Resource No.";
                                TEMPresource."Is Pool" := resource."Is Pool";
                                TEMPresource."Pool Resource no." := resource."pool Resource no.";
                                TEMPresource."Is Foreman" := resource."Is Foreman";
                                TEMPresource."external resource" := resource."external resource";
                                TEMPresource."Direct Unit Cost" := DayTask2."Assigned Hours";
                                DoInsert := true;
                            end else begin
                                TEMPresource."Direct Unit Cost" += DayTask2."Assigned Hours";
                            end;
                            if DoInsert then
                                TEMPresource.Insert()
                            else
                                TEMPresource.Modify();
                        end;
                        currreport.Skip();
                    end;
                }
                Trigger Onpostdataitem()
                var
                begin
                    HtmlCellInfo := CreateHtmlCellInfo();
                end;
            }

            dataitem(Integer2; "Integer")
            {
                dataitemtableview = sorting(Number) where(Number = const(1));
                column(number; Integer2.Number)
                { }
                column(HtmlInfo; HtmlCellInfo)
                { }

            }
            trigger OnAfterGetRecord()
            var
                DateFilter: Text;
            begin
                // Populate the dataset with necessary fields from related tables
                if not Job.Get(DayTask."Job No.") then
                    clear(Job);
                jobdescription := job."No." + ' ' + Job.Description;

                if not jobTask.Get(DayTask."Job No.", DayTask."Job Task No.") then
                    clear(jobTask);

                jobTaskDescription := ' - ' + jobTask."Job Task No." + ' ' + jobTask.Description;

                if not resource.Get(DayTask."Assigned Resource No.") then
                    clear(resource);

                dayTask.SetRange("Job No.", DayTask."Job No.");
                dayTask.SetRange("Job Task No.", DayTask."Job Task No.");
                dateFilter := dayTask.GetFilter("Task Date");
                dayTask.SetRange("Task Date", DayTask."Task Date");
                daytask.FindLast();
                dayTask.SetRange("Job No.");
                dayTask.SetRange("Job Task No.");
                dayTask.Setfilter("Task Date", dateFilter);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                field(WeekFilter; WeekFilter)
                {
                    Caption = 'Year/Week Filter';
                    ToolTip = 'Specifies the year and week number, or only the year for filtering. Format should be YYYY-WW or YYYY.';
                    trigger OnValidate()
                    begin
                        validateYrWkFilterFormat(WeekFilter);
                        calcWeekFilter();
                    end;


                    trigger OnLookup(var Text: Text): Boolean
                    var
                        YearWeek: Record "Integer" temporary;
                        SumWk: Record "Summary Weekly";
                        Year: Integer;
                        Week: Integer;
                        Pg: Page "Week View";
                    begin
                        pg.LookupMode(true);
                        pg.SetShowWeek(true);
                        Pg.SetTempYearWeek(TempYearWeek);
                        if Pg.RunModal() = Action::LookupOK then begin
                            Pg.GetRecord(YearWeek);
                            SumWk.ExtractYearAndWeek(YearWeek.Number, Year, Week);
                            Text := Format(Year) + '-' + Format("Week");
                            exit(true);
                        end;
                    end;
                }
            }
        }



    }

    rendering
    {
        layout(LayoutName)
        {
            Type = Excel;
            LayoutFile = 'src/report/50602 DayTasks/mySpreadsheet.xlsx';
        }
        layout(DayTaskReport)
        {
            Type = Rdlc;
            LayoutFile = 'src/report/50602 DayTasks/DayTaskReport.rdlc';
        }
    }

    var
        Job: Record "Job";
        jobTask: Record "Job Task";
        resource: Record Resource;
        TEMPresource: Record "Resource" temporary;
        TempYearWeek: Record Integer temporary;
        StartDate: Date;
        EndDate: Date;
        HtmlCellInfo: Text;
        JobDescription: Text;
        JobTaskDescription: Text;
        WeekFilter: Text;

    local procedure CreateHtmlCellInfo(): Text
    var
        TEMPresourcePool: Record "Resource" temporary;
        Html: TextBuilder;
        i: Integer;
    begin
        // tempresource.Reset();
        // tempresource.DeleteAll();
        // CreateTestResources(tempresource);
        tempresource.SetFilter("Is Pool", '=%1', true);
        if tempresource.FindSet() then
            repeat
                if not TEMPresourcePool.get(tempresource."pool Resource no.") then begin
                    tempresourcePool.Init();
                    tempresourcePool."No." := tempresource."pool Resource no.";
                    tempresourcePool."Name" := tempresource."pool Resource no.";
                    tempresourcePool."Is Pool" := true;
                    TEMPresourcePool."Direct Unit Cost" := DayTask2."Assigned Hours";
                    tempresourcePool.insert();
                end else begin
                    TEMPresourcePool."Direct Unit Cost" += DayTask2."Assigned Hours";
                    TEMPresourcePool.Modify();
                end;
            until TEMPresource.Next() = 0;

        Html.Append('<html><body>');

        for i := 1 to 3 do begin
            case i of
                1:
                    begin
                        tempresource.reset;
                        tempresource.setrange("Is Foreman", true);
                    end;

                2:
                    begin
                        tempresource.reset;
                        tempresource.setrange("Is Foreman", false);
                        tempresource.setrange("external resource", false);
                    end;
                3:
                    begin
                        tempresource.reset;
                        tempresource.setrange("Is Foreman", false);
                        tempresource.setrange("external resource", true);
                        tempresource.setrange("Is Pool", false);
                        tempresource.SetFilter("pool Resource no.", '=%1', '');
                    end;
            end;

            if tempresource.FindSet() then
                repeat
                    AppendResourceInfo(tempresource, Html);
                until tempresource.Next() = 0;
        end;

        if tempresourcePool.FindSet() then
            repeat
                appendResourceInfo(tempresourcePool, Html);
                tempresource.Reset();
                tempresource.SetRange("pool Resource no.", tempresourcePool."No.");
                tempresource.setrange("Is Foreman", false);
                tempresource.setrange("external resource", true);
                tempresource.setrange("Is Pool", false);
                if tempresource.FindSet() then
                    repeat
                        appendResourceInfo(tempresource, Html);
                    until tempresource.Next() = 0;
            until tempresourcePool.Next() = 0;

        Html.Append('</body></html>');

        exit(Html.ToText());
    end;

    local procedure AppendResourceInfo(var Rs: record "Resource"; var Html: TextBuilder)
    var
        StyleTxt: Text;
        txt: Text;
    begin

        StyleTxt := '';

        if Rs."Is Foreman" = true then
            StyleTxt += 'color:red;';

        if Rs."Is Pool" = true then
            StyleTxt += 'font-weight:bold;';


        Html.Append('<div');
        if StyleTxt <> '' then
            Html.Append(' style="' + StyleTxt + '"');
        Html.Append('>');
        if Rs."external resource" = true then
            Html.Append('-  ');
        if rs."Name" <> '' then
            txt := rs."Name"
        else
            txt := rs."No.";
        txt += ' (' + Format(rs."Direct Unit Cost") + ')';

        Html.Append(HtmlEscape(txt));
        Html.Append('</div>');

    end;

    local procedure HtmlEscape(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        exit(Value);
    end;

    local procedure ValidateYrWkFilterFormat(var YrWkFilter: Text): Boolean
    var
        y, w, l : Integer;
        NotValidFormat: Boolean;
    begin
        l := StrLen(WeekFilter);
        if l in [0, 7] then begin
            if l = 0 then
                exit(false)
            else begin
                if not Evaluate(y, CopyStr(WeekFilter, 1, 4)) then
                    NotValidFormat := true;
                if not Evaluate(w, CopyStr(WeekFilter, 6, 2)) then
                    NotValidFormat := true;
                if not (CopyStr(WeekFilter, 5, 1) = '-') then
                    NotValidFormat := true;

            end;
        end else
            NotValidFormat := true;
        if NotValidFormat then
            Error('Invalid format. Please enter in YYYY-WW format.');
        exit(true)
    end;

    Procedure SetDataViewDateRange(StartDateDataSet: Date; EndDateDataSet: Date)
    begin
        startDate := StartDateDataSet;
        endDate := EndDateDataSet;
        FillTempYearWeek();
    end;

    Local procedure FillTempYearWeek(): Integer
    var
        dateR: Record date;
        yw: Integer;
    begin
        TempYearWeek.Reset();
        TempYearWeek.DeleteAll();
        dateR.SetRange("Period Start", StartDate, EndDate);
        dateR.SetFilter("Period Type", '=%1', dateR."Period Type"::Date);
        if dateR.FindSet() then
            repeat
                yw := CreateYW(dateR."Period Start");
                if not tempYearWeek.Get(yw) then begin
                    TempYearWeek.Init();
                    TempYearWeek.Number := yw;
                    TempYearWeek.Insert();
                end;
            until dateR.Next() = 0;
        exit(TempYearWeek.Count());
    end;

    local procedure CreateYW(TaskDate: Date): Integer
    var
        y: Integer;
        w: Integer;
    begin
        if TaskDate = 0D then
            exit(0);

        y := Date2DWY(TaskDate, 3);
        w := Date2DWY(TaskDate, 2);
        exit((y * 100) + w);
    end;

    local procedure CalcWeekFilter()
    var
        yr: Integer;
        wk: Integer;
        FirstDateOfWeek, LastDateOfWeek : Date;
    begin
        if ValidateYrWkFilterFormat(WeekFilter) then begin
            evaluate(yr, CopyStr(WeekFilter, 1, 4));
            evaluate(wk, CopyStr(WeekFilter, 6, 2));
            FirstDateOfWeek := DWY2Date(1, wk, yr);
            LastDateOfWeek := DWY2Date(7, wk, yr);
            dayTask.SetRange("Task Date", FirstDateOfWeek, LastDateOfWeek);
        end;
    end;

    procedure CreateTestResources(var Resource: Record Resource temporary)

    begin
        InsertTestResource('Rene', 'Rene van Dongen', '', false, false, true, Resource);
        InsertTestResource('Henk', 'Henk van Doorn', '', false, false, false, Resource);

        InsertTestResource('jan', 'Jan Aantjes', '', true, false, false, Resource);

        InsertTestResource('Pool', 'Pool', 'Pool', true, true, false, Resource);
        InsertTestResource('Pool 1', 'Pool 1', 'Pool', true, false, false, Resource);
        InsertTestResource('Pool 2', 'Pool 2', 'Pool', true, false, false, Resource);
        InsertTestResource('Pool 3', 'Pool 3', 'Pool', true, false, false, Resource);

        InsertTestResource('Turk', 'Turk', 'Turk', true, true, false, Resource);
        InsertTestResource('Turk 1', 'Turk 1', 'Turk', true, false, false, Resource);
        InsertTestResource('Turk 2', 'Turk 2', 'Turk', true, false, false, Resource);
        InsertTestResource('Turk 3', 'Turk 3', 'Turk', true, false, false, Resource);
        InsertTestResource('Turk 4', 'Turk 4', 'Turk', true, false, false, Resource);
    end;


    local procedure InsertTestResource(
        ResourceNo: Code[20];
        ResourceName: Text[100];
        PoolResourceNo: Code[20];
        IsExternal: Boolean;
        IsPool: Boolean;
        IsForeman: Boolean;
        var Resource: Record Resource temporary)
    begin

        Resource.Init();
        Resource.Validate("No.", ResourceNo);
        Resource.Type := Resource.Type::Person;

        Resource.Validate(Name, ResourceName);

        Resource."pool Resource no." := PoolResourceNo;
        Resource."external resource" := IsExternal;
        Resource."Is Pool" := IsPool;
        Resource."Is Foreman" := IsForeman;

        Resource.Insert(true);
    end;
}