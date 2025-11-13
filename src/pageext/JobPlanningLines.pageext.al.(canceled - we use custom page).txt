pageextension 50600 "DDSIA Job Planning Lines" extends "Job Planning Lines"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Job No.")
        {
            field(Isboor; Rec.IsBoor)
            {
                ApplicationArea = All;
            }
        }
        modify("Job No.")
        {
            visible = ShowJobNo;
        }
        addafter("Planning Date")
        {
            field("Start Time"; Rec."Start Time")
            {
                ApplicationArea = All;
            }
            field("End Planning Date"; Rec."End Planning Date")
            {
                ApplicationArea = All;
            }
            field("End Time"; Rec."End Time")
            {
                ApplicationArea = All;
            }
        }
        addbefore("Document No.")
        {
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                ApplicationArea = All;
            }
        }
        addafter(Quantity)
        {
            field(Depth; Rec.Depth)
            {
                ApplicationArea = All;
                ToolTip = 'Drill depth in cm';
            }
        }
    }

    actions
    {
        addafter("Insert Ext. Texts")
        {
            action(DownloadDeleteJSon)
            {
                Caption = 'Download DeleteJSon';
                ApplicationArea = All;

                trigger OnAction()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                begin
                    RestMgt.DeleteIntegrationJobPlanningLine(Rec, true);
                end;
            }
        }
        addbefore("Category_Process")
        {
            group("Date_Filter")
            {
                Caption = 'Date Filter', Comment = 'Record list will filtered based on date';

                actionref("Today_filter"; "TodayFilter") { }
                actionref("Prev_filter"; "PrevTodayFilter") { }
                actionref("Nex_filter"; "NextTodayFilter") { }
                actionref("VisualPlanningJobRef"; "VisualPlanning") { }
                actionref("VisualPlanningResRef"; "VisualPlanningRes") { }
                actionref("PushToPlanningIntegrationRef"; "PushToPlanningIntegration") { }
                actionref("RefreshRef"; "Refresh") { }
            }
        }
        // Add to an existing group (here addlast(Processing) — any group is fine)
        addbefore("Create &Sales Invoice")
        {
            action(TodayFilter)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Workdays;

                trigger OnAction()
                begin
                    Rec.SetRange("Planning Date", Today);
                    CurrFilterDate := Today;
                    CurrPage.Update();
                end;
            }
            action(PrevTodayFilter)
            {
                Caption = 'Previous Day';
                ApplicationArea = All;
                Image = PreviousSet;

                trigger OnAction()
                begin
                    CurrFilterDate := CalcDate('<-1D>', CurrFilterDate);
                    Rec.SetRange("Planning Date", CurrFilterDate);
                    CurrPage.Update();
                end;
            }
            action(NextTodayFilter)
            {
                Caption = 'Next Day';
                ApplicationArea = All;
                Image = NextSet;

                trigger OnAction()
                begin
                    CurrFilterDate := CalcDate('<1D>', CurrFilterDate);
                    Rec.SetRange("Planning Date", CurrFilterDate);
                    CurrPage.Update();
                end;
            }
            action("VisualPlanning")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning Job';
                RunObject = codeunit "Job Planning Line Handler";
            }
            action("VisualPlanningRes")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning Resource';
                RunObject = codeunit "Resource DayPilot Handler";
            }
            action("PushToPlanningIntegration")
            {
                ApplicationArea = Jobs;
                Caption = 'Push data';
                Image = LinkWeb;
                ToolTip = 'Submit project, Tasks, and Planning Lines into Planning Integration system.';

                trigger OnAction()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                    Job: Record Job;
                begin
                    if job.GET(rec."Job No.") then
                        RestMgt.PushProjectToPlanningIntegration(job, false);
                end;
            }
            action("Refresh")
            {
                ApplicationArea = Jobs;
                Caption = 'Refresh';
                Image = LinkWeb;
                ToolTip = 'Refresh';

                trigger OnAction()
                var
                begin
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        Rec.SetRange("Planning Date", Today);
        CurrFilterDate := Today;
        ShowJobNo := Rec.GetFilter("Job No.") = '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if CurrFilterDate <> 0D then begin
            Rec."Planning Date" := CurrFilterDate;
            Rec.SetRange("Planning Date", CurrFilterDate);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        IntegrationSetup: Record "Planning Integration Setup";
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
        auto: Boolean;
    begin
        // Integration
        if (Rec."Job No." <> '')
           and (Rec."Job Task No." <> '')
           and (Rec."Line No." <> 0)
        then begin
            auto := IntegrationSetup.Get();
            if auto then
                auto := IntegrationSetup."Auto Sync. Integration";
            if not auto then
                exit;
            RestMgt.PushJobPlanningLineToIntegration(Rec, false);
        end;
    end;

    trigger OnModifyRecord(): Boolean
    var
        Res: Record Resource;
        Ven: Record Vendor;
        IntegrationSetup: Record "Planning Integration Setup";
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
        auto: Boolean;
    begin
        // Integration
        auto := IntegrationSetup.Get();
        if auto then
            auto := IntegrationSetup."Auto Sync. Integration";
        if auto then
            auto := (Rec."Vendor No." <> xRec."Vendor No.")
                    or (Rec."No." <> xRec."No.");
        if not auto then
            exit;
        RestMgt.PushJobPlanningLineToIntegration(Rec, false);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
    begin
        RestMgt.DeleteIntegrationJobPlanningLine(Rec, false);
    end;


    var
        CurrFilterDate: Date;
        ShowJobNo: Boolean;
}