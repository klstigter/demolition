/// <summary>
/// Generic Resource filter popup (Report 50609)
///
/// Report-request-page-only picker shared by any page that needs a quick Resource
/// filter, opened from a (▽) filter icon on a JS timeline toolbar. Currently used by:
///   - Page 50619 "DHX Resource Scheduler" (OnResourceFilterIconClick)
///   - Page 50600 "DHX Scheduler (Pool Resource)" (OnResourceFilterIconClick)
/// Lets the user enter standard Business Central filter syntax (wildcards, ranges,
/// OR-lists, exclusions, etc.) for either Resource No. or Resource Name. No dataset
/// is ever processed — CurrReport.Break() fires immediately, so the RequestPage is
/// the only UI the user ever sees. Follows the same pattern as report 50608 "Task
/// Scheduler Filter".
/// Replaces the former Page 50682 + Table 50623 pair.
///
/// IMPORTANT: unlike Page.RunModal(), Report.RunModal() returns no value (type None),
/// so "FilterDlg.RunModal() = Action::OK" does not compile. Use IsConfirmed() instead,
/// which is set from the request page's OnQueryClosePage(CloseAction) trigger.
///
/// IMPORTANT (2nd pass — corrects a broken 1st pass): the Resource No. field is a
/// plain Text global (not Rec-bound) with TableRelation set. Its multi-select "..."
/// lookup is wired below via an OnLookup trigger. The FIRST attempt at this called
/// "PAGE.RunModal(0, Resource)" directly (no Page variable) and handed the Resource
/// record straight to Codeunit 46 "SelectionFilterManagement".GetSelectionFilterForResource
/// — this compiled fine but was CONFIRMED BROKEN by live testing on the sibling report
/// 50608 (same pattern): multi-selecting rows and clicking OK produced garbage text,
/// not a valid "A|B" filter. Root cause: PAGE.RunModal(0, Record) does NOT populate the
/// passed record variable with a filter reflecting the user's Ctrl/Shift-marked rows.
/// The marked-selection filter only gets written onto a record variable via the
/// dedicated "PageVariable.SetSelectionFilter(var Record)" call — every other working
/// multi-select site in this codebase (pageext_50608_JobPlanningLines.al,
/// pageext_50622_JobLedgerEntries.al, page_50617/50607/50632/Pag50640/Pag50601's own
/// "GetSelectionFilter()" helpers, including pageext_50603_ResourceList.al's proven
/// "Schedule (Visual)"/"DayPlannings (Visual)" actions on the actual base-app
/// "Resource List" page) calls "CurrPage.SetSelectionFilter(RecVar)" before doing
/// anything with the marked set. Since our OnLookup trigger lives outside the
/// popped-up list page, we can't use CurrPage — instead we declare an explicit Page
/// "Resource List" variable (the exact same page pageext_50603 extends), run it
/// modally via LookupMode(true)/RunModal() (the standard base-app "open a list page as
/// a picker from code" idiom, same family as the well-known Page.GetRecord() pattern),
/// and then call ".SetSelectionFilter(Resource)" ON THAT PAGE VARIABLE once it returns
/// Action::LookupOK — SetSelectionFilter is a Page-type method, not a CurrPage-only
/// keyword, so this is a direct, mechanical extension of the confirmed-working
/// CurrPage usages above, and was verified to compile cleanly (al_compile/al_build) in
/// this pass. Only THEN is the record handed to Codeunit 46's
/// GetSelectionFilterForResource wrapper to compact the now correctly-marked selection
/// into ranges/OR-lists.
///
/// The Resource Name field has NO OnLookup (and no TableRelation) at all, deliberately.
/// Codeunit 46 has no GetSelectionFilterForXxx wrapper keyed on an arbitrary
/// non-primary-key field like Name, and SetSelectionFilter()/the GetSelectionFilter
/// wrappers are all built around a table's primary key ("No." for Resource) — there is
/// no proven-working base-app precedent in this codebase for building a Name-keyed
/// multi-select filter this way. Rather than guess again (exactly what caused the
/// previous failure), Resource Name is left as a plain typed-filter-only field: users
/// can still type standard filter syntax (wildcards, ranges, OR-lists) directly, they
/// just don't get a multi-select picker for it.
///
/// IMPORTANT (3rd pass — Skill field added): Codeunit 46 "SelectionFilterManagement"
/// has NO dedicated "GetSelectionFilterForSkillCode"/"GetSelectionFilterForSkill"
/// wrapper (confirmed via al_symbolsearch — 44 GetSelectionFilterForXxx overloads
/// exist, none for Skill Code). It DOES expose a generic RecordRef-based overload:
/// "GetSelectionFilter(var TempRecRef: RecordRef; SelectionFieldID: Integer): Text" —
/// this is the same primitive the dedicated wrappers are themselves built on top of
/// (same doc text: "Get a filter for the selected field from a provided record. Ranges
/// will be used inside the filter where possible."), and it is keyed on whichever field
/// ID you pass in, same shape of contract as the dedicated wrappers (which are keyed to
/// the table's primary key). Table "Skill Code" has a single-field primary key ("Code"),
/// so this is a safe, mechanical fit: call SkillCodeList.SetSelectionFilter(SkillCode)
/// exactly like the Resource No. field above, then GetRecordRef.GetTable(SkillCode) and
/// pass that RecRef + SkillCode.FieldNo(Code) into the generic GetSelectionFilter
/// overload. The lookup page used is the base-app "Skill Codes" page (Microsoft.Service.
/// Setup namespace) — NOT this project's custom Page 50646 "Opti Skill Codes", which has
/// SourceTableTemporary = true and only ever shows rows pushed into it via its own
/// SetTempSkill() procedure, so running it standalone via SetTableView/LookupMode against
/// the real "Skill Code" table would open an empty list. The base-app "Skill Codes" page
/// is a plain non-temporary List page bound directly to "Skill Code", so it behaves like
/// "Resource List" above under SetTableView/LookupMode/SetSelectionFilter.
///
/// Caller pattern:
///   var
///       FilterDlg        : Report "Resource Scheduler Filter";
///       NewResNoFilter   : Text;
///       NewResNameFilter : Text;
///       NewSkillFilter   : Text;
///   begin
///       FilterDlg.SetFilter(ResourceFilter, ResourceNameFilter, SkillFilter);
///       FilterDlg.RunModal();
///       if FilterDlg.IsConfirmed() then begin
///           FilterDlg.GetFilter(NewResNoFilter, NewResNameFilter, NewSkillFilter);
///           ResourceFilter := NewResNoFilter;
///           ResourceNameFilter := NewResNameFilter;
///           SkillFilter := NewSkillFilter;
///           RefreshWithResourceFilterChange();
///       end;
///   end;
///
/// IMPORTANT (4th pass — opt-in Job/Job Task filter group added): Page 50706 "DHX
/// Scheduler (Res+Capacity)" is the only one of this report's three callers whose
/// underlying data (Day Planning) has Job No./Job Task No. fields meaningfully wired
/// up (see DHXDataHandler.SkillResScheduler_BuildDayPlanningJson). Pages 50619 and
/// 50600 have no job-filtering hooks at all, so the new "Filter by Job / Job Task"
/// group is HIDDEN BY DEFAULT (ShowJobFilter = false) and only becomes visible when a
/// caller explicitly opts in by calling EnableJobFilter() before RunModal(). Callers
/// that want the group also call SetJobFilter()/GetJobFilter() (same before/after
/// RunModal() contract as SetFilter()/GetFilter()). Extended caller pattern for a
/// job-aware caller (e.g. Page 50706):
///   var
///       FilterDlg        : Report "Resource Scheduler Filter";
///       ...
///       NewJobNoFilter     : Text;
///       NewJobTaskNoFilter : Text;
///   begin
///       FilterDlg.SetFilter(ResourceFilter, ResourceNameFilter, SkillFilter);
///       FilterDlg.EnableJobFilter();
///       FilterDlg.SetJobFilter(JobFilter, JobTaskFilter);
///       FilterDlg.RunModal();
///       if FilterDlg.IsConfirmed() then begin
///           FilterDlg.GetFilter(NewResNoFilter, NewResNameFilter, NewSkillFilter);
///           FilterDlg.GetJobFilter(NewJobNoFilter, NewJobTaskNoFilter);
///           ...
///       end;
///   end;
/// </summary>
report 50609 "Resource Scheduler Filter"
{
    UsageCategory = None;
    ApplicationArea = All;
    ProcessingOnly = true;
    UseRequestPage = true;
    Caption = 'Filter by Resource';

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

                    field(fldResourceNo; ResourceNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Resource No.';
                        ToolTip = 'Specifies the filter to apply on Resource No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select resources.';
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
                    field(fldResourceName; ResourceNameFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Resource Name';
                        ToolTip = 'Specifies the filter to apply on Resource Name. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists). No multi-select lookup is available for this field (see class doc-comment).';
                    }
                    field(fldSkill; SkillFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Skill';
                        ToolTip = 'Specifies the filter to apply on the resource''s assigned Skill Code. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists), or use the lookup to multi-select skill codes.';
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
                }
                group(JobFilterGroup)
                {
                    Caption = 'Filter by Job / Job Task';
                    Visible = ShowJobFilter;

                    field(fldJobNo; JobNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Job No.';
                        ToolTip = 'Specifies the filter to apply on Day Planning''s Job No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists).';
                        TableRelation = Job;
                    }
                    field(fldJobTaskNo; JobTaskNoFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Job Task No.';
                        ToolTip = 'Specifies the filter to apply on Day Planning''s Job Task No. Standard filter syntax is supported (e.g. wildcards, ranges, OR-lists). Not constrained by Job No. - enter both fields for a meaningful filter.';
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
        ResourceNoFilter: Text;
        ResourceNameFilter: Text;
        SkillFilter: Text;
        JobNoFilter: Text;
        JobTaskNoFilter: Text;
        ShowJobFilter: Boolean;
        Confirmed: Boolean;

    /// <summary>
    /// Must be called BEFORE RunModal(). Pre-fills the request page with the caller's
    /// currently active resource filters (blank for "show everything").
    /// </summary>
    procedure SetFilter(pResourceNoFilter: Text; pResourceNameFilter: Text; pSkillFilter: Text)
    begin
        ResourceNoFilter := pResourceNoFilter;
        ResourceNameFilter := pResourceNameFilter;
        SkillFilter := pSkillFilter;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(), guarded by IsConfirmed(). Returns the raw
    /// filter text entered by the user for each field.
    /// </summary>
    procedure GetFilter(var pResourceNoFilter: Text; var pResourceNameFilter: Text; var pSkillFilter: Text)
    begin
        pResourceNoFilter := ResourceNoFilter;
        pResourceNameFilter := ResourceNameFilter;
        pSkillFilter := SkillFilter;
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

    /// <summary>
    /// Must be called BEFORE RunModal(). Opt-in switch that makes the "Filter by Job /
    /// Job Task" group visible on the request page. Hidden by default because only
    /// Page 50706 "DHX Scheduler (Res+Capacity)" has Job/Job Task filtering meaningfully
    /// wired to its data (Day Planning); callers that never call this (Pages 50619,
    /// 50600) keep the group hidden and never see a dead filter.
    /// </summary>
    procedure EnableJobFilter()
    begin
        ShowJobFilter := true;
    end;

    /// <summary>
    /// Must be called BEFORE RunModal(). Pre-fills the request page with the caller's
    /// currently active Job No./Job Task No. filters (blank for "show everything").
    /// Only meaningful when combined with EnableJobFilter().
    /// </summary>
    procedure SetJobFilter(pJobNoFilter: Text; pJobTaskNoFilter: Text)
    begin
        JobNoFilter := pJobNoFilter;
        JobTaskNoFilter := pJobTaskNoFilter;
    end;

    /// <summary>
    /// Must be called AFTER RunModal(), guarded by IsConfirmed(). Returns the raw
    /// filter text entered by the user for Job No. and Job Task No.
    /// </summary>
    procedure GetJobFilter(var pJobNoFilter: Text; var pJobTaskNoFilter: Text)
    begin
        pJobNoFilter := JobNoFilter;
        pJobTaskNoFilter := JobTaskNoFilter;
    end;
}
