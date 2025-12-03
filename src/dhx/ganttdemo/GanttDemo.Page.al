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

                trigger OnAfterGetAutoscheduling(enabled: Boolean)
                begin
                    if enabled then
                        Message('Auto-Scheduling is currently Enabled')
                    else
                        Message('Auto-Scheduling is currently Disabled');
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
                Image = Undo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl.Undo();
                end;
            }

            action(Redo)
            {
                ApplicationArea = All;
                Caption = 'Redo';
                Image = Redo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl.Redo();
                end;
            }

            action(SetAutoScheduling)
            {
                ApplicationArea = All;
                Caption = 'Toggle Auto-Scheduling';
                Image = AutofillQtyToHandle;
                trigger OnAction()
                begin
                    ToggleAutoScheduling := not ToggleAutoScheduling;
                    CurrPage.DHXGanttControl.SetAutoscheduling(ToggleAutoScheduling);
                    if ToggleAutoScheduling then
                        Message('Auto-Scheduling Enabled')
                    else
                        Message('Auto-Scheduling Disabled');
                end;
            }
            action(GetAutoScheduling)
            {
                ApplicationArea = All;
                Caption = 'Get Auto-Scheduling Status';
                Image = Check;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl.GetAutoscheduling();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref("UodoPromoted"; Undo) { }
                actionref("RedoPromoted"; Redo) { }
                actionref("SetAutoSchedulingPromoted"; SetAutoScheduling) { }
                actionref("GetAutoSchedulingPromoted"; GetAutoScheduling) { }
            }
        }
    }

    var
        ToggleAutoScheduling: Boolean;

    local procedure BuildDummyData(): Text
    var
        tasks: Text;
    begin
        // Tasks are within 2025-12-01 08:00 and 2025-12-12 17:00
        tasks :=
        '{' +
            '"data": [ ' +
                '{ "id": "P1", "text": "Project 01", "type": "milestone", "start_date": "2025-11-28 08:00", "duration": 0}, ' +
                '{ "id": "T1", "text": "Analysis",       "start_date": "2025-11-28 08:00", "duration": 2, "progress": 0.3, "open": true, "parent": "P1" }, ' +
                '{ "id": "T2", "text": "Design",         "start_date": "2025-12-03 08:00", "duration": 3, "progress": 0.2 , "parent": "P1"}, ' +
                '{ "id": "T3", "text": "Implementation", "start_date": "2025-12-08 08:00", "duration": 2, "progress": 0.1 , "parent": "P1"}, ' +
                '{ "id": "T4", "text": "Testing",        "start_date": "2025-12-10 08:00", "duration": 2, "progress": 0.0 , "parent": "P1"}, ' +
                '{ "id": "P1_END",   "text": "Project End", "type": "milestone", "start_date": "2025-12-12 17:00", "duration": 0}, ' +
                '{ "id": "P2", "text": "Project 02", "type": "milestone", "start_date": "2025-11-28 08:00", "duration": 0}, ' +
                '{ "id": "T11", "text": "Analysis",       "start_date": "2025-11-28 08:00", "duration": 2, "progress": 0.3, "open": true, "parent": "P2" }, ' +
                '{ "id": "T22", "text": "Design",         "start_date": "2025-12-03 08:00", "duration": 3, "progress": 0.2 , "parent": "P2"}, ' +
                '{ "id": "T33", "text": "Implementation", "start_date": "2025-12-08 08:00", "duration": 2, "progress": 0.1 , "parent": "P2"}, ' +
                '{ "id": "T44", "text": "Testing",        "start_date": "2025-12-10 08:00", "duration": 2, "progress": 0.0 , "parent": "P2"}, ' +
                '{ "id": "P2_END",   "text": "Project End", "type": "milestone", "start_date": "2025-12-12 17:00", "duration": 0} ' +
            ']' +
            ', "links": [ ' +
                '{ "id": "L1", "source": "P1", "target": "T1", "type": "0" }, ' +
                '{ "id": "L2", "source": "T1",       "target": "T2", "type": "0" }, ' +
                '{ "id": "L3", "source": "T2",       "target": "T3", "type": "0" }, ' +
                '{ "id": "L4", "source": "T3",       "target": "T4", "type": "0" }, ' +
                '{ "id": "L5", "source": "T4",       "target": "P1_END",   "type": "0" } ' +
            ']' +
            ', "markers": [' +
                '{ "id": "kickoff",  "start_date": "2025-11-28 08:00", "text": "Kickoff",  "css": "project-boundary-start" },' +
                '{ "id": "deadline", "start_date": "2025-12-13 17:00", "text": "Deadline/RDD", "css": "project-boundary-end" }' +
            ']' +
        '}';
        exit(tasks);
    end;
}