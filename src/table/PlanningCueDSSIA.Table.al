table 50603 "DDSIA PLanning Cue"
{
    Caption = 'PLanning Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        // field(10; "Projects"; Integer)
        // {
        //     FieldClass = FlowField;
        //     CalcFormula = count(Job where("Job View Type" = filter(Project)));
        //     Caption = 'Projects';
        //     Editable = false;
        // }
        // field(20; "Project Tasks"; Integer)
        // {
        //     FieldClass = FlowField;
        //     CalcFormula = count("Job Task" where("Job View Type" = filter(Project)));
        //     Caption = 'Project Tasks';
        //     Editable = false;
        // }
        // field(30; "Projects (Resource)"; Integer)
        // {
        //     FieldClass = FlowField;
        //     CalcFormula = count(Job where("Job View Type" = filter(Resource)));
        //     Caption = 'Projects (Resource)';
        //     Editable = false;
        // }
        // field(40; "Project Tasks (Resource)"; Integer)
        // {
        //     FieldClass = FlowField;
        //     CalcFormula = count("Job Task" where("Job View Type" = filter(Resource)));
        //     Caption = 'Project Tasks (Resource)';
        //     Editable = false;
        // }
        // field(50; "Date Filter"; Date)
        // {
        //     Caption = 'Date Filter';
        //     Editable = false;
        //     FieldClass = FlowFilter;
        // }
        // field(51; "Date Filter2"; Date)
        // {
        //     Caption = 'Date Filter2';
        //     Editable = false;
        //     FieldClass = FlowFilter;
        // }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    var
        myInt: Integer;

    procedure ProjectCount(ViewType: enum "Job View Type"; ViewDate: Date; LookupView: Boolean): Integer
    var
        Job: record Job;
        JobCheck: record Job;
        JPLine: record "Job Planning Line";
        JobList: page "Job List - Resource";
        rtv: Integer;
    begin
        JPLine.SetRange("Planning Date", ViewDate);
        JPLine.SetFilter("Job No.", '<>%1', '');
        if JPLine.FindSet() then
            repeat
                JobCheck.MarkedOnly := true;
                JobCheck.SetRange("No.", JPLine."Job No.");
                if not JobCheck.FindFirst() then begin
                    if JobCheck.Get(JPLine."Job No.") then
                        JobCheck.Mark(true);

                    Job.SetRange("No.", JPLine."Job No.");
                    Job.SetRange("Job View Type", ViewType);
                    if Job.FindSet() then
                        repeat
                            Job.Mark(true);
                        until Job.Next() = 0;
                end;
            until JPLine.Next() = 0;

        Job.SetRange("No.");
        Job.SetRange("Job View Type");
        Job.MarkedOnly := true;
        if Job.FindSet() then begin
            rtv := Job.Count();
            if LookupView then
                case ViewType of
                    ViewType::Project:
                        page.Run(0, Job);
                    ViewType::Resource:
                        begin
                            Clear(JobList);
                            JobList.SetTableView(Job);
                            JobList.Run();
                        end;
                end;
        end;
        exit(rtv);
    end;

    procedure TaskCount(ViewType: enum "Job View Type"; ViewDate: Date; LookupView: Boolean): Integer
    var
        JobTask: record "Job Task";
        JobTaskCheck: record "Job Task";
        JPLine: record "Job Planning Line";
        JobTaskList: page "Job Task List - Resource";
        rtv: Integer;
    begin
        JPLine.SetRange("Planning Date", ViewDate);
        JPLine.SetFilter("Job Task No.", '<>%1', '');
        if JPLine.FindSet() then
            repeat
                JobTaskCheck.MarkedOnly := true;
                JobTaskCheck.SetRange("Job No.", JPLine."Job No.");
                JobTaskCheck.SetRange("Job Task No.", JPLine."Job Task No.");
                if not JobTaskCheck.FindFirst() then begin
                    if JobTaskCheck.Get(JPLine."Job No.", JPLine."Job Task No.") then
                        JobTaskCheck.Mark(true);

                    JobTask.SetRange("Job No.", JPLine."Job No.");
                    JobTask.SetRange("Job Task No.", JPLine."Job Task No.");
                    JobTask.SetRange("Job View Type", ViewType);
                    if JobTask.FindSet() then
                        repeat
                            JobTask.Mark(true);
                        until JobTask.Next() = 0;
                end;
            until JPLine.Next() = 0;

        JobTask.SetRange("Job No.");
        JobTask.SetRange("Job Task No.");
        JobTask.SetRange("Job View Type");
        JobTask.MarkedOnly := true;
        if JobTask.FindSet() then begin
            rtv := JobTask.Count();
            if LookupView then
                case ViewType of
                    ViewType::Project:
                        page.Run(0, JobTask);
                    ViewType::Resource:
                        begin
                            Clear(JobTaskList);
                            JobTaskList.SetTableView(JobTask);
                            JobTaskList.Run();
                        end;
                end;
        end;
        exit(rtv);
    end;

    procedure PlanningLinesCount(ViewType: enum "Job View Type"; ViewDate: Date; LookupView: Boolean): Integer
    var
        JobTask: record "Job Task";
        JobTaskCheck: record "Job Task";
        JPLine: record "Job Planning Line";
        JobTaskList: page "Job Task List - Resource";
        rtv: Integer;
    begin
        JPLine.CalcFields("Job View Type");
        JPLine.SetRange("Planning Date", ViewDate);
        JPLine.SetRange("Job View Type", ViewType);
        if JPLine.FindSet() then begin
            rtv := JPLine.Count();
            if LookupView then
                case ViewType of
                    ViewType::Project:
                        page.Run(50615, JPLine);
                    ViewType::Resource:
                        page.Run(50616, JPLine);
                end;
        end;
        exit(rtv);
    end;

}