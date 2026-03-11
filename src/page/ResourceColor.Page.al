page 50602 "Resource Color opt"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Resource Color Opt.";
    Caption = 'Resource Color';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }
                field("Day Task"; Rec."Day Task")
                {
                    ApplicationArea = All;
                }
                field("Capacity"; Rec."Capacity")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateColors)
            {
                ApplicationArea = All;
                Caption = 'Generate Colors';
                ToolTip = 'Auto-assign modern complementary colors to all resources for Day Task and Capacity fields. Existing entries will be overwritten.';
                Image = SetupList;

                trigger OnAction()
                var
                    Res: Record Resource;
                    ResColor: Record "Resource Color Opt.";
                    DayTaskColors: array[8] of Text[30];
                    CapColors: array[8] of Text[30];
                    Idx: Integer;
                    Count: Integer;
                    ConfirmLbl: Label 'This will overwrite all existing color settings for all resources. Continue?';
                    DoneLbl: Label 'Colors generated for %1 resource(s).';
                begin
                    if not Confirm(ConfirmLbl, false) then
                        exit;

                    // Modern complementary pairs: lighter shade for Day Task, deeper shade for Capacity
                    DayTaskColors[1] := 'sky';
                    CapColors[1] := 'ocean';
                    DayTaskColors[2] := 'coral';
                    CapColors[2] := 'crimson';
                    DayTaskColors[3] := 'mint';
                    CapColors[3] := 'teal';
                    DayTaskColors[4] := 'sand';
                    CapColors[4] := 'amber';
                    DayTaskColors[5] := 'rose';
                    CapColors[5] := 'plum';
                    DayTaskColors[6] := 'lavender';
                    CapColors[6] := 'indigo';
                    DayTaskColors[7] := 'green';
                    CapColors[7] := 'violet';
                    DayTaskColors[8] := 'yellow';
                    CapColors[8] := 'blue';

                    Count := 0;
                    Res.Reset();
                    Res.SetFilter("No.", '<>%1', '');
                    if Res.FindSet() then
                        repeat
                            Count += 1;
                            Idx := ((Count - 1) mod 8) + 1;
                            if not ResColor.Get(Res."No.") then begin
                                ResColor.Init();
                                ResColor."Resource No." := Res."No.";
                                ResColor."Day Task" := DayTaskColors[Idx];
                                ResColor.Capacity := CapColors[Idx];
                                ResColor.Insert();
                            end else begin
                                ResColor."Day Task" := DayTaskColors[Idx];
                                ResColor.Capacity := CapColors[Idx];
                                ResColor.Modify();
                            end;
                        until Res.Next() = 0;

                    Message(DoneLbl, Count);
                    CurrPage.Update(false);
                end;
            }
        }
    }

}