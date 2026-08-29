query 50608 "Opti Week Capacity Slots Qry"
{
    Caption = 'Opti Week Capacity Slots';
    QueryType = Normal;

    elements
    {
        dataitem(ResourceCapacityWeek; "Opti Resource Capacity Week")
        {
            column(ResourceNo; "Resource No.") { }
            column(WeekStartDate; "Week Start Date") { }
            column(WeekNo; "Week No.") { }
            column(WeekYear; "Week Year") { }
            column(CapacityWeekPatternID; "Capacity Week Pattern ID") { }

            dataitem(CapacityWeekPatternLn; "Opti Capacity Week Pattern Ln")
            {
                DataItemLink = "Effective Week Pattern ID" = ResourceCapacityWeek."Capacity Week Pattern ID";
                SqlJoinType = InnerJoin;

                column(WeekdayNo; "Weekday No.") { }
                column(WeekdayName; "Weekday Name") { }
                column(DayPatternNo; "Day-TimeSlots ID") { }

                dataitem(DayTimeSlotLn; "Opti Day-TimeSlot Line")
                {
                    DataItemLink = "Day-TimeSLots Header No." = CapacityWeekPatternLn."Day-TimeSlots ID";
                    SqlJoinType = InnerJoin;
                    column(DayTimeSlotHeaderNo; "Day-TimeSLots Header No.") { }
                    column(DayTimeSlotLineNo; "Day-TimeSLot Line No.") { }
                    column(TimeSlotNo; "Time Slot No.") { }

                    dataitem(TimeSlot; "Opti Time Slot")
                    {
                        DataItemLink = "Time Slot No." = DayTimeSlotLn."Time Slot No.";
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