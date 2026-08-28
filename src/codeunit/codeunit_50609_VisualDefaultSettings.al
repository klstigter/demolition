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
            if DailyOptimizerSetup."Unassigned Capacity Color" <> '' then
                CapacityColor := DailyOptimizerSetup."Unassigned Capacity Color";
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

    procedure GetDefaultExternalBorderColor(): Text
    begin
        exit(ExternalBorderColorTok);
    end;

    procedure GetDefaultCapacityBorderColor(): Text
    begin
        exit(CapacityBorderColorTok);
    end;

    procedure GetDefaultBarFontColor(): Text
    begin
        exit(BarFontColorTok);
    end;

    /// <summary>
    /// Public getter for the Daily chart's own built-in default bar width - same purpose as
    /// GetDefaultAssignedColor/etc. above (lets page 50654's "Reset to default" restore a concrete
    /// value without re-hardcoding the literal), but deliberately NOT 0: the "Bar Width (px) - Bar
    /// Chart" field is shared by both the Daily and Weekly charts, and 0 has its own distinct
    /// meaning ("use each chart's own built-in default" - see ResolveBarChartWidth) rather than
    /// meaning "unset". Resetting to this Daily-specific default is a deliberate choice - it also
    /// makes the Weekly chart render at this same width instead of its own DefaultWeeklyBarWidthPx,
    /// since the field is shared; confirmed as the desired Reset-to-default behaviour.
    /// </summary>
    procedure GetDefaultDailyBarChartWidth(): Integer
    begin
        exit(DefaultDailyBarWidthPx());
    end;

    /// <summary>
    /// Resolves the bar width (in pixels) to use for the Daily "Requested Hours vs Capacity" bar
    /// chart - page 50681 "Requested vs Capacity Daily" and page 50707 "Requested vs Capacity Daily
    /// P" (each builds its own ChartData JSON inline) - from "Daily Optimizer
    /// Setup"."Bar Width (px) - Bar Chart", falling back to DefaultDailyBarWidthPx when the
    /// singleton doesn't exist yet or the field is 0/blank. Thin wrapper over ResolveBarChartWidth
    /// so neither caller needs to know/pass this chart's own default - matches
    /// GetWeeklyBarChartWidth's shape for the Weekly chart's own default.
    /// </summary>
    procedure GetDailyBarChartWidth(): Integer
    begin
        exit(ResolveBarChartWidth(DefaultDailyBarWidthPx()));
    end;

    /// <summary>
    /// Resolves the bar width (in pixels) to use for the Weekly "Requested Hours vs Capacity" bar
    /// chart - codeunit 50662 "Skill Capacity Analysis Mgt."'s BuildDayCapacityChartData, the single
    /// shared JSON builder for both page 50692 "Requested vs Capacity Weekly" and page 50708
    /// "Requested vs Capacity Weekly P" - from "Daily Optimizer Setup"."Bar Width (px) - Bar Chart",
    /// falling back to DefaultWeeklyBarWidthPx when the singleton doesn't exist yet or the field is
    /// 0/blank. Thin wrapper over ResolveBarChartWidth, mirroring GetDailyBarChartWidth.
    /// </summary>
    procedure GetWeeklyBarChartWidth(): Integer
    begin
        exit(ResolveBarChartWidth(DefaultWeeklyBarWidthPx()));
    end;

    /// <summary>
    /// Shared Get()-with-fallback logic behind GetDailyBarChartWidth/GetWeeklyBarChartWidth. Same
    /// safe boolean-context Get() convention as ResolveCapacitySegmentColors above, for the same
    /// reason: the singleton row is only ever created lazily via page 50654's OnOpenPage, so a bare
    /// Get() can throw.
    /// </summary>
    local procedure ResolveBarChartWidth(DefaultWidth: Integer): Integer
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
    begin
        if DailyOptimizerSetup.Get() then
            if DailyOptimizerSetup."Bar Width (px) - Bar Chart" <> 0 then
                exit(DailyOptimizerSetup."Bar Width (px) - Bar Chart");

        exit(DefaultWidth);
    end;

    /// <summary>
    /// Named default bar width (px) for the Daily chart - matches that chart's own wrapper.js
    /// pre-existing hardcoded default (src/dhx/barchart_daily/wrapper.js's RenderChart,
    /// `barWidth: 50`). A local procedure rather than a var-section constant: AL's var section only
    /// supports an inline initializer for Label (see AssColorTok/CapacityColorTok above, used there
    /// for text/hex constants) - this is the equivalent named-constant idiom for a plain Integer.
    /// </summary>
    local procedure DefaultDailyBarWidthPx(): Integer
    begin
        exit(60);
    end;

    /// <summary>
    /// Named default bar width (px) for the Weekly chart - matches that chart's own wrapper.js
    /// pre-existing hardcoded default (src/dhx/barchart_weekly/wrapper.js's BAR_WIDTH_PX). Same
    /// local-procedure-as-named-constant idiom as DefaultDailyBarWidthPx above.
    /// </summary>
    local procedure DefaultWeeklyBarWidthPx(): Integer
    begin
        exit(60);
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

    /// <summary>
    /// Returns the fixed 8-slot "modern complementary pairs" palette used to auto-generate Day
    /// Planning/Capacity colours for every resource at once (lighter shade for Day Planning, deeper
    /// shade for Capacity at the same index). Index-to-value mapping is fixed and must not be
    /// reordered: 1=sky/ocean, 2=coral/crimson, 3=mint/teal, 4=sand/amber, 5=rose/plum,
    /// 6=lavender/indigo, 7=green/violet, 8=yellow/blue.
    ///
    /// Used by: page 50602 "Resource Scheduler Color opt"'s GenerateColors action, which cycles
    /// both palettes together (same index into each) across all resources via a shared Idx = ((Count
    /// - 1) mod 8) + 1.
    /// </summary>
    procedure GetResourceSchedulerDayPlanningPalette(var Palette: array[8] of Text[30])
    begin
        Palette[1] := 'sky';
        Palette[2] := 'coral';
        Palette[3] := 'mint';
        Palette[4] := 'sand';
        Palette[5] := 'rose';
        Palette[6] := 'lavender';
        Palette[7] := 'green';
        Palette[8] := 'yellow';
    end;

    /// <summary>
    /// Returns the fixed 8-slot Capacity half of the "modern complementary pairs" palette - the
    /// deeper-shade counterpart to GetResourceSchedulerDayPlanningPalette, paired index-for-index
    /// with it. Index-to-value mapping is fixed and must not be reordered: 1=ocean, 2=crimson,
    /// 3=teal, 4=amber, 5=plum, 6=indigo, 7=violet, 8=blue.
    ///
    /// Used by: page 50602 "Resource Scheduler Color opt"'s GenerateColors action, alongside
    /// GetResourceSchedulerDayPlanningPalette - see that procedure's comment.
    /// </summary>
    procedure GetResourceSchedulerCapacityPalette(var Palette: array[8] of Text[30])
    begin
        Palette[1] := 'ocean';
        Palette[2] := 'crimson';
        Palette[3] := 'teal';
        Palette[4] := 'amber';
        Palette[5] := 'plum';
        Palette[6] := 'indigo';
        Palette[7] := 'violet';
        Palette[8] := 'blue';
    end;

    /// <summary>
    /// Resolves the 4-colour hash-based fallback used when a resource has no stored "Planning Color
    /// Opt." row (or its row exists but the requested Day Planning/Capacity field is blank) - both
    /// the fixed palette AND its modulo-indexing resolution rule are centralised here, matching how
    /// GetSkillBarColor above centralises both a palette and its indexing rule rather than just a
    /// bare data array. Index-to-value mapping is fixed and must not be reordered: 1=blue, 2=green,
    /// 3=violet, 4=yellow (ColorHash mod 4, then +1 to convert to AL's 1-based array indexing).
    /// The caller computes ColorHash itself (sum of the resource no.'s character codes) and passes it
    /// in - only the final array + lookup lives here.
    ///
    /// Used by: codeunit 50604 "DHX Data Handler"'s ResScheduler_GetResourceColor, which itself has
    /// several internal call sites across that codeunit's Day Planning/Capacity event-JSON builders -
    /// called whenever a resource has no stored "Planning Color Opt." row for the requested colour
    /// type.
    /// </summary>
    procedure GetResourceSchedulerFallbackColor(ColorHash: Integer): Text
    var
        FallbackColors: array[4] of Text;
    begin
        FallbackColors[1] := 'blue';
        FallbackColors[2] := 'green';
        FallbackColors[3] := 'violet';
        FallbackColors[4] := 'yellow';
        exit(FallbackColors[(ColorHash mod 4) + 1]);
    end;

    var
        // Assigned/Free-Capacity/ExternalBorder fallback tokens - see GetCapacitySegmentColors.
        // Used by: GetCapacitySegmentColors/ResolveCapacitySegmentColors above only.
        AssColorTok: Label '#548235', Locked = true;
        CapacityColorTok: Label '#2E75B6', Locked = true;
        ExternalBorderColorTok: Label '#FF0000', Locked = true;
        // Fallback for GetCapacityBorderColor above - overridable via "Daily Optimizer
        // Setup"."Capacity Border Color". Matches resourceschedule_with_capacity/wrapper.js's and
        // poolresourceschedule/wrapper.js's own "--cap-color-border" CSS default, kept in sync by
        // hand for the case where the setup singleton doesn't exist yet.
        // Used by: GetCapacityBorderColor above only.
        CapacityBorderColorTok: Label '#C97F16', Locked = true;
        // Fallback for GetBarFontColor above - overridable via "Daily Optimizer Setup"."Bar Font
        // Color". Black is this setting's own chosen default (deliberately superseding whatever
        // per-bar text colour - white on most bars, dark "#3a2600" on the Capacity bar - was
        // hardcoded per-file prior to this setting's introduction; see GetBarFontColor's doc
        // comment).
        // Used by: GetBarFontColor above only.
        BarFontColorTok: Label '#000000', Locked = true;
        // Fallback for GetWeekendColor/GetHolidayColor above - overridable via "Daily Optimizer
        // Setup"."Weekend Color"/"Holiday Color". Values match what src/dhx/ganttdemo2/style.css
        // and src/dhx/dayplanning_sequence/style.css already hardcode for .weekend/.holiday, kept
        // in sync by hand for the case where the setup singleton doesn't exist yet.
        // Used by: GetWeekendColor/GetHolidayColor above only.
        WeekendColorTok: Label '#ffe0e0', Locked = true;
        HolidayColorTok: Label '#fff3cd', Locked = true;
        // Synthetic aggregate-row marker used by codeunit 50608's BuildSkillBuffer - must stay
        // text-identical to that codeunit's own CapacitySkillCodeTok.
        // Used by: GetSkillBarColor above only (blank-for-'CAPACITY' guard).
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
}
