# Work-Hour Template Extensions - Implementation Guide

## Objective
Extend the standard "Work-Hour Template" table and page to include default working hours, with automatic calculation of working hours and non-working hours based on start and end times.

## Implementation Steps

### 1. Create Table Extension for Work-Hour Template

**File**: `src/tableext/WorkHourTemplate.TableExt.al`

**Table to Extend**: Table 5954 "Work-Hour Template"

**Fields to Add**:

```al
tableextension 50620 "Work-Hour Template Ext" extends "Work-Hour Template"
{
    fields
    {
        field(50600; "Default Start Time"; Time)
        {
            Caption = 'Default Start Time';
            DataClassification = CustomerContent;
            
            trigger OnValidate()
            begin
                if ("Default Start Time" <> 0T) and ("Default End Time" <> 0T) then
                    if "Default Start Time" >= "Default End Time" then
                        Error('Default Start Time must be earlier than Default End Time.');
            end;
        }
        
        field(50601; "Default End Time"; Time)
        {
            Caption = 'Default End Time';
            DataClassification = CustomerContent;
            
            trigger OnValidate()
            begin
                if ("Default Start Time" <> 0T) and ("Default End Time" <> 0T) then
                    if "Default End Time" <= "Default Start Time" then
                        Error('Default End Time must be later than Default Start Time.');
                
                CalculateNonWorkingHours();
            end;
        }
        
        field(50602; "Non Working Hours"; Decimal)
        {
            Caption = 'Non Working Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0:2;
            Editable = false;
            
            trigger OnValidate()
            begin
                // This field is calculated, but can be manually overridden if needed
                // Remove 'Editable = false' if manual editing is required
            end;
        }
        
        field(50603; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0:2;
            Editable = false;
            
            trigger OnValidate()
            begin
                // This field is calculated, but can be manually overridden if needed
                // Remove 'Editable = false' if manual editing is required
            end;
        }
    }
    
    local procedure CalculateNonWorkingHours()
    var
        TotalMinutes: Integer;
        WorkingMinutes: Integer;
        NonWorkingMinutes: Integer;
    begin
        // If either time is not set, clear both hours fields
        if ("Default Start Time" = 0T) or ("Default End Time" = 0T) then begin
            "Working Hours" := 0;
            "Non Working Hours" := 0;
            exit;
        end;
        
        // Calculate total minutes in a day (24 hours)
        TotalMinutes := 24 * 60;
        
        // Calculate working minutes
        WorkingMinutes := ("Default End Time" - "Default Start Time") div 60000;
        
        // Calculate non-working minutes
        NonWorkingMinutes := TotalMinutes - WorkingMinutes;
        
        // Convert to hours (decimal)
        "Working Hours" := WorkingMinutes / 60;
        "Non Working Hours" := NonWorkingMinutes / 60;
    end;
}
```

**Business Rules**:
- Default Start Time must be earlier than Default End Time
- Non Working Hours is automatically calculated as 24 hours minus working hours
- Non Working Hours is calculated when Default End Time is modified
- All fields use DataClassification = CustomerContent

---

### 2. Create Page Extension for Work-Hour Templates

**File**: `src/pageext/WorkHourTemplates.PageExt.al`

**Page to Extend**: Page 6017 "Work-Hour Templates"

**Implementation**:

```al
pageextension 50620 "Work-Hour Templates Ext" extends "Work-Hour Templates"
{
    layout
    {
        addafter(Description)
        {
            field("Default Start Time"; Rec."Default Start Time")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default start time for work hours using this template.';
            }
            
            field("Default End Time"; Rec."Default End Time")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default end time for work hours using this template.';
            }
            
            field("Working Hours"; Rec."Working Hours")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = false;
                Style = Favorable;
                StyleExpr = true;
            }
            
            field("Non Working Hours"; Rec."Non Working Hours")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of non-working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = false;
                Style = StandardAccent;
                StyleExpr = true;
            }
        }
    }
}
```

**Layout Details**:
- Fields added after the standard "Description" field
- All fields set to `ApplicationArea = All` for visibility
- Appropriate tooltips for user guidance
- Non Working Hours field is read-only (Editable = false)
- Non Working Hours uses accent styling to distinguish it as calculated

---

## Usage Scenarios

### Scenario 1: Creating a Standard 9-5 Work Template
1. Open Work-Hour Templates page
2. Create a new template with Code "STANDARD"
3. Set Description to "Standard 9-5 Workday"
4. Set Default Start Time to 09:00:00
5. Set Default End Time to 17:00:00
5. Working Hours automatically calculates to 8.00
6. Non Working Hours automatically calculates to 16.00 (24 - 8 hours)

### Scenario 2: Night Shift Template
1. Create template with Code "NIGHT"
2. Set Default Start Time to 22:00:00
3. Set Default End Time to 06:00:00 (next day)
4. System validates times and calculates non-working hours

### Scenario 3: Using in Job Planning
1. Reference Work-Hour Template in Job Planning Line
2. Default times can be used to auto-populate start/end times
3. Non-working hours can be used for scheduling calculations

---

## Testing Checklist

- [ ] Table extension compiles without errors
- [ ] Page extension compiles without errors
- [ ] Fields appear on Work-Hour Templates page
- [ ] Default Start Time validation works (must be before End Time)
- [ ] Default End Time validation works (must be after Start Time)
- [ ] Working Hours calculates correctly
- [ ] Non Working Hours calculates correctly
- [ ] Working Hours + Non Working Hours = 24 hours
- [ ] Both calculated fields are read-only
- [ ] ToolTips display correctly
- [ ] Styling appears as expected (Working Hours in green/favorable, Non Working Hours in accent)

---

## Field Specifications

| Field Number | Field Name | Type | Length | Editable | Calculated |
|-------------|------------|------|--------|----------|------------|
| 50600 | Default Start Time | Time | - | Yes | No |
| 50601 | Default End Time | Time | - | Yes | No |
| 50602 | Non Working Hours | Decimal | 0:2 | No | Yes |
| 50603 | Working Hours | Decimal | 0:2 | No | Yes |

---

## Future Enhancements

Consider these additions in future iterations:

1. **Break Time Fields**
   - Add "Break Start Time" and "Break End Time"
   - Adjust Non Working Hours calculation to include breaks

2. **Weekly Template**
   - Different times for different days of the week
   - Weekend/weekday variations

3. **Overtime Calculation**
   - Track hours beyond standard working hours
   - Integration with resource capacity

4. **Auto-Apply to Resources**
   - Automatically update resource calendars based on template
   - Bulk apply templates to multiple resources

5. **Validation Rules**
   - Ensure times align with company working hours
   - Prevent overlapping shifts

---

## Notes

- Object IDs start at 50620 - ensure no conflicts with existing customizations
- Non Working Hours calculation assumes a 24-hour day
- For shifts crossing midnight, additional logic may be needed
- Consider time zone handling for multi-location scenarios
- Fields are designed to work with existing time validation in Business Central
