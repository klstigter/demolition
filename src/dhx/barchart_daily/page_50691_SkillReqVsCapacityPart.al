page 50661 "SkillReq. vs CapacityPart v1"
{
    PageType = ListPart;
    SourceTable = "Skill Req. vs Capacity Buffer";
    SourceTableTemporary = true;
    Caption = 'Requested vs Capacity per Skill';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Skill Code"; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code that the requested hours and capacity are aggregated for.';
                }
                // field(Description; Rec.Description)
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the description of the skill code.';
                // }
                // Added 2026-09-22 (live screenshot request) to mirror the Daily chart's own "C"
                // bar breakdown (see codeunit 50608's BuildSkillBuffer/GetSkillCapacityAssignedFreeSplit) -
                // Capacity Assigned/Free are this skill's own resource-set figures (only resources
                // holding this Skill Code via "Resource Skill"), not a company-wide total.
                field("Capacity Assigned"; Rec."Capacity Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how much of this skill''s own resource capacity is already assigned, for the current Resource No./period filters. Same figure as the "Assigned Capacity" segment of this skill''s "C" bar on the chart.';
                }
                field("Capacity Free"; Rec."Capacity Free")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how much of this skill''s own resource capacity is still free (Internal + External + External Mandatory combined), for the current Resource No./period filters. Same total as the 3 "Free Capacity" segments of this skill''s "C" bar on the chart.';
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total requested hours of the day planning lines that carry this skill.';

                    trigger OnDrillDown()
                    var
                        DayPlanning: Record "Day Planning";
                    begin
                        DayPlanning.Reset();
                        DayPlanning.SetRange(Skill, Rec."No.");
                        if CurrResourceNoFilter <> '' then
                            DayPlanning.SetRange("Assigned Resource No.", CurrResourceNoFilter);
                        case true of
                            (CurrDateFromFilter <> 0D) and (CurrDateToFilter <> 0D):
                                DayPlanning.SetRange("Plan Date", CurrDateFromFilter, CurrDateToFilter);
                            CurrDateFromFilter <> 0D:
                                DayPlanning.SetFilter("Plan Date", '>=%1', CurrDateFromFilter);
                            CurrDateToFilter <> 0D:
                                DayPlanning.SetFilter("Plan Date", '<=%1', CurrDateToFilter);
                        end;
                        Page.Run(Page::"Day Plannings", DayPlanning);
                    end;
                }
                // "Assigned Hours" portion of Requested Hours (see codeunit 50608's
                // BuildSkillAssignedUnassignedSplit) - same figure as the "Requested - Assigned"
                // (green, bottom) segment of this skill's "R" bar on the chart.
                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how much of this skill''s Requested Hours already has an assigned resource. Same figure as the "Requested - Assigned" segment of this skill''s "R" bar on the chart.';
                }
            }
        }
    }

    /// <summary>
    /// Replaces the content of this part with the rows of the supplied temporary buffer.
    /// </summary>
    procedure LoadData(var SourceBuffer: Record "Skill Req. vs Capacity Buffer" temporary; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    begin
        CurrResourceNoFilter := ResourceNoFilter;
        CurrDateFromFilter := DateFromFilter;
        CurrDateToFilter := DateToFilter;

        Rec.Reset();
        Rec.DeleteAll();

        SourceBuffer.Reset();
        if SourceBuffer.FindSet() then
            repeat
                Rec := SourceBuffer;
                Rec.Insert();
            until SourceBuffer.Next() = 0;

        Rec.Reset();
        if Rec.FindFirst() then;

        CurrPage.Update(false);
    end;

    var
        CurrResourceNoFilter: Code[20];
        CurrDateFromFilter: Date;
        CurrDateToFilter: Date;
}
