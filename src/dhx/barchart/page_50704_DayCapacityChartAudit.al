page 50704 "Day Capacity Chart Audit"
{
    PageType = List;
    SourceTable = "Day Capacity Chart Audit Buf";
    SourceTableTemporary = true;
    Caption = 'Day Capacity Chart Audit';
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
                field("Day Name"; Rec."Day Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the weekday that this row belongs to.';
                }
                field("Bar Type"; Rec."Bar Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this row belongs to the Capacity bar or the Requested bar for the day.';
                }
                field(Segment; Rec.Segment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the chart segment (Assigned, Internal, External, or a Skill Code) that this row shows the value for.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of this segment, exactly as shown in the corresponding chart bar.';

                    trigger OnDrillDown()
                    var
                        DayPlanning: Record "Day Planning";
                        Resource: Record Resource;
                        ResourceNoList: List of [Code[20]];
                        ResourceNoFilterText: Text;
                    begin
                        if Rec.Segment = UpperCase(AssignedSegmentTok) then begin
                            DayPlanning.Reset();
                            DayPlanning.SetRange("Plan Date", Rec.Day);
                            DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
                            if CurrResourceNoFilter <> '' then
                                DayPlanning.SetRange("Assigned Resource No.", CurrResourceNoFilter);
                            Page.Run(Page::"Day Plannings", DayPlanning);
                        end else
                            if (Rec.Segment = UpperCase(InternalSegmentTok)) or (Rec.Segment = UpperCase(ExternalSegmentTok)) then begin
                                // "Internal"/"External" rows are now codeunit 50662's Assigned-
                                // Hours split (CalcAssignedSplit), not a free-capacity split - so
                                // this drills into the ASSIGNED Day Planning lines behind that
                                // split, not Res. Capacity Entries.
                                DayPlanning.Reset();
                                DayPlanning.SetRange("Plan Date", Rec.Day);
                                DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');

                                if CurrResourceNoFilter <> '' then
                                    DayPlanning.SetRange("Assigned Resource No.", CurrResourceNoFilter)
                                else begin
                                    Clear(ResourceNoList);
                                    Resource.Reset();
                                    Resource.SetRange("Is External", Rec.Segment = UpperCase(ExternalSegmentTok));
                                    if Resource.FindSet() then
                                        repeat
                                            ResourceNoList.Add(Resource."No.");
                                        until Resource.Next() = 0;

                                    ResourceNoFilterText := BuildCodeOrFilter(ResourceNoList);
                                    if ResourceNoFilterText <> '' then
                                        DayPlanning.SetFilter("Assigned Resource No.", ResourceNoFilterText);
                                end;

                                Page.Run(Page::"Day Plannings", DayPlanning);
                            end else begin
                                // A Skill Code segment (Internal or External half - both share the
                                // same bare Skill Code as their Segment text, see codeunit 50662's
                                // BuildDayCapacityAuditBuffer doc comment) - matches
                                // CalcUnassignedSkillRequestedSplit's own filter exactly (Plan
                                // Date + Assigned Resource No. = '' + Skill), covering BOTH halves
                                // together rather than trying to single one out. Deliberately not
                                // narrowed by CurrResourceNoFilter - unassigned lines have no
                                // assigned resource to filter on (see that procedure's own doc
                                // comment in codeunit 50662).
                                DayPlanning.Reset();
                                DayPlanning.SetRange("Plan Date", Rec.Day);
                                DayPlanning.SetRange("Assigned Resource No.", '');
                                DayPlanning.SetRange(Skill, Rec.Segment);
                                Page.Run(Page::"Day Plannings", DayPlanning);
                            end;
                    end;
                }
            }
        }
    }

    /// <summary>
    /// Replaces the content of this page with the rows of the supplied temporary buffer.
    /// </summary>
    procedure LoadData(var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary)
    begin

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

    local procedure BuildCodeOrFilter(var Values: List of [Code[20]]): Text
    var
        Value: Code[20];
        FilterText: Text;
    begin
        foreach Value in Values do
            if FilterText = '' then
                FilterText := Value
            else
                FilterText += '|' + Value;
        exit(FilterText);
    end;

    var
        CurrResourceNoFilter: Code[20];
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
}
