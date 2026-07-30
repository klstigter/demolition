page 50699 "Opti Resource Capacity Week"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Resource Capacity Week";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }

                field("Week Start Date"; Rec."Week Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first date of the week.';
                }

                field("Week End Date"; Rec."Week End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date of the week.';
                }

                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the week number.';
                }

                field("Week Year"; Rec."Week Year")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year to which the week belongs.';
                }

                field("Effective Pattern Hash"; Rec."Effective Pattern Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the hash of the effective capacity pattern.';

                }

                field("Effective Week Pattern ID"; Rec."Effective Week Pattern ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the persistent effective week pattern linked to this resource week.';
                }

                field("Source Week Pattern ID"; Rec."Source Week Pattern ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source week pattern ID when the week is aligned to a single source pattern.';
                }

                field("Source Week Pattern Hash"; Rec."Source Week Pattern Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source week pattern hash when the week is aligned to a single source pattern.';
                }

                field("Monday Date"; Rec."Monday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Monday.';
                }

                field("Monday Capacity"; Rec."Monday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Monday.';
                }

                field("Tuesday Date"; Rec."Tuesday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Tuesday.';
                }

                field("Tuesday Capacity"; Rec."Tuesday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Tuesday.';
                }

                field("Wednesday Date"; Rec."Wednesday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Wednesday.';
                }

                field("Wednesday Capacity"; Rec."Wednesday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Wednesday.';
                }

                field("Thursday Date"; Rec."Thursday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Thursday.';
                }

                field("Thursday Capacity"; Rec."Thursday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Thursday.';
                }

                field("Friday Date"; Rec."Friday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Friday.';
                }

                field("Friday Capacity"; Rec."Friday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Friday.';
                }

                field("Saturday Date"; Rec."Saturday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Saturday.';
                }

                field("Saturday Capacity"; Rec."Saturday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Saturday.';
                }

                field("Sunday Date"; Rec."Sunday Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of Sunday.';
                }

                field("Sunday Capacity"; Rec."Sunday Capacity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total capacity for Sunday.';
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