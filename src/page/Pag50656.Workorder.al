page 50656 "Work Order Sub"
{
    PageType = ListPart;
    SourceTable = "Work Order";
    DelayedInsert = true;


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(workorderNo; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                    Visible = true;
                    trigger OnAssistEdit()
                    begin
                        if rec.AssistEdit(rec) then
                            CurrPage.Update();
                    end;
                }
                field(orderIntakeNo; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer No. field.', Comment = '%';
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

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Job: Record Job;
                        JobList: Page "Opti Job List";
                    begin
                        if Rec."Project No." = '' then
                            exit(false);

                        Job.Get(Rec."Project No.");
                        Clear(JobList);
                        JobList.SetTableView(Job);
                        JobList.LookupMode(true);
                        if JobList.RunModal() = ACTION::LookupOK then begin
                            JobList.GetRecord(Job);
                            if Job."No." <> Rec."Project No." then begin
                                Rec.Validate("Project No.", Job."No.");
                                currPage.Update(true);
                                Text := Job."No.";
                            end;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Project Task No."; Rec."Project Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Project Task No. field.', Comment = '%';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Task: Record "Job Task";
                        TaskList: Page "Job Task List - Project";
                    begin
                        if Rec."Project No." = '' then
                            exit(false);

                        Task.SetRange("Job No.", Rec."Project No.");
                        if Rec."Project Task No." <> '' then
                            Task.Get(Rec."Project No.", Rec."Project Task No.");
                        Clear(TaskList);
                        TaskList.SetTableView(Task);
                        TaskList.LookupMode(true);
                        if TaskList.RunModal() = ACTION::LookupOK then begin
                            TaskList.GetRecord(Task);
                            if Task."Job Task No." <> Rec."Project Task No." then begin
                                Rec.Validate("Project Task No.", Task."Job Task No.");
                                currPage.Update(true);
                                Text := Task."Job Task No.";
                            end;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Date Window Start"; Rec."Date Window Start")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Date Window Start field.', Comment = '%';
                }
                field("Date Window End"; Rec."Date Window End")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Date Window End field.', Comment = '%';
                }
                field("Deadline Date"; Rec."Deadline Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Deadline Date field.', Comment = '%';
                }
                // field("Time Span Days"; Rec."Time Span Days")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Time Span Days field.', Comment = '%';
                //     trigger OnValidate()
                //     var

                //     begin
                //         CurrPage.Update(true);
                //     end;
                // }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requested Hours.', Comment = '%';
                }
                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Assigned Hours.', Comment = '%';
                }
                field("Realized Hours"; Rec."Realized Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Realized Hours.', Comment = '%';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(WorkOrderLines)
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
                    JobRec: Record Job;
                    JobTaskRec: Record "Job Task";

                begin
                    if not JobRec.get(rec."Customer No.") then begin
                        JobRec.init();
                        JobRec."No." := rec."Customer No.";
                        JobRec.insert();
                    end;
                    if not JobTaskRec.Get(JobRec."No.", Rec."Work Order No.") then begin
                        JobTaskRec.init();
                        JobTaskRec."Job No." := JobRec."No.";
                        JobTaskRec."Job Task No." := Rec."Work Order No.";
                        JobTaskRec.Description := rec.Description;
                        JobTaskRec.insert();
                    end;
                    // JobTaskRec.init();
                    // JobTaskRec."Job No." := rec."Customer No.";
                    // JobTaskRec."Job Task No." := JobTaskRec.GetNextCustomerTaskNo(rec."Customer No.");
                    // JobTaskRec.Description := rec.Description;
                    // JobTaskRec.insert();

                    rec."Project No." := JobTaskRec."Job No.";
                    rec."Project Task No." := JobTaskRec."Job Task No.";
                end;
            }
            action(OpenSpecification)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Workload: Record "Work Order";
                    pg: page "Workorder Card";
                begin
                    Workload.SetRange("Work Order No.", Rec."Work Order No.");
                    pg.SetTableView(Workload);
                    pg.SetRecord(Workload);
                    pg.RunModal();
                end;
            }
        }
    }

    trigger OnInsertRecord(belowxRec: Boolean): Boolean
    var
        OrderIntak: Record "Order Intake Header opt.";
        OptimizerSetup: record "Daily Optimizer Setup";
        NoSeries: Codeunit "No. Series";
    begin
        OptimizerSetup.Get();
        OptimizerSetup.TestField("Work Order Nos");
        rec."Work Order NOS" := OptimizerSetup."Work Order Nos";
        rec."Work Order No." := NoSeries.GetNextNo(rec."Work Order NOS");
        rec.FilterGroup(4);
        rec."Order Intake No." := rec.GetFilter("Order Intake No.");
        if rec."Order Intake No." <> '' then begin
            OrderIntak.Get(rec."Order Intake No.");
            rec."Customer No." := OrderIntak."Customer No.";
        end;
        rec.FilterGroup(0);
    end;


}