# Pilot Instruction 07 - Resource Summary FactBox

**Implementation Status: ✅ COMPLETED**
- FactBox Page ID: 50637 - "Resource Summary FactBox"
- Background Task Codeunit ID: 50617 - "Resource Summary BG Task"
- Files Created:
  - `src/page/ResourceSummaryFactBox.Page.al`
  - `src/codeunit/ResourceSummaryBGTask.Codeunit.al`
- Integration: Job Task Card - Project (Page 50618) updated
- Created: 2025-01-31

## Overview
This document describes a FactBox page for displaying compressed resource summary data on the Job Task Card. The FactBox shows a simplified view of resource usage with only resource name and total hours, optimized for quick reference and performance.

## Purpose
- Display condensed resource usage information as a FactBox
- Show only essential information: Resource Name and Total Hours
- Integrate with Job Task Card - Project (Page 50618)
- Use background processing for optimal performance
- Provide quick overview without drilling into details

## Technical Approach

### Data Source
- Uses **Resource DayTask Summary** table from pilot-instruction05
- Displays only 2 fields: Resource Name and Total Hours
- Omits date range and day task count for simplicity

### Performance Optimization
- **Background Process** fills the buffer asynchronously
- Prevents UI blocking during data loading
- Updates FactBox when data is ready
- Implements progress indication for user feedback

## Page Specifications

### FactBox Page

**Page Type:** ListPart (FactBox)  
**Page ID:** `50xxx` (TBD - assign next available ID in 50xxx range)  
**Source Table:** Resource DayTask Summary (Temporary)  
**Page Name:** `Resource Summary FactBox`

**Purpose:** Display compressed resource usage summary for the current Job Task.

**Fields to Display:**
1. Resource Name (Text[100], FlowField)
2. Total Hours (Decimal)

**Page Properties:**
- PageType = ListPart
- SourceTableTemporary = true
- Editable = false
- InsertAllowed = false
- DeleteAllowed = false
- ModifyAllowed = false
- ShowFilter = false
- LinksAllowed = false

**Layout:**
- Minimal repeater with 2 columns
- No field captions in repeater (use column headers)
- Fixed formatting for Total Hours (decimal with 2 places)
- Optional: Total row at bottom showing sum of all hours

**Actions:**
- **View Details** - Navigate to full Resource DayTask Summary page (pilot-instruction05)
- **Refresh** - Manually trigger background refresh

## Background Process Implementation

### Method 1: Using Page Background Task (Recommended)

**Trigger Flow:**
1. **OnAfterGetCurrRecord** on Job Task Card triggers background task
2. Background task runs FillBuffer in separate session
3. Results returned via **OnPageBackgroundTaskCompleted**
4. FactBox updates with loaded data

**Benefits:**
- Non-blocking UI
- Optimal user experience
- Built-in AL framework support

### Method 2: Using Session.StartSession (Alternative)

**Trigger Flow:**
1. **OnAfterGetCurrRecord** starts new session
2. Session runs data loading codeunit
3. Codeunit stores results in temporary table
4. FactBox polls or receives notification

**Benefits:**
- More control over background process
- Can handle longer-running operations

## Example AL Code Structure

### FactBox Page

```al
page 50xxx "Resource Summary FactBox"
{
    PageType = ListPart;
    SourceTable = "Resource DayTask Summary";
    SourceTableTemporary = true;
    Caption = 'Resource Summary';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                    Caption = 'Resource';
                    ToolTip = 'Specifies the resource name.';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Total Hours';
                    ToolTip = 'Specifies the total hours for this resource.';
                    Style = Strong;
                }
            }
        }
    }
    
    actions
    {
        area(Processing)
        {
            action(ViewDetails)
            {
                ApplicationArea = All;
                Caption = 'View Details';
                Image = View;
                ToolTip = 'View detailed resource usage information.';
                
                trigger OnAction()
                var
                    ResourceSummary: Record "Resource DayTask Summary";
                    ResourceSummaryPage: Page "Resource DayTask Summary";
                begin
                    ResourceSummary.FillBuffer(JobNo, JobTaskNo);
                    ResourceSummaryPage.SetTableView(ResourceSummary);
                    ResourceSummaryPage.Run();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the resource summary data.';
                
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
        TaskParameters.Add('JobTaskNo', JobTaskNo);
        
        // Start background task
        CurrPage.EnqueueBackgroundTask(TaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;
    
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        ResourceSummaryJson: Text;
    begin
        IsDataLoading := false;
        
        if not Results.ContainsKey('ResourceSummary') then
            exit;
        
        ResourceSummaryJson := Results.Get('ResourceSummary');
        LoadDataFromJson(ResourceSummaryJson);
        
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
            Rec."Job No." := GetJsonValue(JObject, 'JobNo');
            Rec."Job Task No." := GetJsonValue(JObject, 'JobTaskNo');
            Rec."Resource No." := GetJsonValue(JObject, 'ResourceNo');
            Evaluate(Rec."Total Hours", GetJsonValue(JObject, 'TotalHours'));
            Rec.CalcFields("Resource Name");
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
}
```

### Background Task Codeunit

```al
codeunit 50xxx "Resource Summary BG Task"
{
    trigger OnRun()
    begin
        RunBackgroundTask();
    end;
    
    procedure RunBackgroundTask()
    var
        ResourceSummary: Record "Resource DayTask Summary";
        Results: Dictionary of [Text, Text];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JsonText: Text;
    begin
        // Get parameters from page background task
        JobNo := CopyStr(Page.GetBackgroundParameters().Get('JobNo'), 1, 20);
        JobTaskNo := CopyStr(Page.GetBackgroundParameters().Get('JobTaskNo'), 1, 20);
        
        // Load data
        ResourceSummary.FillBuffer(JobNo, JobTaskNo);
        
        // Serialize to JSON
        JsonText := SerializeToJson(ResourceSummary);
        
        // Return results
        Results.Add('ResourceSummary', JsonText);
        Page.SetBackgroundTaskResult(Results);
    end;
    
    local procedure SerializeToJson(var ResourceSummary: Record "Resource DayTask Summary"): Text
    var
        JArray: JsonArray;
        JObject: JsonObject;
        JsonText: Text;
    begin
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
}
```

### Integration with Job Task Card - Project

Add FactBox to page 50618 "Job Task Card - Project":

```al
page 50618 "Job Task Card - Project"
{
    // ... existing code ...
    
    layout
    {
        // ... existing content area ...
        
        area(FactBoxes)
        {
            part(ResourceSummary; "Resource Summary FactBox")
            {
                ApplicationArea = All;
                Caption = 'Resource Summary';
                SubPageLink = "Job No." = field("Job No."),
                              "Job Task No." = field("Job Task No.");
            }
        }
    }
    
    trigger OnAfterGetCurrRecord()
    begin
        // Update FactBox with current context
        CurrPage.ResourceSummary.Page.SetContext(Rec."Job No.", Rec."Job Task No.");
    end;
}
```

## Data Flow

1. User opens or navigates in Job Task Card - Project
2. **OnAfterGetCurrRecord** fires
3. FactBox **SetContext** called with Job No. and Job Task No.
4. **LoadDataInBackground** initiates page background task
5. Background task runs codeunit to fill buffer
6. Data serialized to JSON and returned
7. **OnPageBackgroundTaskCompleted** receives results
8. FactBox populated from JSON and displayed
9. User sees resource summary without UI delay

## Performance Considerations

### Background Task Benefits
- UI remains responsive during data loading
- Large datasets don't block user interaction
- Progress can be indicated to user
- Timeout protection (60 seconds default)

### Optimization Tips
1. **Limit data volume** - Only return essential fields
2. **Cache results** - Avoid reloading on every record change
3. **Debounce** - Wait for user to stop navigating before loading
4. **Error handling** - Gracefully handle background task failures
5. **JSON optimization** - Minimize JSON payload size

### Alternative: Cached Loading
If background tasks are too complex, consider:
- Load data synchronously but with progress dialog
- Cache results per Job No. in memory
- Refresh only when explicitly requested
- Display "Loading..." placeholder during refresh

## User Experience

### Loading States
1. **Initial State** - Empty or placeholder text
2. **Loading State** - Progress indicator or "Loading..." message
3. **Loaded State** - Data displayed
4. **Error State** - Error message with Refresh action

### Visual Design
- Compact layout for FactBox space constraints
- Clear column headers (Resource, Hours)
- Bold or styled total hours for emphasis
- Optional: Visual indicator for resources with most hours
- Optional: Color coding for hour ranges

## Integration Points

- **Source Table:** Resource DayTask Summary (pilot-instruction05)
- **Parent Page:** Job Task Card - Project (Page 50618)
- **Background Task Codeunit:** New codeunit for data loading
- **Detailed View:** Resource DayTask Summary page (pilot-instruction05)
- **Further Drilldown:** Resource Weekly Hours page (pilot-instruction06)

## Related Objects

- **Source Table:** Resource DayTask Summary (pilot-instruction05) - Temporary
- **FactBox Page:** Resource Summary FactBox (to be created)
- **Background Task Codeunit:** Resource Summary BG Task (to be created)
- **Parent Page:** Job Task Card - Project (Page 50618) - To be modified
- **Detailed Pages:** Resource DayTask Summary (pilot-instruction05), Resource Weekly Hours (pilot-instruction06)

## Next Steps

1. Assign page ID from available range (50xxx) for FactBox
2. Assign codeunit ID from available range (50xxx) for background task
3. Create FactBox page object in `src/page/` directory
4. Create background task codeunit in `src/codeunit/` directory
5. Modify Job Task Card - Project (Page 50618) to add FactBox area
6. Implement OnAfterGetCurrRecord trigger to update FactBox context
7. Test background loading performance with various data volumes
8. Test error handling when background task fails or times out
9. Verify FactBox refresh on record navigation
10. Optional: Add caching mechanism to reduce redundant loads
11. Optional: Add visual loading indicator during background task

## Implementation Notes

1. FactBox uses SourceTableTemporary = true (no database persistence)
2. Background task runs in separate session with own transaction scope
3. JSON serialization required for data transfer between sessions
4. SubPageLink not effective with temporary tables - use SetContext instead
5. CalcFields for Resource Name must be called after data load
6. Consider timeout value based on expected data volume (default 60000ms)
7. Error handling critical for production stability
8. Test with large datasets (1000+ day tasks) to validate performance

## Alternative Implementations

### Option 1: Page Background Task (Recommended)
- Native AL framework
- Clean API
- Automatic timeout handling
- Best user experience

### Option 2: Session.StartSession
- More flexible
- Requires custom polling or notification
- More complex error handling
- Good for very long operations

### Option 3: Synchronous Loading with Cache
- Simpler implementation
- No background task complexity
- May cause UI lag with large datasets
- Cache prevents repeated loads

## Testing Checklist

- [ ] FactBox displays correctly on Job Task Card
- [ ] Background task loads data without blocking UI
- [ ] Resource names display correctly (FlowField)
- [ ] Total hours calculated and formatted correctly
- [ ] View Details action navigates to full summary page
- [ ] Refresh action reloads data successfully
- [ ] Error handling works when background task fails
- [ ] Timeout handling works for long operations
- [ ] Navigation between job tasks updates FactBox
- [ ] Empty state displays when no resources found
- [ ] Performance acceptable with large datasets (100+ resources)
- [ ] Memory usage reasonable with multiple task cards open
