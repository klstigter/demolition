page 50662 "Workorder Card"
{
    Caption = 'Workorder';
    PageType = Card;
    SourceTable = "Work Order";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    trigger OnAssistEdit()
                    begin
                        if rec.AssistEdit(rec) then
                            CurrPage.Update();
                    end;
                }
                field("Order Intake No."; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Job: Record Job;
                        JobList: Page "Opti Job List";
                    begin
                        if Rec."Project No." = '' then
                            exit(false);

                        Job.Get(Rec."Project No.");
                        Clear(JobList);
                        JobList.SetTableView(Job);
                        JobList.LookupMode(true);
                        if JobList.RunModal() = ACTION::LookupOK then begin
                            JobList.GetRecord(Job);
                            if Job."No." <> Rec."Project No." then begin
                                Rec.Validate("Project No.", Job."No.");
                                currPage.Update(true);
                                Text := Job."No.";
                            end;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Project Task No."; Rec."Project Task No.")
                {
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Task: Record "Job Task";
                        TaskList: Page "Job Task List - Project";
                    begin
                        if Rec."Project No." = '' then
                            exit(false);

                        Task.SetRange("Job No.", Rec."Project No.");
                        if Rec."Project Task No." <> '' then
                            Task.Get(Rec."Project No.", Rec."Project Task No.");
                        Clear(TaskList);
                        TaskList.SetTableView(Task);
                        TaskList.LookupMode(true);
                        if TaskList.RunModal() = ACTION::LookupOK then begin
                            TaskList.GetRecord(Task);
                            if Task."Job Task No." <> Rec."Project Task No." then begin
                                Rec.Validate("Project Task No.", Task."Job Task No.");
                                currPage.Update(true);
                                Text := Task."Job Task No.";
                            end;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

            }

            part(DayPlanningSequence; "Day Planning Sequence Part")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Sequence';
            }

            part(JobTaskPlanning; "Job Task Planning Part")
            {
                ApplicationArea = All;
                SubPageLink = "Job No." = FIELD("Project No."), "Job Task No." = FIELD("Project Task No.");
                Caption = 'Planning';
            }
            Group(LongDescription)
            {
                Caption = 'Long Description';
                usercontrol(RichTextEditor; DHXRichTextAddin)
                {
                    ApplicationArea = All;

                    /// <summary>
                    /// Fires once when the DHTMLX RichText editor is ready.
                    /// Load the current record's blob content into the editor.
                    /// </summary>
                    trigger ControlReady()
                    begin
                        AddinReady := true;
                        CurrPage.RichTextEditor.SetValue(Rec.GetDescription());
                    end;

                    /// <summary>
                    /// Fires ~800 ms after the user stops typing (debounced in JS).
                    /// Persist the HTML into the blob field on the record.
                    /// </summary>
                    trigger OnTextChanged(Html: Text)
                    begin
                        Rec.SetDescription(Html);
                    end;
                }
            }
            // part(SpecificationLines; "Workorder Cap. Req. Subfrm")
            // {
            //     ApplicationArea = All;
            //     SubPageLink = "Workorder No." = FIELD("Work Order No.");
            // }
            part("Day Plannings"; "Work Order Day Plannings")
            {
                ApplicationArea = All;
                SubPageLink = "Work Order No." = FIELD("Work Order No.");
            }
            part(ProjectPlanningLines; "Job Planning Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Job No." = FIELD("Project No."), "Job Task No." = FIELD("Project Task No.");
                Caption = 'Project Planning Lines';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DayPlanningsCreation)
            {
                ApplicationArea = All;
                Caption = 'Day plannings pattern';
                Image = HumanResources;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                var
                    Page: Page "Day Planning Pattern";
                begin
                    page.fillbuffer(Rec."Project No.", Rec."Project Task No.", Rec."Work Order No.");
                    Page.Run();
                    CurrPage.Update();
                end;
            }
            action(DayPlannings)
            {
                ApplicationArea = All;
                Caption = 'Day plannings';
                Image = HumanResources;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                var
                    ResourcePage: Page "Day Plannings";
                    DayPlanning: Record "Day Planning";
                begin
                    DayPlanning.SetRange("Job No.", Rec."Project No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Project Task No.");
                    ResourcePage.SetTableView(DayPlanning);
                    ResourcePage.Run();
                end;
            }
            action(PrepareInvoiceLines)
            {
                ApplicationArea = All;
                Caption = 'Transfer to planning line';
                Image = Invoice;
                ToolTip = 'Creates billable Project Planning Lines, grouped by Skill, from posted Day Planning usage that has not yet been invoiced.';
                trigger OnAction()
                var
                    JobInvoicePrepMgt: Codeunit "Job Planning Lines Prep. Mgt.";
                    LinesCreated: Integer;
                    ProcessedCount: Integer;
                    AlreadyLinkedCount: Integer;
                    NotPostedCount: Integer;
                    SkippedOtherCount: Integer;
                begin
                    LinesCreated := JobInvoicePrepMgt.PrepareJobPlanningLines(Rec."Project No.", Rec."Project Task No.", ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount);
                    CurrPage.Update();
                    Message(JobInvoicePrepMgt.FormatResultMessage(LinesCreated, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount));
                end;
            }
            action(GanttChartDHX)
            {
                ApplicationArea = All;
                Image = GanttChart;
                Caption = 'Gantt Chart';
                //RunObject = page "Gantt Demo DHX 2";
                trigger OnAction()
                var
                    Gantt: page "Gantt Demo DHX 2";
                begin
                    Gantt.SetJobFilter(Rec."Project No.");
                    Gantt.RunModal();
                end;

            }
            action(CapacityPlanningOverviewAct)
            {
                ApplicationArea = All;
                Image = Planning;
                Caption = 'Capacity Planning Overview';
                trigger OnAction()
                var
                    CPO: Page "Capacity Planning Overview";
                begin
                    // Run() (not RunModal()) - a plain top-level navigation, same as how
                    // "DHX Request Assignment Board" (page 50710) is launched from a Role Center
                    // tile - so BC renders just the back arrow instead of a modal dialog's own
                    // title bar/Manage-Actions-Fewer options toolbar/Close button on top of this
                    // control add-in's own JS-rendered header (which would otherwise duplicate it).
                    CPO.SetWorkOrderNo(Rec."Work Order No.");
                    CPO.Run();
                end;
            }
            action(ShowJobLedgerEntries)
            {
                ApplicationArea = All;
                Caption = 'Show Job Ledger Entries';
                Image = JobLedger;
                RunObject = Page "Job Ledger Entries";
                RunPageLink = "Job No." = field("Project No."),
                              "Job Task No." = field("Project Task No.");
                RunPageView = sorting("Job No.", "Job Task No.", "Entry Type", "Posting Date")
                              order(descending);
                ToolTip = 'View the posted project ledger entries for this project and project task.';
            }
            action(ShowSummary)
            {
                ApplicationArea = All;
                Caption = 'Show Summary';
                Image = ViewDetails;
                ToolTip = 'View the day planning summary for this project task.';
                trigger OnAction()
                var
                    SummaryPage: Page "Summary View";
                begin
                    SummaryPage.LoadDataSet(Rec."Project No.", Rec."Project Task No.");
                    SummaryPage.SetJobAndJobTaskVisibility(false);
                    SummaryPage.Run();
                end;
            }
            action(ShowSkillHoursSummary)
            {
                ApplicationArea = All;
                Caption = 'Skill Hours Summary';
                Image = ResourceGroup;
                ToolTip = 'View requested hours per skill code, year and week for this project task.';
                trigger OnAction()
                var
                    SkillHoursPage: Page "Skill Hours Summary";
                begin
                    SkillHoursPage.LoadContext(Rec."Project No.", Rec."Project Task No.");
                    SkillHoursPage.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(DayPlanningsCreation_Promoted; DayPlanningsCreation)
                {
                }
                actionref(DayPlannings_Promoted; DayPlannings)
                {
                }
                actionref(PrepareInvoiceLines_Promoted; PrepareInvoiceLines)
                {
                }
                actionref(GanttChartDHX_Promoted; GanttChartDHX)
                {
                }
                actionref(CapacityPlanningOverviewAct_Promoted; CapacityPlanningOverviewAct)
                {
                }
                actionref(ShowJobLedgerEntries_Promoted; ShowJobLedgerEntries)
                {
                }
                actionref(ShowSummary_Promoted; ShowSummary)
                {
                }
                actionref(ShowSkillHoursSummary_Promoted; ShowSkillHoursSummary)
                {
                }
            }
        }
    }
    var
        AddinReady: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.DayPlanningSequence.Page.SetContext(Rec."Project No.", Rec."Project Task No.");
    end;
}