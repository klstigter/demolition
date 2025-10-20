pageextension 50608 "DDSIAJobPlanningLinesPart" extends "Job Planning Lines Part"
{
    layout
    {
        // Add changes to page layout here
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
        // Add changes to page actions here
        addafter(CreatePurchaseOrder)
        {
            action("DownloadJsonRequest")
            {
                ApplicationArea = Jobs;
                Caption = 'Download JSon Request text';
                Image = LinkWeb;
                ToolTip = 'Download JSon Request text for Planning Integration system.';

                trigger OnAction()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                begin
                    RestMgt.PushJobPlanningLineToIntegration(Rec, true);
                end;
            }
        }
    }

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
    //myInt: Integer;
}