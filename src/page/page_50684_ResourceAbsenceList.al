page 50684 "Resource Absence List"
{
    Caption = 'Resource Absence List';
    PageType = List;
    SourceTable = "Res. Capacity Entry";
    SourceTableView = where(Type = const(Absence));
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of the absence.';
                }
                field(Hours; HoursValue)
                {
                    ApplicationArea = All;
                    Caption = 'Hours';
                    ToolTip = 'Specifies the number of absence hours.';
                }
                field("Absence Reason Code"; Rec."Absence Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason for the absence.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource this absence entry applies to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("RegisterAbsence")
            {
                ApplicationArea = All;
                Caption = 'Register Absence';
                Image = Register;
                ToolTip = 'Open the Register Absence worksheet to record a new absence for this resource.';

                trigger OnAction()
                var
                    RegisterAbsence: Record "Register Absence";
                    RegisterAbsencePage: Page "Register Absence";
                    ResourceNoValue: Code[20];
                begin
                    // RunPageLink needs an actual current row to read field("Resource No.") from,
                    // so it disables itself on an empty list (no absence history yet - the common
                    // case). The filter that MADE the list empty still exists regardless of row
                    // count, so read it as a filter instead of a bound field value. Which filter
                    // group the calling page's RunPageLink actually lands in has not been proven
                    // for an ACTION's RunPageLink specifically (0/2/4 all seen elsewhere in this
                    // codebase for different mechanisms), so check all three rather than assume.
                    ResourceNoValue := GetResourceNoFilterFromAnyGroup();

                    if ResourceNoValue <> '' then
                        RegisterAbsence.SetRange("Resource No.", ResourceNoValue);
                    RegisterAbsencePage.SetTableView(RegisterAbsence);

                    // Filter/SetTableView propagation into a NEW record's field proved
                    // unreliable in practice - pass the default explicitly instead, via a
                    // dedicated setter, so the worksheet's OnNewRecord has a guaranteed value
                    // to read rather than a filter it has to guess the right group for.
                    if ResourceNoValue <> '' then
                        RegisterAbsencePage.SetDefaultResourceNo(ResourceNoValue);

                    RegisterAbsencePage.Run();
                end;
            }
        }
        area(Promoted)
        {
            actionref(RegisterAbsence_Promoted; "RegisterAbsence") { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HoursValue := -Rec.Capacity;
    end;

    local procedure GetResourceNoFilterFromAnyGroup() Result: Code[20]
    var
        FilterValue: Text;
    begin
        Rec.FilterGroup(0);
        FilterValue := Rec.GetFilter("Resource No.");
        if FilterValue <> '' then
            Result := Rec.GetRangeMin("Resource No.");

        if Result = '' then begin
            Rec.FilterGroup(2);
            FilterValue := Rec.GetFilter("Resource No.");
            if FilterValue <> '' then
                Result := Rec.GetRangeMin("Resource No.");
        end;

        if Result = '' then begin
            Rec.FilterGroup(4);
            FilterValue := Rec.GetFilter("Resource No.");
            if FilterValue <> '' then
                Result := Rec.GetRangeMin("Resource No.");
        end;

        Rec.FilterGroup(0);
    end;

    var
        HoursValue: Decimal;
}
