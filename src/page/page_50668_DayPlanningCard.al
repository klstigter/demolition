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
                    field("Task Date"; Rec."Work Date")
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
                    field("Requested Pool Resource No."; Rec."Requested Pool Resource No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the pool resource number.';

                    }
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
                    field("Assigned Pool Resource No."; Rec."Assigned Pool Resource No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the pool resource number.';
                    }

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
            action(CopyRequestedToAssigned)
            {
                Caption = 'Accept Requested';
                ToolTip = 'Copies the requested resource and hours to the assigned resource and hours for the selected day planning line.';
                ApplicationArea = All;
                shortcutkey = 'Alt+C';
                Image = Copy;
                Promoted = true;
                promotedCategory = Process;
                promotedOnly = true;

                trigger OnAction()
                begin
                    Rec.CopyRequestedToAssigned();
                end;
            }
        }
    }
    trigger OnNewRecord(BelowRecord: Boolean)
    begin
        Rec.FilterGroup(2);
        if (Rec."Work Date" = 0D) and (Rec.GetFilter("Work Date") <> '') then
            Rec."Work Date" := Rec.GetRangeMin("Work Date");
        if (Rec."Job No." = '') and (Rec.GetFilter("Job No.") <> '') then
            Rec."Job No." := Rec.GetRangeMin("Job No.");
        if (Rec."Job Task No." = '') and (Rec.GetFilter("Job Task No.") <> '') then
            Rec."Job Task No." := Rec.GetRangeMin("Job Task No.");
        if (Rec."Assigned Resource No." = '') and (Rec.GetFilter("Assigned Resource No.") <> '') then begin
            if Rec.GetRangeMin("Assigned Resource No.") <> '' then
                Rec.Validate("Assigned Resource No.", Rec.GetRangeMin("Assigned Resource No."));
        end;
        if (Rec.Skill = '') and (Rec.GetFilter(Skill) <> '') then
            Rec.Skill := Rec.GetRangeMin(Skill);

        Rec.FilterGroup(0); // restore the page's filter group pointer
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        rec.GetNextDayLineNo();
        exit(true);
    end;

    var
        myInt: Integer;
}