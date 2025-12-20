# Copilot Instructions for Demolition Project

## Project Overview
This is a Business Central AL extension that provides an embedded planning tool for job management using **DHTMLX** components (Gantt and Scheduler). The extension enhances the standard Job Planning functionality with visual scheduling capabilities.

## Naming Conventions

### DO NOT Use Prefixes
- **Never use "DDSIA" prefix** - this was removed from the project
- Use clear, descriptive names without company prefixes
- Example: `"Job Day Planning Line"` not `"DDSIA Job Day Planning Line"`

### AL Object Naming
- Tables: Clear business names (e.g., `"Job Day Planning Line"`)
- Pages: Plural for lists (e.g., `"Job Day Planning Lines"`), singular for cards
- Codeunits: End with `Mgt.` for management units (e.g., `"Job Day Planning Mgt."`)

## Object Number Ranges
- Tables: 50600-50699
- Pages: 50600-50699
- Codeunits: 50600-50699
- Page Extensions: 50600-50699
- Table Extensions: 50600-50699

## Technology Stack

### DHTMLX Integration
- **DHTMLX Gantt**: For project/Gantt chart visualization (located in `src/dhx/`)
- **DHTMLX Scheduler**: For resource scheduling views
- **DayPilot**: Alternative scheduling component (located in `src/daypilot/`)
- JavaScript files in `src/dhx/` handle the frontend integration
- Control Add-ins are used to embed JavaScript components into BC pages

### Key Customizations
- Extended Job Planning Line with:
  - Start Time and End Time fields
  - End Planning Date for multi-day spans
  - Vendor integration
  - Custom fields: Depth, IsBoor
- Day Planning Lines: Break down job planning lines into daily records for detailed scheduling

## Architecture Patterns

### REST API Integration
- `RestAPIMgt` codeunit handles external API calls
- Integration with external planning systems via REST
- Vendor and Resource synchronization with external systems

### Event Subscribers
- Use event subscribers to keep planning data synchronized
- Auto-update day planning lines when job planning lines change
- Follow the pattern in `JobDayPlanningMgt.Codeunit.al`

## Code Style

### Field Definitions
- Always include Caption property
- Use appropriate DataClassification
- Include ToolTip on page fields
- Use FlowFields for calculated values (e.g., Vendor Name)

### Best Practices
- Use `Record` variables with descriptive names
- Add confirmation dialogs for destructive operations
- Provide user feedback with Message() after batch operations
- Keep procedures focused and single-purpose

## Business Logic

### Job Planning
- Planning Date + Start Time = Beginning of work
- End Planning Date + End Time = End of work
- Day Planning Lines automatically split multi-day jobs at midnight
- Quantities are proportionally distributed across days based on time duration

### Time Calculations
- Always validate that End DateTime > Start DateTime
- Handle midnight crossings properly
- Use CreateDateTime() for datetime calculations

## File Organization
```
src/
  codeunit/     - Business logic and API handlers
  page/         - List and card pages
  pageext/      - Extensions to standard BC pages
  table/        - Custom tables
  tableext/     - Extensions to standard BC tables
  dhx/          - DHTMLX Gantt/Scheduler files
  daypilot/     - DayPilot scheduling components
  enum/         - Custom enums
```

## Common Scenarios

### Adding New Planning Features
1. Extend Job Planning Line table if needed (tableext)
2. Create supporting tables for detailed records
3. Add codeunit for business logic
4. Create or extend pages for UI
5. Use event subscribers for automatic synchronization

### Working with Time Ranges
- Always consider multi-day spans
- Calculate using DateTime (not separate Date and Time)
- Handle edge cases (same day, midnight boundaries)
- Distribute quantities proportionally by time

## Notes
- This extension integrates with standard BC Job Management
- Focus on maintaining data integrity between Job Planning Lines and Day Planning Lines
- The planning tools are visual representations backed by BC data structures
