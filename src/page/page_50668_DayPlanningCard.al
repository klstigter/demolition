page 50668 "Day Planning Card Opt"
{
    Caption = 'Day Planning Card';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "Day Planning";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Group(Project)
                {
                    field(JobNo; Rec."Job No.")
                    {
                        ApplicationArea = All;
                    }
                    field(JobTaskNo; Rec."Job Task No.")
                    {
                        ApplicationArea = All;
                    }

                }
                Group(Planning)
                {
                    field("Task Date"; Rec."Task Date")
                    {
                        ApplicationArea = All;
                    }
                    field("Plan Status"; Rec."Plan Status")
                    {
                        ApplicationArea = All;
                    }
                    field("Data Owner"; Rec."Data Owner")
                    {
                        ApplicationArea = All;
                    }
                }
                field(DaylineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                }


            }
            Group(Resource)
            {
                field(skill; Rec."Skill")
                {
                    ApplicationArea = All;
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
                    field("Non Working Minutes"; Rec."Non Working Minutes Assigned")
                    {
                        ApplicationArea = All;
                    }
                    field("Assigned Hours"; Rec."Assigned Hours")
                    {
                        ApplicationArea = All;
                    }

                    field(Capacity; Rec."Capacity")
                    {
                        ApplicationArea = All;
                    }
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

            Group(WorkOrder)
            {
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field("Pattern Line No."; Rec."Pattern Line No.")
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
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
    trigger OnNewRecord(BelowRecord: Boolean)
    begin
        rec.GetNextDayLineNo();
    end;

    var
        myInt: Integer;
}