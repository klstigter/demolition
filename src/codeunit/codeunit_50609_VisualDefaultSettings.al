codeunit 50609 "Visual Default Settings"
{
    /// <summary>
    /// Single authoritative source for every scheduler/chart colour constant and resolution rule
    /// used across the Daily/Weekly bar charts (src/dhx/barchart_daily, src/dhx/barchart_weekly)
    /// and the three scheduler pages (projectschedule/50621, resourceschedule_with_capacity/50706,
    /// poolresourceschedule/50600). Consolidated from three prior duplicate/near-duplicate copies:
    /// codeunit 50662 "Skill Capacity Analysis Mgt." (weekly), codeunit 50608
    /// "SkillCapacityAnalysisMgt.v1" (daily), and codeunit 50604 "DHX Data Handler"'s
    /// ResolveRequestedColor. All three now call into this codeunit instead of holding their own
    /// copy of any hex literal or palette logic - codeunit 50662's/50608's own
    /// GetCapacitySegmentColors/GetSkillBarColor stay in place as thin forwarding wrappers so no
    /// existing caller (including the three scheduler pages, which call codeunit 50662's
    /// GetCapacitySegmentColors directly) needs to change.
    /// </summary>

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Returns the effective Assigned/Free-Capacity/ExternalBorder colours used by the Weekly
    /// chart's stacked Assigned/Capacity segments and, via forwarding, the Daily chart's flat
    /// CAPACITY reference bar plus all three scheduler pages' Assigned/Requested bar colouring
    /// (the scheduler pages fetch ExternalBorderColor too but currently discard it - it only
    /// visually matters on the Daily/Weekly bar charts' "external"/over-capacity segment borders).
    /// All three are overridable via "Daily Optimizer Setup"."Assigned Color"/"Unassigned Capacity
    /// Color"/"External Border Color" when the singleton exists and the field is non-blank, else
    /// fall back to AssColorTok/CapacityColorTok/ExternalBorderColorTok respectively.
    ///
    /// Used by: codeunit 50662 "Skill Capacity Analysis Mgt." - both its own GetCapacitySegmentColors
    /// thin wrapper (called directly by page 50621 ControlReady, page 50706 ControlReady, page 50600
    /// ControlReady, and codeunit 50608's own GetCapacitySegmentColors thin wrapper, which is in turn
    /// called by page 50692 and page 50707) AND its BuildDayCapacityChartData (Weekly bar-chart series
    /// colours), which calls this codeunit directly.
    /// </summary>
    procedure GetCapacitySegmentColors(var AssignedColor: Text; var CapacityColor: Text; var ExternalBorderColor: Text)
    begin
        ResolveCapacitySegmentColors(AssignedColor, CapacityColor, ExternalBorderColor);
    end;

    /// <summary>
    /// Resolves the Assigned/Free-Capacity/ExternalBorder colours together from a single "Daily
    /// Optimizer Setup" lookup - split out from GetCapacitySegmentColors purely so a future caller
    /// that only needs a subset doesn't have to declare/discard unused vars, while still only
    /// paying for one Get() call for all three. "Daily Optimizer Setup".Get() is used in its safe
    /// boolean-context form deliberately - a bare Get() throws when the singleton row doesn't
    /// exist yet (only ever created lazily via page 50654's OnOpenPage, no install-time seeding),
    /// which has already bitten this code area twice before.
    /// </summary>
    local procedure ResolveCapacitySegmentColors(var AssignedColor: Text; var CapacityColor: Text; var ExternalBorderColor: Text)
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        AssignedColor := AssColorTok;
        CapacityColor := CapacityColorTok;
        ExternalBorderColor := ExternalBorderColorTok;

        if DailyOptimizerSetup.Get() then begin
            if DailyOptimizerSetup."Assigned Color" <> '' then
                AssignedColor := DailyOptimizerSetup."Assigned Color";
            if DailyOptimizerSetup."Free Capacity Color" <> '' then
                CapacityColor := DailyOptimizerSetup."Free Capacity Color";
            if DailyOptimizerSetup."External Border Color" <> '' then
                ExternalBorderColor := DailyOptimizerSetup."External Border Color";
        end;
    end;

    /// <summary>
    /// Resolves the border colour used for the Capacity bar/event in the two live
    /// scheduler-timeline pages - resourceschedule_with_capacity/page 50706 and
    /// poolresourceschedule/page 50600 - NOT the same setting as GetCapacitySegmentColors'
    /// ExternalBorderColor above (that one borders the Daily/Weekly bar charts' "external"/
    /// over-capacity segments; this one borders the scheduler timeline's Capacity event/bar
    /// itself). Overridable via "Daily Optimizer Setup"."Capacity Border Color" when the singleton
    /// exists and the field is non-blank, else falls back to CapacityBorderColorTok. Same safe
    /// boolean-context Get() convention as ResolveCapacitySegmentColors above, for the same reason.
    ///
    /// Used by: page 50706 "DHX Scheduler - TimeLine" and page 50600 "DHX Scheduler (Pool
    /// Resource)"'s ControlReady triggers, via codeunit 50662's GetCapacityBorderColor forwarding
    /// wrapper - each sends the result as the "capacityBorder" key in their SetBarColors JSON
    /// payload, which their own wrapper.js already applies to the "--cap-color-border" CSS
    /// variable that the Capacity event's border already reads (that hook pre-existed this change,
    /// just unfed by AL until now).
    /// </summary>
    /// <summary>
    /// Resolves the fill colour used for the Weekly bar chart's Free Capacity - External
    /// (Mandatory) segment - the portion of free capacity held by resources with
    /// Resource."Mandatory Schedulling" = true, shown by page 50692's chart via codeunit 50662's
    /// BuildDayCapacityChartData. Deliberately a standalone getter rather than a 4th out-param on
    /// GetCapacitySegmentColors/ResolveCapacitySegmentColors above, so the many existing callers of
    /// that procedure (codeunit 50662's/50608's own forwarding wrappers, and scheduler pages
    /// 50621/50706/50600) don't need a signature change for a colour none of them use. Overridable
    /// via "Daily Optimizer Setup"."Free Capacity-Mandatory Color" when the singleton exists and the
    /// field is non-blank, else falls back to CapacityMandatoryColorTok - which intentionally
    /// matches CapacityColorTok's hex value, since before this setting existed the Mandatory segment
    /// already rendered using the same colour as regular Free Capacity (zero visual change out of
    /// the box). Same safe boolean-context Get() convention as GetCapacityBorderColor below, for the
    /// same reason.
    ///
    /// Used by: codeunit 50662 "Skill Capacity Analysis Mgt." BuildDayCapacityChartData only.
    /// </summary>
    procedure GetCapacityMandatoryColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Free Capacity-Mandatory Color" <> '' then
                exit(DailyOptimizerSetup."Free Capacity-Mandatory Color");

        exit(CapacityMandatoryColorTok);
    end;

    procedure GetCapacityBorderColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Capacity Border Color" <> '' then
                exit(DailyOptimizerSetup."Capacity Border Color");

        exit(CapacityBorderColorTok);
    end;

    /// <summary>
    /// Text colour for the Capacity bar/event only - "Daily Optimizer Setup"."Capacity Font Color"
    /// when set, else CapacityFontColorTok (black). Never used for any other bar type.
    /// </summary>
    procedure GetCapacityFontColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Capacity Font Color" <> '' then
                exit(DailyOptimizerSetup."Capacity Font Color");

        exit(CapacityFontColorTok);
    end;

    procedure GetDefaultCapacityFontColor(): Text
    begin
        exit(CapacityFontColorTok);
    end;

    /// <summary>
    /// Resolves the text/caption colour used on every event bar's on-bar label across the Gantt
    /// chart (ganttdemo2), the scheduler timeline pages (resourceschedule, resourceschedule_with_
    /// capacity, poolresourceschedule, projectschedule), and the Day Planning bar's label
    /// specifically - a single global setting deliberately applied uniformly to every bar caption,
    /// superseding any bar-specific hardcoded text colour that previously differed (e.g. the
    /// Capacity bar's prior dark-on-light "#3a2600" in resourceschedule_with_capacity/wrapper.js).
    /// Overridable via "Daily Optimizer Setup"."Bar Font Color" when the singleton exists and the
    /// field is non-blank, else falls back to BarFontColorTok (black - this setting's own chosen
    /// default, not a preservation of any single prior per-file hardcoded colour). Same safe
    /// boolean-context Get() convention as GetCapacityBorderColor above, for the same reason.
    ///
    /// Explicitly NOT used for hover/tooltip text colour anywhere, nor for chrome (timeline scale
    /// header cells, grid headers, buttons/icons, dialogs) - those are out of scope by design.
    /// </summary>
    procedure GetBarFontColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Bar Font Color" <> '' then
                exit(DailyOptimizerSetup."Bar Font Color");

        exit(BarFontColorTok);
    end;

    /// <summary>
    /// Resolves the background colour used to shade Saturday/Sunday columns on a scheduler
    /// timeline/Gantt chart - currently consumed as a hardcoded CSS literal by src/dhx/ganttdemo2
    /// (.weekend, style.css) and src/dhx/dayplanning_sequence (.weekend-cell/.weekend-scale,
    /// style.css), both of which this centralises. Overridable via "Daily Optimizer Setup"."Weekend
    /// Color" when the singleton exists and the field is non-blank, else falls back to
    /// WeekendColorTok. Same safe boolean-context Get() convention as GetBarFontColor above.
    /// </summary>
    procedure GetWeekendColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Weekend Color" <> '' then
                exit(DailyOptimizerSetup."Weekend Color");

        exit(WeekendColorTok);
    end;

    /// <summary>
    /// Resolves the background colour used to shade Base Calendar day-off/public-holiday exception
    /// dates (Mon-Fri) on a scheduler timeline/Gantt chart - currently consumed as a hardcoded CSS
    /// literal by src/dhx/ganttdemo2 (.holiday, style.css) and src/dhx/dayplanning_sequence
    /// (.holiday-cell/.holiday-scale, style.css), both of which this centralises. Overridable via
    /// "Daily Optimizer Setup"."Holiday Color" when the singleton exists and the field is
    /// non-blank, else falls back to HolidayColorTok. Same safe boolean-context Get() convention as
    /// GetBarFontColor above.
    /// </summary>
    procedure GetHolidayColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Holiday Color" <> '' then
                exit(DailyOptimizerSetup."Holiday Color");

        exit(HolidayColorTok);
    end;

    /// <summary>
    /// Resolves the fill colour used as the starting seed for every Gantt task bar (ganttdemo2) -
    /// codeunit 50613's CreateJobTaskJsonObject applies this before its own task-type/per-task
    /// Color.Get override waterfall runs, exactly as it already did with the prior hardcoded
    /// literal this setting replaces. Overridable via "Daily Optimizer Setup"."GTB Color" when the
    /// singleton exists and the field is non-blank, else falls back to GanttTaskBarColorTok. Same
    /// safe boolean-context Get() convention as GetHolidayColor above.
    /// </summary>
    procedure GetGanttTaskBarColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Color" <> '' then
                exit(DailyOptimizerSetup."GTB Color");
        exit(GanttTaskBarColorTok);
    end;

    /// <summary>
    /// Resolves the fill colour used as the starting seed for every non-Posting Gantt task bar
    /// (ganttdemo2) - codeunit 50613's CreateJobTaskJsonObject applies this before its own
    /// task-type/per-task Color.Get override waterfall runs, for Job Tasks whose "Job Task Type"
    /// <> Posting. Overridable via "Daily Optimizer Setup"."GTB Color (non posting)" when the
    /// singleton exists and the field is non-blank, else falls back to
    /// GanttTaskBarColorNonPostingTok. Same safe boolean-context Get() convention as
    /// GetHolidayColor above.
    /// </summary>
    procedure GetGanttTaskBarColorNonPosting(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Color (non posting)" <> '' then
                exit(DailyOptimizerSetup."GTB Color (non posting)");
        exit(GanttTaskBarColorNonPostingTok);
    end;

    /// <summary>
    /// Resolves the border colour used for every Gantt task bar (ganttdemo2), applied globally via
    /// wrapper.js's SetGanttTaskBarDefaults into the "--gtb-border-color" CSS custom property.
    /// Overridable via "Daily Optimizer Setup"."GTB Border Color" when the singleton exists and the
    /// field is non-blank, else falls back to GanttTaskBarBorderColorTok. Same safe boolean-context
    /// Get() convention as GetHolidayColor above.
    /// </summary>
    procedure GetGanttTaskBarBorderColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Border Color" <> '' then
                exit(DailyOptimizerSetup."GTB Border Color");
        exit(GanttTaskBarBorderColorTok);
    end;

    /// <summary>
    /// Resolves the progress-fill colour used for every Gantt task bar's completed-portion overlay
    /// (ganttdemo2). Deliberately returns blank when unset - a blank result tells wrapper.js's
    /// onTaskLoading handler to keep computing each task's progress colour dynamically (darkening
    /// that task's own fill colour by 60%, see _darkenHex) rather than freezing every task to one
    /// fixed hex. Overridable via "Daily Optimizer Setup"."GTB Progress Color" when non-blank.
    /// </summary>
    procedure GetGanttTaskBarProgressColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Progress Color" <> '' then
                exit(DailyOptimizerSetup."GTB Progress Color");
        exit('');
    end;

    /// <summary>
    /// Resolves the on-bar label text colour for every Gantt task bar (ganttdemo2). Overridable via
    /// "Daily Optimizer Setup"."GTB Font Color" when the singleton exists and the field is
    /// non-blank, else falls back to GanttTaskBarFontColorTok.
    /// </summary>
    procedure GetGanttTaskBarFontColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Font Color" <> '' then
                exit(DailyOptimizerSetup."GTB Font Color");
        exit(GanttTaskBarFontColorTok);
    end;

    /// <summary>
    /// Resolves the on-bar label font size (px) for every Gantt task bar (ganttdemo2). Overridable
    /// via "Daily Optimizer Setup"."GTB Font size (px)" when the singleton exists and the field is
    /// non-zero, else falls back to DefaultGanttTaskBarFontSizePx (matching the vendored
    /// dhtmlxgantt.css theme's own default).
    /// </summary>
    procedure GetGanttTaskBarFontSize(): Integer
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Font size (px)" <> 0 then
                exit(DailyOptimizerSetup."GTB Font size (px)");
        exit(DefaultGanttTaskBarFontSizePx());
    end;

    /// <summary>
    /// Resolves the bar height (px) for every Gantt task bar (ganttdemo2), applied via
    /// gantt.config.task_height. Overridable via "Daily Optimizer Setup"."GTB Height (px)" when the
    /// singleton exists and the field is non-zero, else falls back to DefaultGanttTaskBarHeightPx
    /// (matching wrapper.js's own pre-existing hardcoded fallback).
    /// </summary>
    procedure GetGanttTaskBarHeight(): Integer
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."GTB Height (px)" <> 0 then
                exit(DailyOptimizerSetup."GTB Height (px)");
        exit(DefaultGanttTaskBarHeightPx());
    end;

    /// <summary>
    /// Resolves the background colour used by every hover/tooltip popup across the DHX control
    /// add-ins (src/dhx/*) - the dhtmlx built-in tooltip plugin's ".dhtmlXTooltip.tooltip" shell,
    /// plus every custom hover-popup div each add-in renders itself (e.g.
    /// request_assignment's .assignment-detail-tooltip/.request-detail-tooltip/
    /// .resource-skill-warning-tooltip/.sequence-drag-tooltip, dayplanning_sequence's
    /// .dps-tooltip, ganttdemo2's #bc_DayPlanning_tooltip and the filter-icon hover popups shared
    /// by ganttdemo2/projectschedule/resourceschedule/resourceschedule_with_capacity/
    /// poolresourceschedule, and capacity_planning_overview's .cpo-event-tip/
    /// .cpo-daily-summary-tip). A single centralised setting so every one of these popups gets a
    /// consistent white-background/black-text look by default, and can all be recoloured together
    /// from one place. Overridable via "Daily Optimizer Setup"."Tooltip Background Color" when
    /// the singleton exists and the field is non-blank, else falls back to
    /// TooltipBackgroundColorTok. Same safe boolean-context Get() convention as GetBarFontColor
    /// above, for the same reason.
    ///
    /// Deliberately a separate setting from GetBarFontColor/BarFontColorTok above - that getter's
    /// own doc comment already states it is explicitly NOT used for hover/tooltip text colour.
    /// </summary>
    procedure GetTooltipBackgroundColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Tooltip Background Color" <> '' then
                exit(DailyOptimizerSetup."Tooltip Background Color");

        exit(TooltipBackgroundColorTok);
    end;

    /// <summary>
    /// Resolves the font/text colour used by every hover/tooltip popup across the DHX control
    /// add-ins - the counterpart to GetTooltipBackgroundColor above; see that procedure's doc
    /// comment for the full list of popups this feeds. Overridable via "Daily Optimizer
    /// Setup"."Tooltip Font Color" when the singleton exists and the field is non-blank, else
    /// falls back to TooltipFontColorTok. Same safe boolean-context Get() convention as
    /// GetBarFontColor above, for the same reason.
    ///
    /// Deliberately a separate setting from GetBarFontColor/BarFontColorTok above - see
    /// GetTooltipBackgroundColor's own doc comment.
    /// </summary>
    procedure GetTooltipFontColor(): Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Tooltip Font Color" <> '' then
                exit(DailyOptimizerSetup."Tooltip Font Color");

        exit(TooltipFontColorTok);
    end;

    /// <summary>
    /// Public getters for this codeunit's own built-in default colours - exposed only so page
    /// 50654's "Reset to default" action can restore a user's setup override back to these
    /// defaults without duplicating the hex literals on the page. The underlying Tok labels stay
    /// local/private per this codeunit's existing convention of never exposing raw vars directly.
    /// </summary>
    procedure GetDefaultWeekendColor(): Text
    begin
        exit(WeekendColorTok);
    end;

    procedure GetDefaultHolidayColor(): Text
    begin
        exit(HolidayColorTok);
    end;

    procedure GetDefaultAssignedColor(): Text
    begin
        exit(AssColorTok);
    end;

    procedure GetDefaultCapacityColor(): Text
    begin
        exit(CapacityColorTok);
    end;

    // Exposed only so page 50654's Reset to default action can restore "Free Capacity-Mandatory
    // Color" without duplicating the hex literal.
    procedure GetDefaultCapacityMandatoryColor(): Text
    begin
        exit(CapacityMandatoryColorTok);
    end;

    // Exposed so table 50605's OnValidate triggers can restore "Envelope Color"/"Envelope Border
    // Color" when a user clears the field - matches src/dhx/resourceschedule_with_capacity/wrapper.js's
    // and src/dhx/projectschedule/wrapper.js's own hardcoded "--dp-color-envelope"/
    // "--dp-color-envelope-border" CSS defaults, which is what a blank value already renders as.
    procedure GetDefaultEnvelopeColor(): Text
    begin
        exit(EnvelopeColorTok);
    end;

    procedure GetDefaultEnvelopeBorderColor(): Text
    begin
        exit(EnvelopeBorderColorTok);
    end;

    procedure GetDefaultExternalBorderColor(): Text
    begin
        exit(ExternalBorderColorTok);
    end;

    /// <summary>
    /// Standard weekly period caption used by every weekly view:
    /// "wk 39 (Mon, 21 Sep 2026 - Sun, 27 Sep 2026)". WeekStartDate is the week's Monday.
    /// </summary>
    procedure FormatWeekPeriodText(WeekStartDate: Date): Text
    begin
        exit(StrSubstNo(WeekPeriodLbl, Date2DWY(WeekStartDate, 2), FormatWeekPeriodDay(WeekStartDate), FormatWeekPeriodDay(WeekStartDate + 6)));
    end;

    local procedure FormatWeekPeriodDay(DayDate: Date): Text
    begin
        exit(Format(DayDate, 0, '<Weekday Text,3>, <Day,2> <Month Text,3> <Year4>'));
    end;

    procedure GetDefaultCapacityBorderColor(): Text
    begin
        exit(CapacityBorderColorTok);
    end;

    procedure GetDefaultBarFontColor(): Text
    begin
        exit(BarFontColorTok);
    end;

    procedure GetDefaultTooltipBackgroundColor(): Text
    begin
        exit(TooltipBackgroundColorTok);
    end;

    procedure GetDefaultTooltipFontColor(): Text
    begin
        exit(TooltipFontColorTok);
    end;

    procedure GetDefaultGanttTaskBarColor(): Text
    begin
        exit(GanttTaskBarColorTok);
    end;

    procedure GetDefaultGanttTaskBarColorNonPosting(): Text
    begin
        exit(GanttTaskBarColorNonPostingTok);
    end;

    procedure GetDefaultGanttTaskBarBorderColor(): Text
    begin
        exit(GanttTaskBarBorderColorTok);
    end;

    procedure GetDefaultGanttTaskBarProgressColor(): Text
    begin
        // Deliberately blank: default is each task's own fill colour darkened 60% (wrapper.js
        // _darkenHex), so there is no single fixed hex to restore.
        exit('');
    end;

    procedure GetDefaultGanttTaskBarFontColor(): Text
    begin
        exit(GanttTaskBarFontColorTok);
    end;

    procedure GetDefaultGanttTaskBarFontSize(): Integer
    begin
        exit(DefaultGanttTaskBarFontSizePx());
    end;

    procedure GetDefaultGanttTaskBarHeight(): Integer
    begin
        exit(DefaultGanttTaskBarHeightPx());
    end;

    /// <summary>
    /// Named default on-bar label font size (px) for every Gantt task bar (ganttdemo2) - matches
    /// the vendored dhtmlxgantt.css theme's own default (--dhx-gantt-regular-font-size: 16px). Same
    /// local-procedure-as-named-constant idiom as the other named-constant helpers
    /// above.
    /// </summary>
    local procedure DefaultGanttTaskBarFontSizePx(): Integer
    begin
        exit(16);
    end;

    /// <summary>
    /// Named default bar height (px) for every Gantt task bar (ganttdemo2) - matches
    /// src/dhx/ganttdemo2/wrapper.js's own pre-existing hardcoded fallback
    /// (`gantt.config.task_height = gantt.config.task_height || 13`). Same
    /// local-procedure-as-named-constant idiom as the other named-constant helpers
    /// above.
    /// </summary>
    local procedure DefaultGanttTaskBarHeightPx(): Integer
    begin
        exit(13);
    end;

    /// <summary>
    /// Returns the colour to use for SkillCode's series/bar. The "Skill Code" master's own
    /// "Bar Color" override (tableext 50609, field 50600) takes precedence when non-blank;
    /// otherwise cycles through a fixed 5-colour palette via PaletteIndex, so any number of active
    /// skills always gets a colour. Blank for the synthetic 'CAPACITY' aggregate-row marker
    /// (CapacitySkillCodeTok) - that bar keeps its own series colour instead of a skill colour.
    /// SkillCode is Code[10] (narrower than Day Planning's own "Skill" field, Code[20]) because
    /// "Skill" has TableRelation = "Skill Code", whose master "Code" field is itself Code[10]
    /// (confirmed live via al_symbolsearch) - any value that ever validated successfully already
    /// fits, so callers holding a Code[20] value truncate via CopyStr before calling this, which is
    /// a safety truncation on already-valid data, not a real loss of precision.
    ///
    /// Used by: codeunit 50604 "DHX Data Handler"'s ResolveRequestedColor (per-skill
    /// "requested_color" on every scheduler event JSON, all three scheduler pages); codeunit
    /// 50662's GetSkillSeriesColor thin wrapper (Weekly bar-chart per-skill series, called from
    /// BuildDayCapacityChartData); codeunit 50608's own GetSkillBarColor thin wrapper (called
    /// directly by page 50692 and page 50707's per-skill Daily bar/legend colouring).
    /// </summary>
    procedure GetSkillBarColor(SkillCode: Code[10]; PaletteIndex: Integer): Text
    var
        SkillCodeRec: Record "Skill Code";
        Palette: array[5] of Text[10];
        BarColor: Text;
    begin
        if SkillCode = CapacitySkillCodeTok then
            exit('');

        if SkillCodeRec.Get(SkillCode) then begin
            BarColor := SkillCodeRec."Bar Color".Trim();
            if BarColor <> '' then
                exit(BarColor);
        end;

        Palette[1] := '#C55A11';
        Palette[2] := '#ED7D31';
        Palette[3] := '#F4B183';
        Palette[4] := '#F8CBAD';
        Palette[5] := '#FBE5D6';
        exit(Palette[(PaletteIndex mod 5) + 1]);
    end;

    /// <summary>
    /// Returns the font/text colour to use for SkillCode's bar label. The "Skill Code" master's own
    /// "Font Color" (tableext 50609, field 50601) takes precedence when non-blank; otherwise falls
    /// back to BarFontColorTok (the same black default GetBarFontColor already uses) - but this
    /// procedure deliberately does NOT consult "Daily Optimizer Setup"."Bar Font Color" itself, even
    /// as a fallback: that setting is reserved for the Capacity bar/event only (see GetBarFontColor's
    /// own doc comment and every scheduler ControlReady that still calls it directly for the Capacity
    /// bar specifically). Blank for the synthetic 'CAPACITY' aggregate-row marker, matching
    /// GetSkillBarColor's own convention - callers rendering the Capacity bar should keep using
    /// GetBarFontColor() directly instead of this procedure.
    /// </summary>
    procedure GetSkillFontColor(SkillCode: Code[10]): Text
    var
        SkillCodeRec: Record "Skill Code";
        FontColor: Text;
    begin
        if SkillCode = CapacitySkillCodeTok then
            exit('');

        if SkillCodeRec.Get(SkillCode) then begin
            FontColor := SkillCodeRec."Font Color".Trim();
            if FontColor <> '' then
                exit(FontColor);
        end;

        exit(BarFontColorTok);
    end;

    /// <summary>
    /// Returns the border colour to use for SkillCode's bar. The "Skill Code" master's own "Border
    /// Color" (tableext 50609, field 50602) takes precedence when non-blank; otherwise falls back to
    /// that same skill's own resolved fill colour (GetSkillBarColor(SkillCode, PaletteIndex)) so an
    /// unconfigured skill's border still looks coherent/solid rather than needing a second unrelated
    /// hardcoded constant - matches the border-equals-fill behaviour src/dhx/dayplanning_sequence's
    /// wrapper.js already has today (applySections: "border-color:" + (s.color || ...)), just now
    /// overridable per-skill. Blank for 'CAPACITY', same convention as GetSkillBarColor/GetSkillFontColor.
    /// </summary>
    procedure GetSkillBorderColor(SkillCode: Code[10]; PaletteIndex: Integer): Text
    var
        SkillCodeRec: Record "Skill Code";
        BorderColor: Text;
    begin
        if SkillCode = CapacitySkillCodeTok then
            exit('');

        if SkillCodeRec.Get(SkillCode) then begin
            BorderColor := SkillCodeRec."Border Color".Trim();
            if BorderColor <> '' then
                exit(BorderColor);
        end;

        exit(GetSkillBarColor(SkillCode, PaletteIndex));
    end;

    var
        // Assigned/Free-Capacity/ExternalBorder fallback tokens - see GetCapacitySegmentColors.
        // Used by: GetCapacitySegmentColors/ResolveCapacitySegmentColors above only.
        AssColorTok: Label '#548235', Locked = true;
        CapacityColorTok: Label '#2E75B6', Locked = true;
        ExternalBorderColorTok: Label '#FF0000', Locked = true;
        WeekPeriodLbl: Label 'wk %1 (%2 - %3)', Comment = '%1 = ISO week number, %2 = week start e.g. "Mon, 21 Sep 2026", %3 = week end e.g. "Sun, 27 Sep 2026"';
        // Fallback for GetCapacityMandatoryColor above - overridable via "Daily Optimizer
        // Setup"."Free Capacity-Mandatory Color". Deliberately the same hex value as
        // CapacityColorTok - see GetCapacityMandatoryColor's doc comment.
        // Used by: GetCapacityMandatoryColor above only.
        CapacityMandatoryColorTok: Label '#2E75B6', Locked = true;
        // Fallback for GetCapacityBorderColor above - overridable via "Daily Optimizer
        // Setup"."Capacity Border Color". Matches resourceschedule_with_capacity/wrapper.js's and
        // poolresourceschedule/wrapper.js's own "--cap-color-border" CSS default, kept in sync by
        // hand for the case where the setup singleton doesn't exist yet.
        // Used by: GetCapacityBorderColor above only.
        CapacityBorderColorTok: Label '#C97F16', Locked = true;
        // Fallback for GetCapacityFontColor - Capacity bar text only.
        CapacityFontColorTok: Label '#000000', Locked = true;
        // Fallback for GetBarFontColor above - overridable via "Daily Optimizer Setup"."Bar Font
        // Color". Black is this setting's own chosen default (deliberately superseding whatever
        // per-bar text colour - white on most bars, dark "#3a2600" on the Capacity bar - was
        // hardcoded per-file prior to this setting's introduction; see GetBarFontColor's doc
        // comment).
        // Used by: GetBarFontColor above only.
        BarFontColorTok: Label '#000000', Locked = true;
        // Fallback for GetTooltipBackgroundColor/GetTooltipFontColor above - overridable via
        // "Daily Optimizer Setup"."Tooltip Background Color"/"Tooltip Font Color". White
        // background / black text is this setting's own chosen default, matching what
        // capacity_planning_overview's .cpo-event-tip/.cpo-daily-summary-tip already hardcoded
        // before this setting centralised it. Deliberately distinct from BarFontColorTok above -
        // see GetTooltipBackgroundColor's own doc comment for why.
        // Used by: GetTooltipBackgroundColor/GetTooltipFontColor above only.
        TooltipBackgroundColorTok: Label '#FFFFFF', Locked = true;
        TooltipFontColorTok: Label '#000000', Locked = true;
        // Fallback for GetWeekendColor/GetHolidayColor above - overridable via "Daily Optimizer
        // Setup"."Weekend Color"/"Holiday Color". Values match what src/dhx/ganttdemo2/style.css
        // and src/dhx/dayplanning_sequence/style.css already hardcode for .weekend/.holiday, kept
        // in sync by hand for the case where the setup singleton doesn't exist yet.
        // Used by: GetWeekendColor/GetHolidayColor above only.
        WeekendColorTok: Label '#ffe0e0', Locked = true;
        HolidayColorTok: Label '#fff3cd', Locked = true;
        // Fallback for GetGanttTaskBarColor above - overridable via "Daily Optimizer Setup"."GTB
        // Color". Matches src/dhx/ganttdemo2/codeunit_50613's own pre-existing hardcoded seed
        // default for a Job Task's bar fill (before that codeunit's own task-type/per-task Color.Get
        // overrides run) - this setting is now that same seed, just made configurable.
        // Used by: GetGanttTaskBarColor above only.
        GanttTaskBarColorTok: Label '#3b8ef0', Locked = true;
        // Fallback for GetGanttTaskBarColorNonPosting above - overridable via "Daily Optimizer
        // Setup"."GTB Color (non posting)". Same literal value as GanttTaskBarColorTok: today
        // Posting and non-Posting bars are visually identical until this field is explicitly set,
        // so the fallback must preserve that until a customer configures it differently.
        // Used by: GetGanttTaskBarColorNonPosting above only.
        GanttTaskBarColorNonPostingTok: Label '#3b8ef0', Locked = true;
        // Fallback for GetGanttTaskBarBorderColor above - overridable via "Daily Optimizer
        // Setup"."GTB Border Color". Matches the vendored dhtmlxgantt.css theme's own resolved
        // default task-bar border colour (--dhx-gantt-task-border: 1px solid #3588c5).
        // Used by: GetGanttTaskBarBorderColor above only.
        GanttTaskBarBorderColorTok: Label '#3588c5', Locked = true;
        // Fallback for GetGanttTaskBarFontColor - black, same as BarFontColorTok.
        GanttTaskBarFontColorTok: Label '#000000', Locked = true;
        // Fallback for GetDefaultEnvelopeColor/GetDefaultEnvelopeBorderColor above - overridable via
        // "Daily Optimizer Setup"."Envelope Color"/"Envelope Border Color". Match the hardcoded
        // "--dp-color-envelope"/"--dp-color-envelope-border" CSS defaults already in
        // resourceschedule_with_capacity/wrapper.js and projectschedule/wrapper.js - what a blank
        // value already renders as.
        // Used by: GetDefaultEnvelopeColor/GetDefaultEnvelopeBorderColor above only.
        EnvelopeColorTok: Label '#1B3A6B', Locked = true;
        EnvelopeBorderColorTok: Label '#14294D', Locked = true;
        // Synthetic aggregate-row marker used by codeunit 50608's BuildSkillBuffer - must stay
        // text-identical to that codeunit's own CapacitySkillCodeTok.
        // Used by: GetSkillBarColor above only (blank-for-'CAPACITY' guard).
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
}
