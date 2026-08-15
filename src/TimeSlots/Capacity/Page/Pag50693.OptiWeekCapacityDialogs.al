page 50693 "Opti Week Capacity Dialogs"
{
    Caption = 'Capacity Time Slots';
    PageType = StandardDialog;
    SourceTable = "Opti Week Capacity Dialog";
    SourceTableTemporary = true;
    ApplicationArea = All;
    DataCaptionExpression = this.GetPageCaption();

    layout
    {
        area(Content)
        {
            repeater(Slots)
            {
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                }
                field("Capacity Date"; Rec."Capacity Date")
                {
                    ApplicationArea = All;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                }
                field("Idle Time"; Rec."Idle Time")
                {
                    ApplicationArea = All;
                }
                field("Working Minutes"; Rec."Working Minutes")
                {
                    ApplicationArea = All;
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure LoadData(ResourceNo: Code[20]; StartDate: Date)
    var
        SlotsQry: Query "Opti Week Capacity Slots Qry";
        EntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        SlotsQry.SetRange(ResourceNo, ResourceNo);
        SlotsQry.SetRange(WeekStartDate, StartDate);

        SlotsQry.Open();
        while SlotsQry.Read() do begin
            EntryNo += 1;

            Rec.Init();
            Rec."Day No." := SlotsQry.WeekdayNo;
            Rec."Entry No." := EntryNo;
            Rec."Weekday Name" := SlotsQry.WeekdayName;
            Rec."Week No." := SlotsQry.WeekNo;
            Rec."Week Year" := SlotsQry.WeekYear;
            Rec."Capacity Date" := DWY2Date(SlotsQry.WeekdayNo, SlotsQry.WeekNo, SlotsQry.WeekYear);
            Rec."Start Time" := SlotsQry.StartTime;
            Rec."End Time" := SlotsQry.EndTime;
            Rec."Idle Time" := SlotsQry.IdleTime;
            Rec."Working Minutes" := SlotsQry.WorkingMinutes;
            Rec."Working Hours" := SlotsQry.WorkingHours;
            Rec."Resource No." := ResourceNo;
            Rec."Week Start Date" := StartDate;
            Rec.Insert();
        end;
        SlotsQry.Close();

        CurrPage.Update(false);
    end;

    Local Procedure GetPageCaption(): Text[100]
    begin
        exit(Format(Rec."Resource No.") + ' - ' + Format(Rec."Week No."));
    end;

}