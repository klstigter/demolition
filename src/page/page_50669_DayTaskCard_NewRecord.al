page 50669 "Day Task Card - New Record"
{
    Caption = 'Day Task Card - New Record';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Day Tasks";
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
                    field("Task Date"; Rec."Task Date")
                    {
                        ApplicationArea = All;
                    }
                    field("Day No."; Rec."Day No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Work Order No."; Rec."Work Order No.")
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
                    field("Requested Hours"; Rec."Requested Hours")
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
                }
                group(Assignment)
                {
                    field("Assigned Resource No."; Rec."Assigned Resource No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Assigned Hours"; Rec."Assigned Hours")
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
                }
            }
        }
    }

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(ActionName)
    //         {

    //             trigger OnAction()
    //             begin

    //             end;
    //         }
    //     }
    // }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];

    procedure SetNewRecordToSave(DayTask: Record "Day Tasks")
    begin
        Rec := DayTask;
        Rec.Insert();
    end;
}