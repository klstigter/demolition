tableextension 50605 "Opti Job Task" extends "Job Task"
{
    fields
    {
        field(50500; "Opti Project Manager"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Project Manager';
            ToolTip = 'Specifies the person who is assigned to manage the project task.';
            tableRelation = "User Setup";
        }

        field(50505; "Opti Work Hour Template"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Hour Template';
            TableRelation = "Work-Hour Template";
        }

        #region Transfer from Work Order

        field(50509; "Opti Long Description"; blob)
        {
            Caption = 'Long Description';
            DataClassification = CustomerContent;
        }

        field(50511; "Opti Deadline Date"; Date) //Transfer from Work Order
        {
            Caption = 'Deadline Date';
            DataClassification = CustomerContent;
        }

        field(50512; "Opti Placeholder Date"; Date) //Transfer from Work Order
        {
            Caption = 'Placeholder Date';
            DataClassification = CustomerContent;
        }

        field(50513; "Opti Closed"; Boolean) //Transfer from Work Order
        {
            Caption = 'Closed';
            DataClassification = CustomerContent;
        }

        field(50514; "Opti Closed Date"; Date) //Transfer from Work Order
        {
            Caption = 'Closed Date';
            DataClassification = CustomerContent;
        }

        field(50515; "Opti Closed Reason Code"; Code[20]) //Transfer from Work Order
        {
            Caption = 'Closed Reason Code';
            DataClassification = CustomerContent;
        }

        #endregion

        field(50521; "Opti VisualBarStartDate"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Visual Bar Start Date';
            ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
                OptiCalculateDuration();
                // Deliberately NOT wired to DayPlanningPeriodSyncMgt.HandleJobTaskPeriodChange here.
                // "Visual Bar Start Date"/"Visual Bar End Date" are Editable = false on page 50618 "Opti
                // Job Task Card" — the only user-facing way to change them from the Card is the
                // AssistEdit action, which runs report 50601 "Job Task Visual Bar Date Updater". That
                // report already calls DayPlanningPeriodSyncMgt.ShowPreview() itself on OnPostReport
                // and assigns the new dates via direct field assignment (not Validate()), so the
                // Job Task Card period-change path is already fully wired without this trigger.
                // Re-enabling this call would ALSO fire for the two other call sites that DO call
                // .Validate(VisualBarEndDate/VisualBarStartDate, ...) directly: the former demo data generator
                // (bulk/unattended generation) and codeunit_50610_DayPlanningMgt's own
                // CreateDayPlanning (pattern-driven Job Task end-date sync, called right after the
                // Day Planning lines it derives dates from were just generated) — both would then
                // unexpectedly pop up the blocking preview dialog for what are internal housekeeping
                // updates, not a user-initiated period change. Leave commented out.
                // if not DayPlanningPeriodSyncMgt.HandleJobTaskPeriodChange(Rec, xRec.VisualBarStartDate, xRec.PlannedEndDate, true) then begin
                //     Rec.VisualBarStartDate := xRec.VisualBarStartDate;
                //     Rec.Duration := xRec.Duration;
                // end;
            end;
        }
        field(50522; "Opti VisualBarEndDate"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Visual Bar End Date';
            ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
            trigger OnValidate()
            begin
                OptiCalculateDuration();
                // See the matching comment on VisualBarStartDate's OnValidate above — same reasoning.
                // if not DayPlanningPeriodSyncMgt.HandleJobTaskPeriodChange(Rec, xRec.VisualBarStartDate, xRec.VisualBarEndDate, true) then begin
                //     Rec.VisualBarEndDate := xRec.VisualBarEndDate;
                //     Rec.Duration := xRec.Duration;
                //     if GuiAllowed then
                //         Message('Period change was cancelled. Visual Bar Start and End Date reverted to %1 - %2', Rec.VisualBarStartDate, Rec.VisualBarEndDate);
                // end;
            end;
        }
        field(50523; "Opti Start Time"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckOverlap();
                //CalculateNonWorkingHours();
            end;
        }
        field(50524; "Opti End Time"; Time)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckOverlap();
                //CalculateNonWorkingHours();
            end;
        }

        field(50025; "Opti Scheduling Type"; Enum "Opti schedulingType")
        {
            DataClassification = CustomerContent;
            Caption = 'Scheduling Type';
            ToolTip = 'Specifies the scheduling type for the project task. The scheduling type is based on the scheduling type on the related project planning line.';
        }
        field(50530; "Opti Estimated Hours"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Estimated Hours';
        }

        field(50531; "Opti Duration"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Duration';
            MinValue = 0;

            trigger OnValidate()
            var
                durationTxt: Text;
                durationLbl: Label '<%1D>', Comment = '%1 = value';
            begin
                if ("Opti VisualBarStartDate" <> 0D) and ("Opti Duration" >= 1) then begin
                    if "Opti Duration" = 1 then
                        "Opti VisualBarEndDate" := "Opti VisualBarStartDate"
                    else begin
                        durationTxt := StrSubstNo(durationLbl, "Opti Duration" - 1);
                        "Opti VisualBarEndDate" := CalcDate(durationTxt, "Opti VisualBarStartDate");
                    end;
                end else
                    "Opti Duration" := 0;
            end;
        }

        field(50601; "Opti Progress"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Progress (%)';
            MinValue = 0;
            MaxValue = 100;
        }

        field(50603; "Opti Non Active"; Boolean)
        {
            Caption = 'Non Active';
            DataClassification = CustomerContent;
        }

        field(50620; "Opti Constraint Type"; Enum "Opti Job Task Constraint Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Planning Constraint Type';
            ToolTip = 'Specifies the scheduling constraint (ASAP, ALAP, SNET, SNLT, etc.) for the planning engine.';
            InitValue = ASAP;

            trigger OnValidate()
            begin
                UpdateConstraintCalcDates();
            end;
        }
        field(50621; "Opti Constraint Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Planning Constraint Date';
            ToolTip = 'Specifies the date associated with the selected planning constraint type.';

            trigger OnValidate()
            begin
                UpdateConstraintCalcDates();
            end;
        }
        field(50622; "Opti Max Duration"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Max Duration (Days)';
            ToolTip = 'Specifies the maximum duration for the project task.';

            trigger OnValidate()
            begin
                UpdateConstraintCalcDates();
            end;
        }
        field(50623; "Opti Constraint Calc Start"; Date)
        {
            Caption = 'Constraint Calc. - Start Date';
            DataClassification = CustomerContent;
        }
        field(50624; "Opti Constraint Calc End"; Date)
        {
            Caption = 'Constraint Calc. - End Date';
            DataClassification = CustomerContent;
        }

        field(50660; "Opti Depth"; Decimal)
        {
            Caption = 'Depth';
            DataClassification = CustomerContent;
        }
        field(50670; "Opti IsBoor"; Boolean)
        {
            Caption = 'IsBoor';
            DataClassification = CustomerContent;
        }

        field(50680; "Opti Job View Type"; Enum "Opti Job View Type")
        {
            Caption = 'Job View Type';
            FieldClass = FlowField;
            CalcFormula = lookup("Job"."Opti Job View Type" where("No." = Field("Job No.")));
            Editable = false;
        }

        field(50690; "Opti Total Assigned Hours"; Decimal)
        {
            Caption = 'Total Assigned Hours';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Day Planning"."Assigned Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Plan Date" = field("Planning Date Filter")));
            BlankNumbers = BlankZero;
            Editable = false;
        }
        field(50691; "Opti Total Requested Hours"; Decimal)
        {
            Caption = 'Total Requested Hours';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Day Planning"."Requested Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Plan Date" = field("Planning Date Filter")));
            BlankNumbers = BlankZero;
            Editable = false;
        }
        field(50692; "Opti Total Realized Hours"; Decimal)
        {
            Caption = 'Total Realized Hours';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Day Planning"."Realized Hours" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Plan Date" = field("Planning Date Filter")));
            BlankNumbers = BlankZero;
            Editable = false;
        }
        field(50700; "Opti Total Day Plannings"; Integer)
        {
            Caption = 'Total Day Plannings';
            FieldClass = FlowField;
            CalcFormula = count("Opti Day Planning" where("Job No." = field("Job No."), "Job Task No." = field("Job Task No."), "Plan Date" = field("Planning Date Filter")));
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
            Rec."Opti Job View Type" := Job."Opti Job View Type";
            Rec.Modify();
        end;
    end;

    var
        DayPlanningMgt: Codeunit "Opti Day Plannings Mgt.";
        // DayPlanningPeriodSyncMgt: Codeunit "DayPlanning Period Sync Mgt.";
        Job: Record Job;

    /// <summary>
    /// Recalculates "Duration" as the inclusive calendar-day count between PlannedStartDate and
    /// PlannedEndDate. This intentionally applies to every "Scheduling Type" value - the case
    /// statement this replaced only had FixedDuration/FixedWork branches, both with byte-for-byte
    /// identical bodies, and no fallback - so any other value (e.g. FixedUnits, which has never
    /// been implemented here or in codeunit 50613's GetSchedulingTypeText) silently left Duration
    /// stale (never recalculated) instead of erroring or defaulting. That was a real stale-data
    /// bug, not just a missing feature: report 50600's RepairJobTaskPlannedPeriodOnAllJobTasks
    /// widened a Job Task's PlannedEndDate but Duration never moved, because that Job Task's
    /// Scheduling Type fell through this case with no matching branch. If a future Scheduling Type
    /// genuinely needs different Duration semantics, branch on "Scheduling Type" here explicitly -
    /// but don't reintroduce a case with no fallback, since that's exactly how this bug happened.
    /// </summary>
    procedure OptiCalculateDuration()
    begin
        if ("Opti VisualBarStartDate" = 0D) or ("Opti VisualBarEndDate" = 0D) then begin
            rec."Opti Duration" := 0;
            exit;
        end;
        if "Opti VisualBarEndDate" < "Opti VisualBarStartDate" then
            error('Planned End Date cannot be before Planned Start Date!');

        rec."Opti Duration" := "Opti VisualBarEndDate" - "Opti VisualBarStartDate" + 1;
        if rec."Opti Duration" < 0 then
            error('Duration cannot be negative!');
    end;

    /// <summary>
    /// Recalculates and persists "Constraint Calc. - Start Date"/"Constraint Calc. - End Date"
    /// from "Constraint Type"/"Constraint Date"/"Max Duration" - called from each of those three
    /// fields' OnValidate trigger so the calc fields never go stale relative to their inputs.
    /// Finish-anchored types (ALAP, FNET, FNLT, MFO) anchor on Finish = Constraint Date and compute
    /// Start backward; start-anchored types (ASAP, SNET, SNLT, MSO) anchor on Start = Constraint
    /// Date and compute Finish forward. Left blank (0D/0D) when Constraint Date or Max Duration
    /// isn't populated - "Constraint Type" always has a value (InitValue = ASAP), so it's not a
    /// reliable "is a constraint populated" signal on its own.
    /// </summary>
    local procedure UpdateConstraintCalcDates()
        var
            D2Txt: Label '<-%1D>', Comment = '%1=Rec.Max Duration - 1';
            DTxt: Label '<+%1D>', Comment = '%1=Rec.Max Duration - 1';
    begin
        Rec."Opti Constraint Calc Start" := 0D;
        Rec."Opti Constraint Calc End" := 0D;
        if (Rec."Opti Constraint Date" = 0D) or (Rec."Opti Max Duration" <= 0) then
            exit;
        case Rec."Opti Constraint Type" of
            Rec."Opti Constraint Type"::ALAP,
            Rec."Opti Constraint Type"::FNET,
            Rec."Opti Constraint Type"::FNLT,
            Rec."Opti Constraint Type"::MFO:
                begin
                    Rec."Opti Constraint Calc End" := Rec."Opti Constraint Date";
                    Rec."Opti Constraint Calc Start" := CalcDate(StrSubstNo(D2Txt, Rec."Opti Max Duration" - 1), Rec."Opti Constraint Calc End");
                end;
            Rec."Opti Constraint Type"::ASAP,
            Rec."Opti Constraint Type"::SNET,
            Rec."Opti Constraint Type"::SNLT,
            Rec."Opti Constraint Type"::MSO:
                begin
                    Rec."Opti Constraint Calc Start" := Rec."Opti Constraint Date";
                    Rec."Opti Constraint Calc End" := CalcDate(StrSubstNo(DTxt, Rec."Opti Max Duration" - 1), Rec."Opti Constraint Calc Start");
                end;
        end;
    end;

    procedure OptiCheckDataLimitations()
    var
        MinDayPlanningDate: Date;
        MaxDayPlanningDate: Date;
        JobStartDate: Date;
        JobEndDate: Date;
        Err01Lbl: Label 'Start en End Date overlaped!';
        Err02Lbl: Label 'Day Plannings exist before Planned Start Date!';
        Err03Lbl: Label 'Day Plannings exist after Planned End Date!';
    begin
        DayPlanningMgt.GetDateRange(Rec."Job No.", Rec."Job Task No.", MinDayPlanningDate, MaxDayPlanningDate);
        JobStartDate := 0D;
        JobEndDate := DMY2Date(31, 12, 2999);
        if ("Opti VisualBarStartDate" <> 0D) then begin
            JobStartDate := "Opti VisualBarStartDate";
        end;
        if ("Opti VisualBarEndDate" <> 0D) then begin
            JobEndDate := "Opti VisualBarEndDate";
        end;
        if HasOverlap(JobStartDate, JobEndDate) then
            error(Err01Lbl);
        if HasOverlap(JobStartDate, MinDayPlanningDate) then
            error(Err02Lbl);
        if HasOverlap(MaxDayPlanningDate, JobEndDate) then
            error(Err03Lbl);
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
            if (rec."Opti VisualBarStartDate" = 0D) or (rec."Opti Start Time" = 0T)
                        or (rec."Opti VisualBarEndDate" = 0D) or (rec."Opti End Time" = 0T) then
                error('Start and End Planning Date and Time must be set to create Day Lines!');
        if ("Opti VisualBarStartDate" <> 0D) and ("Opti Start Time" <> 0T) then begin
            DT := "Opti VisualBarStartDate";
            DTstart := CreateDateTime(DT, "Opti Start Time");
        end;
        if ("Opti VisualBarEndDate" <> 0D) and ("Opti End Time" <> 0T) then begin
            DT := "Opti VisualBarEndDate";
            DTend := CreateDateTime(DT, "Opti End Time");
        end;
        if DTstart > DTend then
            if not TryCreateDayLines then
                error('Datetime overlaped!')
            else begin
                exit(true);
            end;
    end;



    procedure OptiStartEndLimitations(TryCreateDayLines: Boolean) hasOverlap: Boolean
    var
        StartPlanningDateAdjuste2Msg: Label 'Start Planning Date adjusted to Job Starting Date limit.';
        StartPlanningDateAdjusteMsg: Label 'Start Planning Date adjusted to Job Ending Date limit.';
        EndPlanningDateAdjustedT2Msg: Label 'End Planning Date adjusted to Job Ending Date limit.';
        EndPlanningDateAdjustedTMsg: Label 'End Planning Date adjusted to Job Starting Date limit.';
    begin
        GetJob();
        IF TryCreateDayLines THEN begin
            IF CheckOverlap(TryCreateDayLines) then begin
                OptiStartEndLimitations(false); //try to fix
                exit(true);
            end;
        end else
            CheckOverlap(false);
        if TryCreateDayLines or (FieldNo("Opti VisualBarStartDate") = CurrFieldNo) then begin
            if (Job."Starting Date" <> 0D) and (Rec."Opti VisualBarStartDate" < job."Starting Date") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."Opti VisualBarStartDate" := job."Starting Date";
                if GuiAllowed then
                    Message(StartPlanningDateAdjuste2Msg);
            end;
            if (job."Starting Date" <> 0D) and (job."Ending Date" < Rec."Opti VisualBarStartDate") then begin
                if TryCreateDayLines then
                    error('Start Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."Opti VisualBarStartDate" := job."Ending Date";
                if GuiAllowed then
                    Message(StartPlanningDateAdjusteMsg);
            end;
        end;
        if TryCreateDayLines or (FieldNo("Opti VisualBarEndDate") = CurrFieldNo) then begin
            if (job."Ending Date" <> 0D) and (Rec."Opti VisualBarEndDate" > job."Ending Date") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be later than Job Ending Date %1', job."Ending Date");
                Rec."Opti VisualBarEndDate" := job."Ending Date";
                if GuiAllowed then
                    Message(EndPlanningDateAdjustedT2Msg);
            end;
            if (job."Ending Date" <> 0D) and (job."Starting Date" > Rec."Opti VisualBarEndDate") then begin
                if TryCreateDayLines then
                    error('End Planning Date cannot be earlier than Job Starting Date %1', job."Starting Date");
                Rec."Opti VisualBarEndDate" := job."Starting Date";
                if GuiAllowed then
                    Message(EndPlanningDateAdjustedTMsg);
            end;
        end;
    end;

    local procedure GetJob()
    begin
        if job."No." <> Rec."Job No." then
            job.Get(Rec."Job No.");
    end;

    procedure OptiGetNextCustomerTaskNo(CustNo: Code[20]): Code[20]
    var
        JobTaskRec: Record "Job Task";
        CstN: Code[14];
    begin
        JobTaskRec.SetRange("Job No.", CustNo);
        if JobTaskRec.FindLast() then
            exit(IncStr(JobTaskRec."Job Task No."))
        else begin
            CstN := CopyStr(CustNo, 1, 14);
            exit(CstN + '-0001'); //become error if there is record -10, because FindLast record is -9 (not -10), and increament will be -10 which is conflict with existing record.
        end;
    end;

    procedure OptiSetDescription(pDescBody: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Opti Long Description".CreateOutStream(OutStream);
        OutStream.WriteText(pDescBody);
        Rec.Modify();
    end;

    procedure OptiGetDescription(): Text
    var
        InStream: InStream;
        DescText: Text;
    begin
        DescText := '';
        Rec.CalcFields("Opti Long Description");
        if Rec."Opti Long Description".HasValue() then begin
            Rec."Opti Long Description".CreateInStream(InStream);
            InStream.ReadText(DescText);
        end;
        exit(DescText);
    end;
}