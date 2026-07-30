page 50702 "Opti Eff WeekPattern Line Data"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Eff Week Pattern Line";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Effective Week Pattern ID"; Rec."Effective Week Pattern ID")
                {
                    ToolTip = 'Specifies the value of the Effective Week Pattern ID field.', Comment = '%';
                }
                field("Weekday No."; Rec."Weekday No.")
                {
                    ToolTip = 'Specifies the value of the Weekday No. field.', Comment = '%';
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ToolTip = 'Specifies the value of the Weekday field.', Comment = '%';
                }
                field("Day Pattern ID"; Rec."Day Pattern ID")
                {
                    ToolTip = 'Specifies the value of the Day Pattern ID field.', Comment = '%';
                }
                field("Day Effective Hash"; Rec."Day Effective Hash")
                {
                    ToolTip = 'Specifies the value of the Day Effective Hash field.', Comment = '%';
                }
                field("Entry Count"; Rec."Entry Count")
                {
                    ToolTip = 'Specifies the value of the Entry Count field.', Comment = '%';
                }
                field("Capacity Hours"; Rec."Capacity Hours")
                {
                    ToolTip = 'Specifies the value of the Capacity Hours field.', Comment = '%';
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