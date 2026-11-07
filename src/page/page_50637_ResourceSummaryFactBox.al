page 50637 "Resource Summary FactBox"
{
    PageType = ListPart;
    SourceTable = "Resource DayPlanning Summary";
    SourceTableTemporary = true;
    Caption = 'Resource Summary';
    Editable = true;
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
                    trigger OnDrillDown()
                    var
                        ResourceCard: Page "Resource Card";
                        resource: record Resource;
                    begin
                        if rec."Resource No." = '' then
                            error('Field %1 must have a value', rec."Resource No.");
                        resource.get(rec."Resource No.");
                        ResourceCard.SetRecord(resource);
                        ResourceCard.Run();
                    end;

                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Total Hours';
                    ToolTip = 'Specifies the total hours for this resource.';
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        DayPlanning: Page "Day Plannings";
                        DayPlanningRec: Record "Day Planning";
                    begin
                        if rec."Job No." <> '' then
                            DayPlanningRec.setfilter("Job No.", Rec."Job No.");
                        if rec."Job Task No." <> '' then
                            DayPlanningRec.setfilter("Job Task No.", Rec."Job Task No.");
                        if rec."Resource No." <> '' then
                            DayPlanningRec.SetFilter("Assigned Resource No.", rec."Resource No.");
                        DayPlanning.SetTableView(DayPlanningRec);
                        DayPlanning.Run();

                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewdayplanningLines)
            {
                ApplicationArea = All;
                Caption = 'Day Planning Lines';
                Image = View;
                ToolTip = 'View all Day Planning Lines.';

                trigger OnAction()
                var
                    DayPlanning: Page "Day Plannings";
                    DayPlanningRec: Record "Day Planning";
                begin
                    if rec."Job No." <> '' then
                        DayPlanningRec.setfilter("Job No.", Rec."Job No.");
                    if rec."Job Task No." <> '' then
                        DayPlanningRec.setfilter("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetTableView(DayPlanningRec);
                    DayPlanning.Run();

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
