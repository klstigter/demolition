page 50678 "Resource Scheduler Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Resource Scheduler Setup';
    SourceTable = "Resource Scheduler Setup";
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Colors)
            {
                Caption = 'Day Planning Bar Colors';

                group(Envelope)
                {
                    Caption = 'Envelope';

                    field("Envelope Color"; Rec."Envelope Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Background color of the full Day Planning bar (visible where neither the Assigned nor Requested strip covers it). Enter a hex color, e.g. #1B3A6B.';
                    }
                    field("Envelope Border Color"; Rec."Envelope Border Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Border color of the full Day Planning bar. Enter a hex color, e.g. #14294D.';
                    }
                    field("Capacity Color"; Rec."Capacity Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Color of the Capacity time-range strip on the Day Planning bar. Enter a hex color, e.g. #F2994A.';
                    }
                    field("Capacity Border Color"; Rec."Capacity Border Color")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Border color of the Capacity bar. Enter a hex color, e.g. #C97F16. Leave blank for no border.';
                    }
                }
                group(AssignedRequested)
                {
                    ShowCaption = false;

                    group(Assigned)
                    {
                        Caption = 'Assigned';

                        field("Assigned Color"; Rec."Assigned Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Color of the Assigned time-range strip on the Day Planning bar. Enter a hex color, e.g. #7FB3FA.';
                        }
                        field("Assigned High (%)"; Rec."Assigned High (%)")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Percentage of the Assigned height relative to envelope.';
                        }
                    }
                    group(Requested)
                    {
                        Caption = 'Requested';

                        field("Requested Color"; Rec."Requested Color")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Color of the Requested time-range strip on the Day Planning bar. Enter a hex color, e.g. #6FCF97.';
                        }
                        field("Requested High (%)"; Rec."Requested High (%)")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Percentage of the Requested height relative to envelope.';
                        }
                    }
                }
            }
            group(Timeline)
            {
                Caption = 'Timeline';

                field("Timeline Hour Step"; Rec."Timeline Hour Step")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of hours between marks on the Task Scheduler''s timeline header (e.g. 3 shows 00, 03, 06...). Leave blank to use the default (3).';
                }
                field("Timeline Start Hour"; Rec."Timeline Start Hour")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hour of day the timeline starts at (e.g. 7 for 07:00). Leave blank/0 for midnight (full day).';
                }
                field("Timeline End Hour"; Rec."Timeline End Hour")
                {
                    ApplicationArea = All;
                    ToolTip = 'Hour of day the timeline ends at (e.g. 19 for 19:00). Leave blank/0 for midnight (full day, i.e. 24).';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        rec.EnsureUserRecord();
    end;
}
