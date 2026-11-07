page 50624 "Day Planning Info FactBox"
{
    PageType = CardPart;
    SourceTable = "Day Planning";
    Caption = 'Day Planning Information';

    layout
    {
        area(Content)
        {
            group(DayPlanningDetails)
            {
                Caption = 'Day Planning Details';
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                    visible = false;
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day planning.';
                    Caption = 'Day Line No.';
                    visible = false;
                }
                field("Work Order No."; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                    visible = false;
                }
                field("Task Date"; Rec."Plan Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the task date.';
                    Caption = 'Plan Date';
                }
                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                    ApplicationArea = All;
                }
                field("Plan Status"; Rec."Plan Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the plan status of the day planning.';
                }
                field("Project Manager Status"; Rec."Project Manager Status")
                {
                    ApplicationArea = All;
                }
                field("Planner Status"; Rec."Planner Status")
                {
                    ApplicationArea = All;
                }
                field("Vendor Status"; Rec."Vendor Status")
                {
                    ApplicationArea = All;
                }
                field("Approved Project Manager"; Rec."Approved Project Manager")
                {
                    ApplicationArea = All;
                }

            }
            group(JobInformation)
            {
                Caption = 'Job Information';
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                    Caption = 'Job No.';

                    trigger OnDrillDown()
                    var
                        Job: Record Job;
                        JobCard: Page "Opti Job Card";
                    begin
                        Job.Get(Rec."Job No.");
                        JobCard.SetRecord(Job);
                        JobCard.RunModal();
                    end;
                }
                field(JobDescription; JobDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job description.';
                    Caption = 'Job Description';
                    Editable = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number.';
                    Caption = 'Job Task No.';

                    trigger OnDrillDown()
                    var
                        JobTask: Record "Job Task";
                        JobCard: Page "Job Task Card";
                    begin
                        JobTask.Get(Rec."Job No.", Rec."Job Task No.");
                        JobCard.SetRecord(JobTask);
                        JobCard.RunModal();
                    end;
                }
                field(JobTaskDescription; JobTaskDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task description.';
                    Caption = 'Job Task Description';
                    Editable = false;
                }
            }
            Group(Assigned)
            {
                field("Assigned Resource No."; Rec."Assigned Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the assigned number.';
                    Caption = 'Assigned Resource No.';
                    trigger OnDrillDown()
                    var
                        Resource: Record Resource;
                        ResourceCard: Page "Resource Card";
                    begin
                        Resource.Get(Rec."Assigned Resource No.");
                        ResourceCard.SetRecord(Resource);
                        ResourceCard.RunModal();
                    end;
                }
                Field("Assigned Pool Resource No."; Rec."Assigned Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the assigned pool resource number.';
                    Caption = 'Assigned Pool Resource No.';
                    trigger OnDrillDown()
                    var
                        Resource: Record Resource;
                        ResourceCard: Page "Resource Card";
                    begin
                        Resource.Get(Rec."Assigned Resource No.");
                        ResourceCard.SetRecord(Resource);
                        ResourceCard.RunModal();
                    end;
                }


                field("Assigned Start Time"; Rec."Start Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Assigned start time for this day task.';
                }
                field("Assigned End Time"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Assigned end time for this day task.';
                }
                field("Assigned Non Working Minutes"; Rec."Idle Minutes Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Non Working Minutes Assigned field.', Comment = '%';
                }

                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Assigned hours for this day task.';
                }

                field("Total Assigned Hours"; Rec."Total Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total Assigned Hours field for this day and this requested resource no.', Comment = '%';
                }

            }

            group(Requested)
            {
                Caption = 'Request';

                field("Resource No."; Rec."Requested Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the request number.';
                    Caption = 'Request Resource No.';
                    trigger OnDrillDown()
                    var
                        Resource: Record Resource;
                        ResourceCard: Page "Resource Card";
                    begin
                        Resource.Get(Rec."Requested Resource No.");
                        ResourceCard.SetRecord(Resource);
                        ResourceCard.RunModal();
                    end;
                }
                field("Pool Resource No."; Rec."Requested Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                    trigger OnDrillDown()
                    var
                        Resource: Record Resource;
                        ResourceCard: Page "Resource Card";
                    begin
                        Resource.Get(Rec."Requested Pool Resource No.");
                        ResourceCard.SetRecord(Resource);
                        ResourceCard.RunModal();
                    end;
                }
                field("Start Time"; Rec."Start Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                }
                field("End Time"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                }
                field("Non Working Minutes"; Rec."Idle Minutes Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Non Working Minutes Requested field.', Comment = '%';
                }

                field("Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the requested hours for this day task.';
                }
                field("Total Hours"; Rec."Total Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total Requested Hours field for this day and requested resource no.', Comment = '%';
                }
            }

        }
    }

    var
        JobDescription: Text[100];
        JobTaskDescription: Text[100];

    trigger OnAfterGetRecord()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Task";
    begin
        // Get Job Description
        JobDescription := '';
        if Job.Get(Rec."Job No.") then
            JobDescription := Job.Description;

        // Get Job Task Description
        JobTaskDescription := '';
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            JobTaskDescription := JobTask.Description;
    end;
}
