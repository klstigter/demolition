page 50637 "Resource Summary FactBox"
{
    PageType = ListPart;
    SourceTable = "Resource DayTask Summary";
    SourceTableTemporary = true;
    Caption = 'Resource Summary';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                    Caption = 'Resource';
                    ToolTip = 'Specifies the resource name.';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Total Hours';
                    ToolTip = 'Specifies the total hours for this resource.';
                    Style = Strong;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewDetails)
            {
                ApplicationArea = All;
                Caption = 'View Details';
                Image = View;
                ToolTip = 'View detailed resource usage information.';

                trigger OnAction()
                var
                    DayTask: Page "Day Tasks";
                    DayTaskRec: Record "Day Tasks";
                begin
                    if rec."Job No." <> '' then
                        DayTaskRec."Job No." := Rec."Job No.";
                    if rec."Job Task No." <> '' then
                        DayTaskRec."Job Task No." := Rec."Job Task No.";
                    if rec."Resource No." <> '' then
                        DayTaskRec."No." := Rec."Resource No.";
                    DayTask.SetRecord(DayTaskRec);
                    DayTask.RunModal();

                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the resource summary data.';

                trigger OnAction()
                begin
                    LoadData();
                end;
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        TaskId: Integer;

    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        Rec.DeleteAll();
        LoadData();
        CurrPage.Update(false);
    end;

    local procedure LoadData()
    var
    begin
        rec.FillBuffer(JobNo, JobTaskNo);
    end;


}
