tableextension 50605 "Job Task ext" extends "Job Task"
{
    fields
    {
        field(50510; "Constraint Type"; Enum "Gantt Constraint Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Type';
        }
        field(50511; "Constraint Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Date';
        }
        field(50512; "Constraint Is Hard"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Constraint Is Hard';
        }
        field(50513; "Deadline Date"; Date) // optional but recommended
        {
            DataClassification = ToBeClassified;
            Caption = 'Deadline Date';
        }

        // Add changes to table fields here

        field(50520; "Scheduling Type"; Enum schedulingType)
        {
            DataClassification = ToBeClassified;
            Caption = 'Scheduling Type';
        }
        field(50521; PlannedStartDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned Start Date';
            ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
        }
        field(50522; PlannedEndDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned End Date';
            ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
        }


        field(50530; "Estimated Hours"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Estimated Hours';
        }

        field(50531; "Duration"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Duration';
        }

        field(50600; "Job View Type"; Enum "Job View Type")
        {
            DataClassification = ToBeClassified;
        }
        field(50601; Progress; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Progress';
            MinValue = 0;
            MaxValue = 100;
        }
        field(50602; "Total Worked Hours"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Worked Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No.")));
            Caption = 'Total Worked Hours';
            Editable = false;
            DecimalPlaces = 0 : 2;
        }
        field(50603; "Non Active"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnAfterInsert()
    var
        Job: Record Job;
    begin
        if Job.Get(Rec."Job No.") then begin
            Rec."Job View Type" := Job."Job View Type";
            Rec.Modify();
        end;
    end;

    var
        DayTaskMgt: Codeunit "Day Tasks Mgt.";

    procedure CalculateDuration() CalcDuration: Integer
    begin
        case "Scheduling Type" of
            schedulingType::FixedDuration:
                begin
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then
                        exit(0);

                    CalcDuration := "PlannedEndDate" - "PlannedStartDate";

                    if CalcDuration < 0 then
                        CalcDuration := 0;
                end;
            schedulingType::FixedUnits:
                begin
                    // Implement Fixed Units duration calculation if needed
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then
                        exit(0);

                    CalcDuration := "PlannedEndDate" - "PlannedStartDate";

                    if CalcDuration < 0 then
                        CalcDuration := 0;
                end;
            schedulingType::FixedWork:
                begin
                    // Implement Fixed Work duration calculation if needed
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then
                        exit(0);

                    CalcDuration := "PlannedEndDate" - "PlannedStartDate";

                    if CalcDuration < 0 then
                        CalcDuration := 0;
                end;
        end;
    end;

    procedure CheckDataLimitations()
    var
        MinDayTaskDate: Date;
        MaxDayTaskDate: Date;
        JobStartDate: Date;
        JobEndDate: Date;
    begin
        DayTaskMgt.GetDateRange(Rec."Job No.", Rec."Job Task No.", MinDayTaskDate, MaxDayTaskDate);
        JobStartDate := 0D;
        JobEndDate := DMY2Date(31, 12, 2999);
        if ("PlannedStartDate" <> 0D) then begin
            JobStartDate := "PlannedStartDate";
        end;
        if ("PlannedEndDate" <> 0D) then begin
            JobEndDate := "PlannedEndDate";
        end;
        if HasOverlap(JobStartDate, JobEndDate) then
            error('Start en End Date overlaped!');
        if HasOverlap(JobStartDate, MinDayTaskDate) then
            error('Day Tasks exist before Planned Start Date!');
        if HasOverlap(MaxDayTaskDate, JobEndDate) then
            error('Day Tasks exist after Planned End Date!');
    end;

    local procedure HasOverlap(DTstart: Date; DTend: Date): Boolean
    begin
        if DTstart = 0D then
            exit(false);
        if DTend = 0D then
            exit(false);
        exit(DTstart > DTend);
    end;

}