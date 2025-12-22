# General Utilities Codeunit - Implementation Guide

## Objective
Create a centralized codeunit for general helper functions that can be reused across the application.

## Implementation Steps

### Create General Utilities Codeunit

**File**: `src/codeunit/GeneralUtilities.Codeunit.al`

**Codeunit Structure**:
```al
codeunit 50600 "General Utilities"
{
    // All procedures are public and can be called from anywhere
    
    /// <summary>
    /// Converts a Date to Integer in YYYYMMDD format
    /// </summary>
    /// <param name="InputDate">The date to convert</param>
    /// <returns>Integer in YYYYMMDD format (e.g., 20251222 for December 22, 2025)</returns>
    procedure DateToInteger(InputDate: Date): Integer
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputDate = 0D then
            exit(0);
        
        Year := Date2DMY(InputDate, 3);
        Month := Date2DMY(InputDate, 2);
        Day := Date2DMY(InputDate, 1);
        
        exit((Year * 10000) + (Month * 100) + Day);
    end;
    
    /// <summary>
    /// Converts an Integer in YYYYMMDD format back to Date
    /// </summary>
    /// <param name="InputInteger">Integer in YYYYMMDD format</param>
    /// <returns>Date value</returns>
    procedure IntegerToDate(InputInteger: Integer): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        if InputInteger = 0 then
            exit(0D);
        
        Year := InputInteger div 10000;
        Month := (InputInteger mod 10000) div 100;
        Day := InputInteger mod 100;
        
        exit(DMY2Date(Day, Month, Year));
    end;
    
    // Additional utility functions can be added here as needed
}
```

## Usage Examples

### Example 1: Convert Today's Date to Integer
```al
var
    GeneralUtil: Codeunit "General Utilities";
    DateAsInteger: Integer;
begin
    DateAsInteger := GeneralUtil.DateToInteger(Today());
    // Result: 20251222 for December 22, 2025
    Message('Date as integer: %1', DateAsInteger);
end;
```

### Example 2: Convert Integer Back to Date
```al
var
    GeneralUtil: Codeunit "General Utilities";
    MyDate: Date;
begin
    MyDate := GeneralUtil.IntegerToDate(20251222);
    // Result: 12/22/2025
    Message('Integer as date: %1', MyDate);
end;
```

### Example 3: Use in Table Extension or Page
```al
var
    GeneralUtil: Codeunit "General Utilities";
    PlanningDate: Date;
    DateInt: Integer;
begin
    PlanningDate := Rec."Planning Date";
    DateInt := GeneralUtil.DateToInteger(PlanningDate);
    
    // Use DateInt for comparisons, API calls, or storage
end;
```

## Benefits

1. **Centralized Location** - All common utility functions in one place
2. **Code Reusability** - Avoid duplicating the same logic across multiple objects
3. **Easy Maintenance** - Update the function once, benefits all callers
4. **Consistent Implementation** - Same behavior across the application
5. **Easy to Extend** - Add new utility functions as needed

## Future Utility Functions to Consider

As the application grows, consider adding these functions to the General Utilities codeunit:

### String Utilities
- `TrimAll(Text: Text)` - Remove all whitespace
- `IsNullOrEmpty(Text: Text)` - Check if text is empty or null
- `PadLeft(Text: Text; Length: Integer; PadChar: Char)` - Pad string to left

### Number Utilities
- `RoundToNearest(Value: Decimal; Increment: Decimal)` - Round to nearest increment
- `PercentageOf(Part: Decimal; Total: Decimal)` - Calculate percentage

### DateTime Utilities
- `DateTimeToInteger(InputDateTime: DateTime)` - Convert DateTime to Integer
- `GetWeekNumber(InputDate: Date)` - Get ISO week number
- `AddWorkingDays(StartDate: Date; Days: Integer)` - Add working days only

### Validation Utilities
- `IsValidEmail(Email: Text)` - Validate email format
- `IsNumeric(Text: Text)` - Check if text contains only numbers

## Notes

- Object ID 50600 is used - ensure this doesn't conflict with existing objects
- All procedures are public and can be called from any object
- Consider adding error handling if needed for specific use cases
- Functions are kept simple and focused on one task each
