# Pilot Instruction 08 - Resource Week View Page Part ✅ COMPLETED

## Overview
This document describes a new page part (subpage) for the Job Task Card - Project (Page 50618) that displays resource allocation in a weekly view format. The page part shows resources with their weekly hour distribution and uses background processing for optimal performance.

**Implementation Status:** ✅ COMPLETED
- Page 50638 "Resource Week View Part" created
- Codeunit 50617 extended with TaskType routing (Summary/WeekView)
- Integrated into Job Task Card 50618 as page part
- Background processing implemented with JSON serialization

## Purpose
- Display resource allocation in weekly view as an embedded page part
- Show resource-week combinations with hour breakdown by weekday
- Integrate with Job Task Card - Project as a subpage
- Use background processing to prevent UI blocking
- Provide quick overview of resource scheduling by week

## Technical Approach

### Data Source
- **Reuses:** Resource Weekly Hours table (50612) from pilot-instruction06
- Displays weekly hour distribution per resource
- Shows one row per resource per week
- Background loading using Page Background Task pattern

### Display Format
- ListPart page embedded in Job Task Card
- Columns: Week No., Year, Resource Name, weekday hours, total
- Compact view suitable for embedded display
- Optional: Group by resource or by week

## Page Specifications

### Resource Week View Page Part

**Page Type:** ListPart  
**Page ID:** `50638` ✅  
**Source Table:** Resource Weekly Hours (Table 50612, Temporary)  
**Page Name:** `Resource Week View Part`  
**File:** `src/page/ResourceWeekViewPart.Page.al`

**Purpose:** Display resource weekly hours as an embedded page part on Job Task Card.

**Fields to Display:**
1. Week No. (Integer)
2. Year (Integer)
3. Resource No. (Code[20])
4. Resource Name (FlowField - lookup from Resource table)
5. Monday Hours (Decimal)
6. Tuesday Hours (Decimal)
7. Wednesday Hours (Decimal)
8. Thursday Hours (Decimal)
9. Friday Hours (Decimal)
10. Saturday Hours (Decimal)
11. Sunday Hours (Decimal)
12. Total Week Hours (Decimal, styled)

**Page Properties:**
- PageType = ListPart
- SourceTableTemporary = true
- Editable = false
- InsertAllowed = false
- DeleteAllowed = false
- ModifyAllowed = false

**Layout:**
- Repeater with all fields in columns
- Weekday columns should be visually grouped
- Weekend columns styled differently (subtle)
- Compact layout for embedding

**Actions:**
- **Show Day Tasks** - Navigate to Day Tasks filtered by resource and week
- **Resource Card** - Open Resource Card
- **Refresh** - Manually trigger background refresh

## Background Process Implementation

### Using Page Background Task (Reuse pattern from pilot-instruction07)

**Trigger Flow:**
1. Parent page (Job Task Card) calls **SetContext(JobNo, JobTaskNo)**
2. **LoadDataInBackground** initiates page background task with TaskType parameter
3. Background task runs codeunit 50617 with TaskType='WeekView'
4. Codeunit calls RunWeeklyViewTask() procedure based on TaskType
5. Data aggregated from Day Tasks and serialized to JSON
6. **OnPageBackgroundTaskCompleted** receives results
7. Page part populated from JSON and displayed

**Benefits:**
- Non-blocking UI on Job Task Card
- Fast data loading for large datasets
- Progress indication during load
- Automatic timeout handling

### Background Task Codeunit

**Reuses:** Codeunit 50617 "Resource Summary BG Task" (from pilot-instruction07) ✅  
**Enhancement:** Added new procedure `RunWeeklyViewTask()` to existing codeunit  
**File:** `src/codeunit/ResourceSummaryBGTask.Codeunit.al`

**Purpose:** Extend existing background task codeunit to also load resource weekly hours with TaskType routing.

**Logic:**
1. Receive JobNo and JobTaskNo from page parameters
2. Query Day Tasks table for all resources on the job task
3. For each unique resource:
   - Call Resource Weekly Hours.FillBuffer(ResourceNo, JobNo, JobTaskNo)
   - Collect all week records
4. Serialize all resource-week records to JSON
5. Return JSON to page via SetBackgroundTaskResult

**Optimization:** 
- Load all resources in one pass
- Limit to date range if needed (e.g., next 12 weeks)
- Aggregate by resource then by week

## Data Flow

1. User opens/navigates in Job Task Card - Project
2. **OnAfterGetCurrRecord** fires on parent page
3. Page Part **SetContext** called with Job No. and Job Task No.
4. **LoadDataInBackground** initiates page background task with TaskType='WeekView'
5. Background codeunit 50617 receives task, routes to RunWeeklyViewTask()
6. Codeunit aggregates all resources and their weekly hours from Day Tasks
7. Data serialized to JSON and returned with key 'ResourceWeeklyHours'
8. **OnPageBackgroundTaskCompleted** receives results
9. Page part populated from JSON and displayed
10. User sees resource-week view without UI delay

**Note:** The same codeunit 50617 handles both the Resource Summary FactBox (TaskType='Summary' or missing) and the Resource Week View Part (TaskType='WeekView'), ensuring consistency in background processing patterns.

## Example AL Code Structure

### Resource Week View Page Part

```al
page 50xxx "Resource Week View Part"
{
    PageType = ListPart;
    SourceTable = "Resource Weekly Hours";
    SourceTableTemporary = true;
    Caption = 'Resource Week View';
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
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }
                field("Resource Name"; ResourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Name';
                    ToolTip = 'Specifies the resource name.';
                    Editable = false;
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Monday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Friday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Saturday.';
                    StyleExpr = WeekendStyle;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Sunday.';
                    StyleExpr = WeekendStyle;
                }
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the week.';
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
                ToolTip = 'View all day tasks for this resource and week.';

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayTask.Reset();
                    DayTask.SetRange("No.", Rec."Resource No.");
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Task Date", WeekStart, WeekEnd);
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
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the resource week view data.';

                trigger OnAction()
                begin
                    LoadDataInBackground();
                end;
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        IsDataLoading: Boolean;
        WeekdayStyle: Text;
        WeekendStyle: Text;
        ResourceName: Text[100];

    trigger OnAfterGetRecord()
    var
        Resource: Record Resource;
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';
        
        // Get Resource Name
        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';
    end;

    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        LoadDataInBackground();
    end;

    local procedure LoadDataInBackground()
    var
        TaskParameters: Dictionary of [Text, Text];
    begin
        if IsDataLoading then
            exit;

        if (JobNo = '') or (JobTaskNo = '') then
            exit;

        IsDataLoading := true;

        // Prepare parameters for background task
        TaskParameters.Add('JobNo', JobNo);
        TaskParameters.Add('TaskType', 'WeekView');

        // Start background task - reuse codeunit 50617
        CurrPage.EnqueueBackgroundTask(TaskId, 50617gned
        CurrPage.EnqueueBackgroundTask(TaskId, CodeunitID, TaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        ResourceWeekJson: Text;
    begin
        IsDataLoading := false;
lyHours') then
            exit;

        ResourceWeekJson := Results.Get('ResourceWeeklyHours
        ResourceWeekJson := Results.Get('ResourceWeekData');
        LoadDataFromJson(ResourceWeekJson);

        CurrPage.Update(false);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        IsDataLoading := false;
        IsHandled := true;
    end;

    local procedure LoadDataFromJson(JsonText: Text)
    var
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
    begin
        Rec.DeleteAll();

        if not JArray.ReadFrom(JsonText) then
            exit;

        for i := 0 to JArray.Count() - 1 do begin
            JArray.Get(i, JToken);
            JObject := JToken.AsObject();

            Rec.Init();
            Rec."Resource No." := GetJsonValue(JObject, 'ResourceNo');
            Rec."Job No." := GetJsonValue(JObject, 'JobNo');
            Rec."Job Task No." := GetJsonValue(JObject, 'JobTaskNo');
            Evaluate(Rec.Year, GetJsonValue(JObject, 'Year'));
            Evaluate(Rec."Week No.", GetJsonValue(JObject, 'WeekNo'));
            Evaluate(Rec."Monday Hours", GetJsonValue(JObject, 'MondayHours'));
            Evaluate(Rec."Tuesday Hours", GetJsonValue(JObject, 'TuesdayHours'));
            Evaluate(Rec."Wednesday Hours", GetJsonValue(JObject, 'WednesdayHours'));
            Evaluate(Rec."Thursday Hours", GetJsonValue(JObject, 'ThursdayHours'));
            Evaluate(Rec."Friday Hours", GetJsonValue(JObject, 'FridayHours'));
            Evaluate(Rec."Saturday Hours", GetJsonValue(JObject, 'SaturdayHours'));
            Evaluate(Rec."Sunday Hours", GetJsonValue(JObject, 'SundayHours'));
            Evaluate(Rec."Total Week Hours", GetJsonValue(JObject, 'TotalWeekHours'));
            Rec.Insert();
        end;
    end;

    local procedure GetJsonValue(JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(KeyName, JToken) then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        // ISO 8601: Week 1 is the week with Jan 4th
        Jan4 := DMY2Date(4, 1, YearValue);
        Week1Monday := CalcDate(StrSubstNo('<-%1D>', Date2DWY(Jan4, 1) - 1), Jan4);
        exit(CalcDate(StrSubstNo('<+%1W>', WeekNo - 1), Week1Monday));
    end;
}
```
 Enhancement

**Extend Existing Codeunit 50617 "Resource Summary BG Task"**

Add the following procedures to handle weekly view data:

```al
// Add to existing codeunit 50617 "Resource Summary BG Task"

procedure RunBackgroundTask()
var
    Parameters: Dictionary of [Text, Text];
    TaskType: Text;
begin
    // Get parameters from page background task
    Parameters := Page.GetBackgroundParameters();
    
    // Check task type
    if Parameters.ContainsKey('TaskType') then
        TaskType := Parameters.Get('TaskType')
    else
        TaskType := 'Summary'; // Default for backward compatibility
    
    // Route to appropriate handler
    case TaskType of
        'Summary':
            RunSummaryTask();
        'WeekView':
            RunWeeklyViewTask();
    end;
end;

local procedure RunSummaryTask()
var
    ResourceSummary: Record "Resource DayTask Summary";
    Results: Dictionary of [Text, Text];
    Parameters: Dictionary of [Text, Text];
    JobNo: Code[20];
    JobTaskNo: Code[20];
    JsonText: Text;
begin
    // Get parameters from page background task
    Parameters := Page.GetBackgroundParameters();
    JobNo := CopyStr(Parameters.Get('JobNo'), 1, 20);
    JobTaskNo := CopyStr(Parameters.Get('JobTaskNo'), 1, 20);

    // Load data
    ResourceSummary.FillBuffer(JobNo, JobTaskNo);

    // Serialize to JSON
    JsonText := SerializeSummaryToJson(ResourceSummary);

    // Return results
    Results.Add('ResourceSummary', JsonText);
    Page.SetBackgroundTaskResult(Results);
end;

local procedure RunWeeklyViewTask()
var
    DayTask: Record "Day Tasks";
    ResourceList: Record Resource temporary;
    WeeklyHours: Record "Resource Weekly Hours";
    Results: Dictionary of [Text, Text];
    Parameters: Dictionary of [Text, Text];
    JobNo: Code[20];
    JobTaskNo: Code[20];
    JsonText: Text;
begin
    // Get parameters from page background task
    Parameters := Page.GetBackgroundParameters();
    JobNo := CopyStr(Parameters.Get('JobNo'), 1, 20);
    JobTaskNo := CopyStr(Parameters.Get('JobTaskNo'), 1, 20);

    // Get unique list of resources for this job task
    DayTask.Reset();
    DayTask.SetRange("Job No.", JobNo);
    DayTask.SetRange("Job Task No.", JobTaskNo);
    DayTask.SetFilter("No.", '<>%1', '');
    if DayTask.FindSet() then
        repeat
            if not ResourceList.Get(DayTask."No.") then begin
                ResourceList.Init();
                ResourceList."No." := DayTask."No.";
                ResourceList.Insert();
            end;
        until DayTask.Next() = 0;

    // For each resource, get weekly hours and accumulate
    if ResourceList.FindSet() then
        repeat
            WeeklyHours.FillBuffer(ResourceList."No.", JobNo, JobTaskNo);
        until ResourceList.Next() = 0;

    // Serialize to JSON
    JsonText := SerializeWeeklyHoursToJson(WeeklyHours);

    // Return results
    Results.Add('ResourceWeeklyHours', JsonText);
    Page.SetBackgroundTaskResult(Results);
end;

local procedure SerializeSummaryToJson(var ResourceSummary: Record "Resource DayTask Summary"): Text
var
    JArray: JsonArray;
    JObject: JsonObject;
    JsonText: Text;
begin
    ResourceSummary.Reset();
    if ResourceSummary.FindSet() then
        repeat
            Clear(JObject);
            JObject.Add('JobNo', ResourceSummary."Job No.");
            JObject.Add('JobTaskNo', ResourceSummary."Job Task No.");
            JObject.Add('ResourceNo', ResourceSummary."Resource No.");
            JObject.Add('TotalHours', Format(ResourceSummary."Total Hours", 0, 9));
            JArray.Add(JObject);
        until ResourceSummary.Next() = 0;

    JArray.WriteTo(JsonText);
    exit(JsonText);
end;

local procedure SerializeWeeklyHoursToJson(var WeeklyHours: Record "Resource Weekly Hours"): Text
var
    JArray: JsonArray;
    JObject: JsonObject;
    JsonText: Text;
begin
    WeeklyHours.Reset();
    if WeeklyHours.FindSet() then
        repeat
            Clear(JObject);
            JObject.Add('ResourceNo', WeeklyHours."Resource No.");
            JObject.Add('JobNo', WeeklyHours."Job No.");
            JObject.Add('JobTaskNo', WeeklyHours."Job Task No.");
            JObject.Add('Year', Format(WeeklyHours.Year));
            JObject.Add('WeekNo', Format(WeeklyHours."Week No."));
     Codeunit 50617 "Resource Summary BG Task"** (pilot-instruction07)
   - Extended with RunWeeklyViewTask() procedure
   - Reuses background task infrastructure
   - Adds weekly view JSON serialization
   - Maintains backward compatibility with Resource Summary FactBox

3. **Background Processing Pattern** (pilot-instruction07)
   - Page Background Task framework
   - JSON serialization for data transfer
   - OnPageBackgroundTaskCompleted handling
   - Error handling and timeout management

4. **Day Tasks Table** (existing)
   - Source data for resource assignments
   - Filtered by Job No. and Job Task No.

5
    JArray.WriteTo(JsonText);
    exit(JsonText);
end;
```

**Note:** The RunBackgroundTask procedure is modified to check for a TaskType parameter and route to the appropriate handler. This maintains backward compatibility with the existing Resource Summary FactBox while adding support for the new Weekly View.
```

### Integration with Job Task Card - Project

Add page part to page 50618:

```al
page 50618 "Job Task Card - Project"
{
    // ... existing layout ...
    
    layout
    {
        area(content)
        {
            // ... existing groups ...
            
            part(ResourceWeekView; "Resource Week View Part")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Week Schedule';
                Visible = true;
            }
        }
        
        // ... existing factboxes ...
    }
    
    trigger OnAfterGetCurrRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
        
        // Update Resource Summary FactBox
        CurrPage.ResourceSummary.Page.SetContext(Rec."Job No.", Rec."Job Task No.");
        
        // Update Resource Week View Part
        CurrPage.ResourceWeekView.Page.SetContext(Rec."Job No.", Rec."Job Task No.");
    end;
}
```

## Reused Objects

### From Existing Instructions

1. **Table 50612 "Resource Weekly Hours"** (pilot-instruction06)
   - Source table for page part
   - FillBuffer method for data aggregation
   - Weekly hour distribution by weekday

2. **Background Processing Pattern** (pilot-instruction07)
   - Page Background Task framework
   - JSON serialization for data transfer
   - OnPageBackgroundTaskCompleted handling
   - Error handling and timeout management

3. **Day Tasks Table** (existing)
   - Source data for resource assignments
   - Filtered by Job No. and Job Task No.

4. **Resource Table** (existing)
   - Lookup for Resource Name display
Extend codeunit 50617 with RunWeeklyViewTask() procedure
3. Update RunBackgroundTask() in codeunit 50617 to handle TaskType routing
4. Create page part AL file
5. Modify Job Task Card - Project to add page part
6. Add SetContext call in OnAfterGetCurrRecord
7. Test with various resource counts (1, 10, 50)
8. Test background loading performance
9. Verify both Resource Summary FactBox and Week View work correctly
10. Verify week grouping and sorting
11. Test drill-down actions
12. Validate error handling
13. Optional: Add date range filtering
14 **Batch processing** - Load all resources in single background task
3. **Cache results** - Consider caching per Job Task
4. **Incremental updates** - Only refresh when data changes

### Data Volume Management
- Typical: 5-20 resources × 4-12 weeks = 20-240 rows
- Large: 50 resources × 24 weeks = 1,200 rows
- Background task handles large datasets well

## User Experience

### Display Characteristics
- **Compact view** suitable for embedded display
- **Color coding** for weekends (subtle styling)
- **Bold totals** for emphasis
- **Sortable** by week or resource
- **Quick actions** for drill-down

### Loading States
1. **Initial** - Empty or placeholder
2. **Loading** - Progress indicator
3. **Loaded** - Data displayed
4. **Error** - Error message with Refresh action

### Navigation Actions
- Click resource → Open Resource Card
- Click week → Show Day Tasks for that week
- Refresh → Reload data

## Implementation Notes

1. Page part uses SourceTableTemporary = true
2. Background task runs in separate session
3. JSON required for inter-session data transfer
4. Resource Name calculated in OnAfterGetRecord
5. Week calculation uses ISO 8601 standard
6. SubPageLink not used - SetContext called explicitly
7. Consider adding date range filter for very large datasets
8. Test with 50+ resources to validate performance

## Alternative Implementations

### Option 1: Page Background Task (Recommended)
- Native AL framework
- Clean API with automatic timeout
- Best for user experience
- Used in this specification

### Option 2: Direct Synchronous Loading
- Simpler implementation
- No background task complexity
- May cause UI lag with many resources
- Good for small datasets (<10 resources)

### Option 3: Partial Loading with Pagination
- Load data in chunks
- First visible rows loaded immediately
- Background load for remaining rows
- Most complex but best for very large datasets

## Next Steps

1. Assign page ID from available range (50xxx)
2. Assign codeunit ID from available range (50xxx)
3. Create page part AL file
4. Create background task codeunit AL file
5. Modify Job Task Card - Project to add page part
6. Add SetContext call in OnAfterGetCurrRecord
7. Test with various resource counts (1, 10, 50)
8. Test background loading performance
9. Verify week grouping and sorting
10. Test drill-down actions
11. Validate error handling
12. Optional: Add date range filtering
13. Optional: Add group totals by resource

## Cross-References

- **pilot-instruction05**: Resource DayTask Summary (parent data structure)
- **pilot-instruction06**: Resource Weekly Hours table (reused)
- **pilot-instruction07**: Background processing pattern (reused)
- **Page 50618**: Job Task Card - Project (integration target)
- **Table 50610**: Day Tasks (source data)

## Summary

This instruction creates a comprehensive week view of resource scheduling as an embedded page part on the Job Task Card. It reuses the Resource Weekly Hours table (pilot-instruction06) and extends the existing background processing codeunit 50617 (pilot-instruction07), ensuring consistency with existing implementations while providing a new perspective on resource allocation data. The embedded view gives project managers immediate visibility into resource scheduling by week across all resources assigned to a job task. By extending the existing codeunit rather than creating a new one, we maintain a single point of control for all resource-related background tasks.
