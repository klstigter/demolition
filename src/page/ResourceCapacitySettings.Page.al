// Copy from page 6013 "Resource Capacity Settings"
page 50627 "Resource Capacity Settings Opt"
{
    Caption = 'Resource Capacity Settings';
    PageType = Card;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                Group(Parameters)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date for the time period for which you want to change capacity.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the end date relating to the resource capacity.';

                        trigger OnValidate()
                        begin
                            if StartDate > EndDate then
                                Error(Text000);
                        end;
                    }
                    field(WorkTemplateCode; WorkTemplateCode)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Work-Hour Template';
                        LookupPageID = "Work-Hour Templates";
                        TableRelation = "Work-Hour Template";
                        ToolTip = 'Specifies the number of hours in the work week: 30, 36, or 40.';

                        trigger OnValidate()
                        begin
                            if WorkTemplateRec.Get(WorkTemplateCode) then begin
                                StartTime := WorkTemplateRec."Default Start Time";
                                EndTime := WorkTemplateRec."Default End Time";
                            end;
                            SumWeekTotal();
                        end;
                    }

                    field(StartTime; StartTime)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Start Time';
                        ToolTip = 'Specifies the default start time for the resource working hours.';

                        trigger OnValidate()
                        begin
                            UseCustomTimes := true;
                            RecalculateWeekHours();
                        end;
                    }
                    field(EndTime; EndTime)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'End Time';
                        ToolTip = 'Specifies the default end time for the resource working hours.';

                        trigger OnValidate()
                        begin
                            UseCustomTimes := true;
                            RecalculateWeekHours();
                        end;
                    }
                    field(NoOfDuplicates; NoOfDuplicates)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Number of Duplicates';
                        ToolTip = 'Specifies the number of times you want to duplicate the capacity change.';

                        trigger OnValidate()
                        begin
                            if NoOfDuplicates < 1 then
                                NoOfDuplicates := 1;
                        end;
                    }
                }
                group(HoursCalculation)
                {
                    field("WorkTemplateRec.Monday"; WorkTemplateRec.Monday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Monday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Monday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Tuesday"; WorkTemplateRec.Tuesday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Tuesday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Tuesday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Wednesday"; WorkTemplateRec.Wednesday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Wednesday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Wednesday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Thursday"; WorkTemplateRec.Thursday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Thursday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Thursday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Friday"; WorkTemplateRec.Friday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Friday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the work-hour schedule for Friday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Saturday"; WorkTemplateRec.Saturday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Saturday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Friday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field("WorkTemplateRec.Sunday"; WorkTemplateRec.Sunday)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Sunday';
                        MaxValue = 24;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of work-hours on Saturday.';

                        trigger OnValidate()
                        begin
                            SumWeekTotal();
                        end;
                    }
                    field(WeekTotal; WeekTotal)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Week Total';
                        DecimalPlaces = 0 : 5;
                        Editable = false;
                        ToolTip = 'Specifies the total number of hours for the week. The total is calculated automatically.';
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UpdateCapacity)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update &Capacity';
                Image = Approve;
                ToolTip = 'Update the capacity based on the changes you have made in the window.';

                trigger OnAction()
                var
                    CustomizedCalendarChange: Record "Customized Calendar Change";
                    NewCapacity: Decimal;
                    LoopCounter: Integer;
                begin
                    if StartDate = 0D then
                        Error(Text002);

                    if EndDate = 0D then
                        Error(Text003);

                    if not Confirm(Text004, false, Rec.TableCaption(), Rec."No.") then
                        exit;

                    SetCalendar(CustomizedCalendarChange);

                    ResCapacityEntry.Reset();
                    ResCapacityEntry.SetCurrentKey("Resource No.", Date);
                    ResCapacityEntry.SetRange("Resource No.", Rec."No.");
                    TempDate := StartDate;
                    ChangedDays := 0;
                    repeat
                        Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);

                        ResCapacityEntry.SetRange(Date, TempDate);
                        ResCapacityEntry.CalcSums(Capacity);
                        TempCapacity := ResCapacityEntry.Capacity;

                        // Calculate the desired capacity per duplicate (not total)
                        if Holiday then
                            NewCapacity := 0
                        else begin
                            // Use time difference if custom times are set, otherwise use template hours
                            if UseCustomTimes and (StartTime <> 0T) and (EndTime <> 0T) then
                                NewCapacity := (EndTime - StartTime) / 3600000
                            else
                                NewCapacity := SelectCapacity(CustomizedCalendarChange);
                        end;

                        // Calculate capacity change: difference between current and desired per duplicate
                        // TempCapacity could be sum of multiple duplicates, so we need to handle this correctly
                        if NewCapacity <> 0 then begin
                            if NoOfDuplicates > 1 then begin
                                // Create NoOfDuplicates entries for each day
                                for LoopCounter := 1 to NoOfDuplicates do begin
                                    ResCapacityEntry2.Reset();
                                    if ResCapacityEntry2.FindLast() then;
                                    LastEntry := ResCapacityEntry2."Entry No." + 1;
                                    ResCapacityEntry2.Init();
                                    ResCapacityEntry2."Entry No." := LastEntry;

                                    // Calculate adjustment: desired capacity per duplicate minus average existing capacity
                                    // Example: existing sum=24 (3×8), new=5, NoOfDuplicates=3: 5-(24/3)=5-8=-3 per entry
                                    ResCapacityEntry2.Capacity := NewCapacity - (TempCapacity / NoOfDuplicates);

                                    ResCapacityEntry2."Resource No." := Rec."No.";
                                    ResCapacityEntry2."Resource Group No." := Rec."Resource Group No.";
                                    ResCapacityEntry2.Date := TempDate;
                                    ResCapacityEntry2."Duplicate Id" := LoopCounter;

                                    //<< Custom here
                                    // Use custom times if manually set, otherwise use template defaults
                                    if UseCustomTimes and (StartTime <> 0T) then begin
                                        ResCapacityEntry2."Start Time" := StartTime;
                                        if EndTime <> 0T then
                                            ResCapacityEntry2."End Time" := EndTime
                                        else
                                            ResCapacityEntry2."End Time" := StartTime + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                                    end else if WorkTemplateRec.Get(WorkTemplateCode) then begin
                                        if WorkTemplateRec."Default Start Time" <> 0T then begin
                                            ResCapacityEntry2."Start Time" := WorkTemplateRec."Default Start Time";
                                            if WorkTemplateRec."Default End Time" <> 0T then
                                                ResCapacityEntry2."End Time" := WorkTemplateRec."Default End Time"
                                            else
                                                // Calculate end time with automatic wrap-around after 24 hours
                                                // Example: 21:00 + 8 hours = 05:00
                                                ResCapacityEntry2."End Time" := WorkTemplateRec."Default Start Time" + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                                        end;
                                    end;
                                    //>>

                                    if ResCapacityEntry2.Insert(true) then;
                                end;
                            end else begin
                                // Create single entry for each day
                                ResCapacityEntry2.Reset();
                                if ResCapacityEntry2.FindLast() then;
                                LastEntry := ResCapacityEntry2."Entry No." + 1;
                                ResCapacityEntry2.Init();
                                ResCapacityEntry2."Entry No." := LastEntry;
                                // Calculate adjustment: desired capacity minus existing sum
                                // Example: existing=8, new=5: 5-8=-3 | existing=9, new=14: 14-9=5
                                ResCapacityEntry2.Capacity := NewCapacity - TempCapacity;
                                ResCapacityEntry2."Resource No." := Rec."No.";
                                ResCapacityEntry2."Resource Group No." := Rec."Resource Group No.";
                                ResCapacityEntry2.Date := TempDate;
                                ResCapacityEntry2."Duplicate Id" := 1;

                                //<< Custom here
                                // Use custom times if manually set, otherwise use template defaults
                                if UseCustomTimes and (StartTime <> 0T) then begin
                                    ResCapacityEntry2."Start Time" := StartTime;
                                    if EndTime <> 0T then
                                        ResCapacityEntry2."End Time" := EndTime
                                    else
                                        ResCapacityEntry2."End Time" := StartTime + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                                end else if WorkTemplateRec.Get(WorkTemplateCode) then begin
                                    if WorkTemplateRec."Default Start Time" <> 0T then begin
                                        ResCapacityEntry2."Start Time" := WorkTemplateRec."Default Start Time";
                                        if WorkTemplateRec."Default End Time" <> 0T then
                                            ResCapacityEntry2."End Time" := WorkTemplateRec."Default End Time"
                                        else
                                            // Calculate end time with automatic wrap-around after 24 hours
                                            // Example: 21:00 + 8 hours = 05:00
                                            ResCapacityEntry2."End Time" := WorkTemplateRec."Default Start Time" + (Abs(ResCapacityEntry2.Capacity) * 3600000);
                                    end;
                                end;
                                //>>

                                if ResCapacityEntry2.Insert(true) then;
                            end;
                            ChangedDays := ChangedDays + 1;
                        end;
                        TempDate := TempDate + 1;
                    until TempDate > EndDate;
                    Commit();
                    if ChangedDays > 1 then
                        Message(Text006, ChangedDays)
                    else
                        if ChangedDays = 1 then
                            Message(Text007, ChangedDays)
                        else
                            Message(Text008);
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UpdateCapacity_Promoted; UpdateCapacity)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not WorkTemplateRec.Get(WorkTemplateCode) and (Rec."No." <> xRec."No.") then
            Clear(WorkTemplateRec);
        SumWeekTotal();
    end;

    trigger OnOpenPage()
    begin
        StartDate := 0D;
        EndDate := 0D;
        WorkTemplateCode := '';
        StartTime := 0T;
        EndTime := 0T;
        UseCustomTimes := false;
    end;

    var
        StartTime: Time;
        EndTime: Time;
        NoOfDuplicates: Integer;
        WorkTemplateRec: Record "Work-Hour Template";
        ResCapacityEntry: Record "Res. Capacity Entry";
        CompanyInformation: Record "Company Information";
        ResCapacityEntry2: Record "Res. Capacity Entry";
        CalendarMgmt: Codeunit "Calendar Management";
        WorkTemplateCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        WeekTotal: Decimal;
        TempDate: Date;
        TempCapacity: Decimal;
        ChangedDays: Integer;
        LastEntry: Decimal;
        Holiday: Boolean;
        UseCustomTimes: Boolean;

#pragma warning disable AA0074
        Text000: Label 'The starting date is later than the ending date.';
        Text002: Label 'You must fill in the Starting Date field.';
        Text003: Label 'You must fill in the Ending Date field.';
#pragma warning disable AA0470
        Text004: Label 'Do you want to change the capacity for %1 %2?', Comment = 'Do you want to change the capacity for NO No.?';
        Text006: Label 'The capacity for %1 days was changed successfully.';
        Text007: Label 'The capacity for %1 day was changed successfully.';
#pragma warning restore AA0470
        Text008: Label 'The capacity change was unsuccessful.';
#pragma warning restore AA0074

    local procedure SelectCapacity(var CustomizedCalendarChange: Record "Customized Calendar Change") Hours: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCapacity(TempDate, CustomizedCalendarChange, WorkTemplateRec, Hours, IsHandled);
        if IsHandled then
            exit(Hours);

        case Date2DWY(TempDate, 1) of
            1:
                Hours := WorkTemplateRec.Monday;
            2:
                Hours := WorkTemplateRec.Tuesday;
            3:
                Hours := WorkTemplateRec.Wednesday;
            4:
                Hours := WorkTemplateRec.Thursday;
            5:
                Hours := WorkTemplateRec.Friday;
            6:
                Hours := WorkTemplateRec.Saturday;
            7:
                Hours := WorkTemplateRec.Sunday;
        end;
    end;

    local procedure SetCalendar(var CustomizedCalendarChange: Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCalendar(Rec, CustomizedCalendarChange, IsHandled);
        if IsHandled then
            exit;

        if CompanyInformation.Get() then begin
            CompanyInformation.TestField("Base Calendar Code");
            CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);
        end;
    end;

    local procedure SumWeekTotal()
    begin
        WeekTotal := WorkTemplateRec.Monday + WorkTemplateRec.Tuesday + WorkTemplateRec.Wednesday +
          WorkTemplateRec.Thursday + WorkTemplateRec.Friday + WorkTemplateRec.Saturday + WorkTemplateRec.Sunday;
    end;

    local procedure RecalculateWeekHours()
    var
        CalculatedHours: Decimal;
    begin
        if not UseCustomTimes then
            exit;

        if (StartTime = 0T) or (EndTime = 0T) then
            exit;

        // Calculate hours from time difference
        // Convert milliseconds to hours
        CalculatedHours := (EndTime - StartTime) / 3600000;

        // Apply to all weekdays
        WorkTemplateRec.Monday := CalculatedHours;
        WorkTemplateRec.Tuesday := CalculatedHours;
        WorkTemplateRec.Wednesday := CalculatedHours;
        WorkTemplateRec.Thursday := CalculatedHours;
        WorkTemplateRec.Friday := CalculatedHours;
        WorkTemplateRec.Saturday := CalculatedHours;
        WorkTemplateRec.Sunday := CalculatedHours;

        SumWeekTotal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCalendar(var Resource: Record Resource; var CustomizedCalendarChange: Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCapacity(TempDate: Date; var CustomizedCalendarChange: Record "Customized Calendar Change"; var WorkTemplateRec: Record "Work-Hour Template"; var Hours: Decimal; var IsHandled: Boolean)
    begin
    end;
}