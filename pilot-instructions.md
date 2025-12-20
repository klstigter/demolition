# Pilot Instructions - Job Task Enhancements

## Overview
This pilot implements enhancements to Job Task management with progress tracking, indent/bold formatting, and worked hours tracking.

## Tasks to Implement

### 1. Add Indent and Bold to Job Task List - Project Page
**Objective**: Add hierarchical indentation and bold styling to the Job Task List - Project page (50617), similar to Chart of Accounts.

**Steps**:
- Add `Indentation` field to the page with `StyleExpr = Indentation`
- Update `Description` field to use `IndentationColumn` property
- Add trigger to calculate indentation based on `Job Task Type` or hierarchy
- Apply bold styling for header/total rows using `StyleExpr = StyleIsStrong`
- **Create an "Indent Job Tasks" function/action** to automatically calculate and fill indentation values

**Indent Function Requirements**:
- Add action to Job Task List - Project page (similar to Chart of Accounts "Indent" action)
- Create procedure to calculate indentation level based on Job Task Type hierarchy:
  - Begin-Total: Start of indentation level
  - End-Total: End of indentation level  
  - Posting/Total: Inherit current indentation level
- Loop through Job Tasks in order and calculate indentation depth
- Store calculated indentation in the standard `Indentation` field on Job Task
- Provide confirmation before execution
- Show message with number of tasks updated

**Reference**: 
- Chart of Accounts (Page 16) for implementation pattern
- G/L Account table for Indent codeunit reference

---

### 2. Add Progress Field to Job Task
**Objective**: Track completion percentage for each job task.

**Steps**:
- Add field `50601; Progress; Integer` to Job Task table extension
- Add validation: Progress must be 0-100
- Add field to page "Job Task List - Project" (50617)
- Add field to page "Job Task Card - Project"
- Consider adding visual indicator (e.g., StyleExpr for color coding based on progress)

**Business Rules**:
- Progress range: 0-100 (percentage)
- Default value: 0
- Editable by users
- Could be calculated from completion of child tasks (future enhancement)

---

### 3. Add Worked Hours to Day Tasks
**Objective**: Track actual worked hours for each day task after completion.

**Steps**:
- Add field `70; "Worked Hours"; Decimal` to Day Tasks table (50610)
- Set appropriate decimal places (e.g., `DecimalPlaces = 0:2`)
- Add caption: 'Worked Hours'
- Add to Day Tasks list page
- This field represents realized resource hours after the day has passed

**Business Rules**:
- Field is for actual/realized hours (not planned)
- Can be populated manually or via integration
- Should be editable only after Planning Date has passed (future validation)

---

### 4. Add FlowField to Job Task for Total Worked Hours
**Objective**: Calculate total worked hours from all related Day Tasks.

**Steps**:
- Add FlowField to Job Task table extension:
  ```al
  field(50602; "Total Worked Hours"; Decimal)
  {
      FieldClass = FlowField;
      CalcFormula = sum("Day Tasks"."Worked Hours" 
          where("Job No." = field("Job No."), 
                "Job Task No." = field("Job Task No.")));
      Caption = 'Total Worked Hours';
      Editable = false;
      DecimalPlaces = 0:2;
  }
  ```
- Add field to Job Task List - Project page
- Add field to Job Task Card - Project page
- Position near Progress field for easy comparison

**Benefits**:
- Real-time view of actual hours worked
- Compare with planned hours
- Support progress tracking and project reporting

---

## Implementation Order
1. Progress field (simpler, independent)
2. Worked Hours field on Day Tasks
3. FlowField on Job Task (depends on #2)
4. Indent and bold styling (visual enhancement, can be done last)

## Testing Checklist
- [ ] Progress field validates 0-100 range
- [ ] Worked Hours accepts decimal values
- [ ] Total Worked Hours FlowField calculates correctly
- [ ] Indentation displays hierarchically
- [ ] Bold styling applies to appropriate rows
- [ ] All fields visible on list and card pages

## Notes
- Ensure field numbers don't conflict with existing customizations
- Consider adding these fields to relevant FactBoxes
- May want to add filters/views based on Progress percentage
- Future: Auto-calculate Progress from child tasks or worked hours vs planned hours
