codeunit 50608 "Opti Hash Times Cleanup"
{

    Permissions =
        tabledata "Opti Week Pattern Line" = d,
        tabledata "Opti Day-TimeSlot Line" = d,
        tabledata "Opti Week Pattern Header" = d,
        tabledata "Opti Day-TimeSlots Header" = d,
        tabledata "Opti Time Slot" = d,
        //tabledata "Opti Time Slot Buffer" = d,
        tabledata "Opti Week Pattern Dialog" = d,
        tabledata "Opti Resource Capacity Week" = d;

    procedure DeleteAllPatternData()
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        DayPatternLine: Record "Opti Day-TimeSlot Line";
        WeekPattern: Record "Opti Week Pattern Header";
        DayPattern: Record "Opti Day-TimeSlots Header";
        TimeSlot: Record "Opti Time Slot";
        //TimeSlotBuffer: Record "Opti Time Slot Buffer";
        WeekPatternBuffer: Record "Opti Week Pattern Dialog";
        //CapacityEntry: Record "Opti Capacity Entry";

        ResourceCapacity: Record "Opti Resource Capacity";
        ResourceCapacityWeek: Record "Opti Resource Capacity Week";
        //WeekCapacitySlot: Record "Opti Week Capacity Slot";
        EffectiveWeekPatternLine: Record "Opti Capacity Week Pattern Ln";
        EffectiveWeekPattern: Record "Opti Capacity Week Pattern Hdr";
    begin
        /*      WeekPatternLine.DeleteAll(true);
             DayPatternLine.DeleteAll(true);

             WeekPattern.DeleteAll(true);
             DayPattern.DeleteAll(true);
             TimeSlot.DeleteAll(true);
             //TimeSlotBuffer.DeleteAll(true);
             WeekPatternBuffer.DeleteAll(true);
      */


        //CapacityEntry.DeleteAll(true);
        ResourceCapacity.DeleteAll(true);
        ResourceCapacityWeek.DeleteAll(true);
        //WeekCapacitySlot.DeleteAll(true);
        EffectiveWeekPatternLine.DeleteAll(true);
        EffectiveWeekPattern.DeleteAll(true);
    end;
}