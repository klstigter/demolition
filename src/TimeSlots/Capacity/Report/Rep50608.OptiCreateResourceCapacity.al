report 50608 "Opti Create Resource Capacity"
{
    Caption = 'Create Resource Capacity';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.", "Resource Group No.";
            dataitem(DateWk; Date)
            {
                DataItemTableView = sorting("Period Start") where("Period Type" = const(week));

                dataitem(Date; Date)
                {
                    DataItemTableView = sorting("Period Start") where("Period Type" = const(date));

                    trigger OnPreDataItem()
                    begin
                        Date.SetRange("Period Start", DWY2Date(1, Date2DWY(Datewk."Period Start", 2), Date2DWY(Datewk."Period Start", 3)), DWY2Date(7, Date2DWY(DateWk."Period Start", 2), Date2DWY(datewk."Period Start", 3)));
                    end;

                    trigger OnAfterGetRecord()
                    var
                    begin
                        if Date."Period Start" <= EndDate then
                            CopyDayPattern(date."Period Start");
                    end;


                    trigger OnPostDataItem()
                    begin
                        CloseTempWeekPattern();
                    end;
                }

                trigger OnPreDataItem()
                begin
                    DateWk.SetRange("Period Start", DWY2Date(1, Date2DWY(StartDate, 2), Date2DWY(StartDate, 3)), DWY2Date(1, Date2DWY(EndDate, 2), Date2DWY(EndDate, 3)));
                end;
            }

            trigger OnAfterGetRecord()
            var
                CapacityDate: Date;
            begin
                //CapacityDate := StartDate;
                GetWeekPatternHeader();
                GetWeekPatternLines();
            end;
        }


    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(StartDateField; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                    }

                    field(EndDateField; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                    }

                }
            }
        }
    }

    trigger OnPreReport()
    var
        DailyOptiSetup: Record "Daily Optimizer Setup";
    begin
        dailyOptiSetup.Get();
        if dailyOptiSetup."Work Pattern" = '' then
            Error('The Daily Optimizer Setup record does not have a Work Pattern defined. Please define a Work Pattern in the Daily Optimizer Setup before running this report.');
        DefaultWeekPattern := dailyOptiSetup."Work Pattern";
        ValidateRequest();
    end;

    trigger OnPostReport()
    begin
        Message(
            CapacityCreatedMsg,
            CreatedCapacityDates,
            CreatedCapacityEntries);
    end;

    local procedure ValidateRequest()
    begin
        if StartDate = 0D then
            Error(StartDateRequiredErr);

        if EndDate = 0D then
            Error(EndDateRequiredErr);

        if EndDate < StartDate then
            Error(EndDateBeforeStartDateErr);

    end;

    Local procedure InsertCapacityWeekPatternSet(var Temp: Record "Opti Capacity Week Pattern Ln"; WkPatternID: Integer)
    var
        CapacityWeekPatternLn: Record "Opti Capacity Week Pattern Ln";
    begin
        if Temp.FindSet() then
            repeat
                CapacityWeekPatternLn.Init();
                CapacityWeekPatternLn.TransferFields(Temp);
                capacityWeekPatternLn."Effective Week Pattern ID" := WkPatternID;
                CapacityWeekPatternLn.Insert(true);
            until Temp.Next() = 0;
    end;

    Local procedure CloseTempWeekPattern()
    var
        CapacityWkPattern: Record "Opti Capacity Week Pattern Hdr";
        CapWeek: Record "Opti Resource Capacity Week";
        ResourceCapacityWeek: Record "Opti Resource Capacity Week";
        GeneratedHash: Text;
        DoModify: Boolean;
        NewWkPattern: boolean;
        TotalMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        GeneratedHash := CapacityWkPattern.CalcHashCode(TempCapWeekLine, TotalMinutes, NumberOfTimeSlots);
        CapacityWkPattern.setRange("Pattern Hash", GeneratedHash);
        if not CapacityWkPattern.FindFirst() then begin
            CapacityWkPattern.Init();
            CapacityWkPattern."Capacity Week Pattern ID" := 0;
            CapacityWkPattern."Pattern Hash" := GeneratedHash;
            CapacityWkPattern."Total Minutes" := TotalMinutes;
            CapacityWkPattern."Total Hours" := TotalMinutes / 60;
            CapacityWkPattern."No. of Time Slots" := NumberOfTimeSlots;
            NewWkPattern := CapacityWkPattern.Insert(True);
        end;

        resourceCapacityWeek.Init();
        resourceCapacityWeek."Resource No." := Resource."No.";
        resourceCapacityWeek."Week Start Date" := DWY2Date(1, Date2DWY(DateWk."Period Start", 2), Date2DWY(datewk."Period Start", 3));
        DoModify := resourceCapacityWeek.find('=');
        resourceCapacityWeek."Week End Date" := DWY2Date(7, Date2DWY(datewk."Period Start", 2), Date2DWY(datewk."Period Start", 3));
        resourceCapacityWeek."Week No." := Date2DWY(datewk."Period Start", 2);
        resourceCapacityWeek."Week Year" := Date2DWY(datewk."Period Start", 3);
        resourceCapacityWeek."Capacity Pattern Hash" := GeneratedHash;
        resourceCapacityWeek."Capacity Week Pattern ID" := CapacityWkPattern."Capacity Week Pattern ID";
        if DoModify then
            resourceCapacityWeek.Modify(True)
        else
            resourceCapacityWeek.Insert(True);

        if NewWkPattern then
            InsertCapacityWeekPatternSet(TempCapWeekLine, CapacityWkPattern."Capacity Week Pattern ID");
        TempCapWeekLine.DeleteAll();
    end;

    local procedure GetWeekPatternHeader()
    var

    begin
        if not WeekPatternHeader.Get(DefaultWeekPattern) then
            Error(WeekPatternNotFoundErr, DefaultWeekPattern);
    end;

    local procedure GetWeekPatternLines()
    var
    begin
        WeekPatternLine.Reset();
        if resource."Week Pattern" <> '' then
            WeekPatternLine.SetRange("Week Pattern Code", resource."Week Pattern")
        else
            WeekPatternLine.SetRange("Week Pattern Code", DefaultWeekPattern);

        if WeekPatternLine.IsEmpty() then
            Error(WeekPatternNotFoundErr, DefaultWeekPattern);
        repeat
            TempWeekPatternLine.Init();
            TempWeekPatternLine := WeekPatternLine;
            TempWeekPatternLine.Insert();
        until WeekPatternLine.Next() = 0;
    end;

    local procedure CopyDayPattern(CapacityDate: Date)
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        ResourceCapacity: Record "Opti Resource Capacity";
        DayTimeSlotHeader: Record "Opti Day-TimeSlots Header";
        CapacityWkPatternLine: Record "Opti Capacity Week Pattern Ln";
        WeekdayNo: Integer;
    begin
        WeekdayNo := Date2DWY(CapacityDate, 1);
        TempWeekPatternLine.SetRange("Weekday No.", WeekdayNo);
        if not TempWeekPatternLine.FindFirst() then
            exit
        else
            repeat
                TempCapWeekLine.init;
                TempCapWeekLine."Effective Week Pattern ID" := 0;
                TempCapWeekLine."Weekday No." := tempWeekPatternLine."Weekday No.";
                TempCapWeekLine."Day Pattern ID" := TempWeekPatternLine."Day Pattern ID";
                TempCapWeekLine."Day Effective Hash" := TempWeekPatternLine."Day Pattern Hash";
                TempCapWeekLine.Insert();
            until TempWeekPatternLine.Next() = 0;
    end;



    var
        TempCapWeekLine: Record "Opti Capacity Week Pattern Ln" temporary;
        WeekPatternHeader: Record "Opti Week Pattern Header";
        WeekPatternLine: Record "Opti Week Pattern Line";
        TempWeekPatternLine: Record "Opti Week Pattern Line" temporary;
        DefaultWeekPattern: Code[20];
        StartDate: Date;
        EndDate: Date;
        CreatedCapacityDates: Integer;
        CreatedCapacityEntries: Integer;

        StartDateRequiredErr: Label 'Start Date must have a value.';
        EndDateRequiredErr: Label 'End Date must have a value.';
        EndDateBeforeStartDateErr: Label 'End Date cannot be before Start Date.';
        WeekPatternRequiredErr: Label 'Week Pattern ID must have a value.';
        WeekPatternNotFoundErr: Label 'Week Pattern %1 does not contain any weekday lines.';
        CapacityCreatedMsg: Label '%1 capacity-date records and %2 normal capacity entries were created.';
}
