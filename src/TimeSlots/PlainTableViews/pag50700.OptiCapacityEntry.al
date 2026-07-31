page 50700 "Opti Capacity Entry"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Capacity Entry";


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Resource No."; rec."Resource No.")
                {
                }

                field("Capacity Date"; rec."Capacity Date")
                {
                }

                field("Line No."; rec."Line No.")
                {
                }

                field("Entry Type"; rec."Entry Type")
                {
                }

                field("Day Time Slot Header ID"; rec."Day Time Slot Header ID")
                {
                }

                field(Description; rec.Description)
                {
                }

                field("Working Minutes"; rec."Working Minutes")
                {
                }

                field("Working Hours"; rec."Working Hours")
                {
                }

                field("Manual"; rec."Manual")
                {
                }
                field("Capacity Minutes"; rec."Capacity Minutes")
                {
                }

                field("Capacity Hours"; rec."Capacity Hours")
                {
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