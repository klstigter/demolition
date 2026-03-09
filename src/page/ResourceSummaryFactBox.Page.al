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
                    LoadDataInBackground();
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
        TaskParameters.Add('TaskType', 'FactboxSummary');

        // Start background task - codeunit ID 50617
        CurrPage.EnqueueBackgroundTask(TaskId, 50617, TaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        ResourceSummaryJson: Text;
    begin
        if not Results.ContainsKey('ResourceSummary') then
            exit;

        ResourceSummaryJson := Results.Get('ResourceSummary');
        LoadDataFromJson(ResourceSummaryJson);

        //CurrPage.Update(false);
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
    begin


        if not JArray.ReadFrom(JsonText) then
            exit;

        for i := 0 to JArray.Count() - 1 do begin
            JArray.Get(i, JToken);
            JObject := JToken.AsObject();

            Rec.Init();
            Rec."Job No." := GetJsonValue(JObject, 'JobNo');
            Rec."Job Task No." := GetJsonValue(JObject, 'JobTaskNo');
            Rec."Resource No." := GetJsonValue(JObject, 'ResourceNo');
            Evaluate(Rec."Total Hours", GetJsonValue(JObject, 'TotalHours'));
            Rec.CalcFields("Resource Name");
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
}
