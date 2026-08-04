page 50661 "Skill Req. vs Capacity Part"
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
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code that the requested hours and capacity are aggregated for.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the skill code.';
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
                        DayPlanning.SetRange(Skill, Rec."Skill Code");
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
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total resource capacity available for this skill. Each resource day capacity counts in full for every skill that the resource holds.';

                    trigger OnDrillDown()
                    var
                        ResourceSkill: Record "Resource Skill";
                        ResCapacityEntry: Record "Res. Capacity Entry";
                        ResourceFilterList: Text;
                    begin
                        ResourceSkill.Reset();
                        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
                        ResourceSkill.SetRange("Skill Code", Rec."Skill Code");
                        if ResourceSkill.FindSet() then
                            repeat
                                if (CurrResourceNoFilter = '') or (ResourceSkill."No." = CurrResourceNoFilter) then begin
                                    if ResourceFilterList <> '' then
                                        ResourceFilterList += '|';
                                    ResourceFilterList += ResourceSkill."No.";
                                end;
                            until ResourceSkill.Next() = 0;

                        ResCapacityEntry.Reset();
                        if ResourceFilterList <> '' then
                            ResCapacityEntry.SetFilter("Resource No.", ResourceFilterList)
                        else
                            ResCapacityEntry.SetRange("Resource No.", ''); // no matching resource -> show nothing rather than error

                        case true of
                            (CurrDateFromFilter <> 0D) and (CurrDateToFilter <> 0D):
                                ResCapacityEntry.SetRange(Date, CurrDateFromFilter, CurrDateToFilter);
                            CurrDateFromFilter <> 0D:
                                ResCapacityEntry.SetFilter(Date, '>=%1', CurrDateFromFilter);
                            CurrDateToFilter <> 0D:
                                ResCapacityEntry.SetFilter(Date, '<=%1', CurrDateToFilter);
                        end;

                        Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
                    end;
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
