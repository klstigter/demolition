page 50667 "Project Type Color Opt."
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Planning Color Opt.";
    SourceTableView = sorting("No.") where(Type = const("Project Task Type"));
    Caption = 'Project Task Type Color';

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
                    Caption = 'Project Task Type';
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    var
                        Ordinals: List of [Integer];
                        OptionStr: Text;
                        Selection: Integer;
                        i: Integer;
                    begin
                        Ordinals := "Job Task Type".Ordinals();
                        for i := 1 to Ordinals.Count do begin
                            if i > 1 then
                                OptionStr += ',';
                            OptionStr += Format("Job Task Type".FromInteger(Ordinals.Get(i)));
                        end;
                        Selection := StrMenu(OptionStr, 0, 'Select Project Task Type');
                        if Selection = 0 then
                            exit;
                        Rec."No." := CopyStr(
                            Format("Job Task Type".FromInteger(Ordinals.Get(Selection))),
                            1, MaxStrLen(Rec."No."));
                    end;
                }
                field("Task"; Rec."Task")
                {
                    ApplicationArea = All;
                }
            }
        }
        // area(Factboxes)
        // {

        // }
    }

    // actions
    // {
    //     area(Processing)
    //     {

    //     }
    // }

}