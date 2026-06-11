page 50662 "Workorder Card"
{
    Caption = 'Workorder';
    PageType = Card;
    SourceTable = "Work Order";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    trigger OnAssistEdit()
                    begin
                        if rec.AssistEdit(rec) then
                            CurrPage.Update();
                    end;
                }
                field("Order Intake No."; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Project No."; Rec."Project No.")
                {
                    ApplicationArea = All;
                }
                field("Project Task No."; Rec."Project Task No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

            }

            group(Scheduling)
            {

                group(Dates)
                {
                    ShowCaption = false;
                    field("Date Window Start"; Rec."Date Window Start")
                    {
                        ApplicationArea = All;
                    }
                    field("Date Window End"; Rec."Date Window End")
                    {
                        ApplicationArea = All;
                    }
                    field("Deadline Date"; Rec."Deadline Date")
                    {
                        ApplicationArea = All;
                    }
                    field("Placeholder Date"; Rec."Placeholder Date")
                    {
                        ApplicationArea = All;
                    }
                }
                field("Time Span Days"; Rec."Time Span Days")
                {
                    ApplicationArea = All;
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Lookup = false;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = All;
                }
            }
            Group(LongDescription)
            {
                Caption = 'Long Description';
                usercontrol(RichTextEditor; DHXRichTextAddin)
                {
                    ApplicationArea = All;

                    /// <summary>
                    /// Fires once when the DHTMLX RichText editor is ready.
                    /// Load the current record's blob content into the editor.
                    /// </summary>
                    trigger ControlReady()
                    begin
                        AddinReady := true;
                        CurrPage.RichTextEditor.SetValue(Rec.GetDescription());
                    end;

                    /// <summary>
                    /// Fires ~800 ms after the user stops typing (debounced in JS).
                    /// Persist the HTML into the blob field on the record.
                    /// </summary>
                    trigger OnTextChanged(Html: Text)
                    begin
                        Rec.SetDescription(Html);
                    end;
                }
            }
            // part(SpecificationLines; "Workorder Cap. Req. Subfrm")
            // {
            //     ApplicationArea = All;
            //     SubPageLink = "Workorder No." = FIELD("Work Order No.");
            // }
            part("Day Plannings"; "Work Order Day Plannings")
            {
                ApplicationArea = All;
                SubPageLink = "Work Order No." = FIELD("Work Order No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DayPlanningsCreation)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Caption = 'Day plannings creation';
                Image = HumanResources;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                var
                    Page: Page "Day Planning Pattern";
                begin
                    page.fillbuffer(Rec."Project No.", Rec."Project Task No.", Rec."Work Order No.");
                    Page.Run();
                    CurrPage.Update();
                end;
            }
            action(DayPlannings)
            {
                ApplicationArea = All;
                Caption = 'Day plannings';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Image = HumanResources;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                var
                    ResourcePage: Page "Day Plannings";
                    DayPlanning: Record "Day Planning";
                begin
                    DayPlanning.SetRange("Job No.", Rec."Project No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Project Task No.");
                    ResourcePage.SetTableView(DayPlanning);
                    ResourcePage.Run();
                end;
            }
            action(GanttChartDHX)
            {
                ApplicationArea = All;
                Image = GanttChart;
                Caption = 'Gantt Chart';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                //RunObject = page "Gantt Demo DHX 2";
                trigger OnAction()
                var
                    Gantt: page "Gantt Demo DHX 2";
                begin
                    Gantt.SetJobFilter(Rec."Project No.");
                    Gantt.RunModal();
                end;

            }
            action("Fixed Units Rules")
            {
                ApplicationArea = All;
                Image = Resource;
                Caption = 'Fixed Units Rules';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    FixedUnitsRulesPage: Page "Fixed Units Rules";
                    FixedUnitsRulesRec: Record "Fixed Units Rules";
                begin
                    FixedUnitsRulesRec.setrange("Source Type", FixedUnitsRulesRec."Source Type"::WorkOrder);
                    FixedUnitsRulesRec.SetRange("No.", Rec."Work Order No.");
                    FixedUnitsRulesPage.SetTableView(FixedUnitsRulesRec);
                    FixedUnitsRulesPage.RunModal();
                end;
            }
        }
    }
    var
        AddinReady: Boolean;
}