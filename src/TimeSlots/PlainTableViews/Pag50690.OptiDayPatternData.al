page 50690 "Opti Day Time Slots Hdr Data"
{
    PageType = List;
    SourceTable = "Opti Day Time Slots Header";
    Caption = 'Opti Day Time Slots Header Data';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Day Pattern ID"; Rec."Day Time SLot Header ID")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Total Working Minutes"; Rec."Total Working Minutes")
                {
                    ApplicationArea = All;
                }
                field("Total Working Hours"; Rec."Total Working Hours")
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