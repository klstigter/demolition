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
                    Message('Task with ID %1 has been updated. New data: %2', id, taskJson);
                end;

                trigger OnAfterUndo(id: Text; taskJson: Text)
                begin
                    Message('Undo %1 -> %2', id, taskJson);
                end;

                trigger OnAfterRedo(id: Text; taskJson: Text)
                begin
                    Message('Redo %1 -> %2', id, taskJson);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Undo)
            {
                ApplicationArea = All;
                Caption = 'Undo';
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl.Undo();
                end;
            }

            action(Redo)
            {
                ApplicationArea = All;
                Caption = 'Redo';
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl.Redo();
                end;
            }
        }
    }

    var
        globalInt: Integer;

    local procedure BuildDummyData(): Text
    var
        tasks: Text;
    begin
        // Tasks are within 2025-12-01 08:00 and 2025-12-12 17:00
        tasks :=
        '[ ' +
          '{ "id": "MS_START", "text": "Project Start", "type": "milestone", "start_date": "2025-11-28 08:00", "duration": 0 }, ' +
          '{ "id": "T1", "text": "Analysis",       "start_date": "2025-11-28 08:00", "duration": 2, "progress": 0.3, "open": true }, ' +
          '{ "id": "T2", "text": "Design",         "start_date": "2025-12-03 08:00", "duration": 3, "progress": 0.2 }, ' +
          '{ "id": "T3", "text": "Implementation", "start_date": "2025-12-08 08:00", "duration": 2, "progress": 0.1 }, ' +
          '{ "id": "T4", "text": "Testing",        "start_date": "2025-12-10 08:00", "duration": 2, "progress": 0.0 }, ' +
          '{ "id": "MS_END",   "text": "Project End", "type": "milestone", "start_date": "2025-12-12 17:00", "duration": 0 } ' +
        ']';
        exit(tasks);
    end;
}