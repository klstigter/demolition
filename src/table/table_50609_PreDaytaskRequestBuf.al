/// <summary>
/// In-memory (temporary) buffer that holds all user-defined parameters for
/// a single "Generate pre Daytasks" request.  One record per invocation.
/// </summary>
table 50609 "Pre Daytask Request Buf."
{
    TableType = Temporary;
    Caption = 'Pre Daytask Request Buffer';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>Surrogate PK. Always 1 — one buffer record per dialog session.</summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }

        /// <summary>The Order Intake header document number this request targets.</summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }

        // ── General ────────────────────────────────────────────────────────────

        /// <summary>Default description copied to each generated line.</summary>
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        /// <summary>How many planning lines to create per scheduled date
        /// (one per resource slot).</summary>
        field(20; "No. of Resources"; Integer)
        {
            Caption = 'No. of Resources';
            DataClassification = CustomerContent;
            InitValue = 1;
            MinValue = 1;
        }

        /// <summary>Skill requirement applied to every generated line.</summary>
        field(25; Skill; Code[20])
        {
            Caption = 'Skill';
            DataClassification = CustomerContent;
            TableRelation = "Skill Code";
        }

        // ── Date range ─────────────────────────────────────────────────────────

        /// <summary>Start of the date range (From Date).</summary>
        field(40; "Start Date"; Date)
        {
            Caption = 'From Date';
            DataClassification = CustomerContent;
        }

        /// <summary>End of the date range (To Date, inclusive).</summary>
        field(41; "End Date"; Date)
        {
            Caption = 'To Date';
            DataClassification = CustomerContent;
        }

        // ── Recurrence ─────────────────────────────────────────────────────────

        /// <summary>The recurrence pattern applied to the date range.</summary>
        field(50; Recurrence; Enum "Pre Daytask Recurrence")
        {
            Caption = 'Recurrence';
            DataClassification = CustomerContent;
        }

        /// <summary>Interval multiplier for the recurrence pattern.
        /// 1 = every occurrence, 2 = every 2nd occurrence, etc.</summary>
        field(51; "Recurrence Interval"; Integer)
        {
            Caption = 'Recurrence Interval';
            DataClassification = CustomerContent;
            InitValue = 1;
            MinValue = 1;
        }

        // ── Weekday selection ──────────────────────────────────────────────────

        field(60; Monday; Boolean)
        {
            Caption = 'Monday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(61; Tuesday; Boolean)
        {
            Caption = 'Tuesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(62; Wednesday; Boolean)
        {
            Caption = 'Wednesday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(63; Thursday; Boolean)
        {
            Caption = 'Thursday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(64; Friday; Boolean)
        {
            Caption = 'Friday';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(65; Saturday; Boolean)
        {
            Caption = 'Saturday';
            DataClassification = CustomerContent;
        }
        field(66; Sunday; Boolean)
        {
            Caption = 'Sunday';
            DataClassification = CustomerContent;
        }

        // ── Work hours & calendar ──────────────────────────────────────────────

        /// <summary>Work-Hour Template to derive default start/end times.
        /// Validates automatically and populates Daytask Start/End.</summary>
        field(70; "Work-Hour Template"; Code[10])
        {
            Caption = 'Work-Hour Template';
            DataClassification = CustomerContent;
            TableRelation = "Work-Hour Template";

            trigger OnValidate()
            var
                WHTemplate: Record "Work-Hour Template";
            begin
                // Populate start/end time defaults from the selected template
                if WHTemplate.Get(Rec."Work-Hour Template") then begin
                    Rec."Daytask Start" := WHTemplate."Default Start Time";
                    Rec."Daytask End" := WHTemplate."Default End Time";
                end else begin
                    Rec."Daytask Start" := 0T;
                    Rec."Daytask End" := 0T;
                end;
            end;
        }

        /// <summary>Base Calendar used for non-working day and holiday validation.</summary>
        field(71; "Base Calendar"; Code[10])
        {
            Caption = 'Base Calendar';
            DataClassification = CustomerContent;
            TableRelation = "Base Calendar";
        }

        /// <summary>Planned start time for each generated line.
        /// Pre-populated from the Work-Hour Template.</summary>
        field(75; "Daytask Start"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }

        /// <summary>Planned end time for each generated line.
        /// Pre-populated from the Work-Hour Template.</summary>
        field(76; "Daytask End"; Time)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;
        }

        /// <summary>When true, any date identified as non-working by the Base Calendar
        /// is silently skipped rather than included.</summary>
        field(80; "Skip Non-Working Days"; Boolean)
        {
            Caption = 'Skip Non-Working Days';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
