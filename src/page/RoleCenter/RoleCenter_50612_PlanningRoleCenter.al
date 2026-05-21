page 50612 "Planning Role Center"
{
    Caption = 'Planning Role Center';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(ProjectPlanningActivities; "Project Planning Activities")
            {
                ApplicationArea = Jobs;
            }
            // part(ResourcePlanningActivities; "Resource Planning Activities")
            // {
            //     ApplicationArea = Jobs;
            // }
        }
    }

    actions
    {
        area(Sections)
        {
            group("ProjectPlanningGroup")
            {
                Caption = 'Project Planning';
                action("DaytaskOrderIntake")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Order Intake';
                    RunObject = Page "Order Intake Opt.";
                    Image = Quote;
                    ToolTip = 'Open the Daytask Order Intake page to manage daytask orders.';
                }
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Opti Job List";
                }
                action("Job Tasks")
                {
                    ApplicationArea = Suite;
                    Caption = 'Project Tasks';
                    RunObject = Page "Job Task List - Project";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }
                action("Day Tasks")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Day Tasks';
                    RunObject = Page "Day Tasks";
                    ToolTip = 'Open the list of day tasks for the project.';
                }
                action("DaytaskPosting")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Daytask Posting';
                    RunObject = Page "Daytask Journal";
                    Image = PostBatch;
                    ToolTip = 'Open the Daytask posting journal to retrieve unposted day tasks and post them to the project ledger.';
                }

            }

            group("ResourcePlanningGroup")
            {
                Caption = 'Resource Planning';
                Visible = false;

                action("Jobs Resource")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    Image = Job;
                    RunObject = Page "Opti Job List";
                    ToolTip = 'Define a project activity by creating a project card with integrated project tasks and project planning lines, structured in two layers. The project task enables you to set up project planning lines and to post consumption to the project. The project planning lines specify the detailed use of resources, items, and various general ledger expenses.';
                }
                action("Job Tasks Resource")
                {
                    ApplicationArea = All;
                    Caption = 'Project Tasks';
                    RunObject = page "Job Task List - Resource";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }

            }
            group("VisualGroup")
            {
                Caption = 'Visual';

                action(GanttChartDHX)
                {
                    ApplicationArea = All;
                    Caption = 'Gantt Chart';
                    RunObject = page "Gantt Demo DHX 2";
                }
                action("VisualPlanning2")
                {
                    ApplicationArea = All;
                    Caption = 'Day Tasks';
                    RunObject = page "DHX Scheduler (Project)";
                }
                // action("VisualPlanning3")
                // {
                //     ApplicationArea = All;
                //     Caption = 'Capacity';
                //     RunObject = page "DHX Scheduler (Resource)";
                // }
                action("VisualPlanning4")
                {
                    ApplicationArea = All;
                    Caption = 'Capacity (Pool)';
                    RunObject = page "DHX Scheduler (Pool Resource)";
                }

                action("VisualPlanning5")
                {
                    ApplicationArea = All;
                    Caption = 'Resources Scheduler';
                    RunObject = page "DHX Resource Scheduler";
                }
                action("VisualPlanning6")
                {
                    ApplicationArea = All;
                    Caption = 'Order Intake Kanban';
                    RunObject = page "DHX Order Intake Kanban";
                }
            }

            group("Resource")
            {
                Caption = 'Resource';
                action("Resources")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resources';
                    RunObject = page "Resource List";
                }

                action("Base Calendar Entries Subform")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Calendar';
                    RunObject = page "Base Calendar List";
                }
                action("Resource Capacitys")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Capacities';
                    RunObject = page "Resource Capacity";
                }
                action("Resource Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Assignment';
                    RunObject = page "Resource Assignment";
                }
            }
            group("tests")
            {
                Caption = 'Tests';
                action(OpenNodeSet)
                {
                    Caption = 'Open Node Set';
                    ApplicationArea = All;
                    Image = Delete;
                    RunObject = page "Date Span Document"; // Date Span Document
                }
                action(DateEngineTests)
                {
                    ApplicationArea = All;
                    Caption = 'Date Engine Tests';
                    RunObject = page "Date Span Test Runner";

                }
            }
            group("SettingGroup")
            {
                Caption = 'Setup';

                action("GanttSettings")
                {
                    Caption = 'Gantt Settings';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "Gantt Chart Setup";
                }
                action("Create Demo Data")
                {
                    Caption = 'Create Demo Data';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = codeunit "Create Demo Data";
                }
                action("Resource Color")
                {
                    Caption = 'Resource Color';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "Resource Scheduler Color opt";
                }
                action("Projejct Type")
                {
                    Caption = 'Project Type';
                    Image = ProjectExpense;
                    ApplicationArea = All;
                    RunObject = page "Project Type List Opt.";
                }
                action("Daily Optimizer Setup")
                {
                    Caption = 'Daily Optimizer Setup';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "Daily Optimizer Setup";
                }
            }
        }
    }
}