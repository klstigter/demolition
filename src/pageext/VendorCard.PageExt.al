pageextension 50604 "DDSIAVendorCard" extends "Vendor Card"
{
    layout
    {
        // Add changes to page layout here
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