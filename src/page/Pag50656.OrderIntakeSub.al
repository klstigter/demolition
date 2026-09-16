page 50656 "Project Task Sub"
{
    PageType = ListPart;
    SourceTable = "Order Intake Line";
    DelayedInsert = true;
    autosplitkey = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(orderIntakeNo; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }

                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Project No. field.', Comment = '%';
                }
                field("Project Task No."; Rec."Project Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Project Task No. field.', Comment = '%';
                }
                field("Planned Start Date"; Rec."Planned Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Planned Start Date field.', Comment = '%';
                }
                field("Planned End Date"; Rec."Planned End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Planned End Date field.', Comment = '%';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ProjectPlanningLines)
            {
                ApplicationArea = All;
                Caption = 'Project Planning Lines';
                Image = PlanningWorksheet;
                ToolTip = 'Open the material lines for the selected work order.';
                trigger OnAction()
                var
                    JobPlanningLines: Record "Job Planning Line";
                    WorkOrderLinesPage: Page "Job Planning Lines";
                begin
                    JobPlanningLines.SetRange("Job No.", Rec."Project No.");
                    JobPlanningLines.SetRange("Job Task No.", Rec."Project Task No.");
                    WorkOrderLinesPage.SetTableView(JobPlanningLines);
                    WorkOrderLinesPage.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(CreateNewCustomerTask)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    OrderIntake: record "Order Intake Header opt.";
                    JobRec: Record Job;
                    JobTaskRec: Record "Job Task";
                    OptimizerSetup: record "Daily Optimizer Setup";
                    NoSeries: Codeunit "No. Series";
                    NewTaskNo: Code[20];
                begin
                    OrderIntake.Get(Rec."Order Intake No.");
                    OrderIntake.TestField("Customer No.");
                    if not JobRec.get(OrderIntake."Customer No.") then begin
                        JobRec.init();
                        JobRec."No." := OrderIntake."Customer No.";
                        JobRec.validate("Sell-to Customer No.", OrderIntake."Customer No.");
                        JobRec.insert();
                    end;
                    OptimizerSetup.Get();
                    OptimizerSetup.TestField("Work Order Nos");
                    NewTaskNo := NoSeries.GetNextNo(OptimizerSetup."Work Order Nos");
                    if not JobTaskRec.Get(JobRec."No.", NewTaskNo) then begin
                        JobTaskRec.init();
                        JobTaskRec."Job No." := JobRec."No.";
                        JobTaskRec."Job Task No." := NewTaskNo;
                        JobTaskRec.validate("Sell-to Customer No.", OrderIntake."Customer No.");
                        JobTaskRec.Description := rec.Description;
                        JobTaskRec.insert();
                    end;

                    rec."Project No." := JobTaskRec."Job No.";
                    rec."Project Task No." := JobTaskRec."Job Task No.";
                end;
            }
            action(OpenSpecification)
            {
                ApplicationArea = All;
                Caption = 'Open Project Task';
                Image = ProjectToolsProjectMaintenance;
                ToolTip = 'Open the project task card for this project task.';

                trigger OnAction()
                var
                    ProjectTask: Record "Job Task";
                    pg: page "Opti Job Task Card";
                begin
                    ProjectTask.SetRange("Job No.", Rec."Project No.");
                    ProjectTask.SetRange("Job Task No.", Rec."Project Task No.");
                    pg.SetTableView(ProjectTask);
                    pg.SetRecord(ProjectTask);
                    pg.RunModal();
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
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        OrderIntak: Record "Order Intake Header opt.";
        NoSeries: Codeunit "No. Series";
    begin
        rec.FilterGroup(4);
        rec."Order Intake No." := rec.GetFilter("Order Intake No.");
        OrderIntak.Get(rec."Order Intake No.");
        OrderIntak.TestField("Customer No.");
        rec.FilterGroup(0);
    end;

    procedure SetEditable(NewEditable: Boolean)
    begin
        CurrPage.Editable(NewEditable);
    end;

}