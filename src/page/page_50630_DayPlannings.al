page 50630 "Day Plannings"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Planning";
    Caption = 'Day Plannings';
    CardPageId = "Day Planning Card Opt";
    //Editable = false;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            Group(JobFilter)

            {
                Caption = 'Filters';
                Visible = ShowFIlters;
                field("Job No. Filter"; GetJobNoFilterText())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number to filter on.';
                    Visible = Not ShowJob;
                    Editable = false;
                }
                field("Job Task No. Filter"; GetJobTaskNoFilterText())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number to filter on.';
                    Visible = Not ShowJobTask;
                    Editable = false;
                }
                field("No. Filter"; GetResourceNoFilterText())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number to filter on.';
                    Visible = Not ShowResource;
                    Editable = false;
                }
                field("Skill Filter"; GetSkillFilterText())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill to filter on.';
                    Visible = Not ShowSkill;
                    Editable = false;
                }
                field("Plan Status Filter"; GetPlanStatusFilterText())
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning status to filter on.';
                    Visible = Not ShowPlanStatus;
                    Editable = false;
                }

            }
            repeater(Lines)
            {
                field(JobNoDisplay; JobNoDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Job No.';
                    ToolTip = 'Specifies the job number.';
                    Visible = ShowJob;
                    Editable = false;
                }
                field(JobTaskNoDisplay; JobTaskNoDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.';
                    ToolTip = 'Specifies the job task number.';
                    Visible = ShowJobTask;
                    Editable = false;
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day task.';
                    StyleExpr = StyleStr;
                    visible = false;
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field("Plan Status"; Rec."Plan Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning status of this day task.';
                    StyleExpr = StyleStr;
                }
                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of this day task.';
                    StyleExpr = StyleStr;
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field("Pattern Line No."; Rec."Pattern Line No.")
                {
                    ApplicationArea = All;
                }
                field(skill; Rec.skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill associated with the resource.';
                    StyleExpr = StyleStr;
                    Visible = ShowSkill;
                }


                field("Assigned Pool Resource No."; Rec."Assigned Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                    StyleExpr = StyleStr;
                }

                field("Assigned Resource No."; Rec."Assigned Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the assigned resource.';
                    StyleExpr = StyleStr;
                    Visible = ShowResource;
                }

                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of assigned hours for this day task, calculated automatically based on start and end times.';
                    Editable = true;
                    StyleExpr = StyleStr;
                }
                field("Start Time Assigned"; Rec."Start Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day.';
                    StyleExpr = StyleStr;
                }
                field("End Time Assigned"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day.';
                    StyleExpr = StyleStr;
                }
                field("Non Working Minutes"; Rec."Non Working Minutes Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the non-working minutes within the task period.';
                    StyleExpr = StyleStr;
                }

                field("Total Assigned Hours"; TotAssignedHours)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of assigned hours for this day task, calculated automatically based on all related day plannings.';
                    Editable = false;
                    StyleExpr = StyleStr;
                    trigger OnDrillDown()
                    var
                        DayPlanning: Page "Day Plannings";
                        DayPlanningRec: Record "Day Planning";
                    begin

                        if rec."Assigned Resource No." = '' then
                            exit;
                        DayPlanningRec.setrange("Assigned Resource No.", Rec."Assigned Resource No.");
                        DayPlanningRec.SetRange("Task Date", Rec."Task Date");
                        DayPlanning.SetTableView(DayPlanningRec);
                        DayPlanning.RunModal();
                    end;
                }
                field("Worked Hours"; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the actual worked hours for this day task.';
                    Editable = true;
                    StyleExpr = StyleStr;
                }
                field("Requested Pool Resource No."; Rec."Requested Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                    StyleExpr = StyleStr;
                }
                field("Requested Resource No."; Rec."Requested Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the requested resource.';
                    StyleExpr = StyleStr;
                    Visible = ShowResource;
                }
                field("Start Time Requested"; Rec."Start Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                    StyleExpr = StyleStr;
                }
                field("End Time Requested"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                    StyleExpr = StyleStr;
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of requested hours for this day task, calculated automatically based on start and end times.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }

                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity available for this day task.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                    StyleExpr = StyleStr;
                    Visible = false;
                }

                field("Start Time Realized"; Rec."Start Time Realized")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day.';
                    StyleExpr = StyleStr;
                }
                field("End Time Realized"; Rec."End Time Realized")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day.';
                    StyleExpr = StyleStr;
                }
                field("Realized Hours"; Rec."Realized Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of realized hours for this day task, calculated automatically based on start and end times.';
                    Editable = true;
                    StyleExpr = StyleStr;
                }


                field(Fulfilled; StyleStr)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the day task has fulfilled the required capacity.';
                    Editable = false;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
                    StyleExpr = StyleStr;
                }
                field("Pool Resource Name"; Rec."Pool Resource Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource name.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number.';
                    StyleExpr = StyleStr;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor name.';
                    StyleExpr = StyleStr;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                    StyleExpr = StyleStr;
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day task.';
                }
                field(Leader; Rec.Leader)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day task.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code.';
                    StyleExpr = StyleStr;
                }

                field(Posted; Rec.Posted)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the day task has been posted.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }
                field("Job Ledger Entry No."; Rec."Job Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Link to the job ledger entry number.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }
                field("Job Resource No."; Rec."Resource Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Link to the resource ledger entry number.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }

            }
        }
        area(FactBoxes)
        {
            part(DayPlanningInfo; "Day Planning Info FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Task Date" = field("Task Date"),
                              "Day Line No." = field("Day Line No."),
                              "Job No." = field("Job No."),
                              "Job Task No." = field("Job Task No.");
            }
            part(ResourceSkills; "Resource Skills FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                SubPageLink = Type = const(Resource), "No." = field("Assigned Resource No.");
            }
            part(ResourceCapacity; "Res. Capacity FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Capacity';
                SubPageLink = "Resource No." = field("Assigned Resource No."),
                              Date = field("Task Date");
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(CopyRequestedToAssigned_Promoted; CopyRequestedToAssigned) { }

            actionref(DayPlanningsCreation_Promoted; DayPlanningsCreation) { }
            actionref(ShowStyleReason_Promoted; ShowStyleReason) { }
            Group(Visuals_Ref)
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
                actionref("DayPlannings (Visual) actionref"; "DayPlannings (Visual)") { }
                actionref("Capacity actionref"; "Capacity (Visual)") { }
            }
        }

        area(Processing)
        {

            action(RefreshDayPlanning)
            {
                ApplicationArea = All;
                Caption = 'Refresh Day Planning';
                ToolTip = 'Refreshes the day planning lines.';
                Image = Refresh;
                Visible = false;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(DayPlanningsCreation)
            {
                ApplicationArea = All;
                Caption = 'Day plannings pattern';
                Image = HumanResources;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                var
                    Page: Page "Day Planning Pattern";
                begin
                    page.fillbuffer(Rec."Job No.", Rec."Job Task No.", '');
                    Page.Run();
                    CurrPage.Update();
                end;
            }
            action(CopyRequestedToAssigned)
            {
                Caption = 'Accept Requested';
                ApplicationArea = All;
                tooltip = 'Copies the requested resource and hours to the assigned resource and hours for the selected day planning line.';
                shortcutkey = 'Alt+C';
                Image = Copy;

                trigger OnAction()
                var
                    DayPlanning: Record "Day Planning";
                    n: Integer;
                    Lbl: Label '%1 day planning lines have been copied from requested to assigned.';
                begin
                    CurrPage.SetSelectionFilter(DayPlanning);
                    if DayPlanning.FindSet() then
                        repeat
                            DayPlanning.CopyRequestedToAssigned();
                            n += 1;
                        until DayPlanning.Next() = 0;
                    message(Lbl, n);
                end;
            }
            action(ShowStyleReason)
            {
                Caption = 'Show Style Reason';
                ApplicationArea = All;
                ToolTip = 'Shows the reason for the style applied to this day planning line.';
                Image = Info;
                shortcutkey = 'Alt+I';
                trigger OnAction()
                var
                    Descr: Text;
                begin
                    Descr := this.CalculateStyle(true);
                    Message(Descr);
                end;
            }
            action("Schedule (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                    ResourceNo: code[20];
                begin
                    if rec."Assigned Resource No." <> '' then
                        ResourceNo := rec."Assigned Resource No."
                    else
                        ResourceNo := rec."Requested Resource No.";
                    ResScheduler.SetResourceFilter(ResourceNo);
                    ResScheduler.RunModal();
                end;
            }
            action("DayPlannings (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    DayPlanningScheduler: page "DHX Scheduler (Project)";
                    ResourceNo: code[20];
                begin
                    if rec."Assigned Resource No." <> '' then
                        ResourceNo := rec."Assigned Resource No."
                    else
                        ResourceNo := rec."Requested Resource No.";
                    DayPlanningScheduler.SetResourceFilter(ResourceNo);
                    DayPlanningScheduler.RunModal();
                end;
            }
            action("Capacity (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Scheduler (Pool Resource)";
                begin
                    //ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }

        }
    }
    var
        StyleOpt: option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        StyleStr: text;
        TotAssignedHours: Decimal;
        JobNoDisplay: Text[20];
        JobTaskNoDisplay: Text[20];
        SHowJob: Boolean;
        ShowJobTask: Boolean;
        ShowResource: Boolean;
        ShowSkill: Boolean;
        ShowPlanStatus: Boolean;
        ShowFIlters: Boolean;

    trigger OnInit()
    begin
        ShowJob := true;
        ShowJobTask := true;
        ShowResource := true;
        ShowSkill := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Job No.", "Job Task No.", "Task Date", "Day Line No.");
        Rec.Ascending(true);
    end;

    trigger OnAfterGetRecord()
    begin
        this.CalculateStyle();
        GetTotalAssignedHours();
        UpdateGroupDisplay();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        this.CalculateStyle();
        GetTotalAssignedHours();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not ShowJob then
            Rec."Job No." := GetJobNoFilterText();
        if not ShowJobTask then
            Rec."Job Task No." := GetJobTaskNoFilterText();
        if not ShowResource then
            Rec."Assigned Resource No." := GetResourceNoFilterText();
        if not ShowSkill then
            Rec.Skill := GetSkillFilterText();

    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        rec."Day Line No." := rec.GetNextDayLineNo(rec."Task Date", rec."Job No.", rec."Job Task No.");
        if Rec."Plan Status" <> Rec."Plan Status"::"In Request" then
            Rec.TestField("Assigned Resource No.");
        exit(true);
    end;

    local procedure CalculateStyle()
    begin
        CalculateStyle(false);
    end;

    local procedure CalculateStyle(GiveDescription: Boolean) Descr: Text
    begin

        rec.CalcFields(Capacity, "Total Assigned Hours");
        case true of
            rec."Assigned Resource No." = '':
                begin
                    StyleOpt := StyleOpt::StrongAccent;
                    Descr := 'No resource assigned';
                end;
            rec.Capacity = 0:
                begin
                    StyleOpt := StyleOpt::Unfavorable;
                    descr := 'No capacity available';
                end;
            (this.TotAssignedHours < rec.Capacity) and (rec."Assigned Hours" > 0):
                begin
                    StyleOpt := StyleOpt::StandardAccent;
                    descr := StrSubstNo('Capacity (%1 hours) not fully utilized (%2 hours assigned)', rec.Capacity, this.TotAssignedHours);
                end;
            (this.TotAssignedHours > rec.Capacity):
                begin
                    StyleOpt := StyleOpt::Attention;
                    descr := StrSubstNo('Capacity (%1 hours) over utilized (%2 hours assigned)', rec.Capacity, this.TotAssignedHours);
                end;
            rec."Capacity Fully Utilized":
                begin
                    StyleOpt := StyleOpt::Subordinate;
                    descr := 'Capacity fully utilized';
                end;
        end;
        StyleStr := Format(StyleOpt);
    end;

    procedure GetTotalAssignedHours(): Decimal
    begin
        if rec."Assigned Resource No." = '' then
            TotAssignedHours := 0
        else begin
            rec.CalcFields("Total Assigned Hours");
            TotAssignedHours := Rec."Total Assigned Hours";
        end;

    end;

    procedure SetColumsVisible(pShowJob: Boolean; pShowJobTask: Boolean; pShowResource: Boolean; pShowSkill: Boolean; pShowPlanStatus: Boolean);
    begin
        ShowJob := not pShowJob;
        ShowJobTask := not pShowJobTask;
        ShowResource := not pShowResource;
        ShowSkill := not pShowSkill;
        ShowPlanStatus := not pShowPlanStatus;
        ShowFIlters := True;
    end;

    local procedure UpdateGroupDisplay()
    var
        PrevRec: Record "Day Planning";
    begin
        PrevRec.SetCurrentKey("Job No.", "Job Task No.", "Task Date", "Day Line No.");
        PrevRec.CopyFilters(Rec);
        PrevRec."Job No." := Rec."Job No.";
        PrevRec."Job Task No." := Rec."Job Task No.";
        PrevRec."Task Date" := Rec."Task Date";
        PrevRec."Day Line No." := Rec."Day Line No.";
        if PrevRec.Find('<') and
           (PrevRec."Job No." = Rec."Job No.") and
           (PrevRec."Job Task No." = Rec."Job Task No.")
        then begin
            JobNoDisplay := '';
            JobTaskNoDisplay := '';
        end else begin
            JobNoDisplay := Rec."Job No.";
            JobTaskNoDisplay := Rec."Job Task No.";
        end;
    end;

    local procedure BuildCodeOrFilter(var Values: List of [Code[20]]): Text
    var
        Value: Code[20];
        FilterText: Text;
    begin
        foreach Value in Values do
            if FilterText = '' then
                FilterText := Value
            else
                FilterText += '|' + Value;
        exit(FilterText);
    end;

    local procedure BuildIntegerOrFilter(var Values: List of [Integer]): Text
    var
        Value: Integer;
        FilterText: Text;
    begin
        foreach Value in Values do
            if FilterText = '' then
                FilterText := Format(Value)
            else
                FilterText += '|' + Format(Value);
        exit(FilterText);
    end;

    local procedure StripEmptyFilterMarker(FilterText: Text): Text
    begin
        if FilterText = '''''' then
            exit('');
        exit(FilterText);
    end;

    local procedure GetJobNoFilterText(): Text
    var
        FilterText: Text;
    begin
        rec.FilterGroup(2);
        FilterText := Rec.GetFilter("Job No.");
        rec.FilterGroup(0);
        exit(StripEmptyFilterMarker(FilterText));
    end;

    local procedure GetJobTaskNoFilterText(): Text
    var
        FilterText: Text;
    begin
        rec.FilterGroup(2);
        FilterText := Rec.GetFilter("Job Task No.");
        rec.FilterGroup(0);
        exit(StripEmptyFilterMarker(FilterText));
    end;

    local procedure GetResourceNoFilterText(): Text
    var
        FilterText: Text;
    begin
        rec.FilterGroup(2);
        FilterText := Rec.GetFilter("Assigned Resource No.");
        rec.FilterGroup(0);
        exit(StripEmptyFilterMarker(FilterText));
    end;

    local procedure GetSkillFilterText(): Text
    var
        FilterText: Text;
    begin
        rec.FilterGroup(2);
        FilterText := Rec.GetFilter("Skill");
        rec.FilterGroup(0);
        exit(StripEmptyFilterMarker(FilterText));
    end;

    local procedure GetPlanStatusFilterText(): Text
    var
        FilterText: Text;
    begin
        rec.FilterGroup(2);
        FilterText := Rec.GetFilter("Plan Status");
        rec.FilterGroup(0);
        exit(StripEmptyFilterMarker(FilterText));
    end;
}
