page 50656 Workorder
{
    PageType = ListPart;
    SourceTable = "Workorder";
    DelayedInsert = true;


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(workorderNo; Rec."Workorder No.")
                {
                    ApplicationArea = All;
                    Visible = true;
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
                field("Long Description"; Rec."Long Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Long Description field.', Comment = '%';
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
                field("Time Span Days"; Rec."Time Span Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Time Span Days field.', Comment = '%';
                    trigger OnValidate()
                    var

                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Requested Capacity"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requested Capacity field.', Comment = '%';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
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
                    JobTaskRec.init();
                    JobTaskRec."Job No." := rec."Customer No.";
                    JobTaskRec."Job Task No." := JobTaskRec.GetNextCustomerTaskNo(rec."Customer No.");
                    JobTaskRec.Description := rec.Description;
                    JobTaskRec.insert();

                    rec."Project No." := JobTaskRec."Job Task No.";
                    rec."Project Task No." := JobTaskRec."Job Task No.";
                end;
            }
            action(OpenSpecification)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Workload: Record "Workorder";
                    pg: page "Workorder Card";
                begin
                    Workload.SetRange("Workorder No.", Rec."Workorder No.");
                    pg.SetTableView(Workload);
                    pg.SetRecord(Workload);
                    pg.RunModal();
                end;
            }
        }
    }
}