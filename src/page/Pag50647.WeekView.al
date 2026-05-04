page 50647 "Week View"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Integer;
    SourceTableTemporary = true;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; rec.Number)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                Field(Year; Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Year of the week';
                }
                Field(Week; Week)
                {
                    ApplicationArea = All;
                    ToolTip = 'Week number of the year';
                    Visible = ShowWeek;
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

    trigger OnAfterGetRecord()
    begin
        if ShowWeek then
            SumWk.ExtractYearAndWeek(rec.Number, Year, Week)
        else
            Year := rec.Number;
    end;

    var
        SumWk: Record "Summary Weekly";
        Year: Integer;
        Week: Integer;
        ShowWeek: Boolean;

    procedure SetShowWeek(pShowWeek: Boolean)
    begin
        ShowWeek := pShowWeek;
    end;

    procedure SetTempYearWeek(var TempYearWeek: Record "Integer" temporary)
    var
        SumWk: Record "Summary Weekly";
        Year: Integer;
        Week: Integer;
    begin
        IF TempYearWeek.FindSet() THEN
            repeat
                if ShowWeek then begin
                    Rec.Copy(TempYearWeek);
                    rec.Insert()
                end else begin
                    SumWk.ExtractYearAndWeek(TempYearWeek.Number, Year, Week);
                    if not rec.get(Year) then begin
                        rec.Number := Year;
                        rec.Insert();
                    end;

                end;
            UNTIL TempYearWeek.Next() = 0;
    end;
}