/// <summary>
/// Generic Job No. / Job Task No. filter popup (Page 50681)
///
/// StandardDialog shared by any page that needs a quick Job/Job Task filter picker,
/// opened from a (▽) filter icon on a JS timeline toolbar. Currently used by:
///   - Page 50621 "DHX Scheduler (Project)" (wrapper.js's setupFilterToolbar()/OnFilterIconClick)
///   - Page 50620 "Gantt Demo DHX 2" (ganttdemo2/wrapper.js's OnGanttFilterIconClick)
/// Lets the user pick a Job No. and a Job Task No. to filter by.
///
/// Caller pattern:
///   var
///       FilterDlg  : Page "Task Scheduler Filter";
///       NewJobNo   : Code[20];
///       NewJobTaskNo: Code[20];
///   begin
///       FilterDlg.SetFilter(jobFilter, JobTaskFilter);
///       if FilterDlg.RunModal() = Action::OK then begin
///           FilterDlg.GetFilter(NewJobNo, NewJobTaskNo);
///           jobFilter := NewJobNo;
///           JobTaskFilter := NewJobTaskNo;
///           RefreshSchedule();
///       end;
///   end;
/// </summary>
page 50681 "Task Scheduler Filter"
{
    PageType = StandardDialog;
    Caption = 'Filter by Job / Job Task';
    SourceTable = "Task Scheduler Filter Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(fldJobNo; Rec."Job No.")
            {
                ApplicationArea = All;
                Caption = 'Job No.';
                ToolTip = 'Specifies the job to filter the Task Scheduler by.';
            }
            field(fldJobTaskNo; Rec."Job Task No.")
            {
                ApplicationArea = All;
                Caption = 'Job Task No.';
                ToolTip = 'Specifies the job task to filter the Task Scheduler by. Requires a Job No. to be specified first.';

                trigger OnValidate()
                begin
                    CheckJobNoSpecified();
                end;
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Page variables
    // ──────────────────────────────────────────────────────────────────────────

    var
        /// Context set by the caller before RunModal() — used to pre-fill the dialog.
        JobNoCtx: Code[20];
        JobTaskNoCtx: Code[20];
        JobNoRequiredErr: Label 'Job No. must be specified before Job Task No.';

    // ──────────────────────────────────────────────────────────────────────────
    // Context setter & getter (called by page 50621)
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Must be called BEFORE RunModal(). Pre-fills the dialog with the caller's
    /// currently active filter (blank/blank for "show everything").
    /// </summary>
    procedure SetFilter(pJobNo: Code[20]; pJobTaskNo: Code[20])
    begin
        JobNoCtx := pJobNo;
        JobTaskNoCtx := pJobTaskNo;
    end;

    /// <summary>
    /// Must be called AFTER RunModal() = Action::OK. Returns the values entered by
    /// the user.
    /// </summary>
    procedure GetFilter(var pJobNo: Code[20]; var pJobTaskNo: Code[20])
    begin
        pJobNo := Rec."Job No.";
        pJobTaskNo := Rec."Job Task No.";
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Page triggers
    // ──────────────────────────────────────────────────────────────────────────

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Job No." := JobNoCtx;
        Rec."Job Task No." := JobTaskNoCtx;
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            CheckJobNoSpecified();
        exit(true);
    end;

    local procedure CheckJobNoSpecified()
    begin
        if (Rec."Job Task No." <> '') and (Rec."Job No." = '') then
            Error(JobNoRequiredErr);
    end;
}
