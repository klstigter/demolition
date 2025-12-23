page 50650 "Gantt Chart Setup"
{
    PageType = Card;
    SourceTable = "Gantt Chart Setup";
    Caption = 'Gantt Settings';
    UsageCategory = Administration;
    ApplicationArea = All;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            group(Dates)
            {
                Caption = 'Gantt Date Settings';
                field("From Date"; rec."From Date") { }
                field("To Date"; rec."To Date") { }
            }

            group(Columns)
            {
                Caption = 'Visible Columns';
                group(Gridcolumns)
                {

                    field("Show Start Date"; rec."Show Start Date") { }
                    field("Show Duration"; rec."Show Duration") { }
                    field("Show Constraint Type"; rec."Show Constraint Type") { }
                    field("Show Constraint Date"; rec."Show Constraint Date") { }
                    field("Show Task Type"; rec."Show Task Type") { }
                }

            }
        }
    }

    trigger OnOpenPage()
    begin
        rec.EnsureUserRecord();
    end;


}
