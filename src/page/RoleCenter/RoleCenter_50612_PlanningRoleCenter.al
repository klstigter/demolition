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
                action("DayPlanningOrderIntake")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Order Intake';
                    RunObject = Page "Order Intake Opt.";
                    Image = Quote;
                    ToolTip = 'Open the DayPlanning Order Intake page to manage DayPlanning orders.';
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
                action("Day Plannings")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Day Plannings';
                    RunObject = Page "Day Plannings";
                    ToolTip = 'Open the list of day plannings for the project.';
                }
                action("Project Planning Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Planning Lines';
                    RunObject = Page "Job Planning Lines";
                    ToolTip = 'Open the list of project planning lines for the project.';
                }
                action("DayPlanningPosting")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Day Planning Journal';
                    RunObject = Page "Day Planning Journal";
                    Image = PostBatch;
                    ToolTip = 'Open the DayPlanning posting journal to retrieve unposted day Plannings and post them to the project ledger.';
                }
                action("Job Ledger Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Ledger Entries';
                    RunObject = Page "Job Ledger Entries";
                    ToolTip = 'View the posted project ledger entries.';
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
                    Caption = 'Day Plannings';
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
                    Caption = 'Capacity';
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
                    Caption = 'Resource Capacity';
                    RunObject = page "Resource Capacity";
                }
                action("Resource Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Assignment';
                    RunObject = page "Resource Assignment";
                }
                action("Skill Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Skill Codes';
                    RunObject = page "Skill Codes";
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
                action("WorkOrderItemPricing")
                {
                    Caption = 'Work Order Item Pricing';
                    Image = SalesPrices;
                    ApplicationArea = All;
                    RunObject = page "Sales Prices";
                    ToolTip = 'Manage item prices for work orders. Prices are applied automatically based on customer, date, and quantity.';
                }
            }
        }
    }
}