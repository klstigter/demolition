page 50612 "Opti Planning Role Center"
{
    Caption = 'Planning Role Center';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(ProjectPlanningActivities; "Opti Project Plan. Activities")
            {
                ApplicationArea = Jobs;
            }
            part(CapacityPlanningDashboard; "Opti Capacity Plan. Dashboard")
            {
                ApplicationArea = All;
                Caption = 'Workload Pressure';
            }
            part(RequestedVsCapacityDaily; "Opti Requested vs Cap. Daily P")
            {
                ApplicationArea = All;
                Caption = 'Daily';
            }
            part(RequestedVsCapacityWeekly; "Opti Req. vs Cap. Weekly P")
            {
                ApplicationArea = All;
                Caption = 'Weekly';
            }
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
                    RunObject = Page "Opti Order Intake Opt.";
                    Image = Quote;
                    ToolTip = 'Open the DayPlanning Order Intake page to manage DayPlanning orders.';
                }
                action("Jobs")
                {
                    ToolTip = 'Executes the Jobs action.';
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Opti Job List";
                }
                action("Job Tasks")
                {
                    ApplicationArea = Suite;
                    Caption = 'Project Tasks';
                    RunObject = Page "Opti Job Task List - Project";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }
                action("Day Plannings")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Day Plannings';
                    RunObject = Page "Opti Day Plannings";
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
                    RunObject = Page "Opti Day Planning Journal";
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
                    RunObject = page "Opti Job Task List - Resource";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }

            }
            group("VisualGroup")
            {
                Caption = 'Visual';

                action(GanttChartDHX)
                {
                    ToolTip = 'Executes the Gantt Chart DHX action.';
                    ApplicationArea = All;
                    Caption = 'Gantt Chart';
                    RunObject = page "Opti Gantt Demo DHX 2";
                }
                action("VisualPlanning2")
                {
                    ToolTip = 'Executes the Visual Planning2 action.';
                    ApplicationArea = All;
                    Caption = 'Task Scheduler';
                    RunObject = page "Opti DHX Scheduler (Project)";
                }
                action("VisualPlanning4")
                {
                    ToolTip = 'Executes the Visual Planning4 action.';
                    ApplicationArea = All;
                    Caption = 'Resource Capacity Scheduler';
                    RunObject = page "Opti DHX Scheduler (Pool Res.)";
                }
                action("RequestAssignmentBoard")
                {
                    ToolTip = 'Executes the Request Assignment Board action.';
                    ApplicationArea = All;
                    Caption = 'Requested/Assigned';
                    RunObject = page "Opti DHX Request Assign. Board";
                }
                /*
                Split buttons aren't supported in context menus. 
                When the feature key ModernActionBar is turned off, then it isn't supported if the ShowAs property is set to SplitButton on a promoted action category group.

                group(MyGroup)
                {
                    ShowAs = SplitButton;
                    
                    action(MyAction)
                    {
                    }   
                    ...
                */
                action("VisualPlanning5b")
                {
                    ToolTip = 'Executes the Visual Planning5b action.';
                    ApplicationArea = All;
                    Caption = 'Resource Scheduler';
                    RunObject = page "Opti Res. Scheduler - TimeLine";
                }
                action("VisualPlanning5")
                {
                    ToolTip = 'Executes the Visual Planning5 action.';
                    ApplicationArea = All;
                    Caption = 'Resource Calendar';
                    RunObject = page "Opti Resource Calendar";
                }
                action("VisualPlanning6")
                {
                    ToolTip = 'Executes the Visual Planning6 action.';
                    ApplicationArea = All;
                    Caption = 'Order Intake Kanban';
                    RunObject = page "Opti DHX Order Intake Kanban";
                }
                group("Requested/Capacity")
                {
                    caption = 'Requested/Capacity';

                    action("VisualPlanning7")
                    {
                        ToolTip = 'Executes the Visual Planning7 action.';
                        ApplicationArea = All;
                        Caption = 'Daily';
                        RunObject = page "Opti Requested vs Cap. Daily";
                    }
                    action("VisualPlanning8")
                    {
                        ToolTip = 'Executes the Visual Planning8 action.';
                        ApplicationArea = All;
                        Caption = 'Weekly';
                        RunObject = page "Opti Requested vs Cap. Weekly";
                    }
                }
            }

            group("Resource")
            {
                Caption = 'Resource';
                action("Resources")
                {
                    ToolTip = 'Executes the Resources action.';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resources';
                    RunObject = page "Resource List";
                }

                action("Base Calendar Entries Subform")
                {
                    ToolTip = 'Executes the Base Calendar Entries Subform action.';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Calendar';
                    RunObject = page "Base Calendar List";
                }
                action("Resource Capacitys")
                {
                    ToolTip = 'Executes the Resource Capacitys action.';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Capacity';
                    RunObject = page "Resource Capacity";
                }
                action("Resource Assignment")
                {
                    ToolTip = 'Executes the Resource Assignment action.';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Assignment';
                    RunObject = page "Opti Resource Assignment";
                }
                action("Skill Codes")
                {
                    ToolTip = 'Executes the Skill Codes action.';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Skill Codes';
                    RunObject = page "Skill Codes";
                }
                action("Capacity Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Capacity Overview';
                    RunObject = page "Opti Capacity Overview";
                    ToolTip = 'Open the Capacity Overview matrix of requested, assigned, and free capacity per skill.';
                }
                action("Set Capacity")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Capacity';
                    RunObject = report "Opti Set Capacity opt.";
                    ToolTip = 'Batch-set or update resource capacity for many resources at once, based on a Work-Hour Template and a date range.';
                }
            }
            group("SettingGroup")
            {
                Caption = 'Setup';

                group("VisualSetup")
                {
                    Caption = 'Visual Setup';

                    action("GanttSettings")
                    {
                        ToolTip = 'Executes the Gantt Settings action.';
                        Caption = 'Gantt Settings';
                        Image = Setup;
                        ApplicationArea = All;
                        RunObject = page "Opti Gantt Chart Setup";
                    }
                    action("Task Scheduler Setup")
                    {
                        ToolTip = 'Executes the Task Scheduler Setup action.';
                        Caption = 'Task Scheduler Setup';
                        Image = Setup;
                        ApplicationArea = All;
                        RunObject = page "Opti Task Scheduler Setup";
                    }
                    action("Res. Capacity Scheduler Setup")
                    {
                        ToolTip = 'Executes the Res. Capacity Scheduler Setup action.';
                        Caption = 'Resource Capacity Scheduler Setup';
                        Image = Setup;
                        ApplicationArea = All;
                        RunObject = page "Opti Res. Cap. Scheduler Setup";
                    }
                    action("Resource Scheduler Setup")
                    {
                        ToolTip = 'Executes the Resource Scheduler Setup action.';
                        Caption = 'Resource Scheduler Setup';
                        Image = Setup;
                        ApplicationArea = All;
                        RunObject = page "Opti Resource Scheduler Setup";
                    }
                    action("Order Intake Kanban Setup")
                    {
                        ToolTip = 'Executes the Order Intake Kanban Setup action.';
                        Caption = 'Order Intake Kanban Setup';
                        Image = Setup;
                        ApplicationArea = All;
                        RunObject = page "Opti Order Intake Kanban Setup";
                    }
                }
                action("Projejct Type")
                {
                    ToolTip = 'Executes the Projejct Type action.';
                    Caption = 'Project Type';
                    Image = ProjectExpense;
                    ApplicationArea = All;
                    RunObject = page "Opti Project Type List Opt.";
                }
                action("Daily Optimizer Setup")
                {
                    ToolTip = 'Executes the Daily Optimizer Setup action.';
                    Caption = 'Daily Optimizer Setup';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "Opti Daily Optimizer Setup";
                }
                action("WorkOrderItemPricing")
                {
                    Caption = 'Work Order Item Pricing';
                    Image = SalesPrices;
                    ApplicationArea = All;
                    RunObject = page "Sales Price Lists";
                    ToolTip = 'Manage item prices for work orders. Prices are applied automatically based on customer, date, and quantity.';
                }
            }

            group("Integration")
            {
                Caption = 'Integration';

                action("API Record Exposed")
                {
                    ToolTip = 'Executes the API Record Exposed action.';
                    Caption = 'API Record Exposed';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "API Record Exposed Opti";
                }
                action("Update and Delete Log")
                {
                    ToolTip = 'Executes the Update and Delete Log action.';
                    Caption = 'Update and Delete Log';
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "Opti Upd. Del. Log List";
                }
            }
        }
    }
}