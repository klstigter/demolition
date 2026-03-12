tableextension 50605 "Job Task ext" extends "Job Task"
{
    fields
    {

        field(50521; PlannedStartDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned Start Date';
            ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
                CalculateDuration();
            end;
        }
        field(50522; PlannedEndDate; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Planned End Date';
            ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
                CalculateDuration();
            end;
        }
        field(50523; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                //CalculateNonWorkingHours();
            end;
        }
        field(50524; "End Time"; Time)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckOverlap();
                //CalculateNonWorkingHours();
            end;
        }

        field(50025; "Scheduling Type"; Enum "SchedulingType")
        {
            DataClassification = ToBeClassified;
            Caption = 'Scheduling Type';
            ToolTip = 'Specifies the scheduling type for the project task. The scheduling type is based on the scheduling type on the related project planning line.';
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
            MinValue = 0;
        }

        field(50601; Progress; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Progress';
            MinValue = 0;
            MaxValue = 100;
        }

        field(50603; "Non Active"; Boolean)
        {
            DataClassification = ToBeClassified;
        }



        field(50660; Depth; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50670; IsBoor; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(50680; "Job View Type"; Enum "Job View Type")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Job"."Job View Type" where("No." = Field("Job No.")));
            Editable = false;
        }

        field(50690; "Total Assigned Hours"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Assigned Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No.")));
            BlankNumbers = BlankZero;
            Editable = false;
        }
        field(50700; "Total Day Taks"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Day Tasks" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No.")));
            BlankNumbers = BlankZero;
            Editable = false;
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
        Job: Record Job;

    procedure CalculateDuration()
    begin
        case "Scheduling Type" of
            schedulingType::FixedDuration:
                begin
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then begin
                        rec.Duration := 0;
                        exit
                    end;

                    if PlannedEndDate < PlannedStartDate then
                        error('Planned End Date cannot be before Planned Start Date!');

                    rec.Duration := "PlannedEndDate" - "PlannedStartDate" + 1;
                end;

            schedulingType::FixedUnits:
                begin
                    // Implement Fixed Units duration calculation if needed
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then
                        exit;

                    rec.Duration := "PlannedEndDate" - "PlannedStartDate";
                end;
            schedulingType::FixedWork:
                begin
                    if ("PlannedStartDate" = 0D) or ("PlannedEndDate" = 0D) then begin
                        rec.Duration := 0;
                        exit
                    end;

                    if PlannedEndDate < PlannedStartDate then
                        error('Planned End Date cannot be before Planned Start Date!');

                    rec.Duration := "PlannedEndDate" - "PlannedStartDate" + 1;

                end;
        end;
        if rec.Duration < 0 then
            error('Duration cannot be negative!');
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

    local procedure CheckOverlap()
    begin
        CheckOverlap(True);
    end;

    local procedure CheckOverlap(TryCreateDayLines: Boolean) HasOverlap: Boolean
    var
        DT: Date;
        DTstart: DateTime;
        DTend: DateTime;
    begin
        DTstart := 0DT;
        DTend := CreateDateTime(DMY2Date(31, 12, 2999), Time);

        if TryCreateDayLines then
            if (rec."PlannedStartDate" = 0D) or (rec."Start Time" = 0T)
                        or (rec."PlannedEndDate" = 0D) or (rec."End Time" = 0T) then
                error('Start and End Planning Date and Time must be set to create Day Lines!');

        if ("PlannedStartDate" <> 0D) and ("Start Time" <> 0T) then begin
            DT := "PlannedStartDate";
            DTstart := CreateDateTime(DT, "Start Time");
        end;
        if ("PlannedEndDate" <> 0D) and ("End Time" <> 0T) then begin
            DT := "PlannedEndDate";
            DTend := CreateDateTime(DT, "End Time");
        end;
        if DTstart > DTend then
            if not TryCreateDayLines then
                error('Datetime overlaped!')
            else begin
                exit(true);
            end;
    end;



    procedure StartEndLimitations(TryCreateDayLines: Boolean) hasOverlap: Boolean
    var
    begin
        GetJob();

        IF TryCreateDayLines THEN begin
            IF CheckOverlap(TryCreateDayLines) then begin
                StartEndLimitations(false); //try to fix
                exit(true);
            end;
        end else
            CheckOverlap(false);
        if TryCreateDayLines or (FieldNo("PlannedStartDate") = CurrFieldNo) then begin
            if (Job."Starting Date" <> 0D) and (Rec."PlannedStartDate" < job."Starting Date") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."PlannedStartDate" := job."Starting Date";
                if GuiAllowed then
                    Message('Start Planning Date adjusted to Job Starting Date limit.');
            end;
            if (job."Starting Date" <> 0D) and (job."Ending Date" < Rec."PlannedStartDate") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."PlannedStartDate" := job."Ending Date";
                if GuiAllowed then
                    Message('Start Planning Date adjusted to Job Ending Date limit.');
            end;
        end;
        if TryCreateDayLines or (FieldNo("PlannedEndDate") = CurrFieldNo) then begin
            if (job."Ending Date" <> 0D) and (Rec."PlannedEndDate" > job."Ending Date") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."PlannedEndDate" := job."Ending Date";
                if GuiAllowed then
                    Message('End Planning Date adjusted to Job Ending Date limit.');
            end;
            if (job."Ending Date" <> 0D) and (job."Starting Date" > Rec."PlannedEndDate") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."PlannedEndDate" := job."Starting Date";
                if GuiAllowed then
                    Message('End Planning Date adjusted to Job Starting Date limit.');
            end;
        end;
    end;

    local procedure GetJob()
    begin
        if job."No." <> Rec."Job No." then
            job.Get(Rec."Job No.");
    end;
}