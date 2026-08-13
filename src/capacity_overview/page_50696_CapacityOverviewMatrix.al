page 50696 "Capacity Overview Matrix"
{
    PageType = ListPart;
    SourceTable = "Capacity Overview Buffer";
    SourceTableTemporary = true;
    Caption = 'Capacity Overview Matrix';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    /// <summary>
    /// Rows are the 6 fixed lines built by codeunit 50694 (Total Capacity, Total Request,
    /// Assigned Hours, Capacity, Request Plan (not assigned), Surplus), rendered contiguous
    /// - no blank spacer rows. Columns D:.. ("Column 1".."Column 20") are dynamic: only as many
    /// are shown as there are Skill Code records (up to 20). Each column's Visible is bound to a
    /// dedicated ColumnNVisible variable and its header text to CaptionClass = '3,' + ColumnNCaption
    /// (CaptionClass area "3" returns its expression verbatim as the caption - see Caption Class
    /// codeunit 42). AL does not allow array-element access inside these "client expression"
    /// properties (compiler error AL0322), so each column needs its own named variable pair rather
    /// than an indexed array - SetColumnCaptionsAndVisibility fans out into them via a case
    /// statement. Both are populated at runtime, since the actual skill code text (e.g.
    /// "DELIVER2") is only known once the card page reads the "Skill Code" table, not at compile
    /// time.
    ///
    /// Every value cell (Total + each per-skill column) drills down into the underlying detail
    /// list for its row - see DrillDownColumn. "Total Capacity" and "Capacity" now DO have a
    /// per-skill breakdown for their VALUES (codeunit 50694's CalcCapacityPerSkill), but their
    /// DRILLDOWN is still unfiltered by skill - rows 10000/40000/60000 always open
    /// "Res. Capacity Entries" filtered by the period only, regardless of which column was
    /// clicked (a known follow-up gap, not fixed here). Only "Surplus" (60000) still has neither
    /// a per-skill value breakdown nor a skill-aware drilldown.
    ///
    /// Every value field control (Total + Column1..Column20) has StyleExpr = Rec.Style, set by
    /// codeunit 50694's InsertRow/InsertDifferenceRow, so the "Capacity" (Free Capacity) row
    /// renders bold ('Strong') - the Description (row label) field is deliberately not styled.
    ///
    /// Column windowing: FullSkillCodeList (set via LoadPeriod) holds EVERY skill code, unbounded.
    /// Only GetMaxMatrixColumns() (20) of them are ever shown at once - ColumnOffset is the
    /// 0-based index of the first skill in the current window. When there are more than 20 skills,
    /// the "Previous Set / Previous Column / Next Column / Next Set" actions become visible and
    /// page ColumnOffset, then RefreshMatrix() re-slices the window, re-runs the codeunit for just
    /// that slice, and reassigns column captions/visibility - independent of the card page, so
    /// paging never has to round-trip through it.
    /// </summary>

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the calculation that this row shows.';
                }
                field(TotalColumn; Rec."Total Column")
                {
                    ApplicationArea = All;
                    Caption = 'Total';
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the total across all skills for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(0);
                    end;
                }
                field(Column1; Rec."Column 1")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column1Caption;
                    Visible = Column1Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(1);
                    end;
                }
                field(Column2; Rec."Column 2")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column2Caption;
                    Visible = Column2Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(2);
                    end;
                }
                field(Column3; Rec."Column 3")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column3Caption;
                    Visible = Column3Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(3);
                    end;
                }
                field(Column4; Rec."Column 4")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column4Caption;
                    Visible = Column4Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(4);
                    end;
                }
                field(Column5; Rec."Column 5")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column5Caption;
                    Visible = Column5Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(5);
                    end;
                }
                field(Column6; Rec."Column 6")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column6Caption;
                    Visible = Column6Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(6);
                    end;
                }
                field(Column7; Rec."Column 7")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column7Caption;
                    Visible = Column7Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(7);
                    end;
                }
                field(Column8; Rec."Column 8")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column8Caption;
                    Visible = Column8Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(8);
                    end;
                }
                field(Column9; Rec."Column 9")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column9Caption;
                    Visible = Column9Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(9);
                    end;
                }
                field(Column10; Rec."Column 10")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column10Caption;
                    Visible = Column10Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(10);
                    end;
                }
                field(Column11; Rec."Column 11")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column11Caption;
                    Visible = Column11Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(11);
                    end;
                }
                field(Column12; Rec."Column 12")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column12Caption;
                    Visible = Column12Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(12);
                    end;
                }
                field(Column13; Rec."Column 13")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column13Caption;
                    Visible = Column13Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(13);
                    end;
                }
                field(Column14; Rec."Column 14")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column14Caption;
                    Visible = Column14Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(14);
                    end;
                }
                field(Column15; Rec."Column 15")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column15Caption;
                    Visible = Column15Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(15);
                    end;
                }
                field(Column16; Rec."Column 16")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column16Caption;
                    Visible = Column16Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(16);
                    end;
                }
                field(Column17; Rec."Column 17")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column17Caption;
                    Visible = Column17Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(17);
                    end;
                }
                field(Column18; Rec."Column 18")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column18Caption;
                    Visible = Column18Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(18);
                    end;
                }
                field(Column19; Rec."Column 19")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column19Caption;
                    Visible = Column19Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(19);
                    end;
                }
                field(Column20; Rec."Column 20")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Column20Caption;
                    Visible = Column20Visible;
                    StyleExpr = Rec.Style;
                    ToolTip = 'Specifies the value for this skill for the current period. Choose the value to see the underlying detail records.';

                    trigger OnDrillDown()
                    begin
                        DrillDownColumn(20);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ColumnNavigation)
            {
                Caption = 'Skill Columns';
                Visible = ShowColumnNavigation;

                action(PreviousSetAction)
                {
                    ApplicationArea = All;
                    Caption = 'Previous Set';
                    Image = PreviousSet;
                    Enabled = CanPageBack;
                    ToolTip = 'Go to the previous set of skill columns.';

                    trigger OnAction()
                    begin
                        GoToPreviousSet();
                    end;
                }
                action(PreviousColumnAction)
                {
                    ApplicationArea = All;
                    Caption = 'Previous Column';
                    Image = PreviousRecord;
                    Enabled = CanPageBack;
                    ToolTip = 'Go to the previous skill column.';

                    trigger OnAction()
                    begin
                        GoToPreviousColumn();
                    end;
                }
                action(NextColumnAction)
                {
                    ApplicationArea = All;
                    Caption = 'Next Column';
                    Image = NextRecord;
                    Enabled = CanPageForward;
                    ToolTip = 'Go to the next skill column.';

                    trigger OnAction()
                    begin
                        GoToNextColumn();
                    end;
                }
                action(NextSetAction)
                {
                    ApplicationArea = All;
                    Caption = 'Next Set';
                    Image = NextSet;
                    Enabled = CanPageForward;
                    ToolTip = 'Go to the next set of skill columns.';

                    trigger OnAction()
                    begin
                        GoToNextSet();
                    end;
                }
            }
        }
    }

    /// <summary>
    /// Entry point called by the card page whenever the period changes: stores the full,
    /// unbounded skill code list and the period, resets the column window back to the start, and
    /// builds the matrix for that first window. See RefreshMatrix for the actual build/paging
    /// logic.
    /// </summary>
    procedure LoadPeriod(SkillCodeList: List of [Code[20]]; PeriodStartDate: Date; PeriodEndDate: Date)
    begin
        FullSkillCodeList := SkillCodeList;
        CurrPeriodStartDate := PeriodStartDate;
        CurrPeriodEndDate := PeriodEndDate;
        ColumnOffset := 0;
        RefreshMatrix();
    end;

    /// <summary>
    /// Column-window paging for the Previous Set / Previous Column / Next Column / Next Set
    /// actions defined above, on this part's own action bar (kept local to the matrix part rather
    /// than the host card page, so the part is self-contained).
    /// </summary>
    local procedure GoToPreviousSet()
    begin
        ColumnOffset := ColumnOffset - CapacityOverviewMgt.GetMaxMatrixColumns();
        ClampColumnOffset();
        RefreshMatrix();
    end;

    local procedure GoToPreviousColumn()
    begin
        ColumnOffset := ColumnOffset - 1;
        ClampColumnOffset();
        RefreshMatrix();
    end;

    local procedure GoToNextColumn()
    begin
        ColumnOffset := ColumnOffset + 1;
        ClampColumnOffset();
        RefreshMatrix();
    end;

    local procedure GoToNextSet()
    begin
        ColumnOffset := ColumnOffset + CapacityOverviewMgt.GetMaxMatrixColumns();
        ClampColumnOffset();
        RefreshMatrix();
    end;

    /// <summary>
    /// Slices out the current window (at most GetMaxMatrixColumns() codes starting at
    /// ColumnOffset) from FullSkillCodeList, asks codeunit 50694 to (re)build Rec directly for
    /// just that slice and the stored period, then refreshes column captions/visibility and the
    /// Previous/Next action Enabled state. Called on LoadPeriod and after every column-paging
    /// action.
    /// </summary>
    local procedure RefreshMatrix()
    var
        WindowSkillCodeList: List of [Code[20]];
        WindowSize: Integer;
        TotalCount: Integer;
        i: Integer;
    begin
        WindowSize := CapacityOverviewMgt.GetMaxMatrixColumns();
        TotalCount := FullSkillCodeList.Count();
        ShowColumnNavigation := TotalCount > WindowSize;

        Clear(WindowSkillCodeList);
        for i := ColumnOffset + 1 to ColumnOffset + WindowSize do
            if i <= TotalCount then
                WindowSkillCodeList.Add(FullSkillCodeList.Get(i));
        CurrSkillCodeList := WindowSkillCodeList;

        CapacityOverviewMgt.BuildMatrix(Rec, CurrPeriodStartDate, CurrPeriodEndDate, WindowSkillCodeList);

        SetColumnCaptionsAndVisibility(WindowSkillCodeList);

        CanPageBack := ColumnOffset > 0;
        CanPageForward := (ColumnOffset + WindowSize) < TotalCount;

        Rec.Reset();
        if Rec.FindFirst() then;

        CurrPage.Update(false);
    end;

    /// <summary>
    /// Keeps ColumnOffset within [0, max(0, TotalCount - WindowSize)] after a paging action.
    /// </summary>
    local procedure ClampColumnOffset()
    var
        MaxOffset: Integer;
    begin
        MaxOffset := FullSkillCodeList.Count() - CapacityOverviewMgt.GetMaxMatrixColumns();
        if MaxOffset < 0 then
            MaxOffset := 0;
        if ColumnOffset > MaxOffset then
            ColumnOffset := MaxOffset;
        if ColumnOffset < 0 then
            ColumnOffset := 0;
    end;

    local procedure SetColumnCaptionsAndVisibility(SkillCodeList: List of [Code[20]])
    var
        MaxColumns: Integer;
        ColumnCount: Integer;
        i: Integer;
        NewCaption: Text[50];
    begin
        MaxColumns := CapacityOverviewMgt.GetMaxMatrixColumns();
        ColumnCount := SkillCodeList.Count();
        if ColumnCount > MaxColumns then
            ColumnCount := MaxColumns;

        for i := 1 to MaxColumns do begin
            if i <= ColumnCount then
                NewCaption := SkillCodeList.Get(i)
            else
                NewCaption := '';
            SetColumn(i, NewCaption, i <= ColumnCount);
        end;
    end;

    /// <summary>
    /// Fans out into the per-column "ColumnNCaption" / "ColumnNVisible" variable pair. Needed
    /// because CaptionClass/Visible are "client expressions" and cannot reference an indexed
    /// array element (AL0322) - only a plain variable identifier.
    /// </summary>
    local procedure SetColumn(ColumnNo: Integer; NewCaption: Text[50]; NewVisible: Boolean)
    begin
        case ColumnNo of
            1:
                begin
                    Column1Caption := NewCaption;
                    Column1Visible := NewVisible;
                end;
            2:
                begin
                    Column2Caption := NewCaption;
                    Column2Visible := NewVisible;
                end;
            3:
                begin
                    Column3Caption := NewCaption;
                    Column3Visible := NewVisible;
                end;
            4:
                begin
                    Column4Caption := NewCaption;
                    Column4Visible := NewVisible;
                end;
            5:
                begin
                    Column5Caption := NewCaption;
                    Column5Visible := NewVisible;
                end;
            6:
                begin
                    Column6Caption := NewCaption;
                    Column6Visible := NewVisible;
                end;
            7:
                begin
                    Column7Caption := NewCaption;
                    Column7Visible := NewVisible;
                end;
            8:
                begin
                    Column8Caption := NewCaption;
                    Column8Visible := NewVisible;
                end;
            9:
                begin
                    Column9Caption := NewCaption;
                    Column9Visible := NewVisible;
                end;
            10:
                begin
                    Column10Caption := NewCaption;
                    Column10Visible := NewVisible;
                end;
            11:
                begin
                    Column11Caption := NewCaption;
                    Column11Visible := NewVisible;
                end;
            12:
                begin
                    Column12Caption := NewCaption;
                    Column12Visible := NewVisible;
                end;
            13:
                begin
                    Column13Caption := NewCaption;
                    Column13Visible := NewVisible;
                end;
            14:
                begin
                    Column14Caption := NewCaption;
                    Column14Visible := NewVisible;
                end;
            15:
                begin
                    Column15Caption := NewCaption;
                    Column15Visible := NewVisible;
                end;
            16:
                begin
                    Column16Caption := NewCaption;
                    Column16Visible := NewVisible;
                end;
            17:
                begin
                    Column17Caption := NewCaption;
                    Column17Visible := NewVisible;
                end;
            18:
                begin
                    Column18Caption := NewCaption;
                    Column18Visible := NewVisible;
                end;
            19:
                begin
                    Column19Caption := NewCaption;
                    Column19Visible := NewVisible;
                end;
            20:
                begin
                    Column20Caption := NewCaption;
                    Column20Visible := NewVisible;
                end;
        end;
    end;

    /// <summary>
    /// Opens the detail record list backing the clicked cell. ColumnNo = 0 is the Total column;
    /// 1..20 is a per-skill column, resolved back to its Skill Code via CurrSkillCodeList (out of
    /// range / not-visible columns are ignored defensively).
    ///
    /// Row-to-list mapping (Rec."Line No." matches codeunit 50694's InsertRow calls):
    ///  10000 Total Capacity     -> "Res. Capacity Entries", Date = period. No skill filter exists
    ///                              on capacity entries, so per-skill columns open the same list
    ///                              as the Total column.
    ///  20000 Total Request      -> "Day Plannings", Plan Date = period, Skill = column's skill
    ///                              (Total column leaves Skill unfiltered).
    ///  30000 Assigned Hours     -> same as Total Request, plus "Assigned Hours" not equal to 0,
    ///                              since this row is specifically the assigned subset.
    ///  40000 Capacity           -> "Res. Capacity Entries", Date = period (Capacity is a
    ///                              capacity-remaining figure; like row 10000, it does not have a
    ///                              per-skill breakdown to filter by).
    ///  50000 Request Plan       -> same as Total Request, plus "Assigned Hours" = 0, since this
    ///       (not assigned)         row is specifically the still-unassigned subset.
    ///  60000 Surplus            -> "Res. Capacity Entries", Date = period, same reasoning as
    ///                              Total Capacity / Capacity.
    /// </summary>
    local procedure DrillDownColumn(ColumnNo: Integer)
    var
        DayPlanning: Record "Day Planning";
        ResCapacityEntry: Record "Res. Capacity Entry";
        SkillCodeFilter: Code[20];
    begin
        if ColumnNo > 0 then begin
            if ColumnNo > CurrSkillCodeList.Count() then
                exit;
            SkillCodeFilter := CurrSkillCodeList.Get(ColumnNo);
        end;

        case Rec."Line No." of
            10000, 40000, 60000:
                begin
                    ResCapacityEntry.Reset();
                    ResCapacityEntry.SetRange(Date, CurrPeriodStartDate, CurrPeriodEndDate);
                    Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
                end;
            20000:
                begin
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Plan Date", CurrPeriodStartDate, CurrPeriodEndDate);
                    if SkillCodeFilter <> '' then
                        DayPlanning.SetRange(Skill, SkillCodeFilter);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
            30000:
                begin
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Plan Date", CurrPeriodStartDate, CurrPeriodEndDate);
                    if SkillCodeFilter <> '' then
                        DayPlanning.SetRange(Skill, SkillCodeFilter);
                    DayPlanning.SetFilter("Assigned Hours", '<>%1', 0);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
            50000:
                begin
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Plan Date", CurrPeriodStartDate, CurrPeriodEndDate);
                    if SkillCodeFilter <> '' then
                        DayPlanning.SetRange(Skill, SkillCodeFilter);
                    DayPlanning.SetRange("Assigned Hours", 0);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
        end;
    end;

    var
        CapacityOverviewMgt: Codeunit "Capacity Overview Mgt.";
        FullSkillCodeList: List of [Code[20]];
        CurrSkillCodeList: List of [Code[20]];
        CurrPeriodStartDate: Date;
        CurrPeriodEndDate: Date;
        ColumnOffset: Integer;
        ShowColumnNavigation: Boolean;
        CanPageBack: Boolean;
        CanPageForward: Boolean;
        Column1Caption: Text[50];
        Column2Caption: Text[50];
        Column3Caption: Text[50];
        Column4Caption: Text[50];
        Column5Caption: Text[50];
        Column6Caption: Text[50];
        Column7Caption: Text[50];
        Column8Caption: Text[50];
        Column9Caption: Text[50];
        Column10Caption: Text[50];
        Column11Caption: Text[50];
        Column12Caption: Text[50];
        Column13Caption: Text[50];
        Column14Caption: Text[50];
        Column15Caption: Text[50];
        Column16Caption: Text[50];
        Column17Caption: Text[50];
        Column18Caption: Text[50];
        Column19Caption: Text[50];
        Column20Caption: Text[50];
        Column1Visible: Boolean;
        Column2Visible: Boolean;
        Column3Visible: Boolean;
        Column4Visible: Boolean;
        Column5Visible: Boolean;
        Column6Visible: Boolean;
        Column7Visible: Boolean;
        Column8Visible: Boolean;
        Column9Visible: Boolean;
        Column10Visible: Boolean;
        Column11Visible: Boolean;
        Column12Visible: Boolean;
        Column13Visible: Boolean;
        Column14Visible: Boolean;
        Column15Visible: Boolean;
        Column16Visible: Boolean;
        Column17Visible: Boolean;
        Column18Visible: Boolean;
        Column19Visible: Boolean;
        Column20Visible: Boolean;
}
