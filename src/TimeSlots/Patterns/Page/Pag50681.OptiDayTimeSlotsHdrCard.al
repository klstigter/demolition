page 50681 "Opti Day-TimeSlots Hdr Card"
{
    PageType = Card;
    SourceTable = "Opti Day-TimeSlots Header";
    Caption = 'Day Pattern';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Day Pattern ID"; Rec."Day Time SLot Header ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the internal day pattern ID.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the day pattern.';
                }
            }

            group(Totals)
            {
                Caption = 'Totals';

                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of time slots in this day pattern.';
                }
                field("Total Working Minutes"; Rec."Total Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total working duration in minutes.';
                }
                field("Total Working Hours"; Rec."Total Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total working duration in hours.';
                }
            }

            part(TimeSlots; "Opti Day TimeSlot Lines")
            {
                ApplicationArea = All;
                Caption = 'Time Slots';

                SubPageLink =
                    "Day Time SLot Header ID" = field("Day Time SLot Header ID");

                UpdatePropagation = Both;
            }
            group(Technical)
            {
                Caption = 'Technical';

                field("Pattern Hash"; Rec."Pattern Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SHA-256 hash representing the time-slot combination.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Recalculate)
            {
                ApplicationArea = All;
                Caption = 'Recalculate';
                Image = Calculate;
                ToolTip = 'Recalculates the totals for the day pattern.';

                trigger OnAction()
                begin
                    rec.RecalculatePattern();
                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(RecalculatePromoted; Recalculate)
            {
            }
        }
    }


}