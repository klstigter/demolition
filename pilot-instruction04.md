# Day Tasks Working Hours Calculation - Implementation Guide

## Objective
Extend the Day Tasks table to include working hours and non-working hours fields, with automatic calculation based on start and end times.

## Implementation Steps

### 1. Extend Day Tasks Table with Working Hours Fields

**File**: `src/table/DayTasks.Table.al` (modify existing file)

**Fields to Add**:

```al
field(80; "Working Hours"; Decimal)
{
    Caption = 'Working Hours';
    DataClassification = CustomerContent;
    DecimalPlaces = 0:2;
    Editable = false;
}

field(81; "Non Working Hours"; Decimal)
{
    Caption = 'Non Working Hours';
    DataClassification = CustomerContent;
    DecimalPlaces = 0:2;
}
```

**Business Rules**:
- Working Hours is calculated automatically and not editable
- Non Working Hours can be manually entered if needed
- Both fields use 2 decimal places for precision
- Calculation is based on Start Time and End Time fields

---

### 2. Add Calculation Function to Day Tasks Table

**Implementation**:

Add this procedure to the Day Tasks table:

```al
procedure CalculateWorkingHours()
var
    WorkingMinutes: Integer;
begin
    // If either time is not set, clear working hours
    if ("Start Time" = 0T) or ("End Time" = 0T) then begin
        "Working Hours" := 0;
        exit;
    end;

    // Validate that End Time is after Start Time
    if "End Time" <= "Start Time" then begin
        "Working Hours" := 0;
        exit;
    end;

    // Calculate working minutes
    WorkingMinutes := ("End Time" - "Start Time") div 60000;

    // Convert to hours (decimal)
    "Working Hours" := WorkingMinutes / 60;
end;
```

**Alternative with Non-Working Hours**:

If you want to also calculate Non Working Hours automatically based on a 24-hour period:

```al
procedure CalculateWorkingHours()
var
    TotalMinutes: Integer;
    WorkingMinutes: Integer;
    NonWorkingMinutes: Integer;
begin
    // If either time is not set, clear both hours fields
    if ("Start Time" = 0T) or ("End Time" = 0T) then begin
        "Working Hours" := 0;
        "Non Working Hours" := 0;
        exit;
    end;

    // Validate that End Time is after Start Time
    if "End Time" <= "Start Time" then begin
        "Working Hours" := 0;
        "Non Working Hours" := 24;
        exit;
    end;

    // Calculate total minutes in a day (24 hours)
    TotalMinutes := 24 * 60;

    // Calculate working minutes
    WorkingMinutes := ("End Time" - "Start Time") div 60000;

    // Calculate non-working minutes
    NonWorkingMinutes := TotalMinutes - WorkingMinutes;

    // Convert to hours (decimal)
    "Working Hours" := WorkingMinutes / 60;
    "Non Working Hours" := NonWorkingMinutes / 60;
end;
```

---

### 3. Add Triggers to Auto-Calculate Working Hours

Add validation triggers to the Start Time and End Time fields:

**On Start Time field**:
```al
field(50; "Start Time"; Time)
{
    Caption = 'Start Time';
    DataClassification = CustomerContent;

    trigger OnValidate()
    begin
        CalculateWorkingHours();
    end;
}
```

**On End Time field**:
```al
field(60; "End Time"; Time)
{
    Caption = 'End Time';
    DataClassification = CustomerContent;

    trigger OnValidate()
    begin
        CalculateWorkingHours();
    end;
}
```

---

### 4. Add Fields to Day Tasks Page

**File**: Modify the Day Tasks list page

**Implementation**:

Add the fields to the page layout where appropriate:

```al
field("Working Hours"; Rec."Working Hours")
{
    ApplicationArea = All;
    ToolTip = 'Specifies the number of working hours for this day task, calculated automatically based on start and end times.';
    Editable = false;
    Style = Favorable;
    StyleExpr = true;
}

field("Non Working Hours"; Rec."Non Working Hours")
{
    ApplicationArea = All;
    ToolTip = 'Specifies the number of non-working hours in a 24-hour period for this day task.';
}
```

---

### 5. Update Day Tasks Creation in Job Day Planning Mgt

**File**: `src/codeunit/JobDayPlanningMgt.Codeunit.al`

Update the `UnpackJobPlanningLine` procedure to calculate working hours when creating day tasks:

```al
// After setting Start Time and End Time
DayTasks."Start Time" := DayStartTime;
DayTasks."End Time" := DayEndTime;

// Calculate working hours
DayTasks.CalculateWorkingHours();

// Copy other fields from job planning line
DayTasks.Type := JobPlanningLine.Type;
```

---

## Complete Field Structure

### Day Tasks Table Fields for Time Tracking

| Field Number | Field Name | Type | Editable | Calculated | Description |
|-------------|------------|------|----------|------------|-------------|
| 50 | Start Time | Time | Yes | No | When the task starts |
| 60 | End Time | Time | Yes | No | When the task ends |
| 70 | Worked Hours | Decimal | Yes | No | Actual hours worked (manual entry) |
| 80 | Working Hours | Decimal | No | Yes | Planned working hours (calculated) |
| 81 | Non Working Hours | Decimal | Yes | Optional | Non-working hours in 24h period |

---

## Usage Scenarios

### Scenario 1: Creating a Day Task with Specific Times
1. Create a new Day Task
2. Set Start Time to 08:00:00
3. Set End Time to 16:00:00
4. Working Hours automatically calculates to 8.00
5. Non Working Hours automatically calculates to 16.00 (if auto-calculation is enabled)

### Scenario 2: Unpacking Job Planning Lines
1. Job Planning Line has Start Time 09:00 and End Time 17:00
2. When unpacked to Day Tasks, each day task gets these times
3. CalculateWorkingHours() is called automatically
4. Each day task shows 8.00 working hours

### Scenario 3: Comparing Planned vs Actual
1. Working Hours shows planned time (8.00 hours)
2. After work is done, enter Worked Hours (actual: 7.50 hours)
3. Compare to see if task took more or less time than planned
4. Use for productivity analysis and future planning

---

## Testing Checklist

- [ ] Working Hours field is read-only
- [ ] Working Hours calculates correctly when Start/End Time is set
- [ ] Working Hours clears when Start Time or End Time is empty
- [ ] Working Hours is 0 when End Time <= Start Time
- [ ] Non Working Hours field is editable (if manual entry allowed)
- [ ] Non Working Hours calculates correctly (if auto-calculation enabled)
- [ ] Working Hours + Non Working Hours = 24 (if both calculated)
- [ ] Fields appear on Day Tasks page
- [ ] CalculateWorkingHours() is called when unpacking planning lines
- [ ] Decimal places display correctly (2 decimal places)
- [ ] ToolTips display correctly on page

---

## Benefits

1. **Automatic Calculation** - No manual calculation of working hours needed
2. **Consistency** - Same calculation logic across all day tasks
3. **Planning Accuracy** - Clear visibility of planned working hours per day
4. **Comparison** - Easy to compare planned (Working Hours) vs actual (Worked Hours)
5. **Resource Planning** - Better understanding of daily resource requirements
6. **Reporting** - Can sum Working Hours across tasks for project planning

---

## Future Enhancements

### 1. Break Time Consideration
```al
field(82; "Break Hours"; Decimal)
{
    Caption = 'Break Hours';
    DataClassification = CustomerContent;
    DecimalPlaces = 0:2;
}

// Updated calculation
"Working Hours" := (WorkingMinutes / 60) - "Break Hours";
```

### 2. Integration with Work-Hour Template
```al
// Use template's default times if Day Task times are not set
if "Start Time" = 0T then
    "Start Time" := WorkHourTemplate."Default Start Time";
if "End Time" = 0T then
    "End Time" := WorkHourTemplate."Default End Time";
```

### 3. Overtime Calculation
```al
field(83; "Overtime Hours"; Decimal)
{
    Caption = 'Overtime Hours';
    DataClassification = CustomerContent;
    DecimalPlaces = 0:2;
}

// Calculate overtime if working hours exceed template standard
if "Working Hours" > WorkHourTemplate."Working Hours" then
    "Overtime Hours" := "Working Hours" - WorkHourTemplate."Working Hours";
```

### 4. Efficiency Percentage
```al
field(84; "Efficiency %"; Decimal)
{
    Caption = 'Efficiency %';
    FieldClass = FlowField;
    CalcFormula = /* (Worked Hours / Working Hours) * 100 */;
}
```

---

## Notes

- Working Hours represents **planned** working hours based on scheduled times
- Worked Hours (field 70) represents **actual** hours worked after completion
- Consider time zone handling for multi-location scenarios
- For tasks spanning midnight, additional logic may be needed
- Ensure the calculation is called whenever Start Time or End Time changes
- The calculation uses millisecond precision and converts to decimal hours

---

## Implementation Order

1. Add Working Hours and Non Working Hours fields to Day Tasks table
2. Add CalculateWorkingHours() procedure to Day Tasks table
3. Add OnValidate triggers to Start Time and End Time fields
4. Add fields to Day Tasks page
5. Update JobDayPlanningMgt to call CalculateWorkingHours() when creating tasks
6. Test with various time scenarios
7. Verify calculation accuracy
