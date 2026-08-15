query 50609 "Opti Week Pattern Slots Qry"
{
    Caption = 'Opti Week Pattern Slots';
    QueryType = Normal;

    elements
    {
        dataitem(WeekPatternHeader; "Opti Week Pattern Header")
        {
            column(WeekPatternCode; "Week Pattern Code") { }
            column(WeekPatternDescription; Description) { }
            column(WeekHash; "Week Hash") { }
            column(TotalMinutes; "Total Minutes") { }
            column(TotalHours; "Total Hours") { }
            column(NoOfTimeSlots; "No. of Time Slots") { }

            dataitem(WeekPatternLine; "Opti Week Pattern Line")
            {
                DataItemLink = "Week Pattern Code" = WeekPatternHeader."Week Pattern Code";
                SqlJoinType = InnerJoin;

                column(WeekdayNo; "Weekday No.") { }
                column(WeekdayName; "Weekday Name") { }
                column(DayPatternID; "Day Pattern ID") { }

                dataitem(DayTimeSlotLine; "Opti Day-TimeSlot Line")
                {
                    DataItemLink = "Day Time SLot Header ID" = WeekPatternLine."Day Pattern ID";
                    SqlJoinType = InnerJoin;

                    column(DayTimeSlotLineNo; "Day Time SLot Line No.") { }
                    column(TimeSlotID; "Time Slot ID") { }

                    dataitem(TimeSlot; "Opti Time Slot")
                    {
                        DataItemLink = "Time Slot ID" = DayTimeSlotLine."Time Slot ID";
                        SqlJoinType = InnerJoin;

                        column(StartTime; "Start Time") { }
                        column(EndTime; "End Time") { }
                        column(IdleTime; "Idle Time") { }
                        column(WorkingMinutes; "Working Minutes") { }
                        column(WorkingHours; "Working Hours") { }
                    }
                }
            }
        }
    }
}