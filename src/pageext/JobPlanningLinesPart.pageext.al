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

    var
    //myInt: Integer;
}