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
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(Attachments)
        {
            action(AssignPlanningVendor)
            {
                ApplicationArea = All;
                Caption = 'Assign Planning Vendor';

                trigger OnAction()
                begin
                    AssignPlanningVendor();
                end;
            }
        }
    }

    var
    //myInt: Integer;

    local procedure AssignPlanningVendor()
    var
        RestMgt: Codeunit "DDSIA Rest API Mgt.";
    begin
        RestMgt.hello_test();
    end;
}