pageextension 50612 "ItemCard Opti" extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Planning)
        {
            group(PlanningIntegration)
            {
                Caption = 'Planning Integration';

                field("Planning Product id"; Rec."Planning Product id")
                {
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        RestMgt: Codeunit "Rest API Mgt.";
                        ProductId: Integer;
                        ProductName: Text;
                    begin
                        ProductId := RestMgt.SelectPlanningProduct(ProductName);
                        if ProductId <> 0 then begin
                            Rec."Planning Product id" := ProductId;
                            Rec."Planning Product Name" := ProductName;
                        end;
                    end;
                }
                field("Planning Vendor Name"; Rec."Planning Product Name")
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
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
    //myInt: Integer;

    local procedure hellotest()
    var
        RestMgt: Codeunit "Rest API Mgt.";
    begin
        RestMgt.hello_test();
    end;
}