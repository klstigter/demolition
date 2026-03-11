# Pilot Instruction 05 - Job Task Resource Summary Table

**Implementation Status: ✅ COMPLETED**
- Table ID: 50611 - "Resource DayTask Summary"
- Page ID: 50635 - "Resource DayTask Summary"
- Files Created: 
  - `src/table/ResourceDayTaskSummary.Table.al`
  - `src/page/ResourceDayTaskSummary.Page.al`
- Created: 2025-01-31

## Overview
This document describes a new temporary table used for summarizing resource usage across job tasks. The table aggregates resource allocation data with date ranges.

## Table Specifications

### Purpose
- Temporary table (no database persistence)
- Summarizes all resources used for a specific job task
- Tracks the first and last date each resource was used on the task
- Used for reporting and analysis purposes

### Table Structure

**Table Name:** `Resource DayTask Summary` (Temporary)  
**Table ID:** `50xxx` (TBD - assign next available ID in 50xxx range)

### Fields

| Field No | Field Name | Data Type | Length | Description |
|----------|------------|-----------|--------|-------------|
| 1 | Job No. | Code | 20 | Reference to Job |
| 2 | Job Task No. | Code | 20 | Reference to Job Task |
| 3 | Resource No. | Code | 20 | Resource identifier |
| 4 | Resource Name | Text | 100 | Resource name for display | (flowfield)
| 5 | First Date Used | Date | - | Earliest date resource was used on this task |
| 6 | Last Date Used | Date | - | Latest date resource was used on this task |
| 7 | Total Hours | Decimal | - | Total hours allocated (optional) |
| 8 | Total Day Task | Integer | - | Number of daytasks between first and last date |

### Primary Key
- Job No.
- Job Task No.
- Resource No.

### Usage Scenarios

1. **Resource Allocation Overview**
   - Display which resources are assigned to each job task
   - Show the duration of resource commitment

2. **Timeline Analysis**
   - Identify resource usage patterns across tasks
   - Detect overlapping resource allocations

3. **Reporting**
   - Generate resource utilization reports
   - Export summary data for external analysis

### Data Population

The table should be populated by:
- Reading from `Day Tasks` table
- Grouping by Job Task and Resource
- Aggregating MIN(Work Date) as First Date Used
- Aggregating MAX(Work Date) as Last Date Used
- Optionally calculating total hours from Day Tasks

### Table Methods

#### FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])

**Purpose:** Populates the temporary table with resource summary data for a specific job task.

**Parameters:**
- `JobNo` - Job number to filter Day Tasks
- `JobTaskNo` - Job Task number to filter Day Tasks

**Logic:**
1. Clear existing records in the temporary table
2. Query Day Tasks table filtering by Job No. and Job Task No.
3. Group results by Resource No.
4. For each resource:
   - Calculate First Date Used: MIN(Work Date)
   - Calculate Last Date Used: MAX(Work Date)
   - Calculate Total Hours: SUM(Hours)
   - Count Total Day Tasks: COUNT(*)
   - Retrieve Resource Name from Resource table
5. Insert each summary record into the temporary table

**Usage Example:**
```al
var
    ResourceSummary: Record "Resource DayTask Summary";
begin
    ResourceSummary.FillBuffer('JOB001', '1000');
    // Table now contains all resources used on Job Task JOB001-1000
end;
```

### Integration Points

- **Source Data:** Day Tasks table (existing)
- **Consumer Pages:** Job Task cards, resource lists, reporting pages
- **Codeunits:** Resource summary generation, job task analysis

### Implementation Notes

1. Mark table as `TableType = Temporary` in AL
2. Create helper codeunit for data population
3. Consider adding filters for date range selection
4. May need secondary keys for sorting by date or resource

### Example AL Code Structure

```al
table 50xxx "Resource DayTask Summary"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    
    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Job No.';
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
        }
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
        }
        field(4; "Resource Name"; Text[100])
        {
            Caption = 'Resource Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Resource.Name where("No." = field("Resource No.")));
        }
        field(5; "First Date Used"; Date)
        {
            Caption = 'First Date Used';
        }
        field(6; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(7; "Total Hours"; Decimal)
        {
            Caption = 'Total Hours';
            DecimalPlaces = 0:2;
        }
        field(8; "Total Day Task"; Integer)
        {
            Caption = 'Total Day Task';
        }
    }
    
    keys
    {
        key(PK; "Job No.", "Job Task No.", "Resource No.")
        {
            Clustered = true;
        }
        key(DateKey; "First Date Used", "Last Date Used")
        {
        }
    }
    
    procedure FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
        TempResourceList: Record "Resource DayTask Summary" temporary;
    begin
        // Clear existing records
        Rec.DeleteAll();
        
        // Find all Day Tasks for this Job Task
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        
        if not DayTask.FindSet() then
            exit;
        
        // Group by Resource and aggregate
        repeat
            if not TempResourceList.Get(JobNo, JobTaskNo, DayTask."Resource No.") then begin
                TempResourceList.Init();
                TempResourceList."Job No." := JobNo;
                TempResourceList."Job Task No." := JobTaskNo;
                TempResourceList."Resource No." := DayTask."Resource No.";
                TempResourceList."First Date Used" := DayTask."Work Date";
                TempResourceList."Last Date Used" := DayTask."Work Date";
                TempResourceList."Total Hours" := DayTask.Hours;
                TempResourceList."Total Day Task" := 1;
                TempResourceList.Insert();
            end else begin
                // Update existing summary
                if DayTask."Work Date" < TempResourceList."First Date Used" then
                    TempResourceList."First Date Used" := DayTask."Work Date";
                if DayTask."Work Date" > TempResourceList."Last Date Used" then
                    TempResourceList."Last Date Used" := DayTask."Work Date";
                TempResourceList."Total Hours" += DayTask.Hours;
                TempResourceList."Total Day Task" += 1;
                TempResourceList.Modify();
            end;
        until DayTask.Next() = 0;
        
        // Copy from temp to Rec
        if TempResourceList.FindSet() then
            repeat
                Rec := TempResourceList;
                Rec.Insert();
            until TempResourceList.Next() = 0;
    end;
}
```

### Page Specifications

#### Resource DayTask Summary List

**Page Type:** List  
**Page ID:** `50xxx` (TBD - assign next available ID in 50xxx range)  
**Source Table:** Resource DayTask Summary (Temporary)

**Purpose:** Display summarized resource usage for a job task in a list format.

**Fields to Display:**
1. Resource No. (Editable: No)
2. Resource Name (Editable: No, FlowField - requires CalcFields)
3. First Date Used (Editable: No)
4. Last Date Used (Editable: No)
5. Total Day Task (Editable: No)
6. Total Hours (Editable: No)

**Page Layout:**
- **Repeater group** containing all fields
- Fields are read-only (Editable = false)
- Optional: Group fields by date range or resource

**Actions:**
- **Refresh** - Reload data by calling FillBuffer again
- **Show Day Tasks** - Navigate to filtered Day Tasks list for selected resource
- **Weekly Hours** - Drilldown to Resource Weekly Hours page (see pilot-instruction06)
- **Resource Card** - Open Resource Card for selected resource

**Usage Context:**
- Embedded as FactBox on Job Task Card
- Standalone page accessible from Job Task List
- Called from Job Task Card with context (Job No., Job Task No.)

**Page Initialization:**
```al
trigger OnOpenPage()
begin
    // Page will be initialized externally via FillBuffer
    // or by calling code that sets Job No. and Job Task No.
end;
```

**Example AL Code Structure:**
```al
page 50xxx "Resource DayTask Summary"
{
    PageType = List;
    SourceTable = "Resource DayTask Summary";
    SourceTableTemporary = true;
    Caption = 'Resource DayTask Summary';
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
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource name.';
                }
                field("First Date Used"; Rec."First Date Used")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first date the resource was used on this task.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date the resource was used on this task.';
                }
                field("Total Day Task"; Rec."Total Day Task")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of day tasks for this resource.';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total hours allocated to this resource.';
                }
            }
        }
    }
    
    actions
    {
        area(Processing)
        {
            action(ShowWeeklyHours)
            {
                ApplicationArea = All;
                Caption = 'Weekly Hours';
                Image = CalendarMachine;
                ToolTip = 'View weekly hour distribution for this resource on this job task.';
                
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
            action(ShowDayTasks)
            {
                ApplicationArea = All;
                Caption = 'Show Day Tasks';
                Image = TaskList;
                ToolTip = 'View all day tasks for the selected resource on this job task.';
                
                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                begin
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Resource No.", Rec."Resource No.");
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
            action(OpenResourceCard)
            {
                ApplicationArea = All;
                Caption = 'Resource Card';
                Image = Resource;
                ToolTip = 'Open the resource card for the selected resource.';
                
                trigger OnAction()
                var
                    Resource: Record Resource;
                begin
                    if Resource.Get(Rec."Resource No.") then
                        Page.Run(Page::"Resource Card", Resource);
                end;
            }
        }
    }
    
    procedure LoadData(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        Rec.FillBuffer(JobNo, JobTaskNo);
    end;
}
```

**Integration Example:**
```al
// From Job Task Card
var
    ResourceSummary: Record "Resource DayTask Summary";
    ResourceSummaryPage: Page "Resource DayTask Summary";
begin
    ResourceSummary.FillBuffer(JobNo, JobTaskNo);
    ResourceSummaryPage.SetTableView(ResourceSummary);
    ResourceSummaryPage.Run();
end;
```

### Related Objects

- **Source Table:** Day Tasks (existing)
- **Related Tables:** Job, Job Task, Resource
- **Helper Codeunit:** Job Task Resource Summary Mgt. (to be created)
- **Page:** Resource DayTask Summary List (to be created)
- **Drilldown Table:** Resource Weekly Hours (see pilot-instruction06)
- **FactBox Usage:** Resource Summary FactBox (see pilot-instruction07)

## Next Steps

1. Assign table ID from available range (50xxx)
2. Create table object in `src/table/` directory
3. Assign page ID from available range (50xxx)
4. Create page object in `src/page/` directory
5. Add LoadData helper procedure to page for easy initialization
6. Implement Resource Weekly Hours drilldown action (see pilot-instruction06)
7. Consider embedding as FactBox on Job Task Card
8. Add menu item or action to Job Task List for standalone access
9. Test with various Job Task scenarios (single/multiple resources)
10. Optional: Create helper codeunit for additional business logic
