page 50696 "Opti Resource Capacity Weeks"
{
    Caption = 'Resource Capacity by Week';
    PageType = List;
    SourceTable = "Opti Resource Capacity Week";
    ApplicationArea = All;
    UsageCategory = Documents;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Weeks)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }

                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                }

                field("Week Year"; Rec."Week Year")
                {
                    ApplicationArea = All;
                }

                field("Week Start Date"; Rec."Week Start Date")
                {
                    ApplicationArea = All;
                }

                field("Week End Date"; Rec."Week End Date")
                {
                    ApplicationArea = All;
                }

                field("Monday Capacity"; Rec."Monday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Tuesday Capacity"; Rec."Tuesday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Wednesday Capacity"; Rec."Wednesday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Thursday Capacity"; Rec."Thursday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Friday Capacity"; Rec."Friday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Saturday Capacity"; Rec."Saturday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Sunday Capacity"; Rec."Sunday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Week Capacity"; WeekCapacity)
                {
                    ApplicationArea = All;
                    Caption = 'Week Capacity';
                    Editable = false;
                }
            }

            part(CapacitySlots; "Opti Week Capacity Slots")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWeekPattern)
            {
                ApplicationArea = All;
                Caption = 'Open Week Pattern';
                Image = Calendar;
                ToolTip = 'Open the week pattern list.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Opti Week Pattern List");
                end;
            }

            action(CreateResourceCapacity)
            {
                ApplicationArea = All;
                Caption = 'Create Resource Capacity';
                Image = CalculateCalendar;
                ToolTip = 'Create capacity dates and normal capacity entries for the selected resources and date range.';

                trigger OnAction()
                begin
                    Report.RunModal(
                        Report::"Opti Create Resource Capacity",
                        true,
                        false);
                end;
            }
            action(EditWeek)
            {
                //action(EditWeek)

                ApplicationArea = All;
                Caption = 'Edit Week';
                Image = EditLines;
                ToolTip = 'Edit the capacity time slots for the selected resource and week.';

                trigger OnAction()
                var
                    ResourceWeekEdit: Page "Opti Resource Week Edit";
                begin
                    Rec.TestField("Resource No.");
                    Rec.TestField("Week Start Date");

                    ResourceWeekEdit.SetWeek(
                        Rec."Resource No.",
                        Rec."Week Start Date");

                    ResourceWeekEdit.RunModal();

                    CurrPage.Update(false);

                    CurrPage.CapacitySlots.Page.SetWeek(
                        Rec."Resource No.",
                        Rec."Week Start Date");
                end;
            }
        }

        area(Promoted)
        {
            actionref(OpenWeekPatternPromoted; OpenWeekPattern)
            {
            }
            actionref(CreateResourceCapacityPromoted; CreateResourceCapacity)
            {
            }
            actionref(EditWeekPromoted; EditWeek)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Rec.DeleteAll();

        FirstRelevantDate := GetFirstRelevantDate();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Position: Integer;
        SearchTask: Text[1];
    begin
        /*
        Business Central can supply combinations such as:
        =>
        <=

        These must be handled one character at a time.
        */
        for Position := 1 to StrLen(Which) do begin
            SearchTask := CopyStr(Which, Position, 1);

            if FindWeekRecord(SearchTask) then
                exit(true);
        end;

        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Direction: Integer;
        MovedSteps: Integer;
    begin
        if Steps = 0 then
            exit(0);

        if Steps > 0 then
            Direction := 1
        else
            Direction := -1;

        while Abs(MovedSteps) < Abs(Steps) do begin
            if not FindAdjacentWeek(Direction) then
                break;

            MovedSteps += Direction;
        end;

        exit(MovedSteps);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if IsEmptyCurrentPosition() then begin
            Clear(WeekCapacity);
            exit;
        end;

        Rec.CalcFields(
            "Monday Capacity",
            "Tuesday Capacity",
            "Wednesday Capacity",
            "Thursday Capacity",
            "Friday Capacity",
            "Saturday Capacity",
            "Sunday Capacity");

        WeekCapacity :=
            Rec."Monday Capacity" +
            Rec."Tuesday Capacity" +
            Rec."Wednesday Capacity" +
            Rec."Thursday Capacity" +
            Rec."Friday Capacity" +
            Rec."Saturday Capacity" +
            Rec."Sunday Capacity";

        CurrPage.CapacitySlots.Page.SetWeek(
            Rec."Resource No.",
            Rec."Week Start Date");
    end;

    var
        WeekCapacity: Decimal;
        FirstRelevantDate: Date;
        UserStartDate: Date;
        UserEndDate: Date;

    procedure SetDateRange(StartDt: Date; EndDt: Date)
    begin
        UserStartDate := StartDt;
        UserEndDate := EndDt;
    end;

    local procedure FindWeekRecord(Which: Text[1]): Boolean
    begin
        case Which of
            '-':
                exit(FindFirstWeek());

            '+':
                exit(FindLastWeek());

            '=':
                begin
                    if IsEmptyCurrentPosition() then
                        exit(false);

                    exit(FindCurrentWeek());
                end;

            '>':
                begin
                    if IsEmptyCurrentPosition() then
                        exit(FindFirstWeek());

                    exit(FindNextWeek());
                end;

            '<':
                begin
                    if IsEmptyCurrentPosition() then
                        exit(FindLastWeek());

                    exit(FindPreviousWeek());
                end;
        end;

        exit(false);
    end;

    local procedure FindFirstWeek(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
    begin
        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ApplyEffectiveDateRange(ResourceCapacity);

        if not ResourceCapacity.FindFirst() then
            exit(false);

        exit(
            SetCurrentWeek(
                ResourceCapacity."Resource No.",
                ResourceCapacity."Capacity Date"));
    end;

    local procedure FindLastWeek(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
    begin
        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ApplyEffectiveDateRange(ResourceCapacity);

        if not ResourceCapacity.FindLast() then
            exit(false);

        exit(
            SetCurrentWeek(
                ResourceCapacity."Resource No.",
                ResourceCapacity."Capacity Date"));
    end;

    local procedure FindCurrentWeek(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        SearchStartDate: Date;
        SearchEndDate: Date;
    begin
        if IsEmptyCurrentPosition() then
            exit(false);

        GetEffectiveDateRange(
            EffectiveStartDate,
            EffectiveEndDate);

        SearchStartDate := Rec."Week Start Date";
        SearchEndDate := Rec."Week Start Date" + 6;

        if SearchStartDate < EffectiveStartDate then
            SearchStartDate := EffectiveStartDate;

        if (EffectiveEndDate <> 0D) and
           (SearchEndDate > EffectiveEndDate)
        then
            SearchEndDate := EffectiveEndDate;

        if SearchEndDate < SearchStartDate then
            exit(false);

        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ResourceCapacity.SetRange(
            "Resource No.",
            Rec."Resource No.");

        ResourceCapacity.SetRange(
            "Capacity Date",
            SearchStartDate,
            SearchEndDate);

        if not ResourceCapacity.FindFirst() then
            exit(false);

        exit(
            SetCurrentWeek(
                ResourceCapacity."Resource No.",
                ResourceCapacity."Capacity Date"));
    end;

    local procedure FindAdjacentWeek(Direction: Integer): Boolean
    begin
        case Direction of
            1:
                exit(FindNextWeek());

            -1:
                exit(FindPreviousWeek());
        end;

        exit(false);
    end;

    local procedure FindNextWeek(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        SearchStartDate: Date;
    begin
        if IsEmptyCurrentPosition() then
            exit(FindFirstWeek());

        GetEffectiveDateRange(
            EffectiveStartDate,
            EffectiveEndDate);

        SearchStartDate := Rec."Week Start Date" + 7;

        if SearchStartDate < EffectiveStartDate then
            SearchStartDate := EffectiveStartDate;

        if (EffectiveEndDate <> 0D) and
           (SearchStartDate > EffectiveEndDate)
        then
            exit(FindFirstWeekOfNextResource());

        /*
        First search for a later week belonging to the current resource.
        */
        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ResourceCapacity.SetRange(
            "Resource No.",
            Rec."Resource No.");

        if EffectiveEndDate = 0D then
            ResourceCapacity.SetFilter(
                "Capacity Date",
                '>=%1',
                SearchStartDate)
        else
            ResourceCapacity.SetRange(
                "Capacity Date",
                SearchStartDate,
                EffectiveEndDate);

        if ResourceCapacity.FindFirst() then
            exit(
                SetCurrentWeek(
                    ResourceCapacity."Resource No.",
                    ResourceCapacity."Capacity Date"));

        /*
        No later week exists for the current resource.
        Continue with the next resource.
        */
        exit(FindFirstWeekOfNextResource());
    end;

    local procedure FindFirstWeekOfNextResource(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
    begin
        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ResourceCapacity.SetFilter(
            "Resource No.",
            '>%1',
            Rec."Resource No.");

        ApplyEffectiveDateRange(ResourceCapacity);

        if not ResourceCapacity.FindFirst() then
            exit(false);

        exit(
            SetCurrentWeek(
                ResourceCapacity."Resource No.",
                ResourceCapacity."Capacity Date"));
    end;

    local procedure FindPreviousWeek(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        SearchEndDate: Date;
    begin
        if IsEmptyCurrentPosition() then
            exit(FindLastWeek());

        GetEffectiveDateRange(
            EffectiveStartDate,
            EffectiveEndDate);

        SearchEndDate := Rec."Week Start Date" - 1;

        if (EffectiveEndDate <> 0D) and
           (SearchEndDate > EffectiveEndDate)
        then
            SearchEndDate := EffectiveEndDate;

        /*
        First search for an earlier week belonging to the current resource.
        */
        if SearchEndDate >= EffectiveStartDate then begin
            ResourceCapacity.Reset();
            ResourceCapacity.SetCurrentKey(
                "Resource No.",
                "Capacity Date");

            ResourceCapacity.SetRange(
                "Resource No.",
                Rec."Resource No.");

            ResourceCapacity.SetRange(
                "Capacity Date",
                EffectiveStartDate,
                SearchEndDate);

            if ResourceCapacity.FindLast() then
                exit(
                    SetCurrentWeek(
                        ResourceCapacity."Resource No.",
                        ResourceCapacity."Capacity Date"));
        end;

        /*
        No earlier week exists for the current resource.
        Continue with the previous resource.
        */
        exit(FindLastWeekOfPreviousResource());
    end;

    local procedure FindLastWeekOfPreviousResource(): Boolean
    var
        ResourceCapacity: Record "Opti Resource Capacity";
    begin
        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        ResourceCapacity.SetFilter(
            "Resource No.",
            '<%1',
            Rec."Resource No.");

        ApplyEffectiveDateRange(ResourceCapacity);

        if not ResourceCapacity.FindLast() then
            exit(false);

        exit(
            SetCurrentWeek(
                ResourceCapacity."Resource No.",
                ResourceCapacity."Capacity Date"));
    end;

    local procedure SetCurrentWeek(
        ResourceNo: Code[20];
        CapacityDate: Date): Boolean
    var
        WeekStartDate: Date;
    begin
        if (ResourceNo = '') or
           (CapacityDate = 0D)
        then
            exit(false);

        WeekStartDate := GetFirstDateOfWeek(CapacityDate);

        Rec.Reset();

        if Rec.Get(ResourceNo, WeekStartDate) then
            exit(true);

        Rec.Init();
        Rec."Resource No." := ResourceNo;
        Rec."Week Start Date" := WeekStartDate;
        Rec.SetWeekDates();

        exit(Rec.Insert(false));
    end;

    local procedure IsEmptyCurrentPosition(): Boolean
    begin
        exit(
            (Rec."Resource No." = '') or
            (Rec."Week Start Date" = 0D));
    end;

    local procedure GetEffectiveDateRange(
        var EffectiveStartDate: Date;
        var EffectiveEndDate: Date)
    begin
        if UserStartDate <> 0D then
            EffectiveStartDate := UserStartDate
        else
            EffectiveStartDate := FirstRelevantDate;

        EffectiveEndDate := UserEndDate;
    end;

    local procedure ApplyEffectiveDateRange(
        var ResourceCapacity: Record "Opti Resource Capacity")
    var
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
    begin
        GetEffectiveDateRange(
            EffectiveStartDate,
            EffectiveEndDate);

        if EffectiveEndDate <> 0D then
            ResourceCapacity.SetRange(
                "Capacity Date",
                EffectiveStartDate,
                EffectiveEndDate)
        else
            ResourceCapacity.SetFilter(
                "Capacity Date",
                '>=%1',
                EffectiveStartDate);
    end;

    local procedure GetFirstRelevantDate(): Date
    var
        ResourceCapacity: Record "Opti Resource Capacity";
        CurrentWeekStartDate: Date;
        LastCapacityDate: Date;
    begin
        CurrentWeekStartDate :=
            GetFirstDateOfWeek(Today());

        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Capacity Date",
            "Resource No.");

        ResourceCapacity.SetFilter(
            "Capacity Date",
            '>=%1',
            CurrentWeekStartDate);

        if not ResourceCapacity.IsEmpty() then
            exit(CurrentWeekStartDate);

        ResourceCapacity.Reset();
        ResourceCapacity.SetCurrentKey(
            "Capacity Date",
            "Resource No.");

        if not ResourceCapacity.FindLast() then
            exit(CurrentWeekStartDate);

        LastCapacityDate :=
            ResourceCapacity."Capacity Date";

        exit(GetFirstDateOfWeek(LastCapacityDate));
    end;

    local procedure GetFirstDateOfWeek(InputDate: Date): Date
    begin
        if InputDate = 0D then
            exit(0D);

        exit(
            InputDate -
            Date2DWY(InputDate, 1) + 1);
    end;
}