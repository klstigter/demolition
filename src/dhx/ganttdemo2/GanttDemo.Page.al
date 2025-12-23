page 50620 "Gantt Demo DHX 2"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Gantt Demo';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            // controladdin syntax: controladdin(<ControlId>; <ControlAddInName>)
            usercontrol(DHXGanttControl2; "DHX Gantt Control 2")
            {
                ApplicationArea = All;
                // Height/Width can be adjusted if needed
                trigger OnAfterInit()
                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);

                end;

                trigger ControlReady()
                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);
                    CurrPage.DHXGanttControl2.SetColumnVisibility(
                        Setup."Show Start Date",
                        Setup."Show Duration",
                        Setup."Show Constraint Type",
                        Setup."Show Constraint Date",
                        Setup."Show Task Type"
                    );
                    CurrPage.DHXGanttControl2.LoadProject(Setup."From Date", Setup."To Date");


                end;

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GanttSettings)
            {
                Caption = 'Gantt Settings';
                Image = Setup;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Gantt Chart Setup");
                    setup.get(UserId);
                    CurrPage.DHXGanttControl2.SetColumnVisibility(
                     Setup."Show Start Date",
                     Setup."Show Duration",
                     Setup."Show Constraint Type",
                     Setup."Show Constraint Date",
                     Setup."Show Task Type");
                    CurrPage.DHXGanttControl2.LoadProject(Setup."From Date", Setup."To Date");
                    CurrPage.Update(false); // reapply settings after close
                end;
            }
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
                actionref(GanttSettings_ref; GanttSettings) { }
                actionref("UodoPromoted"; Undo) { }
                actionref("RedoPromoted"; Redo) { }
            }
        }
    }



    var
        ToggleAutoScheduling: Boolean;

        Setup: Record "Gantt Chart Setup";


}