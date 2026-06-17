report 50603 "Day Planning Details"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = DayPlanningReport;

    dataset
    {
        dataitem(DayPlanning; "Day Planning")
        {
            dataitemtableview = sorting("Job No.", "Job Task No.", "Task Date") where("plan status" = const(Inprogress));
            RequestFilterFields = "Task Date", "Job No.", "Job Task No.";

            column(JobNo; JobDescription)
            {
                Caption = 'Job No.';
            }
            column(JobTaskNo; JobTaskDescription)
            {
                Caption = 'Job Task No.';
            }
            column(TaskDate; DayPlanning."Task Date")
            {
                Caption = 'Task Date';
            }
            dataitem(Integer; "Integer")
            {
                dataitemtableview = sorting(Number) where(Number = const(1));
                dataitem(DayPlanning2; "Day Planning")
                {
                    DataItemLinkReference = DayPlanning;
                    DataItemLink = "Job No." = field("Job No.")
                    , "Job Task No." = field("Job Task No.")
                    , "Task Date" = field("Task Date");

                    trigger OnAfterGetRecord()
                    var
                        DateFilter: Text;
                        ColumnNo: Integer;
                    begin

                        if not resource.Get(DayPlanning2."Assigned Resource No.") then
                            clear(resource);
                        Case true of
                            resource."Is Pool":
                                begin
                                    TempDayPlanning2 := DayPlanning2;
                                    TempDayPlanning2."Job Entry No." := 4;
                                    TempDayPlanning2.Description := resource.Name;
                                    TempDayPlanning2.Insert(true);
                                end;
                            resource."Is Pool Member":
                                begin
                                    TempDayPlanning2 := DayPlanning2;
                                    if resource."pool resource no." <> '' then
                                        TempDayPlanning2."Job Entry No." := 5
                                    else
                                        TempDayPlanning2."Job Entry No." := 2;
                                    if resource."Is Foreman" then
                                        TempDayPlanning2."Job Entry No." := 1;
                                    TempDayPlanning2.Description := resource.Name;
                                    TempDayPlanning2.Insert(true);
                                end;
                            else begin
                                TempDayPlanning1 := DayPlanning2;
                                if resource."Is Foreman" then
                                    TempDayPlanning1."Job Entry No." := 1
                                else
                                    TempDayPlanning1."Job Entry No." := 2;
                                TempDayPlanning1.Description := resource.Name;
                                TempDayPlanning1.Insert(true);
                            end;
                        end;
                    End;
                }
            }

            dataItem(Output; Integer)
            {
                dataitemtableview = sorting(Number) where(Number = filter(>= 1));
                Column(Number; Output.Number) { }

                Column(InternalLineNo; tempDayPlanning1."Day Line No.") { }
                Column(InternalNo; tempDayPlanning1."Assigned Resource No.") { }
                Column(InternalDescription; tempDayPlanning1.Description) { }
                Column(TimeAssigned1; Time1) { }
                column(Jobentryno1; tempDayPlanning1."Job Entry No.") { }


                Column(ExternalLineNo; tempDayPlanning2."Assigned Resource No.") { }
                Column(ExternalNo; tempDayPlanning2."Assigned Resource No.") { }
                Column(ExternalDescription; tempDayPlanning2.Description) { }
                Column(TimeAssigned2; Time2) { }
                column(Jobentryno2; tempDayPlanning2."Job Entry No.") { }

                trigger OnPreDataItem()
                begin
                    tempDayPlanning1.setcurrentkey("Job Entry No.", "Assigned Resource No.");
                    tempDayPlanning2.setcurrentkey("Job Entry No.", "Assigned Resource No.");
                end;

                trigger OnAfterGetRecord()
                begin
                    if output.Number = 1 then begin
                        eof1 := NOT TempDayPlanning1.FindSet();
                        eof2 := not TempDayPlanning2.FindSet();
                        // eof3 := NOT TempDayPlanning3.FindSet();
                        // eof4 := NOT TempDayPlanning4.FindSet();
                    end else begin
                        if not eof1 then
                            eof1 := TempDayPlanning1.Next() = 0;
                        if not eof2 then
                            eof2 := TempDayPlanning2.Next() = 0;
                        // if not eof3 then
                        //     eof3 := TempDayPlanning3.Next() = 0;
                        // if not eof4 then
                        //     eof4 := TempDayPlanning4.Next() = 0;
                    end;
                    if eof1 then
                        clear(tempDayPlanning1);
                    if eof2 then
                        clear(tempDayPlanning2);
                    // if eof3 then
                    //     clear(tempDayPlanning3);
                    // if eof4 then
                    //     clear(tempDayPlanning4);
                    if eof1 and eof2 then //and eof3 and eof4 then
                        currreport.Break();

                    Time1 := format(tempDayPlanning1."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>') + '..' + format(tempDayPlanning1."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>');
                    Time2 := format(tempDayPlanning2."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>') + '..' + format(tempDayPlanning2."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>');
                end;
            }


            trigger OnPreDataItem()
            begin
                // Set the date filter for the dataset based on user selection

            end;

            trigger OnAfterGetRecord()
            begin
                // Populate the dataset with necessary fields from related tables
                if not Job.Get(DayPlanning."Job No.") then
                    clear(Job);
                jobdescription := job."No." + ' ' + Job.Description;

                if not jobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                    clear(jobTask);

                jobTaskDescription := ' - ' + jobTask."Job Task No." + ' ' + jobTask.Description;

                DayPlanning.SetRange("Job No.", DayPlanning."Job No.");
                DayPlanning.SetRange("Job Task No.", DayPlanning."Job Task No.");
                DateSelectionFilter := DayPlanning.GetFilter("Task Date");
                DayPlanning.SetRange("Task Date", DayPlanning."Task Date");
                DayPlanning.FindLast();
                DayPlanning.SetRange("Job No.");
                DayPlanning.SetRange("Job Task No.");
                DayPlanning.Setfilter("Task Date", DateSelectionFilter);

                TempDayPlanning1.DeleteAll();
                TempDayPlanning2.DeleteAll();
                // TempDayPlanning3.DeleteAll();
                // TempDayPlanning4.DeleteAll();
            end;
        }
    }


    requestpage
    {
        AboutTitle = 'Day Planning Details';
        AboutText = 'Select a date within the planning range to print the day Planning details.';

        layout
        {

        }


    }

    rendering
    {
        layout(DayPlanningReport)
        {
            Type = Rdlc;
            LayoutFile = 'src/report/50603 Day Planning Detail/DayPlanningDetailReport.rdlc';
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
        TempDayPlanning1: Record "Day Planning" temporary;
        TempDayPlanning2: Record "Day Planning" temporary;
        TempDayPlanning3: Record "Day Planning" temporary;
        TempDayPlanning4: Record "Day Planning" temporary;
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
        Resource."Is Pool Member" := IsExternal;
        Resource."Is Pool" := IsPool;
        Resource."Is Foreman" := IsForeman;

        Resource.Insert(true);
    end;
}