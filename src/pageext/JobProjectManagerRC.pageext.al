pageextension 50607 "JobProjectManagerRC Opti" extends "Job Project Manager RC"
{
    layout
    {
        // Add changes to page layout here        
    }

    actions
    {
        // Add changes to page actions here
        addafter(RecurringJobJournals)
        {
            action("Jobs Resource")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects (Resource)';
                Image = Job;
                RunObject = Page "Job List - Resource";
                ToolTip = 'Define a project activity by creating a project card with integrated project tasks and project planning lines, structured in two layers. The project task enables you to set up project planning lines and to post consumption to the project. The project planning lines specify the detailed use of resources, items, and various general ledger expenses.';
            }
            action("Job Tasks Resource")
            {
                ApplicationArea = All;
                Caption = 'Project Tasks (Resource)';
                RunObject = page "Job Task List - Resource";
                ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
            }
            action("VisualPlanning")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning';
                RunObject = codeunit "Job Planning Line Handler";
            }
        }
        addafter("Resource Registers")
        {
            action("VisualPlanningRes")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning';
                RunObject = codeunit "Resource DayPilot Handler";
            }
            action("Jobs Resources")
            {
                ApplicationArea = Jobs;
                Caption = 'Projects (Resource)';
                Image = Job;
                RunObject = Page "Job List - Resource";
                ToolTip = 'Define a project activity by creating a project card with integrated project tasks and project planning lines, structured in two layers. The project task enables you to set up project planning lines and to post consumption to the project. The project planning lines specify the detailed use of resources, items, and various general ledger expenses.';
            }
            action("Job Tasks Resources")
            {
                ApplicationArea = All;
                Caption = 'Project Tasks (Resource)';
                ToolTip = 'Define the various tasks involved in a project. You must create at least one project task per project because all posting refers to a project task. Having at least one project task in your project enables you to set up project planning lines and to post consumption to the project.';
                RunObject = page "Job Task List - Resource";
            }
        }

    }

    var
        myInt: Integer;
}