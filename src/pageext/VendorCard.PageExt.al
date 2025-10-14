pageextension 50604 "DDSIAVendorCard" extends "Vendor Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Receiving)
        {
            group(PlanningIntegration)
            {
                Caption = 'Planning Integration';

                field("Planning Vendor id"; Rec."Planning Vendor id")
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        RestMgt: Codeunit "DDSIA Rest API Mgt.";
                        VendorId: Integer;
                        VendorName: Text;
                    begin
                        VendorId := RestMgt.SelectPlanningVendor(VendorName);
                        if VendorId <> 0 then begin
                            Rec."Planning Vendor id" := VendorId;
                            Rec."Planning Vendor Name" := VendorName;
                        end;
                    end;
                }
                field("Planning Vendor Name"; Rec."Planning Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("access planning integration test"; 'access planning integration test')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnAssistEdit()
                    begin
                        hellotest();
                    end;
                }
                field("Refresh Resources"; 'Refresh Integration Resources')
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnAssistEdit()
                    begin
                        RefreshResource();
                    end;
                }
            }
        }
    }

    var
    //myInt: Integer;

    local procedure hellotest()
    var
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
    begin
        RestMgt.hello_test();
    end;

    local procedure RefreshResource()
    var
        TempVndorId: record Integer temporary;
        ResAPI: codeunit "DDSIA Rest API Mgt.";
        ConfirmLbl: label 'Integration Resources will be refresh, continue?';
    begin
        if not Confirm(ConfirmLbl) then
            exit;
        if Rec."Planning Vendor id" <> 0 then begin
            TempVndorId.Init();
            TempVndorId.Number := Rec."Planning Vendor id";
            TempVndorId.Insert();
        end;
        ResAPI.RefreshPlanningResource(TempVndorId, false);
    end;
}