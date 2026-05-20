page 50665 "Fixed Units Rules"
{

    Caption = 'Fixed Units Rules';
    PageType = List;
    SourceTable = "Fixed Units Rules";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rules)
            {
                field("Rule Type"; Rec."Rule Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of resource rule.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the named resource for this rule.';
                    Visible = true;
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the required skill for this rule.';
                }
                field("Resource Pool Code"; Rec."Resource Pool Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource pool for this rule.';
                }
                field("Is Foreman"; Rec."Is Foreman")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this resource acts as foreman.';
                }
                field("Duration in Hours"; Rec."Duration in Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the duration in hours for this rule.';
                }
                field("Pool Quantity of Lines"; Rec."Pool Quantity of Lines")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fixed pool quantity of lines.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this rule.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {


        }
    }
}