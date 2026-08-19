table 50603 "PLanning Cue"
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
        field(10; "Projects"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count(Job where("Non Active" = filter(False)));
            Caption = 'Projects';
            Editable = false;
        }
        field(20; "Project Tasks"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Job Task" where("Non Active" = filter(False)));
            Caption = 'Project Tasks';
            Editable = false;
        }
        field(30; "Capacity (Today)"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Res. Capacity Entry".Capacity where(Date = field("Date Filter")));
            Caption = 'Capacity (Today)';
            Editable = false;
        }
        field(40; "Capacity (Tomorrow)"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Res. Capacity Entry".Capacity where(Date = field("Date Filter2")));
            Caption = 'Capacity (Tomorrow)';
            Editable = false;
        }
        field(100; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(110; "Date Filter2"; Date)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
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
        JobList: page "Opti Job List";
        rtv: Integer;
    begin


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

    /// <summary>
    /// Total Day Planning hours for ADate: per line, Assigned Hours when it's non-zero, else
    /// Requested Hours (a request with nothing assigned yet still counts toward the cue).
    /// Replaces the old "DayPlanning (Today)"/"(Tomorrow)" FlowFields, which only counted the
    /// number of Day Planning lines rather than their hours.
    /// </summary>
    procedure DayPlanningHours(ADate: Date): Decimal
    var
        DayPlanning: Record "Day Planning";
        TotalHours: Decimal;
    begin
        DayPlanning.SetRange("Plan Date", ADate);
        if DayPlanning.FindSet() then
            repeat
                if DayPlanning."Assigned Hours" <> 0 then
                    TotalHours += DayPlanning."Assigned Hours"
                else
                    TotalHours += DayPlanning."Requested Hours";
            until DayPlanning.Next() = 0;
        exit(TotalHours);
    end;
}