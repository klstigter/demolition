page 50664 "Fixed Units Rules Card"
{
    Caption = 'Fixed Units Rule';
    PageType = Card;
    SourceTable = "Fixed Units Rules";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this rule applies to a Job Task or a Work Order.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job No. or Work Order No. this rule belongs to.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job Task this rule applies to.';
                    Visible = Rec."Source Type" = Rec."Source Type"::JobTask;
                }
                field("Rule Type"; Rec."Rule Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of resource rule.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this rule.';
                }
            }
            group(RuleDetails)
            {
                Caption = 'Rule Details';
                group(Details)
                {
                    ShowCaption = false;
                    field("Resource No."; Rec."Resource No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the named resource for this rule.';
                        Enabled = Rec."Rule Type" = Rec."Rule Type"::"Named Resource";
                    }
                    field("Skill Code"; Rec."Skill Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the required skill for this rule.';
                        Enabled = Rec."Rule Type" = Rec."Rule Type"::Skill;
                    }
                    field("Resource Pool Code"; Rec."Resource Pool Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the resource pool for this rule.';
                        Enabled = Rec."Rule Type" = Rec."Rule Type"::"Resource Pool";
                    }
                    field("Is Foreman"; Rec."Is Foreman")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether this resource acts as foreman.';
                        Enabled = Rec."Rule Type" = Rec."Rule Type"::Foreman;
                    }
                }
                Group(Quantities)
                {
                    ShowCaption = false;
                    field("Duration in Hours"; Rec."Duration in Hours")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the duration in hours for this rule.';
                    }
                    field("Pool Quantity of Lines"; Rec."Pool Quantity of Lines")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the fixed pool quantity of lines.';
                        Enabled = Rec."Rule Type" = Rec."Rule Type"::"Resource Pool";
                    }
                }
            }
        }
    }
}