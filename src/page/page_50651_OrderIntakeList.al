page 50651 "Opti Order Intake Opt."
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Order Intake Header Opt.";
    CardPageId = "Opti Order Intake Card";
    Caption = 'Orders Intake';
    SourceTableView = sorting("Order Date")
                      order(ascending);

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("DayPlanning Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact number for the order intake. This field is typically used for display purposes and is not required, as the customer number can be used to retrieve the contact number from the related customer record.';
                }
                field(CustomerName; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec."Status")
                {
                    ToolTip = 'Specifies the value of the Status field.';
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

}