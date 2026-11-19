// API Integeration for Exposing API Pages
page 50639 "API Record Exposed Opti"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "API Record Exposed Opti";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("API Page No."; Rec."API Page No.")
                {
                    ToolTip = 'Specifies the value of the API Page No. field.';
                    ApplicationArea = All;
                }
                field("API Page Name"; Rec."API Page Name")
                {
                    ToolTip = 'Specifies the value of the API Page Name field.';
                    ApplicationArea = All;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies the value of the Table ID field.';
                    ApplicationArea = All;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ToolTip = 'Specifies the value of the Table Name field.';
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

}