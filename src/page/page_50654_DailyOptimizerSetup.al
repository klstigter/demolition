page 50654 "Daily Optimizer Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Daily Optimizer Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Base Calendar"; Rec."Base Calendar")
                {
                    ApplicationArea = All;
                }
                field("Work hour Template"; Rec."Work hour Template")
                {
                    ApplicationArea = All;
                }
                field("Default Skill"; Rec."Default Skill")
                {
                    ApplicationArea = All;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Order Intake Nos"; Rec."Order Intake Nos")
                {
                    ApplicationArea = All;
                }
                field("Work Order Nos"; Rec."Work Order Nos")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Color)
            {
                Caption = 'Color Setup';

                action(ResourceSchedulerColor)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Scheduler Color';
                    ToolTip = 'Set up colors for Resource Scheduler based on resources, day plannings, and capacity.';
                    Image = ResourcePlanning;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Resource Scheduler Color opt");
                    end;
                }

                action(TaskColor)
                {
                    ApplicationArea = All;
                    Caption = 'Task Color';
                    ToolTip = 'Set up colors for tasks based on job and task.';
                    Image = TaskQualityMeasure;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Task Color Opt.");
                    end;
                }
                action(ProjectTaskTypeColor)
                {
                    ApplicationArea = All;
                    Caption = 'Project Task Type Color';
                    ToolTip = 'Set up colors for project task types.';
                    Image = TaskList;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Project Type Color Opt.");
                    end;
                }
            }

            group(DemoData)
            {
                Caption = 'Demo Data';

                action(CreateDemoData)
                {
                    ApplicationArea = All;
                    Caption = 'Create Demo Data';
                    ToolTip = 'Delete existing demo data and recreate it fresh for all three demo jobs.';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Create Demo Data");
                    end;
                }
                action(DeleteDemoData)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Demo Data';
                    ToolTip = 'Delete only the records that were created by the demo data run. User-created data is not affected.';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(Codeunit::"Delete Demo Data");
                    end;
                }
                action(DemoDataLog)
                {
                    ApplicationArea = All;
                    Caption = 'Demo Data Log';
                    ToolTip = 'View the log of all records created by the demo data run.';
                    Image = Log;

                    trigger OnAction()
                    begin
                        PAGE.Run(Page::"Demo Data Log");
                    end;
                }
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(ResourceSchedulerColor_ref; ResourceSchedulerColor) { }
                actionref(TaskColor_ref; TaskColor) { }
                actionref(ProjectTaskTypeColor_ref; ProjectTaskTypeColor) { }
            }
            group(Category_DemoData)
            {
                Caption = 'Demo Data';
                actionref(CreateDemoData_ref; CreateDemoData) { }
                actionref(DeleteDemoData_ref; DeleteDemoData) { }
                actionref(DemoDataLog_ref; DemoDataLog) { }
            }
        }
    }



    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        myInt: Integer;
}