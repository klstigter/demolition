report 50604 "Day Resource Details"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = DayTaskReport;

    dataset
    {
        dataitem(DayTask; "Day Tasks")
        {
            dataitemtableview = sorting("Task Date", "Assigned Resource No.") where("plan status" = const(Inprogress),
                "assigned Resource No." = filter(<> ''));
            RequestFilterFields = "Task Date";
            Column(TodayFormatted; Format(Today, 0, 4)) { }
            Column(CompanyName; COMPANYPROPERTY.DisplayName()) { }
            Column(ReportCaption; ReportCaption) { }
            Column(CurrReportPageNoCaption; CurrReportPageNoCaption) { }

            column(TaskDate; DayTask."Task Date") { }
            column(JobNo; JobDescription) { }
            column(JobTaskNo; JobTaskDescription) { }

            Column(DayLineNo; DayTask."Day Line No.") { }
            Column(AssResNo; DayTask."Assigned Resource No.") { }
            Column(Description; resource.Name) { }
            Column(assignedHours; DayTask."Assigned Hours") { }
            Column(TimeAssigned; Time1) { }
            column(Mandatory; resource."Mandatory schedulling") { }
            Column(jobTaskDescription; jobTaskDescription) { }
            Column(Capacity; Resource.Capacity) { }
            Column(TotassignedHours; resource."Assigned Hours") { }

            Trigger OnPreDataItem()
            begin
                resource.SetRange("Mandatory schedulling", true);
                if resource.FindSet() then
                    repeat
                        TEMPresource := resource;
                        TEMPresource.Insert();
                    until resource.Next() = 0;
            end;


            trigger OnAfterGetRecord()
            var
                DateFilter: Text;
                ColumnNo: Integer;
            begin
                if not resource.Get(DayTask."Assigned Resource No.") then
                    clear(resource);
                if Tempresource.Get(DayTask."Assigned Resource No.") then
                    TEMPresource.Delete();

                Time1 := format(DayTask."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>') + '..' + format(DayTask."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>');

                if not Job.Get(DayTask."Job No.") then
                    clear(Job);
                jobdescription := job."No." + ' ' + Job.Description;

                if not jobTask.Get(DayTask."Job No.", DayTask."Job Task No.") then
                    clear(jobTask);
                jobTaskDescription := jobTask."Job Task No." + ' ' + jobTask.Description;

                resource.setrange("date filter", dayTask."Task Date");
                resource.CalcFields(Capacity, "Assigned Hours");

            end;
        }
        DataItem(TempRes; Integer)
        {
            dataitemtableview = sorting(Number);
            Column(Number; TempRes.Number) { }
            Column(ResourceNo; TEMPresource."No.") { }
            Column(ResourceName; TEMPresource.Name) { }
            Column(NeedSchedulling; true) { }
            column(TaskDate2; DayTask."Task Date") { }
            Column(Capacity2; TEMPresource.Capacity) { }

            trigger OnPreDataItem()
            begin
                TempRes.setrange(Number, 1, tempresource.count());
            end;

            trigger OnAfterGetRecord()
            begin
                if tempres.Number = 1 then
                    TEMPresource.FindSet()
                else
                    TEMPresource.Next();
                TEMPresource.setrange("date filter", dayTask."Task Date");
                TEMPresource.CalcFields(Capacity);
            end;
        }
    }

    rendering
    {
        // layout(LayoutName)
        // {
        //     Type = Excel;
        //     LayoutFile = 'src/report/50603 Day Task Detail/mySpreadsheet2.xlsx';
        // }
        layout(DayTaskReport)
        {
            Type = Rdlc;
            LayoutFile = 'src/report/50604 Day Resource Detail/DayTaskResourceDetailReport.rdlc';
        }
    }

    var
        Job: Record "Job";
        jobTask: Record "Job Task";
        resource: Record Resource;
        TEMPresource: Record "Resource" temporary;
        StartDate: Date;
        EndDate: Date;
        SelectedDate: Date;
        HtmlCellInfo: Text;
        JobDescription: Text;
        JobTaskDescription: Text;
        DateSelectionFilter: Text;

        Time1, Time2 : Text;
        ReportCaption: Label 'Resource Details Planning';
        CurrReportPageNoCaption: Label 'Page';



    procedure SetDataViewDateRange(StartDatep: Date; EndDatep: Date)
    begin
        StartDate := StartDatep;
        EndDate := EndDatep;
    end;


}