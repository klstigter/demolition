page 50687 "Opti Week Pattern Data"
{
    PageType = List;
    SourceTable = "Opti Week Pattern Header";
    Caption = 'Opti Week Pattern Data';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Capacity Pattern ID"; Rec."Week Pattern ID")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Total Minutes"; Rec."Total Minutes")
                {
                    ApplicationArea = All;
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ApplicationArea = All;
                }
                field("Pattern Hash"; Rec."Pattern Hash")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}