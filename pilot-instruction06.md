# Pilot Instruction 06 - Resource Weekly Hours Table

**Implementation Status: ✅ COMPLETED**
- Table ID: 50612 - "Resource Weekly Hours"
- Page ID: 50636 - "Resource Weekly Hours"
- Files Created:
  - `src/table/ResourceWeeklyHours.Table.al`
  - `src/page/ResourceWeeklyHours.Page.al`
- Created: 2025-01-31
- Integrated with: Resource DayTask Summary page (50635)

## Overview
This document describes a new temporary table used as a drilldown for detailed resource usage. The table shows weekly hour distribution per resource across weekdays, providing a detailed view of daily hour allocation.

## Table Specifications

### Purpose
- Temporary table (no database persistence)
- Drilldown table from Resource DayTask Summary
- Shows one record per week per resource
- Displays total hours for each weekday (Monday-Sunday)
- Used for detailed weekly hour analysis and planning

### Table Structure

**Table Name:** `Resource Weekly Hours` (Temporary)  
**Table ID:** `50xxx` (TBD - assign next available ID in 50xxx range)

### Fields

| Field No | Field Name | Data Type | Length | Description |
|----------|------------|-----------|--------|-------------|
| 1 | Resource No. | Code | 20 | Resource identifier (Primary Key) |
| 2 | Job No. | Code | 20 | Reference to Job (Primary Key) |
| 3 | Job Task No. | Code | 20 | Reference to Job Task (Primary Key) |
| 5 | Year | Integer | - | Year for the week |
| 6 | Week No. | Integer | - | ISO Week number |
| 8 | Monday Hours | Decimal | - | Total hours on Monday |
| 9 | Tuesday Hours | Decimal | - | Total hours on Tuesday |
| 10 | Wednesday Hours | Decimal | - | Total hours on Wednesday |
| 11 | Thursday Hours | Decimal | - | Total hours on Thursday |
| 12 | Friday Hours | Decimal | - | Total hours on Friday |
| 13 | Saturday Hours | Decimal | - | Total hours on Saturday |
| 14 | Sunday Hours | Decimal | - | Total hours on Sunday |
| 15 | Total Week Hours | Decimal | - | Sum of all weekday hours |

### Primary Key
- Resource No.
- Job No.
- Job Task No.
- Year
- Week No.

### Usage Scenarios

1. **Weekly Hour Distribution**
   - View how hours are distributed across weekdays
   - Identify peak workload days

2. **Capacity Planning**
   - Analyze weekly capacity usage per resource
   - Detect overallocation or underutilization

3. **Drilldown Analysis**
   - Detailed view from Resource DayTask Summary
   - Weekly breakdown for specific resource on job task

### Data Population

The table should be populated by:
- Reading from `Day Tasks` table
- Filtering by Resource No., Job No., and Job Task No.
- Extracting Year and Week No. from Work Date using Date2DWY
- Grouping by Year and Week No.
- Distributing hours to appropriate weekday fields
- Calculating weekly totals

### Table Methods

#### FillBuffer(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])

**Purpose:** Populates the temporary table with weekly hour distribution for a specific resource on a job task.

**Parameters:**
- `ResourceNo` - Resource number to filter Day Tasks
- `JobNo` - Job number to filter Day Tasks
- `JobTaskNo` - Job Task number to filter Day Tasks

**Logic:**
1. Clear existing records in the temporary table
2. Query Day Tasks table filtering by Resource No., Job No., and Job Task No.
3. For each Day Task:
   - Extract Year and Week No. using Date2DWY
   - Determine weekday (Monday=1, Sunday=7)
   - Add hours to appropriate weekday field
4. Group by Year and Week No.
5. Calculate Total Week Hours for each week
6. Insert each weekly summary record into the temporary table

**Usage Example:**
```al
var
    WeeklyHours: Record "Resource Weekly Hours";
begin
    WeeklyHours.FillBuffer('RES001', 'JOB001', '1000');
    // Table now contains weekly hour breakdown for resource RES001 on Job Task JOB001-1000
end;
```

### Helper Functions

#### GetDayOfWeekIndex(WorkDate: Date): Integer
Returns day of week (1=Monday, 7=Sunday).

#### GetWeekStartFromYearWeek(Year: Integer; WeekNo: Integer): Date
Calculates the Monday of a specific week given Year and Week Number (ISO 8601 standard).

### Integration Points

- **Source Data:** Day Tasks table (existing)
- **Parent View:** Resource DayTask Summary (drilldown source)
- **Related Tables:** Job, Job Task, Resource
- **Consumer Pages:** Resource Weekly Hours page (drilldown)

### Implementation Notes

1. Mark table as `TableType = Temporary` in AL
2. Primary Key uses Year and Week No. (ISO 8601 standard)
3. All hour fields use Decimal with 2 decimal places
4. Total Week Hours is sum of all weekday fields
5. Empty days show 0.00 hours
6. Week dates calculated on-the-fly when needed using GetWeekStartFromYearWeek helper

### Example AL Code Structure

```al
table 50xxx "Resource Weekly Hours"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    
    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
        }
        field(5; Year; Integer)
        {
            Caption = 'Year';
        }
        field(6; "Week No."; Integer)
        {
            Caption = 'Week No.';
        }
        field(8; "Monday Hours"; Decimal)
        {
            Caption = 'Monday';
            DecimalPlaces = 0:2;
        }
        field(9; "Tuesday Hours"; Decimal)
        {
            Caption = 'Tuesday';
            DecimalPlaces = 0:2;
        }
        field(10; "Wednesday Hours"; Decimal)
        {
            Caption = 'Wednesday';
            DecimalPlaces = 0:2;
        }
        field(11; "Thursday Hours"; Decimal)
        {
            Caption = 'Thursday';
            DecimalPlaces = 0:2;
        }
        field(12; "Friday Hours"; Decimal)
        {
            Caption = 'Friday';
            DecimalPlaces = 0:2;
        }
        field(13; "Saturday Hours"; Decimal)
        {
            Caption = 'Saturday';
            DecimalPlaces = 0:2;
        }
        field(14; "Sunday Hours"; Decimal)
        {
            Caption = 'Sunday';
            DecimalPlaces = 0:2;
        }
        field(15; "Total Week Hours"; Decimal)
        {
            Caption = 'Total';
            DecimalPlaces = 0:2;
        }
    }
    
    keys
    {
        key(PK; "Resource No.", "Job No.", "Job Task No.", Year, "Week No.")
        {
            Clustered = true;
        }
    }
    
    local procedure GetDayOfWeekIndex(WorkDate: Date): Integer
    begin
        // Returns 1-7 (Monday=1, Sunday=7)
        exit(Date2DWY(WorkDate, 1));
    end;
    
    local procedure GetWeekStartFromYearWeek(Year: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        // ISO 8601: Week 1 is the week with Jan 4th
        Jan4 := DMY2Date(4, 1, Year);
        Week1Monday := CalcDate(StrSubstNo('<-%1D>', Date2DWY(Jan4, 1) - 1), Jan4);
        exit(CalcDate(StrSubstNo('<+%1W>', WeekNo - 1), Week1Monday));
    end;
    
    procedure FillBuffer(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
        TempWeekList: Record "Resource Weekly Hours" temporary;
        DayIndex: Integer;
        YearValue: Integer;
        WeekNoValue: Integer;
    begin
        // Clear existing records
        Rec.DeleteAll();
        
        // Find all Day Tasks for this Resource/Job/Task
        DayTask.SetRange("Resource No.", ResourceNo);
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        
        if not DayTask.FindSet() then
            exit;
        
        // Group by week and distribute hours to weekdays
        repeat
            YearValue := Date2DWY(DayTask."Work Date", 3);
            WeekNoValue := Date2DWY(DayTask."Work Date", 2);
            DayIndex := GetDayOfWeekIndex(DayTask."Work Date");
            
            if not TempWeekList.Get(ResourceNo, JobNo, JobTaskNo, YearValue, WeekNoValue) then begin
                // Create new week record
                TempWeekList.Init();
                TempWeekList."Resource No." := ResourceNo;
                TempWeekList."Job No." := JobNo;
                TempWeekList."Job Task No." := JobTaskNo;
                TempWeekList."Week No." := WeekNoValue;
                TempWeekList.Year := YearValue;
                
                // Initialize all day hours to 0
                TempWeekList."Monday Hours" := 0;
                TempWeekList."Tuesday Hours" := 0;
                TempWeekList."Wednesday Hours" := 0;
                TempWeekList."Thursday Hours" := 0;
                TempWeekList."Friday Hours" := 0;
                TempWeekList."Saturday Hours" := 0;
                TempWeekList."Sunday Hours" := 0;
                TempWeekList."Total Week Hours" := 0;
                
                // Add hours to appropriate day
                case DayIndex of
                    1: TempWeekList."Monday Hours" := DayTask.Hours;
                    2: TempWeekList."Tuesday Hours" := DayTask.Hours;
                    3: TempWeekList."Wednesday Hours" := DayTask.Hours;
                    4: TempWeekList."Thursday Hours" := DayTask.Hours;
                    5: TempWeekList."Friday Hours" := DayTask.Hours;
                    6: TempWeekList."Saturday Hours" := DayTask.Hours;
                    7: TempWeekList."Sunday Hours" := DayTask.Hours;
                end;
                TempWeekList."Total Week Hours" := DayTask.Hours;
                TempWeekList.Insert();
            end else begin
                // Update existing week record
                case DayIndex of
                    1: TempWeekList."Monday Hours" += DayTask.Hours;
                    2: TempWeekList."Tuesday Hours" += DayTask.Hours;
                    3: TempWeekList."Wednesday Hours" += DayTask.Hours;
                    4: TempWeekList."Thursday Hours" += DayTask.Hours;
                    5: TempWeekList."Friday Hours" += DayTask.Hours;
                    6: TempWeekList."Saturday Hours" += DayTask.Hours;
                    7: TempWeekList."Sunday Hours" += DayTask.Hours;
                end;
                TempWeekList."Total Week Hours" += DayTask.Hours;
                TempWeekList.Modify();
            end;
        until DayTask.Next() = 0;
        
        // Copy from temp to Rec
        if TempWeekList.FindSet() then
            repeat
                Rec := TempWeekList;
                Rec.Insert();
            until TempWeekList.Next() = 0;
    end;
}
```

### Page Specifications

#### Resource Weekly Hours List

**Page Type:** List  
**Page ID:** `50xxx` (TBD - assign next available ID in 50xxx range)  
**Source Table:** Resource Weekly Hours (Temporary)

**Purpose:** Display weekly hour distribution for a specific resource on a job task.

**Fields to Display:**
1. Week No. (Editable: No)
2. Year (Editable: No)
3. Monday Hours (Editable: No)
4. Tuesday Hours (Editable: No)
5. Wednesday Hours (Editable: No)
6. Thursday Hours (Editable: No)
7. Friday Hours (Editable: No)
8. Saturday Hours (Editable: No)
9. Sunday Hours (Editable: No)
10. Total Week Hours (Editable: No, styled/bold)

**Page Layout:**
- **Repeater group** containing all fields
- Fields are read-only (Editable = false)
- Weekday columns should be visually grouped
- Consider using fixed decimal format (0.00)

**Actions:**
- **Show Day Tasks** - Navigate to filtered Day Tasks list for selected week
- **Resource Card** - Open Resource Card
- **Job Task Card** - Open Job Task Card

**Usage Context:**
- Drilldown from Resource DayTask Summary page
- Called with Resource No., Job No., and Job Task No.
- Shows detailed weekly breakdown

**Example AL Code Structure:**
```al
page 50xxx "Resource Weekly Hours"
{
    PageType = List;
    SourceTable = "Resource Weekly Hours";
    SourceTableTemporary = true;
    Caption = 'Resource Weekly Hours';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISO week number.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year.';
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Monday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Friday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Saturday.';
                    StyleExpr = WeekendStyle;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Sunday.';
                    StyleExpr = WeekendStyle;
                }
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the entire week.';
                    Style = Strong;
                }
            }
        }
    }
    
    actions
    {
        area(Processing)
        {
            action(ShowDayTasks)
            {
                ApplicationArea = All;
                Caption = 'Show Day Tasks';
                Image = TaskList;
                ToolTip = 'View all day tasks for this week.';
                
                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayTask.SetRange("Resource No.", Rec."Resource No.");
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Work Date", WeekStart, WeekEnd);
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
            action(OpenResourceCard)
            {
                ApplicationArea = All;
                Caption = 'Resource Card';
                Image = Resource;
                ToolTip = 'Open the resource card.';
                
                trigger OnAction()
                var
                    Resource: Record Resource;
                begin
                    if Resource.Get(Rec."Resource No.") then
                        Page.Run(Page::"Resource Card", Resource);
                end;
            }
            action(OpenJobTaskCard)
            {
                ApplicationArea = All;
                Caption = 'Job Task Card';
                Image = Task;
                ToolTip = 'Open the job task card.';
                
                trigger OnAction()
                var
                    JobTask: Record "Job Task";
                begin
                    if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
                        Page.Run(Page::"Job Task Card", JobTask);
                end;
            }
        }
    }
    
    var
        WeekdayStyle: Text;
        WeekendStyle: Text;
    
    trigger OnAfterGetRecord()
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';
    end;
    
    procedure LoadData(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        Rec.FillBuffer(ResourceNo, JobNo, JobTaskNo);
    end;
}
```

**Integration Example - Drilldown from Resource DayTask Summary:**
```al
// Add to Resource DayTask Summary page as drilldown action
action(ShowWeeklyHours)
{
    ApplicationArea = All;
    Caption = 'Weekly Hours';
    Image = CalendarMachine;
    ToolTip = 'View weekly hour distribution for this resource.';
    
    trigger OnAction()
    var
        WeeklyHours: Record "Resource Weekly Hours";
        WeeklyHoursPage: Page "Resource Weekly Hours";
    begin
        WeeklyHours.FillBuffer(Rec."Resource No.", Rec."Job No.", Rec."Job Task No.");
        WeeklyHoursPage.SetTableView(WeeklyHours);
        WeeklyHoursPage.Run();
    end;
}
```

### Related Objects

- **Source Table:** Day Tasks (existing)
- **Parent Table:** Resource DayTask Summary (pilot-instruction05)
- **Related Tables:** Job, Job Task, Resource
- **Page:** Resource Weekly Hours List (to be created)
- **Accessible From:** Resource DayTask Summary page, Resource Summary FactBox (pilot-instruction07)

## Next Steps

1. Assign table ID from available range (50xxx)
2. Create table object in `src/table/` directory
3. Assign page ID from available range (50xxx)
4. Create page object in `src/page/` directory
5. Add drilldown action to Resource DayTask Summary page (from pilot-instruction05)
6. Test week calculation logic with various date ranges
7. Verify weekend styling (Saturday/Sunday different color)
8. Test with resources working across multiple weeks
9. Consider adding filtering by date range for large datasets
