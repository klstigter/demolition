page 50622 "Resource Day Tasks"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Tasks";
    Caption = 'Resource Day Tasks';

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
                    ApplicationArea = All;
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                }
                field(DayLineNo; Rec.DayLineNo)
                {
                    ApplicationArea = All;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                }
                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(ActionName)
    //         {

    //             trigger OnAction()
    //             begin

    //             end;
    //         }
    //     }
    // }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DayTaskRec: Record "Day Tasks";
        ResourceNo: Code[20];
        DayNo: Integer;
        DayLineNo: Integer;
    begin
        Rec.Type := Rec.Type::Resource;

        // Get the No. from the SubPageLink filter (FilterGroup 4)
        Rec.FilterGroup(4);
        if Rec.GetFilter("No.") <> '' then
            ResourceNo := Rec.GetRangeMin("No.");
        Rec.FilterGroup(0);

        if ResourceNo <> '' then
            Rec."No." := ResourceNo;

        DayNo := Date2DMY(Today(), 3) * 10000 + Date2DMY(Today(), 2) * 100 + Date2DMY(Today(), 1);
        DayLineNo := 10000;
        DayTaskRec.SetRange("Day No.", DayNo);
        if DayTaskRec.FindLast() then
            DayLineNo := DayTaskRec.DayLineNo + 10000;

        Rec."Day No." := DayNo;
        Rec.DayLineNo := DayLineNo;
    end;

}