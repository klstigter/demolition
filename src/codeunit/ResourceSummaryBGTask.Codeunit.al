codeunit 50617 "Resource Summary BG Task"
{
    trigger OnRun()
    begin
        RunBackgroundTask();
    end;

    procedure RunBackgroundTask()
    var
        Parameters: Dictionary of [Text, Text];
        TaskType: Text;
    begin
        // Get parameters from page background task
        Parameters := Page.GetBackgroundParameters();
        TaskType := Parameters.Get('TaskType');
        case TaskType of
            'FactboxSummary':
                RunSummaryTask();
            'WeekView':
                RunWeeklyViewTask();
        end;
    end;

    local procedure RunSummaryTask()
    var
        ResourceSummary: Record "Resource DayTask Summary";
        Results: Dictionary of [Text, Text];
        Parameters: Dictionary of [Text, Text];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JsonText: Text;
    begin
        // Get parameters from page background task
        Parameters := Page.GetBackgroundParameters();
        JobNo := CopyStr(Parameters.Get('JobNo'), 1, 20);
        JobTaskNo := CopyStr(Parameters.Get('JobTaskNo'), 1, 20);

        ResourceSummary.FillBuffer(JobNo, JobTaskNo);
        JsonText := SerializeSummaryToJson(ResourceSummary);

        // Return results
        Results.Add('ResourceSummary', JsonText);
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure RunWeeklyViewTask()
    var
        DayTask: Record "Day Tasks";
        WeeklyHours: Record "Resource Weekly Hours";
        Results: Dictionary of [Text, Text];
        Parameters: Dictionary of [Text, Text];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JsonText: Text;
    begin
        // Get parameters from page background task
        Parameters := Page.GetBackgroundParameters();
        JobNo := CopyStr(Parameters.Get('JobNo'), 1, 20);
        JobTaskNo := CopyStr(Parameters.Get('JobTaskNo'), 1, 20);

        WeeklyHours.FillBuffer(JobNo, JobTaskNo);

        // Serialize to JSON
        JsonText := SerializeWeeklyHoursToJson(WeeklyHours);

        // Return results
        Results.Add('ResourceWeeklyHours', JsonText);
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure SerializeSummaryToJson(var ResourceSummary: Record "Resource DayTask Summary"): Text
    var
        JArray: JsonArray;
        JObject: JsonObject;
        JsonText: Text;
    begin
        ResourceSummary.Reset();
        if ResourceSummary.FindSet() then
            repeat
                Clear(JObject);
                JObject.Add('JobNo', ResourceSummary."Job No.");
                JObject.Add('JobTaskNo', ResourceSummary."Job Task No.");
                JObject.Add('ResourceNo', ResourceSummary."Resource No.");
                JObject.Add('TotalHours', Format(ResourceSummary."Total Hours", 0, 9));
                JArray.Add(JObject);
            until ResourceSummary.Next() = 0;

        JArray.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure SerializeWeeklyHoursToJson(var WeeklyHours: Record "Resource Weekly Hours"): Text
    var
        JArray: JsonArray;
        JObject: JsonObject;
        JsonText: Text;
    begin
        WeeklyHours.Reset();
        if WeeklyHours.FindSet() then
            repeat
                Clear(JObject);
                JObject.Add('ResourceNo', WeeklyHours."Resource No.");
                JObject.Add('JobNo', WeeklyHours."Job No.");
                JObject.Add('JobTaskNo', WeeklyHours."Job Task No.");
                JObject.Add('Year', Format(WeeklyHours.Year));
                JObject.Add('WeekNo', Format(WeeklyHours."Week No."));
                JObject.Add('MondayHours', Format(WeeklyHours."Monday Hours", 0, 9));
                JObject.Add('TuesdayHours', Format(WeeklyHours."Tuesday Hours", 0, 9));
                JObject.Add('WednesdayHours', Format(WeeklyHours."Wednesday Hours", 0, 9));
                JObject.Add('ThursdayHours', Format(WeeklyHours."Thursday Hours", 0, 9));
                JObject.Add('FridayHours', Format(WeeklyHours."Friday Hours", 0, 9));
                JObject.Add('SaturdayHours', Format(WeeklyHours."Saturday Hours", 0, 9));
                JObject.Add('SundayHours', Format(WeeklyHours."Sunday Hours", 0, 9));
                JObject.Add('TotalWeekHours', Format(WeeklyHours."Total Week Hours", 0, 9));
                JArray.Add(JObject);
            until WeeklyHours.Next() = 0;

        JArray.WriteTo(JsonText);
        exit(JsonText);
    end;
}

