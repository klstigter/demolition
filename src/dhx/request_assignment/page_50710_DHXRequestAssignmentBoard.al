page 50710 "DHX Request Assignment Board"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Request and Assignment Board';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; DHXRequestAssignmentAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    RefreshPlanningData();
                end;

                trigger OnAcceptSequence(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    // JS already applied its own optimistic update for the whole-sequence drop -
                    // this is the only point where that drop actually persists (confirmed product
                    // decision - see codeunit 50604's ReqAssign_AcceptSequence doc comment). No
                    // need to push data back to the control afterwards.
                    DHXDataHandler.ReqAssign_AcceptSequence(PayloadJsonTxt);
                end;

                trigger OnRejectSequence(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    // JS already discards its provisional state on reject - nothing was ever
                    // persisted, so this is a no-op/optional-logging stub on the AL side too.
                    DHXDataHandler.ReqAssign_RejectSequence(PayloadJsonTxt);
                end;

                trigger OnAssignDayTaskLine(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_AssignDayTaskLine(PayloadJsonTxt);
                end;

                trigger OnMoveAssignment(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_MoveAssignment(PayloadJsonTxt);
                end;

                trigger OnResizeAssignment(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_ResizeAssignment(PayloadJsonTxt);
                end;

                trigger OnUnassignDayTaskLine(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_UnassignDayTaskLine(PayloadJsonTxt);
                end;

                trigger OnRequestReset()
                begin
                    // In-canvas "Reset assignments" button - the ported wrapper.js discards all
                    // unsaved client-side state itself before raising this event; the AL side's
                    // only job is to hand back a completely fresh payload, same as Refresh.
                    RefreshPlanningData();
                end;
            }
        }
    }

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(Refresh)
    //         {
    //             Caption = 'Refresh';
    //             ApplicationArea = All;
    //             Image = Refresh;
    //             trigger OnAction()
    //             begin
    //                 RefreshPlanningData();
    //             end;
    //         }
    //     }

    //     area(Promoted)
    //     {
    //         group(Category_Process)
    //         {
    //             Caption = 'Process';
    //             actionref(Refresh_Promoted; Refresh) { }
    //         }
    //     }
    // }

    /// <summary>
    /// Default 30-workday window: StartDate is the Monday of the current week, and EndDate is
    /// the date of the 30th workday counted from that Monday inclusive.
    /// </summary>
    local procedure GetDefaultWindow(var StartDate: Date; var EndDate: Date)
    var
        CurDate: Date;
        WorkdaysCounted: Integer;
    begin
        StartDate := Today() - (Date2DWY(Today(), 1) - 1);
        CurDate := StartDate;
        WorkdaysCounted := 1;

        while WorkdaysCounted < 30 do begin
            CurDate += 1;
            if IsWorkday(CurDate) then
                WorkdaysCounted += 1;
        end;

        EndDate := CurDate;
    end;

    local procedure IsWorkday(D: Date): Boolean
    begin
        // Date2DWY(.., 1) returns the day number within the week, 1=Monday .. 7=Sunday.
        exit(Date2DWY(D, 1) < 6);
    end;

    /// <summary>
    /// Shared rebuild-and-push routine - the single place that calls
    /// ReqAssign_BuildPlanningDataJson and SetPlanningData. Called by ControlReady, the Refresh
    /// action, and the OnRequestReset trigger (the in-canvas "Reset assignments" button) - all
    /// three want the exact same fresh current-week-plus-30-workday payload, so none of them
    /// duplicate this logic themselves.
    /// </summary>
    local procedure RefreshPlanningData()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        StartDate: Date;
        EndDate: Date;
    begin
        GetDefaultWindow(StartDate, EndDate);
        CurrPage.DhxScheduler.SetPlanningData(DHXDataHandler.ReqAssign_BuildPlanningDataJson(StartDate, EndDate));
    end;
}
