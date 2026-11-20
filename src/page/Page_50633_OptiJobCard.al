page 50633 "Opti Job Card"
{
    Caption = 'Opti Job Card';
    PageType = document;
    RefreshOnActivate = true;
    sourceTable = "Job";
    AdditionalSearchTerms = 'Optimized Job Card Planning';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a short description of the project.';
                }
                field("Project Type"; Rec."Project Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of the project. The project type is used to categorize projects. You can set up different project types based on your business needs.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the person at your company who is responsible for the project.';
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person who is assigned to manage the project.';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of archived versions of this project.';
                }
            }
            part(JobTaskLines; "Opti Job Task Lines Subform")
            {
                ApplicationArea = Jobs;
                Caption = 'Tasks';
                SubPageLink = "Job No." = field("No.");
                SubPageView = sorting("Job Task No.")
                              order(ascending);
                UpdatePropagation = Both;
                Editable = JobTaskLinesEditable;
                Enabled = JobTaskLinesEditable;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Task Scheduler (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Task Scheduler (Visual)';
                Image = HumanResources;
                ToolTip = 'Open the task scheduler for this project.';

                trigger OnAction()
                var
                    DayPlanningScheduler: Page "DHX Scheduler (Project)";
                begin
                    DayPlanningScheduler.SetJobTaskFilter(Rec."No.", '');
                    DayPlanningScheduler.RunModal();
                end;
            }
            action("Gantt (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Gantt (Visual)';
                Image = GanttChart;
                ToolTip = 'Open the Gantt chart for this project.';

                trigger OnAction()
                var
                    Gantt: Page "Gantt Demo DHX 2";
                begin
                    Gantt.SetJobFilter(Rec."No.");
                    Gantt.RunModal();
                end;
            }
            action("Resource Calender (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Resource Calender (Visual)';
                Image = Calendar;
                ToolTip = 'Open the resource calendar for the resources assigned to this project.';

                trigger OnAction()
                var
                    ResCalender: Page "Resource Calendar";
                    JobResource: Record Resource;
                begin
                    MarkJobResources(JobResource);
                    ResCalender.SetResourceFilter(JobResource);
                    ResCalender.RunModal();
                end;
            }
            action("Resource Scheduler (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Resource Scheduler (Visual)';
                Image = ResourcePlanning;
                ToolTip = 'Open the resource scheduler for the resources assigned to this project.';

                trigger OnAction()
                var
                    ResScheduler: Page "Resource Scheduler - TimeLine";
                    JobResource: Record Resource;
                begin
                    MarkJobResources(JobResource);
                    ResScheduler.SetResourceNoFilter(JobResource);
                    ResScheduler.RunModal();
                end;
            }
            action("Capacity (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Capacity (Visual)';
                Image = Capacity;
                ToolTip = 'Open the capacity scheduler for the resources assigned to this project.';

                trigger OnAction()
                var
                    ResScheduler: Page "DHX Scheduler (Pool Resource)";
                    JobResource: Record Resource;
                begin
                    MarkJobResources(JobResource);
                    ResScheduler.SetResourceFilter(JobResource);
                    ResScheduler.RunModal();
                end;
            }
            action("Request Assignment (Visual)")
            {
                ApplicationArea = All;
                Caption = 'Request and Assignment Board (Visual)';
                Image = Allocations;
                ToolTip = 'Open the request and assignment board for this project.';

                trigger OnAction()
                var
                    ReqAssignBoard: Page "DHX Request Assignment Board";
                begin
                    ReqAssignBoard.SetJobFilter(Rec."No.");
                    ReqAssignBoard.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Visuals_Ref)
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Task Scheduler (Visual) actionref"; "Task Scheduler (Visual)") { }
                actionref("Gantt (Visual) actionref"; "Gantt (Visual)") { }
                actionref("Resource Calender (Visual) actionref"; "Resource Calender (Visual)") { }
                actionref("Resource Scheduler (Visual) actionref"; "Resource Scheduler (Visual)") { }
                actionref("Capacity (Visual) actionref"; "Capacity (Visual)") { }
                actionref("Request Assignment (Visual) actionref"; "Request Assignment (Visual)") { }
            }
        }
    }


    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        SetNoFieldVisible();
        ActivateFields();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;


    trigger OnAfterGetCurrRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
        JobTaskLinesEditable := Rec.CalcJobTaskLinesEditable();
        CurrPage.JobTaskLines.Page.SetPerTaskBillingFieldsVisible(Rec."Task Billing Method" = Rec."Task Billing Method"::"Multiple customers");
        CurrPage.Update(false);
    end;

    var
        FormatAddress: Codeunit "Format Address";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        JobArchiveManagement: Codeunit "Job Archive Management";
        EmptyShipToCodeErr: Label 'The Code field can only be empty if you select Custom Address in the Ship-to field.';
        NoFieldVisible: Boolean;
        JobTaskLinesEditable: Boolean;
        ExtendedPriceEnabled: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        BillToInformationEditable: Boolean;
        ShouldSearchForCustByName: Boolean;

    local procedure MarkJobResources(var Resource: Record Resource)
    var
        DayPlanning: Record "Day Planning";
        Marked: List of [Code[20]];
    begin
        Resource.Reset();
        Resource.ClearMarks();
        DayPlanning.SetRange("Job No.", Rec."No.");
        DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        DayPlanning.SetLoadFields("Assigned Resource No.");
        if DayPlanning.FindSet() then
            repeat
                if not Marked.Contains(DayPlanning."Assigned Resource No.") then begin
                    Marked.Add(DayPlanning."Assigned Resource No.");
                    if Resource.Get(DayPlanning."Assigned Resource No.") then
                        Resource.Mark(true);
                end;
            until DayPlanning.Next() = 0;
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.JobNoIsVisible();
    end;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    local procedure SetControlVisibility()
    begin
        ShouldSearchForCustByName := Rec.ShouldSearchForCustomerByName(Rec."Sell-to Customer No.");
    end;


}