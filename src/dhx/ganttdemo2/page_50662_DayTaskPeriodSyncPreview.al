page 50663 "DayTask Period Sync Preview"
{
    Caption = 'DayTask Period Change Preview';
    PageType = List;
    SourceTable = "DayTask Sync Preview Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
                    Caption = 'DayTask No.';
                    ToolTip = 'DayTask line number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Description of the DayTask record.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    Caption = 'Resource';
                    ToolTip = 'Resource assigned to this DayTask.';
                }
                field("Old Task Date"; Rec."Old Task Date")
                {
                    ApplicationArea = All;
                    Caption = 'Current Date';
                    Style = Unfavorable;
                    StyleExpr = true;
                    ToolTip = 'The current DayTask date before the period change is applied.';
                }
                // ── Right Pane: calculated values ───────────────────────────────────
                field("New Task Date"; Rec."New Task Date")
                {
                    ApplicationArea = All;
                    Caption = 'New Date';
                    Style = Favorable;
                    StyleExpr = true;
                    ToolTip = 'The calculated new DayTask date after the period change is applied.';
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
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Apply all calculated date changes to the DayTask records. The Gantt chart will reflect the updates on the next data load.';

                trigger OnAction()
                var
                    DayTaskPeriodSyncMgt: Codeunit "DayTask Period Sync Mgt.";
                    AppliedMsg: Label '%1 DayTask record(s) updated successfully.';
                    RecordCount: Integer;
                begin
                    Rec.Reset();
                    RecordCount := Rec.Count();
                    if SkipJobTaskModify then
                        DayTaskPeriodSyncMgt.ApplyChangesOnly(Rec)
                    else
                        DayTaskPeriodSyncMgt.ApplyChanges(SavedJobTask, Rec);
                    Applied := true;
                    Message(AppliedMsg, RecordCount);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            InfoTxt := 'No DayTask records are linked to this project task. ' +
                       'Click Apply Changes to save the new period to the project task, or close this page to cancel.'
        else
            InfoTxt := 'The following DayTask records are affected by the project task period change. ' +
                       'Review the Current Date and New Date columns, then click Apply Changes to confirm.';
    end;

    trigger OnClosePage()
    var
        GanttPage: Page "Gantt Demo DHX 2";
    begin
        // Fires whenever this page closes — either after Apply Changes or by dismissing.
        // Applied = false (the default) means the user cancelled without applying.
        // ShowPreview() in "DayTask Period Sync Mgt." reads WasApplied() after RunModal()
        // returns and propagates false back to the Gantt page, which then reloads task
        // data from the database to revert the dragged bar to its original position.
    end;

    /// <summary>
    /// Called by "DayTask Period Sync Mgt.".ShowPreview() before RunModal().
    /// Shares the calculated temp buffer with the page's Rec via Rec.Copy(ShareTable = true).
    /// </summary>
    procedure SetPreviewData(var TempBuffer: Record "DayTask Sync Preview Buffer" temporary)
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
}
