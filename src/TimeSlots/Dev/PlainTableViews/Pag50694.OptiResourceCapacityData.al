page 50694 "Opti Resource Capacity Data"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Resource Capacity";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {

                field("Capacity Date"; Rec."Capacity Date")
                {
                    ToolTip = 'Specifies the value of the Capacity Date field.', Comment = '%';
                }
                field("Day Time Slot Header ID"; Rec."Day Time Slot Header ID")
                {
                    ToolTip = 'Specifies the value of the Day Time Slot ID field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ToolTip = 'Specifies the value of the Entry Type field.', Comment = '%';
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.', Comment = '%';
                }
                field(Manual; Rec.Manual)
                {
                    ToolTip = 'Specifies the value of the Manual field.', Comment = '%';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ToolTip = 'Specifies the value of the Resource No. field.', Comment = '%';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ToolTip = 'Specifies the value of the Working Hours field.', Comment = '%';
                }
                field("Working Minutes"; Rec."Working Minutes")
                {
                    ToolTip = 'Specifies the value of the Working Minutes field.', Comment = '%';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
}