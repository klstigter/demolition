page 50638 "Resource Week View Part"
{
    PageType = ListPart;
    SourceTable = "Resource Weekly Hours";
    SourceTableTemporary = true;
    Caption = 'Resource Week View';
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
                field(Year; Rec.Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year.';
                    Visible = false;
                }
                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISO week number.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }
                field("Resource Name"; ResourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Name';
                    ToolTip = 'Specifies the resource name.';
                    Editable = false;
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Monday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Friday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Saturday.';
                    StyleExpr = WeekendStyle;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Sunday.';
                    StyleExpr = WeekendStyle;
                }
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the week.';
                    Style = Strong;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDayTasks)
            {
                ApplicationArea = All;
                Caption = 'Show Day Tasks';
                Image = TaskList;
                ToolTip = 'View all day tasks for this resource and week.';

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    if rec."Job No." = '' then begin
                        Message('No resource assigned for this job task.');
                        exit;
                    end;

                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayTask.Reset();
                    DayTask.SetRange("No.", Rec."Resource No.");
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Task Date", WeekStart, WeekEnd);
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
            action(OpenResourceCard)
            {
                ApplicationArea = All;
                Caption = 'Resource Card';
                Image = Resource;
                ToolTip = 'Open the resource card.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                begin
                    if Resource.Get(Rec."Resource No.") then
                        Page.Run(Page::"Resource Card", Resource);
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the resource week view data.';

                trigger OnAction()
                begin
                    LoadDataInBackground();
                end;
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        WeekdayStyle: Text;
        WeekendStyle: Text;
        ResourceName: Text[100];
        TaskId: Integer;

    trigger OnAfterGetRecord()
    var
        Resource: Record Resource;
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';

        // Get Resource Name
        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';
    end;

    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        Rec.DeleteAll();
        LoadDataInBackground();
    end;

    local procedure LoadDataInBackground()
    var
        TaskParameters: Dictionary of [Text, Text];
    begin
        if (JobNo = '') or (JobTaskNo = '') then
            exit;
        // Prepare parameters for background task
        TaskParameters.Add('JobNo', JobNo);
        TaskParameters.Add('JobTaskNo', JobTaskNo);
        TaskParameters.Add('TaskType', 'WeekView');
        // Start background task - reuse codeunit 50617
        CurrPage.EnqueueBackgroundTask(TaskId, 50617, TaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        ResourceWeekJson: Text;
    begin
        if not Results.ContainsKey('ResourceWeeklyHours') then
            exit;

        ResourceWeekJson := Results.Get('ResourceWeeklyHours');
        LoadDataFromJson(ResourceWeekJson);

        CurrPage.Update(false);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    local procedure LoadDataFromJson(JsonText: Text)
    var
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
        n: Integer;
    begin

        if not JArray.ReadFrom(JsonText) then
            exit;
        n := JArray.Count() - 1;
        for i := 0 to n do begin
            JArray.Get(i, JToken);
            JObject := JToken.AsObject();

            Rec.Init();
            Rec."Resource No." := GetJsonValue(JObject, 'ResourceNo');
            Rec."Job No." := GetJsonValue(JObject, 'JobNo');
            Rec."Job Task No." := GetJsonValue(JObject, 'JobTaskNo');
            Evaluate(Rec.Year, GetJsonValue(JObject, 'Year'));
            Evaluate(Rec."Week No.", GetJsonValue(JObject, 'WeekNo'));
            Evaluate(Rec."Monday Hours", GetJsonValue(JObject, 'MondayHours'));
            Evaluate(Rec."Tuesday Hours", GetJsonValue(JObject, 'TuesdayHours'));
            Evaluate(Rec."Wednesday Hours", GetJsonValue(JObject, 'WednesdayHours'));
            Evaluate(Rec."Thursday Hours", GetJsonValue(JObject, 'ThursdayHours'));
            Evaluate(Rec."Friday Hours", GetJsonValue(JObject, 'FridayHours'));
            Evaluate(Rec."Saturday Hours", GetJsonValue(JObject, 'SaturdayHours'));
            Evaluate(Rec."Sunday Hours", GetJsonValue(JObject, 'SundayHours'));
            Evaluate(Rec."Total Week Hours", GetJsonValue(JObject, 'TotalWeekHours'));
            Rec.Insert();
        end;
    end;

    local procedure GetJsonValue(JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(KeyName, JToken) then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        // ISO 8601: Week 1 is the week with Jan 4th
        Jan4 := DMY2Date(4, 1, YearValue);
        Week1Monday := CalcDate(StrSubstNo('<-%1D>', Date2DWY(Jan4, 1) - 1), Jan4);
        exit(CalcDate(StrSubstNo('<+%1W>', WeekNo - 1), Week1Monday));
    end;
}
