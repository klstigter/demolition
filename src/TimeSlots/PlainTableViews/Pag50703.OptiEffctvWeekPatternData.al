page 50703 "Opti Effctv WeekPattern Data"

{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Effective Week Pattern";

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
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Pattern Hash"; Rec."Pattern Hash")
                {
                    ToolTip = 'Specifies the value of the Pattern Hash field.', Comment = '%';
                }
                field("Source Week Pattern ID"; Rec."Source Week Pattern ID")
                {
                    ToolTip = 'Specifies the value of the Source Week Pattern ID field.', Comment = '%';
                }
                field("Source Week Pattern Hash"; Rec."Source Week Pattern Hash")
                {
                    ToolTip = 'Specifies the value of the Source Week Pattern Hash field.', Comment = '%';
                }
                field("No. of Active Days"; Rec."No. of Active Days")
                {
                    ToolTip = 'Specifies the value of the No. of Active Days field.', Comment = '%';
                }
                field("Total Capacity Hours"; Rec."Total Capacity Hours")
                {
                    ToolTip = 'Specifies the value of the Total Capacity Hours field.', Comment = '%';
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