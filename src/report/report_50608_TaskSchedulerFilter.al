/// <summary>
/// Generic Job No. / Job Task No. filter popup (Report 50608)
///
/// Report-request-page-only picker shared by any page that needs a quick Job/Job Task
/// filter, opened from a (▽) filter icon on a JS timeline toolbar. Currently used by:
///   - Page 50621 "DHX Scheduler (Project)" (wrapper.js's setupFilterToolbar()/OnFilterIconClick)
///   - Page 50620 "Gantt Demo DHX 2" (ganttdemo2/wrapper.js's OnGanttFilterIconClick)
/// Lets the user enter standard Business Central filter syntax (wildcards, ranges,
/// OR-lists, exclusions, etc.) for either Job No. or Job Task No. No dataset is ever
/// processed — CurrReport.Break() fires immediately, so the RequestPage is the only
/// UI the user ever sees. Follows the same pattern as report 50609 "Resource
/// Scheduler Filter". Replaces the former Page 50681 + Table 50622 pair.
///
/// IMPORTANT: unlike Page.RunModal(), Report.RunModal() returns no value (type None),
/// so "FilterDlg.RunModal() = Action::OK" does not compile. Use IsConfirmed() instead,
/// which is set from the request page's OnQueryClosePage(CloseAction) trigger.
///
/// IMPORTANT (2nd pass — corrects a broken 1st pass): both fields are plain Text
/// globals (not Rec-bound) with TableRelation set. The multi-select "..." lookup is
/// wired below via an OnLookup trigger per field. The FIRST attempt at this called
/// "PAGE.RunModal(0, Job)" directly (no Page variable) and then handed the Job record
/// straight to Codeunit 46 "SelectionFilterManagement".GetSelectionFilterForJob — this
/// compiled fine but was CONFIRMED BROKEN by live testing: multi-selecting two Jobs
/// and clicking OK produced garbage text (e.g. "..PR00030"), not a valid "A|B" filter.
/// Root cause: PAGE.RunModal(0, Record) does NOT populate the passed record variable
/// with a filter reflecting the user's Ctrl/Shift-marked rows. The marked-selection
/// filter only gets written onto a record variable via a dedicated
/// "PageVariable.SetSelectionFilter(var Record)" call — every other working multi-select
/// site in this codebase (pageext_50608_JobPlanningLines.al, pageext_50622_JobLedgerEntries.al,
/// page_50617/50607/50632/Pag50640/Pag50601/Pag50609's own "GetSelectionFilter()"
/// helpers) calls "CurrPage.SetSelectionFilter(RecVar)" before doing anything with the
/// marked set. Since our OnLookup trigger lives outside the popped-up list page, we
/// can't use CurrPage — instead we declare an explicit Page variable, run it modally
/// via LookupMode(true)/RunModal() (the standard base-app "open a list page as a
/// picker from code" idiom, same family as the well-known Page.GetRecord() pattern),
/// and then call ".SetSelectionFilter(Job)" ON THAT PAGE VARIABLE once it returns
/// Action::LookupOK — SetSelectionFilter is a Page-type method, not a CurrPage-only
/// keyword, so this is a direct, mechanical extension of the confirmed-working
/// CurrPage usages above, and was verified to compile cleanly (al_compile/al_build)
/// in this pass. Only THEN is the record handed to Codeunit 46's
/// GetSelectionFilterForJob/GetSelectionFilterForJobTask wrapper to compact the now
/// correctly-marked selection into ranges/OR-lists. Typing directly into either field
/// is unaffected — no OnValidate is added. Note: the Job Task No. lookup is NOT scoped
/// to the currently-typed Job No. — a dynamic where("Job No."=field(JobNoFilter)) does
/// not resolve on a non-Rec report global (AL0186), so this is an accepted tradeoff;
/// see project memory for the earlier attempt and removal.
///
/// Caller pattern:
///   var
///       FilterDlg    : Report "Task Scheduler Filter";
///       NewJobNo     : Text;
///       NewJobTaskNo : Text;
///   begin
///       FilterDlg.SetFilter(jobFilter, JobTaskFilter);
///       FilterDlg.RunModal();
///       if FilterDlg.IsConfirmed() then begin
///           FilterDlg.GetFilter(NewJobNo, NewJobTaskNo);
///           jobFilter := NewJobNo;
///           JobTaskFilter := NewJobTaskNo;
///           RefreshSchedule();
///       end;
///   end;
/// </summary>
report 50608 "Task Scheduler Filter"
{
    UsageCategory = None;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'Filter by Job / Job Task';

    dataset
    {
        dataitem(DummyInteger; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(0));

            trigger OnPreDataItem()
            begin
                // No actual dataset is ever processed — the RequestPage is the sole UI.
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(FilterGroup)
                {
                    ShowCaption = false;

                    field(fldJobNo; JobNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Job No.';
                        ToolTip = 'Specifies the filter to apply on Job No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select jobs.';
                        TableRelation = Job;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Job: Record Job;
                            JobList: Page "Job List";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        begin
                            Job.SetFilter("No.", JobNoFilter);
                            JobList.SetTableView(Job);
                            JobList.LookupMode(true);
                            if JobList.RunModal() = Action::LookupOK then begin
                                JobList.SetSelectionFilter(Job);
                                Text := SelectionFilterManagement.GetSelectionFilterForJob(Job);
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldJobTaskNo; JobTaskNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Job Task No.';
                        ToolTip = 'Specifies the filter to apply on Job Task No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select job tasks. Not scoped to the Job No. above.';
                        TableRelation = "Job Task"."Job Task No.";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobTask: Record "Job Task";
                            JobTaskList: Page "Job Task List";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        begin
                            JobTask.SetFilter("Job Task No.", JobTaskNoFilter);
                            JobTaskList.SetTableView(JobTask);
                            JobTaskList.LookupMode(true);
                            if JobTaskList.RunModal() = Action::LookupOK then begin
                                JobTaskList.SetSelectionFilter(JobTask);
                                Text := SelectionFilterManagement.GetSelectionFilterForJobTask(JobTask);
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Confirmed := CloseAction = Action::OK;
            exit(true);
        end;
    }

    var
        JobNoFilter: Text;
        JobTaskNoFilter: Text;
        Confirmed: Boolean;

    /// <summary>
    /// Must be called BEFORE RunModal(). Pre-fills the request page with the caller's
    /// currently active filter (blank/blank for "show everything").
    /// </summary>
    procedure SetFilter(pJobNo: Text; pJobTaskNo: Text)
    begin
        JobNoFilter := pJobNo;
        JobTaskNoFilter := pJobTaskNo;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(), guarded by IsConfirmed(). Returns the raw
    /// filter text entered by the user for each field.
    /// </summary>
    procedure GetFilter(var pJobNo: Text; var pJobTaskNo: Text)
    begin
        pJobNo := JobNoFilter;
        pJobTaskNo := JobTaskNoFilter;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(). Report.RunModal() has no return value (unlike
    /// Page.RunModal(), which returns Action), so callers must use this instead of
    /// comparing the RunModal() call to Action::OK. Reflects whether the user closed
    /// the request page with OK (true) rather than Cancel/close (false).
    /// </summary>
    procedure IsConfirmed(): Boolean
    begin
        exit(Confirmed);
    end;
}
