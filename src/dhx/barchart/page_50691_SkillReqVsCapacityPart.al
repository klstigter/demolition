page 50691 "Skill Req. vs Capacity Part"
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
                field(Segment; Rec.Segment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what this row''s "Requested Hours" figure represents - "Cap. X" for a capacity-side total (Assigned/Internal/External), "Req. X" for a skill''s requested-hours total ("Req. (No Skill)" for unassigned lines with no Skill set). Drilldown still uses the underlying raw Skill Code, unaffected by this label.';
                }
                // field(Description; Rec.Description)
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the description of the skill code.';
                // }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total requested hours of the day planning lines that carry this skill. On the synthetic Capacity row, this instead shows the total resource capacity (a single aggregate figure for the Resource No. / date filters, not split per skill).';

                    trigger OnDrillDown()
                    var
                        DayPlanning: Record "Day Planning";
                        ResCapacityEntry: Record "Res. Capacity Entry";
                    begin
                        if Rec."No." = CapacitySkillCodeTok then begin
                            // Synthetic aggregate row: capacity is resource/date only, no skill
                            // lookup involved (see codeunit 50662's doc comment). This is the
                            // same drilldown logic that used to live on the separate Capacity
                            // field before that field/column was removed.
                            ResCapacityEntry.Reset();

                            case true of
                                (CurrDateFromFilter <> 0D) and (CurrDateToFilter <> 0D):
                                    ResCapacityEntry.SetRange(Date, CurrDateFromFilter, CurrDateToFilter);
                                CurrDateFromFilter <> 0D:
                                    ResCapacityEntry.SetFilter(Date, '>=%1', CurrDateFromFilter);
                                CurrDateToFilter <> 0D:
                                    ResCapacityEntry.SetFilter(Date, '<=%1', CurrDateToFilter);
                            end;

                            Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
                        end else begin
                            DayPlanning.Reset();
                            DayPlanning.SetRange(Skill, Rec."No.");
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
                    end;
                }
            }
        }
    }

    /// <summary>
    /// Replaces the content of this part with the rows of the supplied temporary buffer.
    /// </summary>
    procedure LoadData(var SourceBuffer: Record "Skill Req. vs Capacity Buffer" temporary; DateFromFilter: Date; DateToFilter: Date)
    begin
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
        CurrDateFromFilter: Date;
        CurrDateToFilter: Date;
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
}
