page 50632 "Opti Job Task List TEMP"
{
    Caption = 'Project Task List (Project)';
    CardPageID = "Opti Job Task Card";
    DataCaptionFields = "Job No.";
    Editable = false;
    PageType = List;
    SourceTable = "Job Task";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;

                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the related project task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies a description of the project task. You can enter anything that is meaningful in describing the task. The description is copied and used in descriptions on the project planning line.';
                }
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;

                    ToolTip = 'Specifies the purpose of the account. Newly created accounts are automatically assigned the Posting account type, but you can change this. Choose the field to select one of the following five options:';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an interval or a list of project task numbers.';
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Manager';
                    ToolTip = 'Specifies the project manager for the project task. The project manager is based on the project manager on the related project planning line.';
                }
                field(PlannedStartDate; Rec.PlannedStartDate)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the project task is planned to start.';
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the duration of the project task in days.';
                }
                field(PlannedEndDate; Rec.PlannedEndDate)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the project task is planned to end.';
                }
                field(Progress; Rec.Progress)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the progress percentage (0-100) for this job task.';
                }
                field("Total Day Taks"; Rec."Total Day Tasks")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total number of related day tasks.';
                }
                field("Total Assigned Hours"; Rec."Total Assigned Hours")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total assigned hours from all related day tasks.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                }

            }
        }

        area(factboxes)
        {

            part(JobInformation; "Job Information FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "Job No." = field("Job No.");
            }
            part(ResourceSummaryFactbox; "Resource Summary FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Summary';

            }
            part(TaskLinkFactbox; "Task Link Factbox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "Job No." = field("Job No."),
                              "Source Task No." = field("Job Task No.");
            }


            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job Task")
            {

                Caption = '&Project Task';
                Image = Task;
                group(Job)
                {
                    Caption = 'Project';
                    Image = Job;
                    action(JobCard)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Card';
                        Image = Job;
                        RunObject = Page "Opti Job Card";
                        RunPageLink = "No." = field("Job No.");
                        ToolTip = 'View details of the related project.';
                    }
                    action(GanttChartDHX)
                    {
                        ApplicationArea = All;
                        Caption = 'Gantt Chart';
                        Image = GanttChart;
                        //RunObject = page "Gantt Demo DHX 2";

                        trigger OnAction()
                        var
                            Gantt: page "Gantt Demo DHX 2";
                        begin
                            Gantt.SetJobFilter(Rec."Job No.");
                            Gantt.RunModal();
                        end;
                    }
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Job Task Dimensions";
                        RunPageLink = "Job No." = field("Job No."),
                                      "Job Task No." = field("Job Task No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                        Visible = false;
                    }
                    action("Dimensions-Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';
                        Visible = false;

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
        }
        area(processing)
        {
            action(IndentJobTasks)
            {
                ApplicationArea = Jobs;
                Caption = 'Indent Job Tasks';
                Image = Indent;
                ToolTip = 'Automatically calculate and apply indentation to job tasks based on their hierarchy.';

                trigger OnAction()
                var
                    JobTaskIndent: Codeunit "Job Task Indent";
                begin
                    JobTaskIndent.IndentJobTasks(Rec);
                    CurrPage.Update(false);
                end;
            }

            action("Copy Job Task From")
            {
                ApplicationArea = Jobs;
                Caption = 'Copy Project Task From';
                Ellipsis = true;
                Image = CopyFromTask;
                ToolTip = 'Use a batch job to help you copy project task lines and project planning lines from one project task to another. You can copy from a project task within the project you are working with or from a project task linked to a different project.';

                trigger OnAction()
                var
                    Job: Record Job;
                    CopyJobTasks: Page "Copy Job Tasks";
                begin
                    if Job.Get(Rec."Job No.") then begin
                        CopyJobTasks.SetToJob(Job);
                        CopyJobTasks.RunModal();
                    end;
                end;
            }
            action("Copy Job Task To")
            {
                ApplicationArea = Jobs;
                Caption = 'Copy Project Task To';
                Ellipsis = true;
                Image = CopyToTask;
                ToolTip = 'Use a batch job to help you copy project task lines and project planning lines from one project task to another. You can copy from a project task within the project you are working with or from a project task linked to a different project.';

                trigger OnAction()
                var
                    Job: Record Job;
                    CopyJobTasks: Page "Copy Job Tasks";
                begin
                    if Job.Get(Rec."Job No.") then begin
                        CopyJobTasks.SetFromJob(Job);
                        CopyJobTasks.RunModal();
                    end;
                end;
            }
        }
        area(reporting)
        {

            action("Job - Suggested Billing")
            {
                ApplicationArea = Jobs;
                Caption = 'Project - Suggested Billing';
                Image = "Report";
                RunObject = Report "Job Suggested Billing";
                ToolTip = 'View a list of all projects, grouped by customer, how much the customer has already been invoiced, and how much remains to be invoiced, that is, the suggested billing.';
            }
            action("Jobs - Transaction Detail")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects - Transaction Detail';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Job - Transaction Detail";
                ToolTip = 'View all postings with entries for a selected project for a selected period, which have been charged to a certain project. At the end of each project list, the amounts are totaled separately for the Sales and Usage entry types.';
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Navigation';

                actionref("JobCard_Promoted"; jobcard)
                {
                }
                actionref("Gantt_Promoted"; "GanttChartDHX")
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Copy Job Task From_Promoted"; "Copy Job Task From")
                {
                }
                actionref("Copy Job Task To_Promoted"; "Copy Job Task To")
                {
                }
                actionref(IndentJobTasksRef; IndentJobTasks)
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';

                    actionref("Dimensions-Multiple_Promoted"; "Dimensions-Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
                group(Category_Report)
                {
                    Caption = 'Reports';


                    actionref("Job - Suggested Billing_Promoted"; "Job - Suggested Billing")
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.ResourceSummaryFactbox.Page.SetContext(Rec."Job No.", Rec."Job Task No.");
    end;

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Rec."Job Task Type" <> Rec."Job Task Type"::Posting;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job View Type" := Rec."Job View Type"::"Project";
    end;

    var
        StyleIsStrong: Boolean;

    procedure SetTempJobTasks(var TempJobTask: Record "Job Task" temporary)
    begin
        IF TempJobTask.FindSet() THEN
            repeat
                Rec.Copy(TempJobTask, true);
            UNTIL TempJobTask.Next() = 0;
    end;
}

