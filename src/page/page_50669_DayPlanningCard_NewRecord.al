page 50669 "Day Planning Card - New Record"
{
    Caption = 'Day Planning Card - New Record';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Day Planning";
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
                        ApplicationArea = All;
                    }
                    field("Data Owner"; Rec."Data Owner")
                    {
                        ApplicationArea = All;
                    }
                    field("Task Date"; Rec."Plan Date")
                    {
                        ApplicationArea = All;
                        Caption = 'Work Date';
                    }
                    field("Day No."; Rec."Day No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Work Order No."; Rec."Work Order No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Pattern Line No."; Rec."Pattern Line No.")
                    {
                        ApplicationArea = All;
                    }
                    field(skill; Rec."Skill")
                    {
                        ApplicationArea = All;
                    }
                    field(Capacity; Rec."Capacity")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Requested)
                {
                    field("Requested Resource No."; Rec."Requested Resource No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Start Time Requested"; Rec."Start Time Requested")
                    {
                        ApplicationArea = All;
                    }
                    field("End Time Requested"; Rec."End Time Requested")
                    {
                        ApplicationArea = All;
                    }
                    field("Non Working Minutes Requested"; Rec."Non Working Minutes Requested")
                    {
                        ApplicationArea = All;
                    }

                    field("Requested Hours"; Rec."Requested Hours")
                    {
                        ApplicationArea = All;
                    }

                }
                group(Assignment)
                {
                    field("Assigned Resource No."; Rec."Assigned Resource No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Start Time Assigned"; Rec."Start Time Assigned")
                    {
                        ApplicationArea = All;
                    }
                    field("End Time Assigned"; Rec."End Time Assigned")
                    {
                        ApplicationArea = All;
                    }
                    field("Non Working Minutes Assigned"; Rec."Non Working Minutes Assigned")
                    {
                        ApplicationArea = All;
                    }

                    field("Assigned Hours"; Rec."Assigned Hours")
                    {
                        ApplicationArea = All;
                    }

                }
                group(Realized)
                {
                    field("Realized Hours"; Rec."Realized Hours")
                    {
                        ApplicationArea = All;
                    }
                    field("Start Time Realized"; Rec."Start Time Realized")
                    {
                        ApplicationArea = All;
                    }
                    field("End Time Realized"; Rec."End Time Realized")
                    {
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

    procedure SetNewRecordToSave(DayPlanning: Record "Day Planning")
    begin
        Rec := DayPlanning;
        Rec.Insert(true);
        JobNo := Rec."Job No.";
        JobTaskNo := Rec."Job Task No.";
    end;
}