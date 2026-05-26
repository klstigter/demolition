report 50603 "Day Task Details"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = DayTaskReport;

    dataset
    {
        dataitem(DayTask; "Day Tasks")
        {
            dataitemtableview = sorting("Job No.", "Job Task No.", "Task Date") where("plan status" = const(Inprocess));
            RequestFilterFields = "Task Date", "Job No.", "Job Task No.";

            column(JobNo; JobDescription)
            {
                Caption = 'Job No.';
            }
            column(JobTaskNo; JobTaskDescription)
            {
                Caption = 'Job Task No.';
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

                    trigger OnAfterGetRecord()
                    var
                        DateFilter: Text;
                        ColumnNo: Integer;
                    begin

                        if not resource.Get(DayTask2."Assigned Resource No.") then
                            clear(resource);
                        Case true of
                            resource."Is Pool":
                                begin
                                    TempDayTask2 := DayTask2;
                                    TempDayTask2."Job Entry No." := 4;
                                    TempDayTask2.Description := resource.Name;
                                    TempDayTask2.Insert();
                                end;
                            resource."external resource":
                                begin
                                    TempDayTask2 := DayTask2;
                                    if resource."pool resource no." <> '' then
                                        TempDayTask2."Job Entry No." := 5
                                    else
                                        TempDayTask2."Job Entry No." := 2;
                                    if resource."Is Foreman" then
                                        TempDayTask2."Job Entry No." := 1;
                                    TempDayTask2.Description := resource.Name;
                                    TempDayTask2.Insert();
                                end;
                            else begin
                                TempDayTask1 := DayTask2;
                                if resource."Is Foreman" then
                                    TempDayTask1."Job Entry No." := 1
                                else
                                    TempDayTask1."Job Entry No." := 2;
                                TempDayTask1.Description := resource.Name;
                                TempDayTask1.Insert();
                            end;
                        end;
                    End;
                }


            }

            dataItem(Output; Integer)
            {
                dataitemtableview = sorting(Number) where(Number = filter(>= 1));
                Column(Number; Output.Number) { }

                Column(InternalLineNo; tempdaytask1."Day Line No.") { }
                Column(InternalNo; tempdaytask1."Assigned Resource No.") { }
                Column(InternalDescription; tempdaytask1.Description) { }
                Column(TimeAssigned1; Time1) { }
                column(Jobentryno1; tempdaytask1."Job Entry No.") { }


                Column(ExternalLineNo; tempdaytask2."Assigned Resource No.") { }
                Column(ExternalNo; tempdaytask2."Assigned Resource No.") { }
                Column(ExternalDescription; tempdaytask2.Description) { }
                Column(TimeAssigned2; Time2) { }
                column(Jobentryno2; tempdaytask2."Job Entry No.") { }

                trigger OnPreDataItem()
                begin
                    tempDayTask1.setcurrentkey("Job Entry No.", "Assigned Resource No.");
                    tempDayTask2.setcurrentkey("Job Entry No.", "Assigned Resource No.");
                end;

                trigger OnAfterGetRecord()
                begin
                    if output.Number = 1 then begin
                        eof1 := NOT TempDayTask1.FindSet();
                        eof2 := not TempDayTask2.FindSet();
                        // eof3 := NOT TempDayTask3.FindSet();
                        // eof4 := NOT TempDayTask4.FindSet();
                    end else begin
                        if not eof1 then
                            eof1 := TempDayTask1.Next() = 0;
                        if not eof2 then
                            eof2 := TempDayTask2.Next() = 0;
                        // if not eof3 then
                        //     eof3 := TempDayTask3.Next() = 0;
                        // if not eof4 then
                        //     eof4 := TempDayTask4.Next() = 0;
                    end;
                    if eof1 then
                        clear(tempDayTask1);
                    if eof2 then
                        clear(tempDayTask2);
                    // if eof3 then
                    //     clear(tempDayTask3);
                    // if eof4 then
                    //     clear(tempDayTask4);
                    if eof1 and eof2 then //and eof3 and eof4 then
                        currreport.Break();

                    Time1 := format(tempDayTask1."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>') + '..' + format(tempDayTask1."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>');
                    Time2 := format(tempDayTask2."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>') + '..' + format(tempDayTask2."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>');
                end;
            }


            trigger OnPreDataItem()
            begin
                // Set the date filter for the dataset based on user selection

            end;

            trigger OnAfterGetRecord()
            begin
                // Populate the dataset with necessary fields from related tables
                if not Job.Get(DayTask."Job No.") then
                    clear(Job);
                jobdescription := job."No." + ' ' + Job.Description;

                if not jobTask.Get(DayTask."Job No.", DayTask."Job Task No.") then
                    clear(jobTask);

                jobTaskDescription := ' - ' + jobTask."Job Task No." + ' ' + jobTask.Description;

                dayTask.SetRange("Job No.", DayTask."Job No.");
                dayTask.SetRange("Job Task No.", DayTask."Job Task No.");
                DateSelectionFilter := dayTask.GetFilter("Task Date");
                dayTask.SetRange("Task Date", DayTask."Task Date");
                daytask.FindLast();
                dayTask.SetRange("Job No.");
                dayTask.SetRange("Job Task No.");
                dayTask.Setfilter("Task Date", DateSelectionFilter);

                TempDayTask1.DeleteAll();
                TempDayTask2.DeleteAll();
                // TempDayTask3.DeleteAll();
                // TempDayTask4.DeleteAll();
            end;
        }
    }


    requestpage
    {
        AboutTitle = 'Day Task Details';
        AboutText = 'Select a date within the planning range to print the day task details.';

        layout
        {

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
            LayoutFile = 'src/report/50603 Day Task Detail/DayTaskDetailReport.rdlc';
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
        TempDayTask1: Record "Day Tasks" temporary;
        TempDayTask2: Record "Day Tasks" temporary;
        TempDayTask3: Record "Day Tasks" temporary;
        TempDayTask4: Record "Day Tasks" temporary;
        EOF1: Boolean;
        EOF2: Boolean;
        EOF3: Boolean;
        EOF4: Boolean;
        Time1, Time2 : Text;



    procedure SetDataViewDateRange(StartDatep: Date; EndDatep: Date)
    begin
        StartDate := StartDatep;
        EndDate := EndDatep;
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