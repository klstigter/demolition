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
            part(ResourcePlanningActivities; "Resource Planning Activities")
            {
                ApplicationArea = Jobs;
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
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Job List";
                }
                action("Job Tasks")
                {
                    ApplicationArea = Suite;
                    Caption = 'Project Tasks';
                    RunObject = Page "Job Task List - Project";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }
                action("Job Planning Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Planning Lines';
                    RunObject = Page "Job Planning Line (Project)";
                    ToolTip = 'Open the list of ongoing project planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (budget) or you can specify what you actually agreed with your customer that he should pay for the project (billable).';
                }
            }

            group("ResourcePlanningGroup")
            {
                Caption = 'Resource Planning';

                action("Jobs Resource")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    Image = Job;
                    RunObject = Page "Job List - Resource";
                    ToolTip = 'Define a project activity by creating a project card with integrated project tasks and project planning lines, structured in two layers. The project task enables you to set up project planning lines and to post consumption to the project. The project planning lines specify the detailed use of resources, items, and various general ledger expenses.';
                }
                action("Job Tasks Resource")
                {
                    ApplicationArea = All;
                    Caption = 'Project Tasks';
                    RunObject = page "Job Task List - Resource";
                    ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                }
                action("Job Planning Lines Res")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Planning Lines';
                    RunObject = Page "Job Planning Line (Resource)";
                    ToolTip = 'Open the list of ongoing project planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (budget) or you can specify what you actually agreed with your customer that he should pay for the project (billable).';
                }

            }
            group("VisualGroup")
            {
                Caption = 'Visual';

                action("VisualPlanning")
                {
                    ApplicationArea = All;
                    Caption = 'Visual Planning';
                    RunObject = codeunit "Job Planning Line Handler";
                }
            }
        }
    }
}