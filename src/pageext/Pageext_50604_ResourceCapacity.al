// Page 213 "Resource Capacity" builds its 12 matrix columns in a private local procedure
// SetMatrixColumns(StepType), which always calls
//     MatrixMgt.GeneratePeriodMatrixData(StepType, 12, false, PeriodType, '', ...)
// with a HARDCODED EMPTY DateFilter, so the column set is always anchored on WorkDate().
// All of page 213's state (MatrixRecords, MatrixColumnCaptions, ColumnSet, PKFirstRecInCurrSet,
// CurrSetLength, PeriodType, QtyType) is page-private and page 213 / page 9237 publish no
// integration events, so an extension cannot influence that call. The only supported levers are
// the public procedure "Resource Capacity Matrix".LoadMatrix() and the public codeunit procedure
// "Matrix Management".GeneratePeriodMatrixData().
//
// Therefore, when SetPeriod() has been called by the caller before Run(), this extension takes
// over the WHOLE matrix-column pipeline (initial column set, View by / View as, and the four
// Previous/Next Set/Column navigation actions) and keeps its own copy of the navigation state.
// The base controls/actions are hidden in that mode so the two states can never diverge; when
// SetPeriod() was NOT called the page behaves exactly like standard BC.
//
// NOTE: no event subscriber is used on codeunit "Matrix Management" / codeunit
// PeriodPageManagement on purpose - those are shared by many unrelated BC analysis pages and a
// subscriber there would change all of them, not just this page.
pageextension 50604 "ResourceCapacity Opt." extends "Resource Capacity"
{
    layout
    {
        modify(PeriodType)
        {
            Visible = not PeriodOverrideActive;
        }
        modify(QtyType)
        {
            Visible = not PeriodOverrideActive;
        }
        addafter(QtyType)
        {
            group(MatrixOptionsOpt)
            {
                ShowCaption = false;
                Visible = PeriodOverrideActive;

                field(PeriodTypeOpt; PeriodTypeOpt)
                {
                    ApplicationArea = Jobs;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        SetMatrixColumnsOpt("Matrix Page Step Type"::Initial);
                        UpdateMatrixSubformOpt();
                    end;
                }
                field(QtyTypeOpt; QtyTypeOpt)
                {
                    ApplicationArea = Jobs;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        UpdateMatrixSubformOpt();
                    end;
                }
            }
        }
    }

    actions
    {
        // The base actions drive page 213's own (WorkDate-anchored) private position, which this
        // extension cannot reach. Hide them while the override is active and offer equivalents
        // that step from the overridden anchor instead.
        modify("Previous Set")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Previous Column")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Next Column")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Next Set")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Previous Set_Promoted")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Previous Column_Promoted")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Next Column_Promoted")
        {
            Visible = not PeriodOverrideActive;
        }
        modify("Next Set_Promoted")
        {
            Visible = not PeriodOverrideActive;
        }

        addafter("Next Set")
        {
            action("Previous Set Opt")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';
                Visible = PeriodOverrideActive;

                trigger OnAction()
                begin
                    SetMatrixColumnsOpt("Matrix Page Step Type"::Previous);
                    UpdateMatrixSubformOpt();
                end;
            }
            action("Previous Column Opt")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';
                Visible = PeriodOverrideActive;

                trigger OnAction()
                begin
                    SetMatrixColumnsOpt("Matrix Page Step Type"::PreviousColumn);
                    UpdateMatrixSubformOpt();
                end;
            }
            action("Next Column Opt")
            {
                ApplicationArea = Jobs;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';
                Visible = PeriodOverrideActive;

                trigger OnAction()
                begin
                    SetMatrixColumnsOpt("Matrix Page Step Type"::NextColumn);
                    UpdateMatrixSubformOpt();
                end;
            }
            action("Next Set Opt")
            {
                ApplicationArea = Jobs;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';
                Visible = PeriodOverrideActive;

                trigger OnAction()
                begin
                    SetMatrixColumnsOpt("Matrix Page Step Type"::Next);
                    UpdateMatrixSubformOpt();
                end;
            }
        }

        addafter("Next Set_Promoted")
        {
            actionref("Previous Set Opt_Promoted"; "Previous Set Opt")
            {
            }
            actionref("Previous Column Opt_Promoted"; "Previous Column Opt")
            {
            }
            actionref("Next Column Opt_Promoted"; "Next Column Opt")
            {
            }
            actionref("Next Set Opt_Promoted"; "Next Set Opt")
            {
            }
        }
    }

    // Runs AFTER the base page's own OnOpenPage (which has already loaded the matrix subform with
    // its WorkDate-anchored columns). When SetPeriod() was called, re-generate and re-push the
    // column set anchored on the requested start date, and remember the resulting record position
    // so the Previous/Next actions continue from here instead of from the base page's position.
    trigger OnOpenPage()
    begin
        if not PeriodOverrideActive then
            exit;

        SetMatrixColumnsOpt("Matrix Page Step Type"::Initial);
        UpdateMatrixSubformOpt();
    end;

    var
        OptMatrixRecords: array[32] of Record Date;
        PeriodTypeOpt: Enum "Analysis Period Type";
        QtyTypeOpt: Enum "Analysis Amount Type";
        OptMatrixColumnCaptions: array[32] of Text[1024];
        OptColumnSet: Text[1024];
        OptPKFirstRecInCurrSet: Text[100];
        OptCurrSetLength: Integer;
        ForcedPeriodStart: Date;
        ForcedPeriodEnd: Date;
        PeriodOverrideActive: Boolean;

    // Extension-owned equivalent of page 213's private SetMatrixColumns().
    //
    // DateFilter semantics (see codeunit "Matrix Management".GeneratePeriodMatrixData and
    // codeunit PeriodPageManagement.GetFullPeriodDateFilter):
    //  * The filter is applied as Calendar.SetFilter("Period Start", ...) and therefore acts as a
    //    HARD CAP on how many period records the column-generation loop
    //        until (CurrSetLength = MaximumSetLength) or (PeriodPageMgt.NextDate(1, ...) not 1)
    //    can ever walk over - it is NOT just an anchor. Passing the caller's narrow
    //    ForcedPeriodStart..ForcedPeriodEnd window (typically a single day, coming from one
    //    DHTMLX event) is exactly why only column 1 got a real date/caption and columns 2..12
    //    stayed blank: CurrSetLength came back as 1 while page 9237 always renders its 12 fixed
    //    Field1..Field12 controls (blank CaptionClass + 0.00 cell value for the unused ones).
    //  * So for the Initial step we pass a deliberately WIDE closed range that starts exactly at
    //    ForcedPeriodStart. Only the lower bound matters (it is what the Initial branch's
    //    FindDate('-') anchors on); the upper bound just has to leave room for 12 periods of any
    //    "View by" granularity, hence +24 years. ForcedPeriodEnd is intentionally NOT used as the
    //    upper bound.
    //  * The range is kept CLOSED (not open-ended) on purpose: GetFullPeriodDateFilter resolves
    //    the upper bound for Week/Month/Quarter/Year with a "Period End" greater-than EndDate
    //    filter plus FindFirst, which finds nothing when EndDate is the max date and would
    //    collapse the whole filter to an empty range.
    //  * For every navigation step an EMPTY DateFilter is passed. Those branches position
    //    themselves purely via Calendar.SetPosition(RecordPosition), so an empty filter keeps the
    //    anchor from the previous call while allowing navigation freely in both directions past
    //    the originally requested window.
    local procedure SetMatrixColumnsOpt(StepType: Enum "Matrix Page Step Type")
    var
        DateRec: Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        DateFilterTxt: Text;
    begin
        if StepType = StepType::Initial then begin
            // Build the filter text with SetRange + GetFilter instead of formatting dates by hand,
            // so it is guaranteed round-trippable regardless of the session's date format.
            DateRec.SetRange("Period Start", ForcedPeriodStart, CalcDate('<+24Y>', ForcedPeriodStart));
            DateFilterTxt := DateRec.GetFilter("Period Start");
        end else
            DateFilterTxt := '';

        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 12, false, PeriodTypeOpt, DateFilterTxt,
            OptPKFirstRecInCurrSet, OptMatrixColumnCaptions, OptColumnSet, OptCurrSetLength, OptMatrixRecords);
    end;

    /// <summary>
    /// Extension-owned equivalent of page 213's private UpdateMatrixSubform().
    /// </summary>
    local procedure UpdateMatrixSubformOpt()
    begin
        CurrPage.MatrixForm.PAGE.LoadMatrix(QtyTypeOpt, OptMatrixColumnCaptions, OptMatrixRecords, OptCurrSetLength);
        CurrPage.Update(false);
    end;

    procedure ResourceFilter(pResFilter: Text)
    begin
        CurrPage.MatrixForm.PAGE.ResourceFilter(pResFilter);
    end;

    /// <summary>
    /// Call BEFORE Run()/RunModal() to anchor the capacity matrix on pStartDate instead of on
    /// WorkDate(). Enables the extension-owned column pipeline for this page instance.
    /// </summary>
    procedure SetPeriod(pStartDate: Date; pEndDate: Date)
    begin
        if pStartDate = 0D then
            exit;

        ForcedPeriodStart := pStartDate;
        ForcedPeriodEnd := pEndDate;
        PeriodOverrideActive := true;
    end;
}
