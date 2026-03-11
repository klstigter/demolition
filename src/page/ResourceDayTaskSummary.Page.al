page 50635 "Resource DayTask Summary"
{
    PageType = List;
    SourceTable = "Resource DayTask Summary";
    Caption = 'Resource DayTask Summary';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource name.';
                }
                field("First Task Date"; Rec."First Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first task date for this resource.';
                }
                field("Last Task Date"; Rec."Last Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last task date for this resource.';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total working hours for this resource.';
                }
                field("Total Days"; Rec."Total Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of days this resource is scheduled.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowWeeklyHours)
            {
                Caption = 'Show Weekly Hours';
                Image = Calendar;
                ToolTip = 'Show weekly hour distribution for this resource.';
                ApplicationArea = All;

                trigger OnAction()
                var
                    WeeklyHours: Record "Resource Weekly Hours";
                    WeeklyHoursPage: Page "Resource Weekly Hours";
                begin
                    WeeklyHours.FillBuffer(Rec."Resource No.", Rec."Job No.", Rec."Job Task No.");
                    WeeklyHoursPage.SetTableView(WeeklyHours);
                    WeeklyHoursPage.Run();
                end;
            }
            action(ShowDayTasks)
            {
                Caption = 'Show Day Tasks';
                Image = TaskList;
                ToolTip = 'Show all day tasks for this resource.';
                ApplicationArea = All;

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                begin
                    DayTask.Reset();
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("No.", Rec."Resource No.");
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
            action(OpenResourceCard)
            {
                Caption = 'Open Resource Card';
                Image = Resource;
                ToolTip = 'Open the resource card.';
                ApplicationArea = All;

                trigger OnAction()
                var
                    Resource: Record Resource;
                begin
                    if Resource.Get(Rec."Resource No.") then
                        Page.Run(Page::"Resource Card", Resource);
                end;
            }
        }
    }

    procedure LoadData(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        Rec.FillBuffer(JobNo, JobTaskNo);
    end;
}
