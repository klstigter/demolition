page 50663 "DayPlanning PeriodSyncPreview"
{
    Caption = 'DayPlanning Period Change Preview';
    PageType = List;
    SourceTable = "DayPlanning Sync PreviewBuff";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(Instructions)
            {
                ShowCaption = false;

                field(InfoText; InfoTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = Attention;
                    StyleExpr = true;
                }
            }
            repeater(PreviewLines)
            {
                // ── Left Pane: original values ──────────────────────────────────────
                field("Day Line No."; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'DayPlanning No.';
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'DayPlanning line number. 0 = new DayPlanning to be created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Description of the DayPlanning record.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource';
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Resource assigned to this DayPlanning.';
                }
                field("Old Task Date"; Rec."Old Task Date")
                {
                    ApplicationArea = All;
                    Caption = 'Current Date';
                    Editable = false;
                    StyleExpr = OldDateStyleExpr;
                    ToolTip = 'The current DayPlanning date before the period change is applied. Blank for new DayPlanning entries.';
                }
                // ── Right Pane: calculated / new values ───────────────────────────
                field("New Task Date"; Rec."New Task Date")
                {
                    ApplicationArea = All;
                    Caption = 'New Date';
                    Editable = false;
                    StyleExpr = NewDateStyleExpr;
                    ToolTip = 'The calculated new DayPlanning date after the period change is applied.';
                }
                field("Day Name"; Rec."Day Name")
                {
                    ApplicationArea = All;
                    Caption = 'Day Name';
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Shows the weekday name of the new DayPlanning date.';
                }
                field("Day Type"; Rec."Day Type")
                {
                    ApplicationArea = All;
                    Caption = 'Day Type';
                    Editable = false;
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Indicates whether the new date falls on a Work-day, Weekend, or Public Holiday.';
                }
                field("Convert to DayPlanning"; Rec."Convert to DayPlanning")
                {
                    ApplicationArea = All;
                    Caption = 'Convert to DayPlanning';
                    StyleExpr = RowStyleExpr;
                    ToolTip = 'Uncheck to exclude this date from the DayPlanning creation when Apply Changes is clicked.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ApplyChanges)
            {
                ApplicationArea = All;
                Caption = 'Apply Changes';
                Image = Apply;
                InFooterBar = true;
                ToolTip = 'Apply all calculated date changes to the DayPlanning records. The Gantt chart will reflect the updates on the next data load.';

                trigger OnAction()
                var
                    DayPlanningPeriodSyncMgt: Codeunit "DayPlanning Period Sync Mgt.";
                    AppliedMsg: Label '%1 DayPlanning record(s) updated successfully.';
                    RecordCount: Integer;
                begin
                    Rec.Reset();
                    Rec.SetRange("Convert to DayPlanning", true);
                    RecordCount := Rec.Count();
                    Rec.Reset();
                    if SkipJobTaskModify then
                        DayPlanningPeriodSyncMgt.ApplyChangesOnly(Rec)
                    else
                        DayPlanningPeriodSyncMgt.ApplyChanges(SavedJobTask, Rec);
                    Applied := true;
                    Message(AppliedMsg, RecordCount);
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ApplyChanges_Promoted; ApplyChanges) { }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            InfoTxt := 'No DayPlanning records are linked to this project task. ' +
                       'Click Apply Changes to save the new period to the project task, or close this page to cancel.'
        else
            InfoTxt := 'The following DayPlanning records are affected by the project task period change. ' +
                       'Rows shown in red are Weekend or Public Holiday dates – uncheck “Convert to DayPlanning” to skip them. ' +
                       'Click Apply Changes to confirm.';
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec."Day Type" of
            Rec."Day Type"::Weekend,
            Rec."Day Type"::"Public-Holiday":
                begin
                    RowStyleExpr := 'Unfavorable';
                    OldDateStyleExpr := 'Unfavorable';
                    NewDateStyleExpr := 'Unfavorable';
                end;
            else begin
                RowStyleExpr := '';
                OldDateStyleExpr := 'Unfavorable';
                NewDateStyleExpr := 'Favorable';
            end;
        end;
    end;

    trigger OnClosePage()
    var
        GanttPage: Page "Gantt Demo DHX 2";
    begin
        // Fires whenever this page closes — either after Apply Changes or by dismissing.
        // Applied = false (the default) means the user cancelled without applying.
        // ShowPreview() in "DayPlanning Period Sync Mgt." reads WasApplied() after RunModal()
        // returns and propagates false back to the Gantt page, which then reloads task
        // data from the database to revert the dragged bar to its original position.
    end;

    /// <summary>
    /// Called by "DayPlanning Period Sync Mgt.".ShowPreview() before RunModal().
    /// Shares the calculated temp buffer with the page's Rec via Rec.Copy(ShareTable = true).
    /// </summary>
    procedure SetPreviewData(var TempBuffer: Record "DayPlanning Sync PreviewBuff" temporary)
    begin
        Rec.Copy(TempBuffer, true);
    end;

    procedure SetJobTask(var JT: Record "Job Task")
    begin
        SavedJobTask := JT;
    end;

    /// <summary>
    /// When TRUE the Apply Changes action calls ApplyChangesOnly (no JobTask.Modify / Commit).
    /// Set to TRUE when the preview is opened from a table extension OnValidate trigger;
    /// the page that owns the record handles the persist automatically.
    /// </summary>
    procedure SetSkipJobTaskModify(Value: Boolean)
    begin
        SkipJobTaskModify := Value;
    end;

    procedure WasApplied(): Boolean
    begin
        exit(Applied);
    end;

    var
        InfoTxt: Text;
        Applied: Boolean;
        SkipJobTaskModify: Boolean;
        SavedJobTask: Record "Job Task";
        RowStyleExpr: Text;
        OldDateStyleExpr: Text;
        NewDateStyleExpr: Text;
}
