page 50619 "Gantt Demo DHX"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            // controladdin syntax: controladdin(<ControlId>; <ControlAddInName>)
            usercontrol(DHXGanttControl; "DHX Gantt Control")
            {
                ApplicationArea = All;
                // Height/Width can be adjusted if needed
                trigger ControlReady()
                begin
                    CurrPage.DHXGanttControl.Init();
                    CurrPage.DHXGanttControl.LoadData(BuildDummyData());
                end;

                trigger OnAfterTaskUpdate(id: Text; taskJson: Text);
                begin
                    // Finalize saving changed task to BC
                    // Parse taskJson with JsonObject if needed
                    Message('Task with ID %1 has been updated. New data: %2', id, taskJson);
                end;
            }
        }
    }

    local procedure BuildDummyData(): Text
    var
        tasks: Text;
    begin
        // A minimal JSON array suitable for gantt.parse({ data: [...] })
        tasks :=
        '[ ' +
          '{ "id": 1, "text": "Task #1", "start_date": "2025-12-01", "duration": 5, "progress": 0.4, "open": true }, ' +
          '{ "id": 2, "text": "Task #2", "start_date": "2025-12-03", "duration": 3, "progress": 0.2, "parent": 1 }, ' +
          '{ "id": 3, "text": "Milestone", "start_date": "2025-12-06", "duration": 0, "progress": 0, "parent": 1 } ' +
        ']';
        // The add-in expects a JSON string representing the `data` array.
        // We send just the array text; the control add-in wraps it into { data: [...] }.
        exit(tasks);
    end;
}