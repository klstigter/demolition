/// <summary>
/// Filter popup for page 50712 "Day Planning Sequence" (Report 50610)
///
/// Request-page-only picker, opened from the filter icon on the sequence timeline toolbar.
/// Lets the user enter standard Business Central filter syntax (wildcards, ranges, OR-lists,
/// exclusions) for Job No., Job Task No., Skill and Resource No. No dataset is ever processed -
/// CurrReport.Break() fires immediately. Same pattern as report 50608 "Task Scheduler Filter"
/// (plus a Resource No. field, whose lookup follows report 50609 "Resource Scheduler Filter").
///
/// Report.RunModal() returns no value, so callers use IsConfirmed() (set from the request
/// page's OnQueryClosePage). Multi-select lookups use an explicit Page variable +
/// LookupMode(true) + PageVar.SetSelectionFilter(Rec), then Codeunit 46
/// "SelectionFilterManagement" to compact the marked rows (PAGE.RunModal(0, Rec) alone does
/// NOT populate the record with the marked selection).
///
/// Caller pattern:
///   FilterDlg.SetFilter(JobFilter, JobTaskFilter, SkillFilter, ResourceFilter, PeriodFrom, PeriodTo);
///   FilterDlg.RunModal();
///   if FilterDlg.IsConfirmed() then
///       FilterDlg.GetFilter(JobFilter, JobTaskFilter, SkillFilter, ResourceFilter, PeriodFrom, PeriodTo);
/// </summary>
report 50610 "Day Planning Sequence Filter"
{
    UsageCategory = None;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'Filter Day Planning Sequence';

    dataset
    {
        dataitem(DummyInteger; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(0));

            trigger OnPreDataItem()
            begin
                // No actual dataset is ever processed - the RequestPage is the sole UI.
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
                        ToolTip = 'Specifies the filter to apply on Job Task No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select job tasks. The lookup lists only the tasks of the Job No. above, when one is entered.';
                        TableRelation = "Job Task"."Job Task No.";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobTask: Record "Job Task";
                            JobTaskList: Page "Job Task List";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                            PickedJobNos: List of [Code[20]];
                            PickedJobNo: Code[20];
                        begin
                            if JobNoFilter <> '' then
                                JobTask.SetFilter("Job No.", JobNoFilter);
                            JobTask.SetFilter("Job Task No.", JobTaskNoFilter);
                            JobTaskList.SetTableView(JobTask);
                            JobTaskList.LookupMode(true);
                            if JobTaskList.RunModal() = Action::LookupOK then begin
                                JobTaskList.SetSelectionFilter(JobTask);
                                Text := SelectionFilterManagement.GetSelectionFilterForJobTask(JobTask);
                                // Job No. left blank: take it from the picked tasks (distinct, OR-list)
                                if JobNoFilter = '' then begin
                                    if JobTask.FindSet() then
                                        repeat
                                            if not PickedJobNos.Contains(JobTask."Job No.") then
                                                PickedJobNos.Add(JobTask."Job No.");
                                        until JobTask.Next() = 0;
                                    foreach PickedJobNo in PickedJobNos do begin
                                        if JobNoFilter <> '' then
                                            JobNoFilter += '|';
                                        JobNoFilter += PickedJobNo;
                                    end;
                                end;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldSkill; SkillFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Skill';
                        ToolTip = 'Specifies the filter to apply on the Day Planning''s Skill. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select skill codes.';
                        TableRelation = "Skill Code";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            SkillCode: Record "Skill Code";
                            SkillCodeList: Page "Skill Codes";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                            RecRef: RecordRef;
                        begin
                            SkillCode.SetFilter(Code, SkillFilter);
                            SkillCodeList.SetTableView(SkillCode);
                            SkillCodeList.LookupMode(true);
                            if SkillCodeList.RunModal() = Action::LookupOK then begin
                                SkillCodeList.SetSelectionFilter(SkillCode);
                                RecRef.GetTable(SkillCode);
                                Text := SelectionFilterManagement.GetSelectionFilter(RecRef, SkillCode.FieldNo(Code));
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldResourceNo; ResourceNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Resource No.';
                        ToolTip = 'Specifies the filter to apply on the Day Planning''s Assigned or Requested Resource No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select resources.';
                        TableRelation = Resource;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Resource: Record Resource;
                            ResourceList: Page "Resource List";
                            SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        begin
                            Resource.SetFilter("No.", ResourceNoFilter);
                            ResourceList.SetTableView(Resource);
                            ResourceList.LookupMode(true);
                            if ResourceList.RunModal() = Action::LookupOK then begin
                                ResourceList.SetSelectionFilter(Resource);
                                Text := SelectionFilterManagement.GetSelectionFilterForResource(Resource);
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(fldPeriodFrom; PeriodFromFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Period From';
                        ToolTip = 'Specifies the first Plan Date to show. Leave blank for no lower limit.';
                    }
                    field(fldPeriodTo; PeriodToFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Period To';
                        ToolTip = 'Specifies the last Plan Date to show. Leave blank for no upper limit.';
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
        SkillFilter: Text;
        ResourceNoFilter: Text;
        PeriodFromFilter: Date;
        PeriodToFilter: Date;
        Confirmed: Boolean;

    /// <summary>
    /// Must be called BEFORE RunModal(). Pre-fills the request page with the caller's currently
    /// active filters.
    /// </summary>
    procedure SetFilter(pJobNo: Text; pJobTaskNo: Text; pSkill: Text; pResourceNo: Text; pPeriodFrom: Date; pPeriodTo: Date)
    begin
        JobNoFilter := pJobNo;
        JobTaskNoFilter := pJobTaskNo;
        SkillFilter := pSkill;
        ResourceNoFilter := pResourceNo;
        PeriodFromFilter := pPeriodFrom;
        PeriodToFilter := pPeriodTo;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(), guarded by IsConfirmed(). Returns the raw filter text
    /// entered by the user for each field.
    /// </summary>
    procedure GetFilter(var pJobNo: Text; var pJobTaskNo: Text; var pSkill: Text; var pResourceNo: Text; var pPeriodFrom: Date; var pPeriodTo: Date)
    begin
        pJobNo := JobNoFilter;
        pJobTaskNo := JobTaskNoFilter;
        pSkill := SkillFilter;
        pResourceNo := ResourceNoFilter;
        pPeriodFrom := PeriodFromFilter;
        pPeriodTo := PeriodToFilter;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(). True when the user closed the request page with OK.
    /// </summary>
    procedure IsConfirmed(): Boolean
    begin
        exit(Confirmed);
    end;
}
