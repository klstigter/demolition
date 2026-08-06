page 50698 "OrderIntakeHeaderApi Opt"
{
    PageType = API;
    Caption = 'Order Intake Header API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'OrderIntakeHeader';
    EntitySetName = 'OrderIntakeHeaders';
    SourceTable = "Order Intake Header Opt.";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(no_; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                }
                field(customerNo_; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(customerName; Rec."Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(contactNo_; Rec."Contact No.")
                {
                    Caption = 'Contact No.';
                }
                field(shortDescription; Rec."Short Description")
                {
                    Caption = 'Short Description';
                }
                field(description; Rec.GetDescription())
                {
                    Caption = 'Description';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(noSeries; Rec."No. Series")
                {
                    Caption = 'No. Series';
                }
            }
        }
    }
}
