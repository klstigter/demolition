page 50669 "Opti Day Plan. Card - New Rec."
{
    Caption = 'Day Planning Card - New Record';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Opti Day Planning";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Group(Project)
                {
                    field(JobNo; JobNo)
                    {
                        ToolTip = 'Specifies the value of the Job No field.';
                        Caption = 'Job No';
                        ApplicationArea = All;
                        tableRelation = Job;

                        trigger OnValidate()
                        begin
                            xRec."Job No." := JobNo;
                            Rec."Job No." := JobNo;
                        end;
                    }
                    field(JobTaskNo; JobTaskNo)
                    {
                        ToolTip = 'Specifies the value of the Job Task No field.';
                        Caption = 'Job Task No';
                        ApplicationArea = All;
                        tableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

                        trigger OnValidate()
                        begin
                            xRec."Job Task No." := JobTaskNo;
                            Rec."Job Task No." := JobTaskNo;
                        end;
                    }
                    field("Plan Status"; Rec."Plan Status")
                    {
                        ToolTip = 'Specifies the value of the Plan Status field.';
                        ApplicationArea = All;
                    }
                    field("Data Owner"; Rec."Data Owner")
                    {
                        ToolTip = 'Specifies the value of the Data Owner field.';
                        ApplicationArea = All;
                    }
                    field("Task Date"; Rec."Plan Date")
                    {
                        ToolTip = 'Specifies the value of the Task Date field.';
                        ApplicationArea = All;
                        Caption = 'Plan Dates';
                    }
                    field("Day No."; Rec."Day No.")
                    {
                        ToolTip = 'Specifies the value of the Day No. field.';
                        ApplicationArea = All;
                    }
                    field("Work Order No."; Rec."Order Intake No.")
                    {
                        ToolTip = 'Specifies the value of the Work Order No. field.';
                        ApplicationArea = All;
                    }
                    field(skill; Rec."Skill")
                    {
                        ToolTip = 'Specifies the value of the skill field.';
                        ApplicationArea = All;
                    }
                    field(Capacity; Rec."Capacity")
                    {
                        ToolTip = 'Specifies the value of the Capacity field.';
                        ApplicationArea = All;
                    }
                    field("Project Manager Status"; Rec."Project Manager Status")
                    {
                        ToolTip = 'Specifies the value of the Project Manager Status field.';
                        ApplicationArea = All;
                    }
                    field("Planner Status"; Rec."Planner Status")
                    {
                        ToolTip = 'Specifies the value of the Planner Status field.';
                        ApplicationArea = All;
                    }
                    field("Vendor Status"; Rec."Vendor Status")
                    {
                        ToolTip = 'Specifies the value of the Vendor Status field.';
                        ApplicationArea = All;
                    }
                    field("Approved Project Manager"; Rec."Approved Project Manager")
                    {
                        ToolTip = 'Specifies the value of the Approved Project Manager field.';
                        ApplicationArea = All;
                    }

                }
                group(Requested)
                {
                    field("Requested Resource No."; Rec."Requested Resource No.")
                    {
                        ToolTip = 'Specifies the value of the Requested Resource No. field.';
                        ApplicationArea = All;
                    }
                    field("Start Time Requested"; Rec."Start Time Requested")
                    {
                        ToolTip = 'Specifies the value of the Start Time Requested field.';
                        ApplicationArea = All;
                    }
                    field("End Time Requested"; Rec."End Time Requested")
                    {
                        ToolTip = 'Specifies the value of the End Time Requested field.';
                        ApplicationArea = All;
                    }
                    field("Non Working Minutes Requested"; Rec."Idle Minutes Requested")
                    {
                        ToolTip = 'Specifies the value of the Non Working Minutes Requested field.';
                        ApplicationArea = All;
                    }

                    field("Requested Hours"; Rec."Requested Hours")
                    {
                        ToolTip = 'Specifies the value of the Requested Hours field.';
                        ApplicationArea = All;
                    }

                }
                group(Assignment)
                {
                    field("Assigned Resource No."; Rec."Assigned Resource No.")
                    {
                        ToolTip = 'Specifies the value of the Assigned Resource No. field.';
                        ApplicationArea = All;
                    }
                    field("Start Time Assigned"; Rec."Start Time Assigned")
                    {
                        ToolTip = 'Specifies the value of the Start Time Assigned field.';
                        ApplicationArea = All;
                    }
                    field("End Time Assigned"; Rec."End Time Assigned")
                    {
                        ToolTip = 'Specifies the value of the End Time Assigned field.';
                        ApplicationArea = All;
                    }
                    field("Non Working Minutes Assigned"; Rec."Idle Minutes Assigned")
                    {
                        ToolTip = 'Specifies the value of the Non Working Minutes Assigned field.';
                        ApplicationArea = All;
                    }

                    field("Assigned Hours"; Rec."Assigned Hours")
                    {
                        ToolTip = 'Specifies the value of the Assigned Hours field.';
                        ApplicationArea = All;
                    }

                }
                group(Realized)
                {
                    field("Realized Hours"; Rec."Realized Hours")
                    {
                        ToolTip = 'Specifies the value of the Realized Hours field.';
                        ApplicationArea = All;
                    }
                    field("Start Time Realized"; Rec."Start Time Realized")
                    {
                        ToolTip = 'Specifies the value of the Start Time Realized field.';
                        ApplicationArea = All;
                    }
                    field("End Time Realized"; Rec."End Time Realized")
                    {
                        ToolTip = 'Specifies the value of the End Time Realized field.';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyRequestedToAssigned)
            {
                ToolTip = 'Executes the Copy Requested To Assigned action.';
                Caption = 'Accept Requested';
                ApplicationArea = All;
                Image = Copy;

                trigger OnAction()
                begin
                    Rec.CopyRequestedToAssigned();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ActionRefName; CopyRequestedToAssigned) { }
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];

    procedure SetNewRecordToSave(DayPlanning: Record "Opti Day Planning")
    begin
        Rec := DayPlanning;
        Rec.Insert(false); // temp buffer only: skip OnInsert (PK check fires when no Job/Task filter is set); real Insert(true) happens in the caller
        JobNo := Rec."Job No.";
        JobTaskNo := Rec."Job Task No.";
    end;
}