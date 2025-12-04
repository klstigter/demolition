page 50620 "Gantt Demo DHX 2"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Gantt Demo';

    layout
    {
        area(content)
        {
            // controladdin syntax: controladdin(<ControlId>; <ControlAddInName>)
            usercontrol(DHXGanttControl2; "DHX Gantt Control 2")
            {
                ApplicationArea = All;
                // Height/Width can be adjusted if needed
                trigger ControlReady()
                begin
                    CurrPage.DHXGanttControl2.Init(DMY2Date(28, 11, 2025), DMY2Date(13, 12, 2025));
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
                    CurrPage.DHXGanttControl2.Undo();
                end;
            }

            action(Redo)
            {
                ApplicationArea = All;
                Caption = 'Redo';
                Image = Redo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.Redo();
                end;
            }
            // action(AddMarker)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Add Marker';
            //     Image = Add;
            //     trigger OnAction()
            //     begin
            //         CurrPage.DHXGanttControl2.AddMarker('2024-04-03', 'New Marker');
            //     end;
            // }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref("UodoPromoted"; Undo) { }
                actionref("RedoPromoted"; Redo) { }
            }
        }
    }

    var
        ToggleAutoScheduling: Boolean;
}