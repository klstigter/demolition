page 50703 "Opti Effctv WeekPattern Data"

{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Capacity Week Pattern Hdr";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Effective Week Pattern ID"; Rec."Capacity Week Pattern ID")
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
                field("No. of Active Days"; Rec."No. of Active Days")
                {
                    ToolTip = 'Specifies the value of the No. of Active Days field.', Comment = '%';
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ToolTip = 'Specifies the value of the No. of Time Slots field.', Comment = '%';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ToolTip = 'Specifies the value of the Total Hours field.', Comment = '%';
                }
                field("Total Minutes"; Rec."Total Minutes")
                {
                    ToolTip = 'Specifies the value of the Total Minutes field.', Comment = '%';
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