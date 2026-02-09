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
            Group(filters)
            {
                Caption = 'Filters';
                field("Job No. Filter"; rec."Job No. Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a filter to limit the Gantt chart to a specific job.';
                }
            }
            group(Dates)
            {
                Caption = 'Gantt Date Settings';

                group(DateRangeOption)
                {
                    field("Date Range Type"; rec."Date Range Type")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the type of date range to display on the Gantt chart.';

                        trigger OnValidate()
                        begin
                            SetDateRangeVisibility();
                            CurrPage.Update();
                        end;
                    }
                }
                group(DateRange)
                {
                    Visible = DateRangeVisible;

                    field("From Date"; rec."From Date")
                    {
                        ApplicationArea = All;
                        Enabled = DateRangeVisible;
                    }
                    field("To Date"; rec."To Date")
                    {
                        ApplicationArea = All;
                        Enabled = DateRangeVisible;
                    }
                }
                group(Calculate)
                {
                    Visible = CalculateVisible;
                    field("From Data Formula"; rec."From Data Formula")
                    {
                        ApplicationArea = All;
                        Enabled = CalculateVisible;
                    }
                    field("To Data Formula"; rec."To Data Formula")
                    {
                        ApplicationArea = All;
                        Enabled = CalculateVisible;
                    }
                }

            }
            group(Loadsettings)
            {
                Caption = 'Data Load Settings';
                field("Load Job Tasks"; rec."Load Job Tasks") { }
                field("Load Resources"; rec."Load Resources") { }
                field("Load Day Tasks"; rec."Load Day Tasks") { }

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
        SetDateRangeVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetDateRangeVisibility();
        CurrPage.Update();
    end;

    var
        [InDataSet]
        DateRangeVisible: Boolean;
        CalculateVisible: Boolean;

    local procedure SetDateRangeVisibility()
    begin
        DateRangeVisible := Rec."Date Range Type" = Rec."Date Range Type"::"Date Range";
        CalculateVisible := Rec."Date Range Type" = Rec."Date Range Type"::"Calculated";
    end;

}
