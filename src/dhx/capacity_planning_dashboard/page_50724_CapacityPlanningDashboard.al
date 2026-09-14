page 50724 "Capacity Planning Dashboard"
{
    // Role Center tile - embeds DHXCapacityPlanningDashboardAddin (Sections 1/3/4 only, no single
    // inspected Work Order - see that controladdin's own capacityPlanningDashboard.js doc comment).
    // CardPart, not Card, so page 50612 "Planning Role Center" can embed it directly as a part().
    PageType = CardPart;
    ApplicationArea = All;
    Caption = '';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            usercontrol(DhxCpoDash; DHXCapacityPlanningDashboardAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    EnsureDaysToShow();
                    SendColors();
                    RefreshData();
                end;

                // JS-owned "Days to show" input, inherited unchanged from the base component - see
                // page 50722's own identical trigger doc comment.
                trigger OnDaysToShowChanged(NumberOfDays: Integer)
                begin
                    if NumberOfDays <= 0 then
                        NumberOfDays := DefaultDaysToShow;
                    DaysToShow := NumberOfDays;
                    RefreshData();
                end;

                trigger OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text)
                begin
                    // Never actually raised in normal use - there is no Confirm-changes button on
                    // this tile (capacityPlanningDashboard.js removes it from the DOM, and
                    // workOrderSequences[] is always empty so there is nothing to reschedule
                    // anyway) - declared only so no inherited base-class code path can throw
                    // calling an undeclared controladdin event. See page 50722's own
                    // PersistReschedule for what a real implementation would look like if this
                    // tile ever needed one.
                end;

                trigger OnRequestCapacityLookup(FilterJsonTxt: Text)
                begin
                    // Stub - same as page 50722's own (CPO_BuildCapacityLookupJson wiring comes in
                    // a later step, shared across both pages).
                end;

                trigger OnSequenceChipClick(PayloadJsonTxt: Text)
                begin
                    // Stub - same as page 50722's own.
                end;

                /// <summary>
                /// Section 4's flat skill-grid right-click "Show Data" (2026-09-14) - same
                /// delegation as page 50722's own OnOpenDayPlanningList trigger. Read-only browse,
                /// no RefreshData() call needed afterwards.
                /// </summary>
                trigger OnOpenDayPlanningList(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.CPO_OpenDayPlanningList(PayloadJsonTxt);
                end;

                /// <summary>
                /// Section 3's right-click "Show Data" context menu (2026-09-14) - identical
                /// trigger/delegation as page 50722's own OnShowCapacityBarSegment. Read-only
                /// browse, no RefreshData() call needed afterwards.
                /// </summary>
                trigger OnShowCapacityBarSegment(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.CPO_ShowCapacityBarSegment(PayloadJsonTxt);
                end;
            }
        }
    }

    var
        DaysToShow: Integer;

    local procedure DefaultDaysToShow(): Integer
    begin
        exit(30);
    end;

    local procedure EnsureDaysToShow()
    begin
        if DaysToShow <= 0 then
            DaysToShow := DefaultDaysToShow;
    end;

    /// <summary>Same tooltip-color channel as page 50722's own SendColors - see that procedure's own doc comment.</summary>
    local procedure SendColors()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ColorsJsonTxt: Text;
    begin
        ColorsJsonTxt := StrSubstNo('{"tooltipBg":"%1","tooltipFont":"%2"}',
            VisualDefaultSettings.GetTooltipBackgroundColor(),
            VisualDefaultSettings.GetTooltipFontColor());
        CurrPage.DhxCpoDash.SetColors(ColorsJsonTxt);
    end;

    /// <summary>
    /// Rebuild-and-push routine - builds the real payload via codeunit 50604's new
    /// CPO_BuildDashboardDataJson (2026-09-11 Section 4 perf/simplicity fix - see that procedure's
    /// own doc comment) and pushes it via SetPlanningData in one synchronous call.
    ///
    /// No background-task pagination any more (this used to also call
    /// EnqueueOtherWorkOrderDataBackgroundTask against codeunit "CPO BG Other WO Data", now
    /// removed) - that machinery existed solely to bound the old per-line "groups[]"/
    /// "dayPlanningLines[]" build (CPO_BuildDashboardDataJson_Paged, since removed from codeunit
    /// 50604), which company-wide could be large enough to be slow to build synchronously. Section 4
    /// is now a flat Skill list fed by a single SQL-side aggregation (query 50713 "Day Planning
    /// Skill Day Hours", grouped by Skill+Plan Date) that stays small (skills x days) regardless of
    /// how many real Day Planning rows exist company-wide, so it never needs paging. Section 3's own
    /// capacity/resource builders (CPO_BuildDailyCapacityArray/CPO_BuildResourcesArray/
    /// CPO_BuildExternalFreeArray) were never part of the paginated path and are unaffected - see
    /// CPO_BuildDashboardDataJson's own doc comment. page 50722's own RefreshData/pagination is
    /// untouched - that page's own Section 4 drilldown still needs it.
    /// </summary>
    local procedure RefreshData()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanningDataJson: Text;
    begin
        PlanningDataJson := DHXDataHandler.CPO_BuildDashboardDataJson(DaysToShow);
        CurrPage.DhxCpoDash.SetPlanningData(PlanningDataJson);
    end;
}
