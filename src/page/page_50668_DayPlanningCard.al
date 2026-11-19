page 50668 "Opti Day Planning Card Opt"
{
    Caption = 'Day Planning Card';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTable = "Opti Day Planning";

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
                        ToolTip = 'Specifies the value of the Job No field.';
                        ApplicationArea = All;
                    }
                    field(JobTaskNo; Rec."Job Task No.")
                    {
                        ToolTip = 'Specifies the value of the Job Task No field.';
                        ApplicationArea = All;
                    }
                }
                Group(SequenceGroup)
                {
                    Caption = 'Sequence';

                    field(skill; Rec."Skill")
                    {
                        ToolTip = 'Specifies the value of the skill field.';
                        ApplicationArea = All;
                    }
                    field(sequence; Rec."Sequence No.")
                    {
                        ToolTip = 'Specifies the value of the sequence field.';
                        ApplicationArea = All;
                    }
                }
                Group(Planning)
                {
                    field("Task Date"; Rec."Plan Date")
                    {
                        ToolTip = 'Specifies the value of the Task Date field.';
                        ApplicationArea = All;
                        caption = 'Plan Date';
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
                    field("Project Manager Status"; Rec."Project Manager Status")
                    {
                        ToolTip = 'Specifies the value of the Project Manager Status field.';
                        ApplicationArea = All;
                        Visible = false;
                    }
                    field("Planner Status"; Rec."Planner Status")
                    {
                        ToolTip = 'Specifies the value of the Planner Status field.';
                        ApplicationArea = All;
                        Visible = false;
                    }
                    field("Vendor Status"; Rec."Vendor Status")
                    {
                        ToolTip = 'Specifies the value of the Vendor Status field.';
                        ApplicationArea = All;
                        Visible = false;
                    }
                    field("Approved Project Manager"; Rec."Approved Project Manager")
                    {
                        ToolTip = 'Specifies the value of the Approved Project Manager field.';
                        ApplicationArea = All;
                        Visible = false;
                    }
                }

                field(DaylineNo; Rec."Day Line No.")
                {
                    ToolTip = 'Specifies the value of the Dayline No field.';
                    ApplicationArea = All;
                }
                field("task date fixation"; Rec."Task Date Fixation")
                {
                    ToolTip = 'Specifies the value of the task date fixation field.';
                    ApplicationArea = All;
                }


            }
            Group(Resource)
            {
                group(Requested)
                {
                    field("Requested Pool Resource No."; Rec."Requested Pool Resource No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the pool resource number.';

                    }
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
                    field("Assigned Pool Resource No."; Rec."Assigned Pool Resource No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the pool resource number.';
                    }

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
                    field("Non Working Minutes"; Rec."Idle Minutes Assigned")
                    {
                        ToolTip = 'Specifies the value of the Non Working Minutes field.';
                        ApplicationArea = All;
                    }
                    field("Assigned Hours"; Rec."Assigned Hours")
                    {
                        ToolTip = 'Specifies the value of the Assigned Hours field.';
                        ApplicationArea = All;
                    }

                    field(Capacity; Rec."Capacity")
                    {
                        ToolTip = 'Specifies the value of the Capacity field.';
                        ApplicationArea = All;
                    }
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

            Group(WorkOrder)
            {
                field("Work Order No."; Rec."Order Intake No.")
                {
                    ToolTip = 'Specifies the value of the Work Order No. field.';
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
        if (Rec."Plan Date" = 0D) and (Rec.GetFilter("Plan Date") <> '') then
            Rec."Plan Date" := Rec.GetRangeMin("Plan Date");
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