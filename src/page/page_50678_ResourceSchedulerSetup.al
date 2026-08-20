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
