/// <summary>
/// Generate Pre Daytasks dialog (Page 50657)
///
/// StandardDialog popup opened from the "Generate pre Daytasks" action on
/// the Order Intake Card (page 50655).
///
/// Responsibilities (page only):
///   • Collect scheduling parameters from the user (From Date, To Date, weekdays, recurrence).
///   • Pre-populate defaults from "Daily Optimizer Setup" (table 50605).
///   • Validate required fields on OK via codeunit 50617.
///   • Hand off the completed request buffer to the caller.
///
/// Caller pattern:
///   var
///       GenerateDlg : Page "Generate Pre Daytasks";
///       RequestBuf  : Record "Pre Daytask Request Buf.";
///   begin
///       GenerateDlg.SetContext(Rec."No.", Rec.Description);
///       if GenerateDlg.RunModal() = Action::OK then begin
///           GenerateDlg.GetRequestBuffer(RequestBuf);
///           PreDaytaskGen.GenerateLines(RequestBuf, Rec."No.");
///       end;
///   end;
/// </summary>
page 50657 "Generate Pre Daytasks"
{
    PageType = StandardDialog;
    Caption = 'Generate Pre Daytasks';
    SourceTable = "Pre Daytask Request Buf.";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            // ── General ────────────────────────────────────────────────────
            group(grpGeneral)
            {
                Caption = 'General';

                field(fldDescription; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description copied to each generated Daytask planning line.';
                }
                field(fldNoOfResources; Rec."No. of Resources")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many planning lines to create per scheduled date (one per resource slot).';
                }
                field(fldSkill; Rec.Skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code applied to every generated line.';
                }
            }

            // ── Scheduling ─────────────────────────────────────────────────
            group(grpScheduling)
            {
                Caption = 'Scheduling';

                field(fldStartDate; Rec."Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'From Date';
                    ToolTip = 'Specifies the first date of the generation range.';
                }
                field(fldEndDate; Rec."End Date")
                {
                    ApplicationArea = All;
                    Caption = 'To Date';
                    ToolTip = 'Specifies the last date of the generation range (inclusive).';
                }

                field(fldRecurrence; Rec.Recurrence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recurrence pattern: Daily, Weekly, or Monthly.';
                }
                field(fldRecurrenceInterval; Rec."Recurrence Interval")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interval multiplier for the recurrence pattern. For example, 2 with Weekly means every 2nd week.';
                }
            }

            // ── Work Days ──────────────────────────────────────────────────
            group(grpWorkDays)
            {
                Caption = 'Work Days';

                field(fldMonday; Rec.Monday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Mondays in the generation.';
                }
                field(fldTuesday; Rec.Tuesday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Tuesdays in the generation.';
                }
                field(fldWednesday; Rec.Wednesday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Wednesdays in the generation.';
                }
                field(fldThursday; Rec.Thursday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Thursdays in the generation.';
                }
                field(fldFriday; Rec.Friday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Fridays in the generation.';
                }
                field(fldSaturday; Rec.Saturday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Saturdays in the generation.';
                }
                field(fldSunday; Rec.Sunday)
                {
                    ApplicationArea = All;
                    ToolTip = 'Include Sundays in the generation.';
                }
            }

            // ── Work Hours & Calendar ──────────────────────────────────────
            group(grpWorkHours)
            {
                Caption = 'Work Hours & Calendar';

                field(fldWorkHourTemplate; Rec."Work-Hour Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work-hour template used to derive default start and end times.';

                    trigger OnValidate()
                    begin
                        // Rec.OnValidate already populates start/end times;
                        // refresh the page to show the updated values.
                        CurrPage.Update(false);
                    end;
                }
                field(fldBaseCalendar; Rec."Base Calendar")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base calendar used to identify non-working days and public holidays.';
                }
                field(fldDaytaskStart; Rec."Daytask Start")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planned start time for each generated line. Pre-populated from the Work-Hour Template.';
                }
                field(fldDaytaskEnd; Rec."Daytask End")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planned end time for each generated line. Pre-populated from the Work-Hour Template.';
                }
                field(fldSkipNonWorking; Rec."Skip Non-Working Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'When enabled, dates marked as non-working in the Base Calendar are automatically skipped.';
                }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Page variables
    // ──────────────────────────────────────────────────────────────────────────

    var
        /// Context set by the caller before RunModal().
        DocNoCtx: Code[20];
        HeaderDescCtx: Text[250];

    // ──────────────────────────────────────────────────────────────────────────
    // Context setter & getter (called by the Order Intake Card action)
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Must be called BEFORE RunModal().
    /// Stores the header context so OnOpenPage can initialise the buffer record.
    /// </summary>
    procedure SetContext(DocNo: Code[20]; HeaderDesc: Text[250])
    begin
        DocNoCtx := DocNo;
        HeaderDescCtx := HeaderDesc;
    end;

    /// <summary>
    /// Must be called AFTER RunModal() = Action::OK.
    /// Returns the completed request buffer to the caller for processing.
    /// </summary>
    procedure GetRequestBuffer(var RequestBuf: Record "Pre Daytask Request Buf.")
    begin
        RequestBuf := Rec;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Page triggers
    // ──────────────────────────────────────────────────────────────────────────

    trigger OnOpenPage()
    var
        Setup: Record "Daily Optimizer Setup";
    begin
        // Initialise the single temp buffer record
        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Document No." := DocNoCtx;
        Rec.Description := CopyStr(HeaderDescCtx, 1, MaxStrLen(Rec.Description));

        // Sensible defaults
        Rec."No. of Resources" := 1;
        Rec."Recurrence Interval" := 1;
        Rec."Skip Non-Working Days" := true;

        // Default to Mon-Fri selected
        Rec.Monday := true;
        Rec.Tuesday := true;
        Rec.Wednesday := true;
        Rec.Thursday := true;
        Rec.Friday := true;

        // Load defaults from Daily Optimizer Setup (table 50605)
        if Setup.Get() then begin
            Rec."Work-Hour Template" := Setup."Work hour Template";
            Rec."Base Calendar" := Setup."Base Calendar";

            // Populate start/end times from the work-hour template
            if Rec."Work-Hour Template" <> '' then
                Rec.Validate("Work-Hour Template");
        end;

        Rec.Insert();
    end;

    /// <summary>
    /// Pre-validate required fields before the dialog closes with OK.
    /// Detailed business-logic validation is deferred to codeunit 50613.
    /// </summary>
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PreDaytaskGen: Codeunit "Pre Daytask Generator";
    begin
        if CloseAction = Action::OK then
            PreDaytaskGen.ValidateRequest(Rec);
        exit(true);
    end;

}
