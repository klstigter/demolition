page 50602 "Resource Scheduler Color opt"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Planning Color Opt.";
    SourceTableView = sorting("No.") where(Type = const("Resource Scheduler"));
    Caption = 'Resource Scheduler Color';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Type"; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    Caption = 'Resource No.';
                    ApplicationArea = All;
                    TableRelation = Resource;
                }
                field("Day Planning"; Rec."Day Planning")
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
                ToolTip = 'Auto-assign modern complementary colors to all resources for Day Planning and Capacity fields. Existing entries will be overwritten.';
                Image = SetupList;

                trigger OnAction()
                var
                    Res: Record Resource;
                    ResColor: Record "Planning Color Opt.";
                    ColorConstants: Codeunit "Visual Default Settings";
                    DayPlanningColors: array[8] of Text[30];
                    CapColors: array[8] of Text[30];
                    Idx: Integer;
                    Count: Integer;
                    ConfirmLbl: Label 'This will overwrite all existing color settings for all resources. Continue?';
                    DoneLbl: Label 'Colors generated for %1 resource(s).';
                begin
                    if not Confirm(ConfirmLbl, false) then
                        exit;

                    // Modern complementary pairs: lighter shade for Day Planning, deeper shade for Capacity
                    ColorConstants.GetResourceSchedulerDayPlanningPalette(DayPlanningColors);
                    ColorConstants.GetResourceSchedulerCapacityPalette(CapColors);

                    Count := 0;
                    Res.Reset();
                    Res.SetFilter("No.", '<>%1', '');
                    if Res.FindSet() then
                        repeat
                            Count += 1;
                            Idx := ((Count - 1) mod 8) + 1;
                            if not ResColor.Get(ResColor.Type::"Resource Scheduler", Res."No.", '', '') then begin
                                ResColor.Init();
                                ResColor.Type := ResColor.Type::"Resource Scheduler";
                                ResColor."No." := Res."No.";
                                ResColor."Day Planning" := DayPlanningColors[Idx];
                                ResColor.Capacity := CapColors[Idx];
                                ResColor.Insert();
                            end else begin
                                ResColor."Day Planning" := DayPlanningColors[Idx];
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