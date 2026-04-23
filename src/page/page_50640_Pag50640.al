
page 50640 "Opti Job Task Lines Subform"
{
    Caption = 'Project Task Lines Subform';
    DataCaptionFields = "Job No.";
    PageType = ListPart;
    SaveValues = true;
    CardPageId = "Opti Job Task Card";
    SourceTable = "Job Task";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies a description of the project task. You can enter anything that is meaningful in describing the task. The description is copied and used in descriptions on the project planning line.';
                }
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this. Choose the field to select one of the following five options:';

                    trigger OnValidate()
                    begin
                        StyleIsStrong := Rec."Job Task Type" <> Rec."Job Task Type"::Posting;
                        CurrPage.Update();
                    end;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an interval or a list of project task numbers.';
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default for the project task.';
                    Visible = PerTaskBillingFieldsVisible;
                    Editable = PostingTypeRow;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the customer who pays for the project task.';
                    Visible = PerTaskBillingFieldsVisible;
                    Editable = PostingTypeRow;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the project posting group of the task.';
                    Visible = false;
                }
                field("WIP-Total"; Rec."WIP-Total")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the project tasks you want to group together when calculating Work In Process (WIP) and Recognition.';
                    Visible = false;
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the Work in Process calculation method that is associated with a project. The value in this field comes from the WIP method specified on the project card.';
                    Visible = false;
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Manager';
                    ToolTip = 'Specifies the project manager for the project task. The project manager is based on the project manager on the related project planning line.';
                }
                field(PlannedStartDate; Rec.PlannedStartDate)
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the planned start date for the project task. The date is based on the date on the related project planning line.';
                }
                field(PlannedEndDate; Rec.PlannedEndDate)
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the planned end date for the project task. The date is based on the date on the related project planning line.';
                }

                field("Scheduling Type"; Rec."Scheduling Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Scheduling Type field.', Comment = '%';
                }
                field("Estimated Hours"; Rec."Estimated Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Estimated Hours field.', Comment = '%';
                }
                field("Duration"; Rec."Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the duration of the project task in days.';
                }
                field(Progress; Rec.Progress)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the progress percentage (0-100) for this job task.';
                }
                field("Total Worked Hours"; Rec."Total Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total worked hours from all related day tasks.';
                }
                field("Total Day Taks"; Rec."Total Day Tasks")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total Day Taks field.', Comment = '%';
                }

                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    Visible = PerTaskBillingFieldsVisible;
                    Editable = PerTaskBillingFieldsVisible;
                    Tooltip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Jobs;
                    Visible = PerTaskBillingFieldsVisible;
                    Editable = PerTaskBillingFieldsVisible;
                    Tooltip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the start date for the project task. The date is based on the date on the related project planning line.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies the end date for the project task. The date is based on the date on the related project planning line.';
                }

            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                group("&Job")
                {
                    Caption = '&Project Task';
                    Image = Job;

                    action(JobTaskStatistics)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Statistics';
                        Image = StatisticsDocument;
                        RunObject = Page "Job Task Statistics";
                        RunPageLink = "Job No." = field("Job No."),
                                  "Job Task No." = field("Job Task No.");
                        ToolTip = 'View statistics for the project task.';
                    }
                }
                group("&Dimensions")
                {
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    ShowAs = SplitButton;

                    action("Dimensions-&Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Single';
                        Image = Dimensions;
                        RunObject = Page "Job Task Dimensions";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            JobTask: Record "Job Task";
                            JobTaskDimensionsMultiple: Page "Job Task Dimensions Multiple";
                        begin
                            CurrPage.SetSelectionFilter(JobTask);
                            JobTaskDimensionsMultiple.SetMultiJobTask(JobTask);
                            JobTaskDimensionsMultiple.RunModal();
                        end;
                    }
                }
                group(Documents)
                {
                    Caption = 'Documents';
                    Image = Invoice;
                    action("Create &Sales Invoice")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Create &Sales Invoice';
                        Ellipsis = true;
                        Image = JobSalesInvoice;
                        ToolTip = 'Use a batch job to help you create sales invoices for the involved project tasks.';

                        trigger OnAction()
                        var
                            Job: Record Job;
                            JobTask: Record "Job Task";
                        begin
                            Rec.TestField("Job No.");
                            Job.Get(Rec."Job No.");
                            if Job.Blocked = Job.Blocked::All then
                                Job.TestBlocked();

                            JobTask.SetRange("Job No.", Job."No.");
                            if Rec."Job Task No." <> '' then
                                JobTask.SetRange("Job Task No.", Rec."Job Task No.");

                            REPORT.RunModal(REPORT::"Job Create Sales Invoice", true, false, JobTask);
                        end;
                    }
                    action(SalesInvoicesCreditMemos)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Sales &Invoices/Credit Memos';
                        Image = GetSourceDoc;
                        ToolTip = 'View sales invoices or sales credit memos that are related to the selected project task.';

                        trigger OnAction()
                        var
                            JobInvoices: Page "Job Invoices";
                        begin
                            JobInvoices.SetPrJobTask(Rec);
                            JobInvoices.RunModal();
                        end;
                    }
                }
                group(History)
                {
                    Caption = 'History';
                    Image = History;
                    action("Job Ledger E&ntries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Ledger E&ntries';
                        Image = JobLedger;
                        RunObject = Page "Job Ledger Entries";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        RunPageView = sorting("Job No.", "Job Task No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the project ledger entries.';
                    }
                }
                group("F&unctions")
                {
                    Caption = 'F&unctions';
                    Image = "Action";

                }

                action("<Action7>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'I&ndent Project Tasks';
                    Image = Indent;
                    //RunObject = Codeunit "Job Task-Indent";
                    ToolTip = 'Move the selected lines in one position to show that the tasks are subcategories of other tasks. Project tasks that are totaled are the ones that lie between one pair of corresponding Begin-Total and End-Total project tasks.';

                    trigger OnAction()
                    var
                        Indent: codeunit "Job Task Indent";
                    begin
                        Indent.IndentJobTasks(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := Rec.Indentation;
        StyleIsStrong := Rec."Job Task Type" <> "Job Task Type"::Posting;
        PostingTypeRow := Rec."Job Task Type" = "Job Task Type"::Posting;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ClearTempDim();
        StyleIsStrong := Rec."Job Task Type" <> "Job Task Type"::Posting;
        PostingTypeRow := Rec."Job Task Type" = "Job Task Type"::Posting;
    end;

    var
        DescriptionIndent: Integer;
        StyleIsStrong: Boolean;
        PostingTypeRow: Boolean;
#if not CLEAN24
        RefreshCustomerControl: Boolean;
#endif

        PerTaskBillingFieldsVisible: Boolean;

    procedure SetPerTaskBillingFieldsVisible(Visible: Boolean)
    begin
        PerTaskBillingFieldsVisible := Visible;
        CurrPage.Update(false);
    end;

}

